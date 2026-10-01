/**
 * Subagents for pi: delegate a task to a named agent running in its own `pi`
 * process, so its exploration never lands in the parent's context window.
 *
 * Agents are markdown files with frontmatter (name, description, and optional
 * tools, model, thinking) in ~/.pi/agent/agents, plus .pi/agents of a trusted
 * project. One tool, three modes:
 *   - single:   { agent, task }
 *   - parallel: { tasks: [{ agent, task }, ...] }
 *   - chain:    { chain: [{ agent, task }, ...] }, `{previous}` is the prior step's output
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { type AgentConfig, discoverAgents, userAgentsDir } from "./agents.ts";
import { type Mode, renderCall, renderResult, type SubagentDetails } from "./render.ts";
import { addUsage, DEPTH_ENV, emptyUsage, newResult, type RunResult, runAgent } from "./runner.ts";

const MAX_PARALLEL_TASKS = 8;
const MAX_CONCURRENCY = 4;
const OUTPUT_CAP_BYTES = 50 * 1024;

const Step = Type.Object({
  agent: Type.String({ description: "Name of the agent to run" }),
  task: Type.String({ description: "Self-contained task; the agent sees nothing of this conversation" }),
  cwd: Type.Optional(Type.String({ description: "Working directory for this agent" })),
});

const Params = Type.Object({
  agent: Type.Optional(Type.String({ description: "Single mode: name of the agent to run" })),
  task: Type.Optional(Type.String({ description: "Single mode: self-contained task for the agent" })),
  cwd: Type.Optional(Type.String({ description: "Single mode: working directory for the agent" })),
  tasks: Type.Optional(Type.Array(Step, { description: `Parallel mode: up to ${MAX_PARALLEL_TASKS} independent tasks` })),
  chain: Type.Optional(
    Type.Array(Step, { description: "Chain mode: sequential steps; {previous} in a task is replaced by the prior step's output" }),
  ),
});

function capOutput(output: string): string {
  const bytes = Buffer.byteLength(output, "utf8");
  if (bytes <= OUTPUT_CAP_BYTES) return output;
  const kept = Buffer.from(output, "utf8").subarray(0, OUTPUT_CAP_BYTES).toString("utf8");
  return `${kept}\n\n[Output truncated: ${bytes - OUTPUT_CAP_BYTES} bytes omitted.]`;
}

function resultText(result: RunResult): string {
  if (result.status === "done") return capOutput(result.output) || "(no output)";
  return [result.error, capOutput(result.output)].filter(Boolean).join("\n\n") || "(no output)";
}

function snapshot(result: RunResult): RunResult {
  return { ...result, items: [...result.items] };
}

async function mapWithConcurrency<T, R>(items: T[], limit: number, fn: (item: T, index: number) => Promise<R>): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let next = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (next < items.length) {
      const index = next++;
      results[index] = await fn(items[index], index);
    }
  });
  await Promise.all(workers);
  return results;
}

function describeAgents(agents: AgentConfig[]): string {
  if (agents.length === 0) return `No agents found in ${userAgentsDir()}.`;
  return agents.map((agent) => `- ${agent.name}: ${agent.description}`).join("\n");
}

export default function subagentExtension(pi: ExtensionAPI) {
  pi.registerCommand("agents", {
    description: "List the agents the subagent tool can run",
    handler: async (_args, ctx) => {
      const agents = discoverAgents(ctx.cwd, ctx.isProjectTrusted());
      const lines = agents.map((agent) => {
        const model = agent.model ? ` [${agent.model}]` : "";
        return `${agent.name} (${agent.source})${model}: ${agent.description}`;
      });
      ctx.ui.notify(lines.join("\n") || `No agents found in ${userAgentsDir()}.`, "info");
    },
  });

  // A subagent does not delegate further: one level keeps cost and process count bounded.
  if (process.env[DEPTH_ENV]) return;

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Delegate work to a specialized agent that runs in its own pi process with a fresh context window.",
      "Only the agent's final answer comes back. The agent knows nothing about this conversation, so every task must be self-contained: include paths, constraints, and the expected output.",
      "Modes (use exactly one): single (agent + task), parallel (tasks), chain (chain, with {previous} carrying the prior step's output).",
      `Available agents:\n${describeAgents(discoverAgents(process.cwd(), false))}`,
    ].join("\n"),
    promptSnippet: "Delegate a self-contained task to a specialized agent with its own context window",
    promptGuidelines: [
      "Use subagent for broad codebase exploration, independent parallel work, or a second-opinion review; do small lookups yourself.",
    ],
    parameters: Params,

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const agents = discoverAgents(ctx.cwd, ctx.isProjectTrusted());
      const available = agents.map((agent) => agent.name);
      const inherit = {
        model: ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined,
        thinking: ctx.thinkingLevel,
      };

      const chain = params.chain ?? [];
      const tasks = params.tasks ?? [];
      const single = params.agent && params.task ? { agent: params.agent, task: params.task, cwd: params.cwd } : undefined;
      const modes = Number(chain.length > 0) + Number(tasks.length > 0) + Number(Boolean(single));
      if (modes !== 1) {
        throw new Error(
          `Provide exactly one of: agent + task, tasks, or chain. Available agents: ${available.join(", ") || "none"}.`,
        );
      }
      if (tasks.length > MAX_PARALLEL_TASKS) {
        throw new Error(`Too many parallel tasks (${tasks.length}); the maximum is ${MAX_PARALLEL_TASKS}.`);
      }

      const mode: Mode = chain.length > 0 ? "chain" : tasks.length > 0 ? "parallel" : "single";
      const steps = single ? [single] : mode === "chain" ? chain : tasks;
      const results: RunResult[] = steps.map((step, index) =>
        newResult(step.agent, step.task, mode === "chain" ? index + 1 : undefined),
      );

      const emit = (text: string) => {
        onUpdate?.({ content: [{ type: "text", text }], details: { mode, results: results.map(snapshot) } });
      };
      const run = async (index: number, task: string) => {
        const step = steps[index];
        results[index] = await runAgent({
          agent: agents.find((agent) => agent.name === step.agent),
          agentName: step.agent,
          available,
          task,
          cwd: step.cwd ?? ctx.cwd,
          inherit,
          step: results[index].step,
          signal,
          onUpdate: (partial) => {
            results[index] = partial;
            const done = results.filter((result) => result.status !== "running").length;
            emit(`${done}/${results.length} done`);
          },
        });
        return results[index];
      };

      let text: string;
      let failed: boolean;
      if (mode === "parallel") {
        await mapWithConcurrency(steps, MAX_CONCURRENCY, (step, index) => run(index, step.task));
        const ok = results.filter((result) => result.status === "done").length;
        failed = ok === 0;
        const sections = results.map((result) => `### [${result.agent}] ${result.status}\n\n${resultText(result)}`);
        text = `Parallel: ${ok}/${results.length} succeeded\n\n${sections.join("\n\n---\n\n")}`;
      } else {
        let previous = "";
        let last = results[0];
        for (let index = 0; index < steps.length; index++) {
          last = await run(index, steps[index].task.replace(/\{previous\}/g, previous));
          if (last.status !== "done") break;
          previous = last.output;
        }
        failed = last.status !== "done";
        text = resultText(last);
        if (failed && mode === "chain") {
          text = `Chain stopped at step ${last.step} (${last.agent}): ${text}`;
          // Steps after the failure never ran; drop their placeholders.
          results.length = last.step ?? results.length;
        }
      }

      if (signal?.aborted) throw new Error("Subagent was aborted.");

      // Child model calls are otherwise invisible to the session's cost totals.
      const usage = emptyUsage();
      for (const result of results) addUsage(usage, result.usage);
      const details: SubagentDetails = { mode, results };
      return { content: [{ type: "text", text }], details, usage, isError: failed || undefined };
    },

    renderCall(args, theme) {
      return renderCall(args, theme);
    },

    renderResult(result, { expanded }, theme) {
      return renderResult(result.content, result.details as SubagentDetails | undefined, expanded, theme);
    },
  });
}

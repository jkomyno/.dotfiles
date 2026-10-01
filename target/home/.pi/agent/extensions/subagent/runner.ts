import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { Usage } from "@earendil-works/pi-ai";
import type { AgentConfig, AgentSource } from "./agents.ts";

/** Set on child processes so a subagent never registers the `subagent` tool itself. */
export const DEPTH_ENV = "PI_SUBAGENT_DEPTH";

const KILL_GRACE_MS = 5000;
const STDERR_CAP = 16 * 1024;

export type RunStatus = "running" | "done" | "failed" | "aborted";

export type DisplayItem =
  | { type: "text"; text: string }
  | { type: "tool"; name: string; args: Record<string, unknown> };

export interface RunResult {
  agent: string;
  source: AgentSource | "unknown";
  task: string;
  status: RunStatus;
  items: DisplayItem[];
  output: string;
  error?: string;
  model?: string;
  turns: number;
  contextTokens: number;
  usage: Usage;
  step?: number;
}

export interface RunOptions {
  agent: AgentConfig | undefined;
  agentName: string;
  available: string[];
  task: string;
  cwd: string;
  /** Model and thinking level of the dispatching session, used when the agent pins none. */
  inherit: { model?: string; thinking?: string };
  step?: number;
  signal?: AbortSignal;
  onUpdate?: (result: RunResult) => void;
}

export function emptyUsage(): Usage {
  return {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
    totalTokens: 0,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
  };
}

export function addUsage(total: Usage, usage: Partial<Usage> | undefined): void {
  if (!usage) return;
  total.input += usage.input ?? 0;
  total.output += usage.output ?? 0;
  total.cacheRead += usage.cacheRead ?? 0;
  total.cacheWrite += usage.cacheWrite ?? 0;
  total.totalTokens += usage.totalTokens ?? 0;
  total.cost.input += usage.cost?.input ?? 0;
  total.cost.output += usage.cost?.output ?? 0;
  total.cost.cacheRead += usage.cost?.cacheRead ?? 0;
  total.cost.cacheWrite += usage.cost?.cacheWrite ?? 0;
  total.cost.total += usage.cost?.total ?? 0;
}

export function newResult(agent: string, task: string, step?: number): RunResult {
  return {
    agent,
    source: "unknown",
    task,
    status: "running",
    items: [],
    output: "",
    turns: 0,
    contextTokens: 0,
    usage: emptyUsage(),
    step,
  };
}

/** Re-run the pi that is hosting this extension, whether it is a script or a compiled binary. */
function piInvocation(args: string[]): { command: string; args: string[] } {
  const script = process.argv[1];
  if (script && !script.startsWith("/$bunfs/root/") && fs.existsSync(script)) {
    return { command: process.execPath, args: [script, ...args] };
  }
  const execName = path.basename(process.execPath).toLowerCase();
  if (!/^(node|bun)(\.exe)?$/.test(execName)) return { command: process.execPath, args };
  return { command: "pi", args };
}

function childDepth(): string {
  const current = Number.parseInt(process.env[DEPTH_ENV] ?? "0", 10);
  return String((Number.isFinite(current) ? current : 0) + 1);
}

type ChildMessage = {
  role?: string;
  content?: unknown;
  usage?: Partial<Usage>;
  model?: string;
  stopReason?: string;
  errorMessage?: string;
};

function recordAssistantMessage(result: RunResult, message: ChildMessage): void {
  result.turns++;
  addUsage(result.usage, message.usage);
  result.contextTokens = message.usage?.totalTokens ?? result.contextTokens;
  if (message.model) result.model = message.model;
  if (message.stopReason === "error" || message.stopReason === "aborted") {
    result.error = message.errorMessage || `stopped: ${message.stopReason}`;
  } else {
    result.error = undefined;
  }

  let text = "";
  for (const part of Array.isArray(message.content) ? message.content : []) {
    if (part?.type === "text" && typeof part.text === "string") {
      text += part.text;
      result.items.push({ type: "text", text: part.text });
    } else if (part?.type === "toolCall" && typeof part.name === "string") {
      result.items.push({ type: "tool", name: part.name, args: part.arguments ?? {} });
    }
  }
  // The last assistant message carrying text is the agent's answer.
  if (text.trim()) result.output = text;
}

export async function runAgent(options: RunOptions): Promise<RunResult> {
  const { agent, agentName, task, signal, onUpdate } = options;
  const result = newResult(agentName, task, options.step);

  if (!agent) {
    result.status = "failed";
    result.error = `Unknown agent "${agentName}". Available agents: ${options.available.join(", ") || "none"}.`;
    return result;
  }
  result.source = agent.source;

  const args = ["--mode", "json", "-p", "--no-session"];
  const model = agent.model ?? options.inherit.model;
  if (model) args.push("--model", model);
  const thinking = agent.thinking ?? (agent.model ? undefined : options.inherit.thinking);
  if (thinking) args.push("--thinking", thinking);
  if (agent.tools) args.push("--tools", agent.tools.join(","));
  result.model = model;

  let promptDir: string | undefined;
  try {
    if (agent.systemPrompt.trim()) {
      promptDir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-subagent-"));
      const promptPath = path.join(promptDir, "system-prompt.md");
      await fs.promises.writeFile(promptPath, agent.systemPrompt, { encoding: "utf-8", mode: 0o600 });
      args.push("--append-system-prompt", promptPath);
    }
    args.push(`Task: ${task}`);

    let stderr = "";
    let aborted = false;
    const exitCode = await new Promise<number>((resolve) => {
      const invocation = piInvocation(args);
      const child = spawn(invocation.command, invocation.args, {
        cwd: options.cwd,
        env: { ...process.env, [DEPTH_ENV]: childDepth() },
        shell: false,
        stdio: ["ignore", "pipe", "pipe"],
      });

      const handleLine = (line: string) => {
        if (!line.trim()) return;
        let event: { type?: string; message?: ChildMessage };
        try {
          event = JSON.parse(line);
        } catch {
          return;
        }
        if (event.type !== "message_end" || event.message?.role !== "assistant") return;
        recordAssistantMessage(result, event.message);
        onUpdate?.(result);
      };

      let buffer = "";
      child.stdout.on("data", (chunk) => {
        buffer += chunk.toString();
        const lines = buffer.split("\n");
        buffer = lines.pop() ?? "";
        for (const line of lines) handleLine(line);
      });
      child.stderr.on("data", (chunk) => {
        if (stderr.length < STDERR_CAP) stderr += chunk.toString();
      });

      const kill = () => {
        aborted = true;
        child.kill("SIGTERM");
        setTimeout(() => {
          if (child.exitCode === null) child.kill("SIGKILL");
        }, KILL_GRACE_MS).unref();
      };
      if (signal?.aborted) kill();
      else signal?.addEventListener("abort", kill, { once: true });

      child.on("error", (error) => {
        stderr += error.message;
        resolve(1);
      });
      child.on("close", (code) => {
        signal?.removeEventListener("abort", kill);
        if (buffer.trim()) handleLine(buffer);
        resolve(code ?? 1);
      });
    });

    if (aborted) {
      result.status = "aborted";
      result.error = "Subagent was aborted.";
    } else if (exitCode !== 0 || result.error) {
      result.status = "failed";
      result.error = result.error || stderr.trim() || `pi exited with code ${exitCode}`;
    } else {
      result.status = "done";
    }
    return result;
  } finally {
    if (promptDir) await fs.promises.rm(promptDir, { recursive: true, force: true });
  }
}

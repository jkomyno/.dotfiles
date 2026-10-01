import * as os from "node:os";
import type { Usage } from "@earendil-works/pi-ai";
import { getMarkdownTheme, type Theme } from "@earendil-works/pi-coding-agent";
import { type Component, Container, Markdown, Spacer, Text } from "@earendil-works/pi-tui";
import { addUsage, type DisplayItem, emptyUsage, type RunResult } from "./runner.ts";

export type Mode = "single" | "parallel" | "chain";

export interface SubagentDetails {
  mode: Mode;
  results: RunResult[];
}

const COLLAPSED_ITEMS = 6;

function clip(text: string, max: number): string {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max)}...` : flat;
}

function tokens(count: number): string {
  if (count < 1000) return String(count);
  if (count < 10_000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1000)}k`;
  return `${(count / 1_000_000).toFixed(1)}M`;
}

function usageLine(usage: Usage, extra: { turns?: number; contextTokens?: number; model?: string } = {}): string {
  const parts: string[] = [];
  if (extra.turns) parts.push(`${extra.turns} turn${extra.turns > 1 ? "s" : ""}`);
  if (usage.input) parts.push(`↑${tokens(usage.input)}`);
  if (usage.output) parts.push(`↓${tokens(usage.output)}`);
  if (usage.cacheRead) parts.push(`R${tokens(usage.cacheRead)}`);
  if (usage.cacheWrite) parts.push(`W${tokens(usage.cacheWrite)}`);
  if (usage.cost.total) parts.push(`$${usage.cost.total.toFixed(4)}`);
  if (extra.contextTokens) parts.push(`ctx:${tokens(extra.contextTokens)}`);
  if (extra.model) parts.push(extra.model);
  return parts.join(" ");
}

function toolLine(item: Extract<DisplayItem, { type: "tool" }>, theme: Theme): string {
  const home = os.homedir();
  const shorten = (value: unknown) => {
    const text = typeof value === "string" ? value : "";
    return text.startsWith(home) ? `~${text.slice(home.length)}` : text;
  };
  const { name, args } = item;
  const target = args.file_path ?? args.path;
  let detail: string;
  if (name === "bash") detail = clip(String(args.command ?? ""), 70);
  else if (name === "grep" || name === "find") detail = `${args.pattern ?? ""} ${shorten(target)}`.trim();
  else if (typeof target === "string") detail = shorten(target);
  else detail = clip(JSON.stringify(args), 60);
  return `${theme.fg("muted", "→ ")}${theme.fg("accent", name)} ${theme.fg("dim", detail)}`;
}

function statusIcon(result: RunResult, theme: Theme): string {
  if (result.status === "running") return theme.fg("warning", "⏳");
  return result.status === "done" ? theme.fg("success", "✓") : theme.fg("error", "✗");
}

function heading(result: RunResult, theme: Theme): string {
  const step = result.step ? theme.fg("muted", `${result.step}. `) : "";
  const source = result.source === "project" ? theme.fg("muted", " (project)") : "";
  return `${statusIcon(result, theme)} ${step}${theme.fg("toolTitle", theme.bold(result.agent))}${source}`;
}

function collapsedBody(result: RunResult, theme: Theme): string {
  if (result.error) return theme.fg("error", clip(result.error, 200));
  if (result.items.length === 0) return theme.fg("muted", result.status === "running" ? "(running...)" : "(no output)");
  const lines: string[] = [];
  const hidden = result.items.length - COLLAPSED_ITEMS;
  if (hidden > 0) lines.push(theme.fg("muted", `... ${hidden} earlier items`));
  for (const item of result.items.slice(-COLLAPSED_ITEMS)) {
    lines.push(item.type === "tool" ? toolLine(item, theme) : theme.fg("toolOutput", clip(item.text, 160)));
  }
  return lines.join("\n");
}

function totalUsage(results: RunResult[]): Usage {
  const total = emptyUsage();
  for (const result of results) addUsage(total, result.usage);
  return total;
}

function summary(details: SubagentDetails, theme: Theme): string {
  const done = details.results.filter((result) => result.status === "done").length;
  const running = details.results.filter((result) => result.status === "running").length;
  const counts = running > 0 ? `${done}/${details.results.length} done, ${running} running` : `${done}/${details.results.length} ok`;
  return `${theme.fg("toolTitle", theme.bold(`subagent ${details.mode}`))} ${theme.fg("accent", counts)}`;
}

export function renderCall(
  args: { agent?: string; task?: string; tasks?: { agent: string; task: string }[]; chain?: { agent: string; task: string }[] },
  theme: Theme,
): Component {
  const title = theme.fg("toolTitle", theme.bold("subagent "));
  const list = args.chain?.length ? args.chain : args.tasks;
  if (!list?.length) {
    return new Text(`${title}${theme.fg("accent", args.agent ?? "...")}\n  ${theme.fg("dim", clip(args.task ?? "...", 80))}`, 0, 0);
  }
  const mode = args.chain?.length ? "chain" : "parallel";
  let text = `${title}${theme.fg("accent", `${mode} (${list.length})`)}`;
  for (const item of list.slice(0, 4)) {
    text += `\n  ${theme.fg("accent", item.agent)} ${theme.fg("dim", clip(item.task.replace(/\{previous\}/g, ""), 60))}`;
  }
  if (list.length > 4) text += `\n  ${theme.fg("muted", `... +${list.length - 4} more`)}`;
  return new Text(text, 0, 0);
}

export function renderResult(
  content: { type: string; text?: string }[],
  details: SubagentDetails | undefined,
  expanded: boolean,
  theme: Theme,
): Component {
  if (!details || details.results.length === 0) {
    return new Text(content[0]?.text ?? "(no output)", 0, 0);
  }
  const multiple = details.mode !== "single";

  if (!expanded) {
    const blocks = details.results.map((result) => {
      const stats = usageLine(result.usage, result);
      return `${heading(result, theme)}\n${collapsedBody(result, theme)}${stats && !multiple ? `\n${theme.fg("dim", stats)}` : ""}`;
    });
    let text = multiple ? `${summary(details, theme)}\n\n${blocks.join("\n\n")}` : blocks[0];
    if (multiple) {
      const stats = usageLine(totalUsage(details.results));
      if (stats) text += `\n\n${theme.fg("dim", `Total: ${stats}`)}`;
    }
    return new Text(text, 0, 0);
  }

  const container = new Container();
  if (multiple) container.addChild(new Text(summary(details, theme), 0, 0));
  for (const result of details.results) {
    if (multiple) container.addChild(new Spacer(1));
    container.addChild(new Text(heading(result, theme), 0, 0));
    container.addChild(new Text(theme.fg("muted", "Task: ") + theme.fg("dim", result.task), 0, 0));
    for (const item of result.items) {
      if (item.type === "tool") container.addChild(new Text(toolLine(item, theme), 0, 0));
    }
    if (result.error) container.addChild(new Text(theme.fg("error", result.error), 0, 0));
    if (result.output.trim()) {
      container.addChild(new Spacer(1));
      container.addChild(new Markdown(result.output.trim(), 0, 0, getMarkdownTheme()));
    }
    const stats = usageLine(result.usage, result);
    if (stats) container.addChild(new Text(theme.fg("dim", stats), 0, 0));
  }
  if (multiple) {
    const stats = usageLine(totalUsage(details.results));
    if (stats) {
      container.addChild(new Spacer(1));
      container.addChild(new Text(theme.fg("dim", `Total: ${stats}`), 0, 0));
    }
  }
  return container;
}

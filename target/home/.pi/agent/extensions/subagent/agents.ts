import * as fs from "node:fs";
import * as path from "node:path";
import { CONFIG_DIR_NAME, getAgentDir, parseFrontmatter } from "@earendil-works/pi-coding-agent";

export type AgentSource = "user" | "project";

export interface AgentConfig {
  name: string;
  description: string;
  tools?: string[];
  model?: string;
  thinking?: string;
  systemPrompt: string;
  source: AgentSource;
  filePath: string;
}

type AgentFrontmatter = {
  name?: unknown;
  description?: unknown;
  tools?: unknown;
  model?: unknown;
  thinking?: unknown;
};

// `tools: read, bash` and `tools: [read, bash]` are both valid YAML and both in use.
function parseToolList(value: unknown): string[] | undefined {
  const raw = Array.isArray(value) ? value : typeof value === "string" ? value.split(",") : [];
  const tools = raw
    .filter((tool): tool is string => typeof tool === "string")
    .map((tool) => tool.trim())
    .filter(Boolean);
  return tools.length > 0 ? tools : undefined;
}

function optionalString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim() ? value.trim() : undefined;
}

// One unreadable or malformed file must not hide every other agent in the directory.
function loadAgentsFromDir(dir: string, source: AgentSource): AgentConfig[] {
  let entries: fs.Dirent[];
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }

  const agents: AgentConfig[] = [];
  for (const entry of entries) {
    if (!entry.name.endsWith(".md")) continue;
    if (!entry.isFile() && !entry.isSymbolicLink()) continue;

    const filePath = path.join(dir, entry.name);
    let content: string;
    try {
      content = fs.readFileSync(filePath, "utf-8");
    } catch {
      continue;
    }

    const { frontmatter, body } = parseFrontmatter<AgentFrontmatter>(content);
    const name = optionalString(frontmatter.name);
    const description = optionalString(frontmatter.description);
    if (!name || !description) continue;

    agents.push({
      name,
      description,
      tools: parseToolList(frontmatter.tools),
      model: optionalString(frontmatter.model),
      thinking: optionalString(frontmatter.thinking),
      systemPrompt: body,
      source,
      filePath,
    });
  }
  return agents.sort((a, b) => a.name.localeCompare(b.name));
}

function findProjectAgentsDir(cwd: string): string | undefined {
  let current = cwd;
  while (true) {
    const candidate = path.join(current, CONFIG_DIR_NAME, "agents");
    try {
      if (fs.statSync(candidate).isDirectory()) return candidate;
    } catch {
      // keep walking up
    }
    const parent = path.dirname(current);
    if (parent === current) return undefined;
    current = parent;
  }
}

export function userAgentsDir(): string {
  return path.join(getAgentDir(), "agents");
}

/**
 * User agents always load. Project agents are repo-controlled prompts, so they
 * load only for trusted projects, where they override user agents by name.
 */
export function discoverAgents(cwd: string, includeProject: boolean): AgentConfig[] {
  const byName = new Map<string, AgentConfig>();
  for (const agent of loadAgentsFromDir(userAgentsDir(), "user")) byName.set(agent.name, agent);

  const projectDir = includeProject ? findProjectAgentsDir(cwd) : undefined;
  if (projectDir) {
    for (const agent of loadAgentsFromDir(projectDir, "project")) byName.set(agent.name, agent);
  }
  return Array.from(byName.values());
}

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawn } from "node:child_process";
import path from "node:path";
import os from "node:os";

// pi adapter for the shared auto-commit checkpoint.
//
// `agent_end` fires once per completed user prompt (unlike `turn_end`, which
// fires per LLM/tool cycle) — so this makes one checkpoint commit per response.
// We fire-and-forget the shared script, detached, so pi never blocks or breaks
// if the commit is slow or errors.
export default function autocheckpoint(pi: ExtensionAPI) {
  pi.on("agent_end", async () => {
    const script = path.join(os.homedir(), ".agents", "bin", "agent-checkpoint.sh");
    try {
      const child = spawn(script, ["commit", "--agent", "pi", "--cwd", process.cwd()], {
        stdio: "ignore",
        detached: true,
      });
      child.on("error", () => {});
      child.unref();
    } catch {
      // Never let a checkpoint failure surface to the agent.
    }
  });
}

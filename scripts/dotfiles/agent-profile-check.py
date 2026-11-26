#!/usr/bin/env python3
"""Check profile-to-profile agent migration with existing host-owned state."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def check(home):
    def run(profile, *options, ok=True):
        env = dict(os.environ, HOME=str(home), DOTFILES_SELECTION=profile)
        result = subprocess.run(["bash", str(HERE / "claude-skill-links.sh"), *options],
                                capture_output=True, text=True, env=env)
        if (result.returncode == 0) != ok:
            raise AssertionError(result.stderr)
        return result

    shared = home / ".agents/skills"
    claude = home / ".claude/settings.json"
    pi = home / ".pi/agent/settings.json"
    codex = home / ".codex/config.toml"
    private = home / ".pi/agent/models.json"
    source = HERE.parents[1] / "target/home/.agents/skills"
    full = set(run("full", "--list").stdout.splitlines())
    assert full == {entry.parent.name for entry in source.glob("*/SKILL.md")}
    write(shared / "local/SKILL.md", "local skill\n")
    write(claude, '{"model":"host","hooks":{"Stop":[{"hooks":[{"type":"command","command":"host-hook"}]}]},"enabledPlugins":{"local@host":true}}')
    write(pi, '{"defaultProvider":"host","packages":["npm:host-extension"]}')
    write(private, '{"providers":{"openrouter":{"apiKey":"fixture-provider"}}}')
    project = '[projects."/host/project"]\ntrust_level = "trusted"\n'
    write(codex, 'model = "host"\n' + project + '\n[mcp_servers.host]\nurl = "http://localhost"\n')
    run("full")
    run("full", "--check")
    assert (shared / "lean4/SKILL.md").is_file()
    assert "[mcp_servers.lean-lsp]" in codex.read_text()
    switch = run("work go", "--plan").stderr
    assert "unlink ~/.agents/skills/lean4" in switch
    assert (shared / "lean4").is_symlink()
    run("work go")
    run("work go", "--check")
    assert not (shared / "lean4").is_symlink()
    assert not (home / ".claude/skills/lean4").is_symlink()
    assert (shared / "local/SKILL.md").read_text() == "local skill\n"
    assert project in codex.read_text() and "[mcp_servers.host]" in codex.read_text()
    assert "[mcp_servers.lean-lsp]" not in codex.read_text()
    settings = json.loads(claude.read_text())
    assert settings["model"] == "host" and settings["enabledPlugins"]["local@host"]
    assert "host-hook" in json.dumps(settings["hooks"])
    assert settings["enabledPlugins"]["interface-design@interface-design"]
    assert json.loads(pi.read_text())["defaultProvider"] == "host"
    assert "npm:host-extension" in json.loads(pi.read_text())["packages"]
    assert json.loads(private.read_text())["providers"]["openrouter"]["apiKey"] == "fixture-provider"
    before_pi = pi.read_text()
    settings = json.loads(before_pi)
    settings["packages"].append({"source": "npm:pi-web-access", "extensions": ["*"]})
    write(pi, json.dumps(settings))
    assert "customized Pi package" in run("essentials", ok=False).stderr
    assert json.loads(pi.read_text()) == settings
    write(pi, before_pi)
    (shared / "research").unlink()
    write(shared / "research/SKILL.md", "host-owned collision\n")
    before = claude.read_bytes()
    assert "research" in run("essentials", ok=False).stderr
    assert claude.read_bytes() == before
    assert (shared / "research/SKILL.md").read_text() == "host-owned collision\n"


if __name__ == "__main__":
    with tempfile.TemporaryDirectory() as tmp:
        check(Path(tmp))
    print("Agent profile migration passed")

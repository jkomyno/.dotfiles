#!/usr/bin/env python3
"""Converge the agent configuration owned by the selected dotfiles bundles."""
import argparse
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

try:
    import tomllib
except ImportError:  # Apple Command Line Tools ship Python 3.9.
    from pip._vendor import tomli as tomllib

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1] / "target/home"
HOME = Path.home()
BUNDLES = os.environ["DOTFILES_BUNDLES"].split()
SHARED = Path(".agents/skills")
CLAUDE = Path(".claude/skills")
CONFIGS = (".claude/settings.json", ".codex/config.toml", ".pi/agent/settings.json",
           ".pi/agent/mcp.json", ".pi/agent/models.json", ".pi/agent/claude-bridge.json")
SKILLS = json.loads((HERE / "agent-skills.json").read_text())
MANIFEST = json.loads((HERE / "agent-plugins.json").read_text())


def selected_skills():
    return sorted(name for bundle in BUNDLES for name in SKILLS[bundle])


def command_available(name):
    executable = shutil.which(name)
    if not executable:
        return False
    # A rustup or mise shim can exist when the toolchain lacks rust-analyzer.
    # Both LSP servers support a local --version probe without starting a service.
    try:
        return subprocess.run([executable, "--version"], stdin=subprocess.DEVNULL,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                              timeout=3).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def selected_plugins():
    result = MANIFEST.copy()
    requirements = result.pop("pluginRequirements")
    def enabled(name):
        entry = requirements.get(name, {})
        return (entry.get("bundle", "essentials") in BUNDLES and
                ("command" not in entry or command_available(entry["command"])))
    result["plugins"] = [name for name in result["plugins"] if enabled(name)]
    markets = {name.split("@", 1)[1] for name in result["plugins"]}
    result["marketplaces"] = [m for m in result["marketplaces"] if m["name"] in markets]
    return result


def immediate_link_target(path):
    return Path(os.path.abspath(path.parent / os.readlink(path)))


def check_parents(path):
    for parent in path.relative_to(HOME).parents:
        candidate = HOME / parent
        if candidate.is_symlink() or (candidate.exists() and not candidate.is_dir()):
            raise ValueError(f"host-owned parent of {path}: {candidate}")


def skill_changes():
    selected = set(selected_skills())
    catalog = {name for names in SKILLS.values() for name in names}
    for rel in (SHARED, CLAUDE):
        view = HOME / rel
        source = ROOT / SHARED
        check_parents(view)
        legacy = view.is_symlink()
        if legacy:
            allowed = [source] + ([HOME / SHARED] if rel == CLAUDE else [])
            if immediate_link_target(view) not in allowed:
                raise ValueError(f"host-owned skill directory link: {view}")
        elif view.exists() and not view.is_dir():
            raise ValueError(f"expected skill directory at {view}")
        if legacy or not view.is_dir():
            yield ("directory", view, None, os.readlink(view) if legacy else None)
        existing = set() if legacy or not view.is_dir() else {p.name for p in view.iterdir()}
        for name in sorted(selected | existing):
            path = view / name
            target = source / name if rel == SHARED else Path("..", "..", SHARED, name)
            owned = (name in existing and path.is_symlink() and
                     immediate_link_target(path) in ([source / name] if rel == SHARED else
                                                 [source / name, HOME / SHARED / name]))
            if name not in selected:
                if owned:
                    yield ("unlink", path, None, os.readlink(path))
                elif name in catalog:
                    raise ValueError(f"host-owned skill shadows an excluded skill: {path}")
            elif not (source / name / "SKILL.md").is_file():
                raise ValueError(f"listed skill is missing: {source/name}")
            elif name not in existing:
                yield ("link", path, target, None)
            elif not owned:
                raise ValueError(f"host-owned skill conflicts with selection: {path}")
            elif os.readlink(path) != str(target):
                yield ("link", path, target, os.readlink(path))


def fill_defaults(local, defaults):
    """Add missing dictionary entries while retaining machine-owned preferences."""
    for key, value in defaults.items():
        if key not in local:
            local[key] = copy.deepcopy(value)
        elif isinstance(value, dict) and isinstance(local[key], dict):
            fill_defaults(local[key], value)


def claude_settings(local, defaults, fresh):
    enabled = selected_plugins()["plugins"]
    plugins = local.setdefault("enabledPlugins", {})
    for name in defaults.pop("enabledPlugins"):
        if name in enabled:
            plugins[name] = True
        elif name in plugins:
            plugins[name] = False
    hooks = local.setdefault("hooks", {})
    for event, groups in defaults.pop("hooks").items():
        current = hooks.get(event, [])
        for original in groups:
            group = copy.deepcopy(original)
            design_hook = any("/impeccable/scripts/impeccable" in h["command"] for h in group["hooks"])
            if design_hook:
                for hook in group["hooks"]:
                    hook["command"] = ('runner="$HOME/.claude/skills/impeccable/scripts/impeccable"; '
                                       '[ ! -f "$runner" ] || "$runner" hook')
                if original in current:
                    current.remove(original)
            enabled_hook = not design_hook or "web" in BUNDLES
            if enabled_hook and group not in current:
                current.append(group)
            elif not enabled_hook and group in current:
                current.remove(group)
        if current:
            hooks[event] = current
        else:
            hooks.pop(event, None)
    if "web" not in BUNDLES:
        description = defaults.pop("description", None)
        if description is not None and local.get("description") == description:
            local.pop("description")
    # A GUI-launched agent can lack activation and mise does not always create
    # shims. mise exec supplies PATH to ccstatusline and its ccusage widget.
    status = defaults["statusLine"]
    if local.get("statusLine") == status:
        local.pop("statusLine")
    status["command"] = '"$HOME/.local/bin/mise" exec -- ccstatusline'
    # An existing host keeps its model, permissions and prompt preferences.
    if fresh:
        fill_defaults(local, defaults)
    elif "statusLine" not in local:
        local["statusLine"] = defaults["statusLine"]


def selected_pi_packages(packages):
    return [package for package in packages
            if package != "npm:pi-web-access" or "web" in BUNDLES]


def pi_settings(local, defaults, fresh):
    packages = local.setdefault("packages", [])
    managed = defaults.pop("packages")
    selected = selected_pi_packages(managed)
    for package in managed:
        configured_source = any(isinstance(entry, dict) and entry.get("source") == package
                                for entry in packages)
        if package not in selected:
            if configured_source:
                raise ValueError(f"review the host's customized Pi package {package} in ~/.pi/agent/settings.json")
            if package in packages:
                packages.remove(package)
        elif package not in packages and not configured_source:
            packages.append(package)
    if fresh:
        fill_defaults(local, defaults)


def codex_settings(content, source):
    # Bootstrap from the curated base. Existing preferences and project tables
    # belong to Codex; only the named managed MCP server tables change.
    text = source if content is None else content
    current = tomllib.loads(text)
    expected = copy.deepcopy(current)
    servers = expected.setdefault("mcp_servers", {})
    for name, entry in tomllib.loads(source)["mcp_servers"].items():
        header = f"[mcp_servers.{name}]"
        block = header + "\n" + "\n".join(f"{k} = {json.dumps(v)}" for k, v in entry.items()) + "\n"
        if name == "lean-lsp" and "system-engineering" not in BUNDLES:
            if name not in servers:
                continue
            if servers[name] != entry or block not in text:
                raise ValueError("review host-owned [mcp_servers.lean-lsp] before switching profiles")
            text = text.replace(block, "", 1)
            del servers[name]
        elif name not in servers:
            text = text.rstrip() + "\n\n" + block
            servers[name] = entry
    if tomllib.loads(text) != expected:
        raise ValueError("cannot edit managed MCP entries without altering host TOML")
    return text


def config_changes():
    for relative in CONFIGS:
        path = HOME / relative
        check_parents(path)
        if path.is_symlink() and immediate_link_target(path) != ROOT / relative:
            raise ValueError(f"host-owned config link: {path}")
        if path.exists() and not path.is_file():
            raise ValueError(f"expected a regular file at {path}")
        content = path.read_text() if path.is_file() else None
        source = (ROOT / relative).read_text()
        if path.suffix == ".toml":
            updated = codex_settings(content, source)
        else:
            local = json.loads(content) if content is not None else {}
            before = copy.deepcopy(local)
            defaults = json.loads(source)
            if not isinstance(local, dict):
                raise ValueError(f"expected a configuration object at {path}")
            if relative == ".claude/settings.json":
                claude_settings(local, defaults, content is None)
            elif relative == ".pi/agent/settings.json":
                pi_settings(local, defaults, content is None)
            else:
                fill_defaults(local, defaults)
            if not path.is_symlink() and content is not None and local == before:
                continue
            updated = json.dumps(local, indent=2, ensure_ascii=False) + "\n"
        if content != updated or path.is_symlink():
            yield ("configure", path, (content, updated), os.readlink(path) if path.is_symlink() else None)


def apply_change(action, path, value, expected_link):
    check_parents(path)
    if (os.readlink(path) if path.is_symlink() else None) != expected_link:
        raise ValueError(f"link changed during apply; review {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    if action == "configure":
        # Preserve an existing restrictive mode. A legacy link is replaced at
        # the destination, never followed for writes.
        before, updated = value
        if (path.read_text() if path.exists() else None) != before:
            raise ValueError(f"configuration changed during apply; retry {path}")
        with tempfile.NamedTemporaryFile(dir=path.parent, mode="w", delete=False) as tmp:
            temp_path = Path(tmp.name)
            try:
                tmp.write(updated)
                if path.is_file() and not path.is_symlink():
                    os.fchmod(tmp.fileno(), path.stat().st_mode & 0o777)
                tmp.flush()
                os.replace(temp_path, path)
            finally:
                if temp_path.exists():
                    temp_path.unlink()
    elif action == "directory":
        if path.is_symlink():
            path.unlink()
        path.mkdir()
    elif action == "link":
        if path.is_symlink():
            path.unlink()
        path.symlink_to(value)
    elif action == "unlink":
        path.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    for name in ("plan", "check", "list", "list-configs", "plugins", "pi-packages"):
        mode.add_argument("--" + name, action="store_true")
    args = parser.parse_args()
    if args.list:
        print("\n".join(selected_skills()))
        return 0
    if args.list_configs:
        print("\n".join(CONFIGS))
        return 0
    if args.pi_packages:
        defaults = json.loads((ROOT / ".pi/agent/settings.json").read_text())
        print("\n".join(selected_pi_packages(defaults["packages"])))
        return 0
    if args.plugins:
        print(json.dumps(selected_plugins()))
        return 0
    changes = list(skill_changes()) + list(config_changes())
    for action, path, value, expected_link in changes:
        print(f"{action} ~/{path.relative_to(HOME)}", file=sys.stderr)
        if not args.check and not args.plan:
            apply_change(action, path, value, expected_link)
    return int(args.check and bool(changes))


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, TypeError, AttributeError, KeyError) as exc:
        # A malformed document may contain secrets; report its location/type,
        # never dump configuration values.
        sys.exit(f"agent profile: {exc}")

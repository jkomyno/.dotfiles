#!/usr/bin/env python3
"""Report dotfile coverage and local ownership without exporting file contents."""

import argparse
import json
import os
from pathlib import Path
import subprocess

try:
    import tomllib
except ImportError:  # Python 3.9 on fresh macOS hosts
    from pip._vendor import tomli as tomllib


def inventory(root, home):
    scripts = root / "scripts/dotfiles"
    env = {**os.environ, "HOME": str(home), "DOTFILES": str(root)}

    def read_names(script, *args):
        return subprocess.check_output(["bash", script, *args], env=env, text=True).split()

    selector = root / "target/home/.config/mise/dotfiles-profile.sh"
    [profile] = read_names(selector, "profile")
    bundles = read_names(selector, "bundles")
    envs = read_names(scripts / "dotfiles.sh", "envs")
    configs = [root / "mise.toml", *(root / f"mise.{name}.toml" for name in envs)]
    mappings = []

    def record(destination, mode, source):
        path = home / destination.removeprefix("~/")
        if path.is_symlink():
            state = "linked" if path.resolve() == source.resolve() else "different link"
        elif not path.exists():
            state = "missing"
        elif mode == "copy" and path.is_file() and source.is_file():
            state = "equal" if path.read_bytes() == source.read_bytes() else "copy differs; review local state"
        elif mode == "template":
            state = "rendered; use just diff"
        elif mode == "fields" and path.is_file():
            state = "field-managed; use just diff"
        else:
            state = "unexpected local file"
        mappings.append({"path": str(path.relative_to(home)), "mode": mode, "state": state})

    for config in configs:
        for destination, entry in tomllib.loads(config.read_text()).get("dotfiles", {}).items():
            record(destination, entry.get("mode", "symlink"), root / entry["source"])
    for destination in read_names(scripts / "claude-skill-links.sh", "--list-configs"):
        record(destination, "fields", root / "target/home" / destination)
    for name in read_names(scripts / "claude-skill-links.sh", "--list"):
        source = root / "target/home/.agents/skills" / name
        for parent in (".agents/skills", ".claude/skills"):
            record(f"{parent}/{name}", "symlink", source)

    mapped = [home / item["path"] for item in mappings]

    def coverage(path):
        if any(path == parent or parent in path.parents for parent in mapped):
            return "managed"
        if any(path in child.parents for child in mapped):
            return "partly managed"
        return "undeclared; review ownership"

    entries = []
    for parent in [home, home / ".config", home / ".local/bin"]:
        if not parent.is_dir():
            continue
        for path in sorted(parent.iterdir()):
            if parent == home and not path.name.startswith("."):
                continue
            item = {"path": str(path.relative_to(home)), "coverage": coverage(path)}
            if path.is_symlink():
                item["link"] = os.readlink(path)
                item["broken"] = not path.exists()
            entries.append(item)
    return {"profile": profile, "bundles": bundles, "mappings": mappings, "home_entries": entries}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="emit a machine-readable inventory")
    args = parser.parse_args()
    result = inventory(Path(__file__).resolve().parents[2], Path.home())
    if args.json:
        print(json.dumps(result, indent=2))
        return
    print(f"Profile {result['profile']} ({', '.join(result['bundles'])})")
    print("Managed mappings:")
    counts = {}
    for item in result["mappings"]:
        counts[item["state"]] = counts.get(item["state"], 0) + 1
    for state, count in sorted(counts.items()):
        print(f"  {count}: {state}")
    print("\nHome entries outside explicit mappings (configuration, credentials, caches, and app state):")
    for item in result["home_entries"]:
        if item["coverage"] == "managed":
            continue
        suffix = " [broken link]" if item.get("broken") else ""
        print(f"  ~/{item['path']}: {item['coverage']}{suffix}")
    print("\nUndeclared does not mean unused. This report never copies configuration values.")


if __name__ == "__main__":
    main()

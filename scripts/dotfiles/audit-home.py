#!/usr/bin/env python3
"""Report dotfile coverage and local ownership without exporting file contents."""

import argparse
import json
import os
from pathlib import Path
import sys
import tomllib


def inventory(root, home):
    profiles = ["mise.toml", "mise.macos.toml" if sys.platform == "darwin" else "mise.linux.toml"]
    mappings = []
    for profile in profiles:
        for destination, entry in tomllib.loads((root / profile).read_text()).get("dotfiles", {}).items():
            path = home / destination.removeprefix("~/")
            source = root / entry["source"]
            mode = entry.get("mode", "symlink")
            if path.is_symlink():
                state = "linked" if path.resolve() == source.resolve() else "different link"
            elif not path.exists():
                state = "missing"
            elif mode == "copy" and path.is_file() and source.is_file():
                state = "equal" if path.read_bytes() == source.read_bytes() else "copy differs; review local state"
            elif mode == "template":
                state = "rendered; use mise bootstrap dotfiles status"
            else:
                state = "unexpected local file"
            mappings.append({"path": str(path.relative_to(home)), "mode": mode, "state": state})

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
    return {"mappings": mappings, "home_entries": entries}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="emit a machine-readable inventory")
    args = parser.parse_args()
    result = inventory(Path(__file__).resolve().parents[2], Path.home())
    if args.json:
        print(json.dumps(result, indent=2))
        return
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

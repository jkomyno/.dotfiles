#!/usr/bin/env python3
"""PreToolUse guard for `rm` in Bash commands.

`rm` is allowed by a static permission rule. This hook narrows that rule by
looking at what each `rm` would delete:

  deny  system directories, $HOME and its personal folders, and any ancestor of
        the project or of $HOME
  ask   anything else outside the project and temp directories, or a target the
        hook cannot resolve (unknown variable, command substitution)
  pass  everything inside the project, its git repository, a temp directory, or a cache directory

When nobody can answer a prompt (non-interactive or bypass modes), `ask` is
reported as a denial with the reason, so an unattended run adapts instead of
stalling. The hook never widens permissions: on `pass` it prints nothing.
"""

import json
import os
import re
import shlex
import sys

HOME = os.path.realpath(os.path.expanduser("~"))

SYSTEM_DIRS = (
    "/Applications", "/Library", "/System", "/Users", "/Volumes", "/bin", "/boot", "/cores",
    "/dev", "/etc", "/home", "/lib", "/lib32", "/lib64", "/opt", "/private", "/proc", "/root",
    "/run", "/sbin", "/srv", "/sys", "/usr", "/var",
)
PERSONAL_DIRS = (
    "Desktop", "Documents", "Downloads", "Movies", "Music", "Pictures", "Public",
    ".ssh", ".gnupg", ".aws", ".kube",
)
CACHE_DIRS = ("Library/Caches", ".cache")
# Single-purpose caches: unlike the shared ones above, deleting the directory itself is fine.
TOOL_CACHE_DIRS = (".npm/_cacache", ".bun/install/cache", "Library/pnpm/store")
TEMP_DIRS = ("/tmp", "/private/tmp", "/var/tmp", "/private/var/tmp", "/var/folders", "/private/var/folders")

WRAPPERS = {"sudo", "command", "builtin", "exec", "nohup", "time", "nice", "env"}
SEPARATORS = {";", "&&", "||", "|", "&", "|&", ";;", "(", ")", "{", "}", "!", "then", "do", "else"}
ASSIGNMENT = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", re.S)
EXPANSION = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)")
HEREDOC = re.compile(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1[^\n]*\n.*?\n[ \t]*\2[ \t]*(?=\n|$)", re.S)

MAX_CANDIDATES = 64

DENY, ASK = "deny", "ask"


def is_within(path, root):
    return path == root or path.startswith(root.rstrip("/") + "/")


def real(path):
    return os.path.realpath(path)


class Unresolved(Exception):
    pass


def expand(word, variables):
    """Expand ~ and known variables into every value the word can take.

    A variable holds a list of candidate values: one for an assignment, several for a
    `for` loop variable. Raise when the result depends on anything unknown.
    """
    if "$(" in word or "`" in word:
        raise Unresolved("command substitution")
    if word == "~" or word.startswith("~/"):
        word = HOME + word[1:]
    elif word.startswith("~"):
        raise Unresolved("another user's home")

    results = [word]
    for match in EXPANSION.finditer(word):
        name = match.group(1) or match.group(2)
        values = variables.get(name)
        if not values:
            raise Unresolved(f"${name}")
        results = [result.replace(match.group(0), value) for result in results for value in values]
        if len(results) > MAX_CANDIDATES:
            raise Unresolved("too many loop combinations")
    if any("$" in result for result in results):
        raise Unresolved("shell expansion")
    return results


def split_commands(command):
    """Yield simple commands as word lists, plus '(' and ')' markers for subshell scoping."""
    source = HEREDOC.sub("", command).replace("\\\n", " ")
    lexer = shlex.shlex(source, posix=True, punctuation_chars="();<>|&\n")
    lexer.whitespace = " \t\r"
    lexer.whitespace_split = True
    lexer.commenters = ""
    words = []
    skip_next = False
    for token in lexer:
        if skip_next:
            skip_next = False
            continue
        # Redirections are not operands: drop `2>`, `>`, `<<<` and the word they point at.
        if token and set(token) <= set("<>&") and set(token) & set("<>"):
            if words and words[-1].isdigit():
                words.pop()
            skip_next = True
            continue
        if token in SEPARATORS or (token and set(token) <= set(";&|()\n")):
            if words:
                yield words
            words = []
            if token in ("(", ")"):
                yield token
        else:
            words.append(token)
    if words:
        yield words


def classify_target(raw, cwd, variables, safe_roots, project):
    """Return the strictest (verdict, reason) for one rm operand, or None when it is safe."""
    try:
        candidates = expand(raw, variables)
    except Unresolved as unresolved:
        return ASK, f"cannot resolve `{raw}` ({unresolved})"
    findings = [classify_path(raw, candidate, cwd, safe_roots, project) for candidate in candidates]
    findings = [finding for finding in findings if finding]
    return next((finding for finding in findings if finding[0] == DENY), findings[0] if findings else None)


def classify_path(raw, expanded, cwd, safe_roots, project):
    if cwd is None and not expanded.startswith("/"):
        return ASK, f"cannot resolve `{raw}` (working directory unknown)"

    # A glob deletes entries of its directory, so judge the directory holding the first wildcard.
    glob = re.search(r"[*?\[]", expanded)
    literal = expanded[: glob.start()] if glob else expanded
    if glob:
        literal = literal if literal.endswith("/") else os.path.dirname(literal)
    lexical = os.path.normpath(os.path.join(cwd or "/", literal or "."))
    # realpath follows symlinks, so a link pointing out of the project is judged by its destination.
    # A trailing slash (or a glob) makes rm act on the link's target rather than the link itself.
    follows_link = bool(glob) or expanded.endswith("/")
    path = real(lexical) if follows_link or not os.path.islink(lexical) else os.path.join(real(os.path.dirname(lexical)), os.path.basename(lexical))
    shown = f"`{raw}` -> {path}" + ("/*" if glob else "")

    if path == "/" or is_within(HOME, path) or (project and is_within(project, path) and path != project):
        return DENY, f"{shown} is an ancestor of your home or project directory"
    if any(is_within(path, real(os.path.join(HOME, name))) for name in PERSONAL_DIRS):
        return DENY, f"{shown} is inside a protected personal folder"

    for root in safe_roots:
        if is_within(path, root):
            disposable = any(root == real(os.path.join(HOME, cache)) for cache in TOOL_CACHE_DIRS)
            if path == root and not disposable and not (glob and root != project):
                return ASK, f"{shown} is the whole {'project' if root == project else 'temp or cache'} directory"
            if root == project and is_within(path, os.path.join(project, ".git")):
                return ASK, f"{shown} is inside the repository's .git directory"
            return None

    # A linked worktree of the project's own repository is part of the same project.
    worktree = repo_root(path)
    if project and worktree and worktree != path and not is_within(HOME, worktree):
        if git_common_dir(worktree) and git_common_dir(worktree) == git_common_dir(project):
            return None

    if any(is_within(path, real(system)) or is_within(path, system) for system in SYSTEM_DIRS) and not is_within(path, HOME):
        return DENY, f"{shown} is inside a system directory"
    return ASK, f"{shown} is outside the project, temp and cache directories"


def repo_root(path):
    """Nearest ancestor holding a .git entry, so a session started in a subdirectory covers its repo."""
    current = path
    while current and current != "/":
        if os.path.exists(os.path.join(current, ".git")):
            return current
        current = os.path.dirname(current)
    return None


def git_common_dir(root):
    """The shared .git directory of a checkout: its own for a main checkout, the main one for a worktree."""
    dot_git = os.path.join(root, ".git")
    if os.path.isdir(dot_git):
        return real(dot_git)
    try:
        with open(dot_git, encoding="utf-8") as handle:
            line = handle.readline().strip()
    except OSError:
        return None
    if not line.startswith("gitdir:"):
        return None
    gitdir = real(os.path.join(root, line[len("gitdir:"):].strip()))
    parent = os.path.dirname(gitdir)
    return os.path.dirname(parent) if os.path.basename(parent) == "worktrees" else None


def inspect(command, cwd, project):
    """Return the strictest (verdict, reason) across every rm in the command, or None."""
    # The project comes first so its own rules (.git, the whole tree) win when it lives under a temp directory.
    safe_roots = [project] if project else []
    safe_roots += [real(root) for root in TEMP_DIRS if os.path.isdir(root)]
    tmpdir = os.environ.get("TMPDIR")
    if tmpdir:
        safe_roots.append(real(tmpdir))
    safe_roots += [real(os.path.join(HOME, cache)) for cache in CACHE_DIRS + TOOL_CACHE_DIRS]

    variables = {name: [value] for name, value in (("HOME", HOME), ("PWD", cwd), ("TMPDIR", tmpdir), ("CLAUDE_PROJECT_DIR", project)) if value}
    scopes = []
    findings = []

    for words in split_commands(command):
        if words == "(":
            scopes.append((cwd, dict(variables)))
            continue
        if words == ")":
            if scopes:
                cwd, variables = scopes.pop()
            continue

        # Leading VAR=value words: a bare assignment sets shell state for later commands.
        index = 0
        while index < len(words) and ASSIGNMENT.match(words[index]):
            index += 1
        assignments, words = words[:index], words[index:]
        if words and words[0] == "export":
            assignments, words = [word for word in words[1:] if ASSIGNMENT.match(word)], []
        if not words:
            for word in assignments:
                name, value = ASSIGNMENT.match(word).groups()
                try:
                    variables[name] = expand(value, variables)
                except Unresolved:
                    variables[name] = None
            continue
        # `for d in a b c`: the loop variable takes each listed word.
        if words[0] == "for" and len(words) >= 3 and words[2] == "in":
            try:
                variables[words[1]] = [value for word in words[3:] for value in expand(word, variables)][:MAX_CANDIDATES + 1]
            except Unresolved:
                variables[words[1]] = None
            continue

        sudo = False
        while words and (words[0] in WRAPPERS or ASSIGNMENT.match(words[0])):
            sudo = sudo or words[0] == "sudo"
            words = words[1:]
        if not words:
            continue
        name = os.path.basename(words[0].lstrip("\\"))

        if name == "cd":
            operands = [word for word in words[1:] if not word.startswith("-")]
            try:
                targets = expand(operands[0], variables) if operands else [HOME]
                target = targets[0] if len(targets) == 1 else None
                cwd = os.path.normpath(os.path.join(cwd or "/", target)) if target and (cwd or target.startswith("/")) else None
            except Unresolved:
                cwd = None
            variables["PWD"] = [cwd] if cwd else None
            continue
        if name != "rm":
            continue

        operands, options_done = [], False
        for word in words[1:]:
            if not options_done and word == "--":
                options_done = True
            elif not options_done and word.startswith("-") and len(word) > 1:
                continue
            else:
                operands.append(word)
        for operand in operands:
            finding = classify_target(operand, cwd, variables, safe_roots, project)
            if finding is None and sudo:
                finding = (ASK, f"`sudo rm {operand}` runs as root")
            if finding:
                findings.append(finding)

    if not findings:
        return None
    denials = [reason for verdict, reason in findings if verdict == DENY]
    if denials:
        return DENY, "; ".join(denials)
    return ASK, "; ".join(reason for _, reason in findings)


def main():
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return
    command = (payload.get("tool_input") or {}).get("command") or ""
    if payload.get("tool_name") != "Bash" or not re.search(r"(^|[^\w.-])rm\s", command):
        return

    cwd = payload.get("cwd") or os.getcwd()
    project = real(os.environ.get("CLAUDE_PROJECT_DIR") or cwd)
    project = repo_root(project) or project
    # Running from $HOME or above would make the whole home directory "the project".
    if project and is_within(HOME, project):
        project = None

    try:
        finding = inspect(command, real(cwd), project)
    except ValueError as error:  # unbalanced quotes and similar: shlex could not tokenize
        finding = (ASK, f"could not parse the command ({error})")
    if finding is None:
        return

    verdict, reason = finding
    unattended = payload.get("permission_mode") in ("bypassPermissions", "dontAsk") or os.environ.get("CLAUDE_GUARD_RM_UNATTENDED") == "1"
    if verdict == ASK and unattended:
        verdict = DENY
        reason += ". Nobody can approve this in an unattended run: delete only inside the project, a temp directory or a cache directory, or leave it for the user."
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": verdict,
                "permissionDecisionReason": f"guard-rm: {reason}",
            }
        },
        sys.stdout,
    )


if __name__ == "__main__":
    main()

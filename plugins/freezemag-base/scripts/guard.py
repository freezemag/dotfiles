import json, os, sys, fnmatch

mode = sys.argv[1] if len(sys.argv) > 1 else "pre"
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

path = (data.get("tool_input") or {}).get("file_path") or ""
root = os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or os.getcwd()
if not path:
    sys.exit(0)
rel = os.path.relpath(os.path.abspath(path), os.path.abspath(root))
if rel.startswith(".."):
    rel = path

rules = []
guards = os.path.join(root, ".claude", "freezemag-guards.txt")
if os.path.isfile(guards):
    with open(guards, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split(None, 2)
            if len(parts) < 2:
                continue
            kind, glob = parts[0].lower(), parts[1]
            msg = parts[2] if len(parts) > 2 else ""
            rules.append((kind, glob, msg))

def matches(glob):
    return fnmatch.fnmatch(rel, glob) or fnmatch.fnmatch(os.path.basename(rel), glob)

if mode == "pre":
    for kind, glob, msg in rules:
        if kind == "block" and matches(glob):
            sys.stderr.write(f"BLOCKED by .claude/freezemag-guards.txt ({glob}): {msg or 'this path is protected.'}\n")
            sys.exit(2)
    sys.exit(0)

# post: collect warnings; exit 2 so the message is shown to Claude after the edit.
notes = []
for kind, glob, msg in rules:
    if kind == "warn" and matches(glob):
        notes.append(msg or f"{glob}: check before you stop.")
# CLAUDE.md has a ceiling. Every session pays for every line of it, and the
# docs put the adherence cliff around 200 lines; 400 is the studio's limit.
# Past it, the fix is a move, not a trim: decisions to docs/DECISIONS.md,
# history to docs/, area rules to .claude/rules/ with a paths: header.
if os.path.basename(rel) == "CLAUDE.md":
    try:
        with open(path, encoding="utf-8") as fh:
            n = sum(1 for _ in fh)
    except OSError:
        n = 0
    if n > 400:
        notes.append(f"CLAUDE.md is {n} lines; the limit is 400. Move what grew: decisions to docs/DECISIONS.md, history to docs/, area-specific rules to .claude/rules/ with a paths: header. Never delete; move.")
if rel.endswith((".html", ".css")) and not any("screenshot" in n.lower() for n in notes):
    notes.append("Visual file edited. Screenshot the affected surface at 1920x1080 and 390x844 and say what you checked before you stop.")
if notes:
    sys.stderr.write("freezemag guard: " + " | ".join(notes) + "\n")
    sys.exit(2)
sys.exit(0)

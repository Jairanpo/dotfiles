#!/usr/bin/env python3
"""Refuse any tool call that would grant broad youtube.com access in a browser
policy file. The only youtube patterns allowed to survive are the embed-only
ones already present in the Firefox WebsiteFilter exceptions."""
import json
import re
import sys

ALLOWED = {
    "https://*.youtube.com/embed/*",
    "https://*.youtube-nocookie.com/embed/*",
    "https://player.vimeo.com/video/*",
}
POLICY_PATH = re.compile(r"(?:^|[/\\])(?:managed_)?policies\.json$|[/\\]policies[/\\]", re.I)
POLICY_CMD = re.compile(r"(?:managed_)?policies\.json|WebsiteFilter", re.I)
MUTATES = re.compile(r">>?|sed\s+-i|\btee\b|\bpython|\bperl\b|\bcp\b|\bmv\b|\bdd\b|\bjq\b.*>", re.I)
YOUTUBE = re.compile(r"[^\s\"',`]*(?:youtube(?:-nocookie)?\.com|youtu\.be)[^\s\"',`]*", re.I)


def added_text(tool, tool_input):
    if tool in ("Edit", "MultiEdit"):
        edits = tool_input.get("edits") or [tool_input]
        return "\n".join(str(e.get("new_string", "")) for e in edits)
    if tool in ("Write", "NotebookEdit"):
        return str(tool_input.get("content", tool_input.get("new_source", "")))
    if tool == "Bash":
        cmd = str(tool_input.get("command", ""))
        return cmd if MUTATES.search(cmd) else ""
    return json.dumps(tool_input)


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input") or {}

    # Only guard the browser policy files themselves: a policies.json target for
    # the file tools, or a shell command that mutates one.
    if tool == "Bash":
        if not POLICY_CMD.search(str(tool_input.get("command", ""))):
            return 0
    elif not POLICY_PATH.search(str(tool_input.get("file_path", ""))):
        return 0

    text = added_text(tool, tool_input)
    offenders = sorted({m.strip("\"',`") for m in YOUTUBE.findall(text)} - ALLOWED)
    if not offenders:
        return 0

    reason = (
        "Blocked by the user's standing rule: YouTube must never be opened directly "
        "in Firefox. This change would add broad youtube access to a browser policy "
        "file (" + ", ".join(offenders) + "). Only the existing embed-only exceptions "
        "are permitted. Do not work around this - tell the user it is blocked."
    )
    print(json.dumps({
        "systemMessage": "Blocked: adding direct YouTube access to a browser policy file.",
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        },
    }))
    return 0


sys.exit(main())

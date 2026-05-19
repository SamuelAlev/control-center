#!/usr/bin/env python3
"""PreToolUse hook: require a concurrency cap on flutter/dart test runs.

`flutter test` spawns one flutter_tester per CPU core by default, and in
this monorepo each of them loads the entire app (plus a frontend_server
compiler), so an uncapped run can exhaust machine memory — it has crashed
a laptop. Deny the call and tell the model to re-run with a cap.
"""
import json
import re
import sys


def main() -> None:
    data = json.load(sys.stdin)
    command = (data.get("tool_input") or {}).get("command") or ""

    # Ignore quoted text (commit messages, grep patterns) so a command that
    # merely *mentions* "flutter test" is not denied.
    unquoted = re.sub(r"'[^']*'|\"[^\"]*\"", " ", command)

    runs_tests = re.search(r"\b(flutter|dart)\s+test\b", unquoted)
    has_cap = re.search(r"--concurrency[= ]?\d+|-j\s?\d+", command)
    if not runs_tests or has_cap:
        return

    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": (
                        "Test runs in this repo must cap concurrency: each "
                        "flutter_tester loads the entire app, and the "
                        "default of one per CPU core can exhaust machine "
                        "memory. Re-run the same command with "
                        "--concurrency=2 added after `test` (use "
                        "--concurrency=1 for the root app suite)."
                    ),
                }
            }
        )
    )


if __name__ == "__main__":
    main()

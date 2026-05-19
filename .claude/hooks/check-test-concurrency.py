#!/usr/bin/env python3
"""PreToolUse hook: require a concurrency cap on flutter/dart test runs.

`flutter test` spawns one flutter_tester per CPU core by default, and in
this monorepo each of them loads the entire app (plus a frontend_server
compiler), so an uncapped run can exhaust machine memory — it has crashed
a laptop. Deny the call and tell the model to re-run with a cap.

Three things this checks that the first version did not:

* The cap must appear in the UNQUOTED command. The original looked for
  ``--concurrency`` in the raw string while deciding *whether tests run* from
  the quote-stripped one, so ``flutter test && echo "--concurrency=2"`` —
  or any commit message, grep pattern or heredoc that merely contains the
  flag — satisfied the guard while running uncapped.
* The cap must be small enough to matter. ``--concurrency=64`` is a cap the
  way ``ulimit -n 1000000`` is a limit.
* EVERY test invocation in a compound command needs its own cap. One capped
  run does not license the uncapped one after the ``&&``.
"""

from __future__ import annotations  # `str | None` on the system python3

import json
import re
import sys

# AGENTS.md: --concurrency=2 everywhere, --concurrency=1 for the root app
# suite. Anything above 2 defeats the purpose of the rule.
MAX_CONCURRENCY = 2

_QUOTED = re.compile(r"'[^']*'|\"[^\"]*\"")
# A heredoc body is a payload, not a command line — and prose inside one is
# full of apostrophes, which desynchronize the naive quote stripping below and
# can leave a bare `dart test` visible in what is actually a comment.
_HEREDOC = re.compile(
    r"<<-?\s*['\"]?(\w+)['\"]?\n.*?^\1$",
    re.DOTALL | re.MULTILINE,
)
_SEGMENT = re.compile(r"&&|\|\||;|\n|\||\$\(|`")
# `\b` is not enough on the left: a Dart FILENAME followed by a path that
# starts with `test/` reads as "dart test" to a word-boundary match, so
# `head foo.dart test/bar.dart` was denied as an uncapped test run. Require
# that the word is not preceded by a path or extension character.
_RUNS_TESTS = re.compile(r"(?<![.\w/-])(?:flutter|dart)\s+test\b")
_CAP = re.compile(r"(?:--concurrency[=\s]+|-j\s*)(\d+)")
_HELP = re.compile(r"(?:^|\s)(?:--help|-h)(?:\s|$)")

_MISSING = (
    "Test runs in this repo must cap concurrency: each flutter_tester loads "
    "the entire app, and the default of one per CPU core can exhaust machine "
    "memory. Re-run the same command with --concurrency=2 added after `test` "
    "(use --concurrency=1 for the root app suite). Every test invocation in a "
    "compound command needs its own cap."
)
_TOO_HIGH = (
    "--concurrency={found} is above this repo's ceiling of "
    f"{MAX_CONCURRENCY}: each flutter_tester loads the entire app plus a "
    "frontend_server, so a high cap is no cap at all. Re-run with "
    "--concurrency=2 (or --concurrency=1 for the root app suite)."
)


def violation(command: str) -> str | None:
    """Return a denial reason for `command`, or None if it is acceptable."""
    # Ignore heredoc bodies and quoted text (commit messages, grep patterns,
    # inline scripts) so a command that merely *mentions* `flutter test` is not
    # denied — and, symmetrically, so a quoted `--concurrency=2` cannot vouch
    # for an uncapped run.
    unquoted = _QUOTED.sub(" ", _HEREDOC.sub(" ", command))

    for segment in _SEGMENT.split(unquoted):
        if not _RUNS_TESTS.search(segment) or _HELP.search(segment):
            continue
        caps = [int(m.group(1)) for m in _CAP.finditer(segment)]
        if not caps:
            return _MISSING
        if max(caps) > MAX_CONCURRENCY:
            return _TOO_HIGH.format(found=max(caps))
    return None


def main() -> None:
    data = json.load(sys.stdin)
    command = (data.get("tool_input") or {}).get("command") or ""

    reason = violation(command)
    if reason is None:
        return

    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )


if __name__ == "__main__":
    main()

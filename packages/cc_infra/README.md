# cc_infra

Server-side infrastructure adapters: `dart:io` implementations of cc_domain ports, the built-in agent harness, dispatch and the paired evaluation engine. It never depends on Flutter. Ownership and contracts are in [ARCH.md](../../ARCH.md).

## cc_eval

`cc_eval` runs paired evaluation campaigns. Run it from this package:

```bash
fvm dart run bin/cc_eval.dart <list|run|replay|verify|report> [options]
```

`--help` prints every option. How the engine, the axes, the goal-verification executor and the gate work is in [ARCH.md](../../ARCH.md#agent-loop-contract).

### Paid runs

A live `run` calls a model and spends money, so it needs a ceiling: `--max-spend-usd <n>`, in USD. A run without it, or with a value that is not a positive number, is refused before anything starts. A plan's own `maxSpendUsd` lowers the ceiling when it is smaller, never raises it.

- The ceiling stops scheduling. It is checked between attempts, so the attempt in flight when it is reached can pass it by that one attempt. A goal attempt cannot (next point).
- A goal attempt is held to what is left of the ceiling as it starts: its segments and review runs stop at the call that reaches that remainder, or at its first unpriced call. An attempt that runs out between segments ends with an error unless a claim was already accepted.
- A live campaign with a goal arm needs its model priced in `--pricing-cache` (`<provider>/<model>`). Without a price it is refused before the code runner, the credential or the backend is touched, so nothing is spent or written.
- An attempt whose cost could not be priced stops the campaign after that attempt, because unknown spend cannot be held under a ceiling.
- `--dry-run` prints the schedule and an empty gate report. It needs no ceiling, no price and no provider credential. `replay` needs no ceiling either.
- The ceiling is the CLI's. `EvaluationEngine` has no spend policy of its own: a program that drives it brings its own (`cancelled`, `onAttempt`).

### The long-running work campaigns

Four plans in `eval/plans/` measure the long-running work (plan section 20). Each command below starts one live campaign. `<n>` is the ceiling; add `--dry-run` and drop `--max-spend-usd` to see the schedule without spending.

```bash
# 1: goal verification (builtin harness only)
fvm dart run bin/cc_eval.dart run --plan eval/plans/campaign-goal-verification.json \
  --corpus eval/corpus.json --model <pinned model> --pricing-cache <path> \
  --out <dir outside the repo> --max-spend-usd <n>
# 2: conversation history against --fresh
fvm dart run bin/cc_eval.dart run --plan eval/plans/campaign-goal-fresh-history.json \
  --corpus eval/corpus.json --model <pinned model> --pricing-cache <path> \
  --out <dir outside the repo> --max-spend-usd <n>
# 3: compaction policy
fvm dart run bin/cc_eval.dart run --plan eval/plans/campaign-compaction-policy.json \
  --corpus eval/corpus.json --model <pinned model> --pricing-cache <path> \
  --out <dir outside the repo> --max-spend-usd <n>
# 4: code mode (builtin harness only)
CC_CODEMODE_RUNNER=<self-tested runner> fvm dart run bin/cc_eval.dart run \
  --plan eval/plans/campaign-code-mode.json --corpus eval/corpus.json \
  --model <pinned model> --pricing-cache <path> --out <dir outside the repo> --max-spend-usd <n>
```

Estimated cost per campaign. These are estimates: no attempt has ever been priced. They assume about 0.25 to 0.50 USD per synthetic attempt and 1.5 to 3 USD per real-repository (`cc-*`) attempt.

| Campaign | Attempts (synthetic + real repository) | Estimate |
| --- | --- | --- |
| 1, goal verification | 18 + 0 | 6 to 12 USD (the treatment adds review runs and up to three more segments) |
| 2, conversation against `--fresh` | 16 + 4 | 10 to 20 USD |
| 3, compaction | 18 + 9 | 18 to 36 USD |
| 4, code mode | 12 + 8 | 15 to 30 USD |

- Campaign 4 needs `CC_CODEMODE_RUNNER` naming a runner that passes its self-test. Without one, the builtin backend refuses the `repl` arm before anything is spent, a dry run included.
- Campaigns 1 and 4 run on the builtin harness only. The Claude CLI backend (`--backend claude-cli`) refuses goal and code mode arms.
- A goal attempt's workspace is `<out>/work/goal-<n>/repos/cc-eval-<task>-<stamp>`, the layout of a space's checkout that the product's check runner reads.
- None of these campaigns has been started. Each plan declares its hypothesis and primary outcome and needs at least 10 used tasks (`minTasks`); today's task sets have 3 to 5, so every result will read "No decision (not enough evidence)" with the reason "N tasks, 10 needed" until tasks are added. With 10 or more tasks the task-cluster t test and its sign-flip check can conclude either way. The "Descriptive numbers (not a verdict)" section of the report (verified rate, false completions, cost, turns, round trips) is what a run can tell you before then.
- At 10 tasks a campaign costs, in attempts: goal verification 60, code mode 40, fresh history 40, compaction 90.

### Calibration

`eval/plans/calibration-baseline.json` runs every corpus task on one arm (22 tasks × 3 repetitions = 66 attempts) and reports descriptive tables only, with no verdict. Its `maxSpendUsd` is unset, so a live run is held to `--max-spend-usd` alone.

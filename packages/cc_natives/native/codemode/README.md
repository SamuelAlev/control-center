# cc_codemode

The runner for code mode. Each process runs **one** model-written JavaScript
script in QuickJS-NG and then exits. The script's only way out is a bridge
over stdio, where the host answers its tool calls. The process confines itself
at the OS level before it reads any input. A runner that cannot confine itself
fully says so and refuses to run.

```
packages/cc_natives/native/codemode/
  Cargo.toml        workspace (release profile: LTO, panic=abort, stripped)
  lockdown/         cc_codemode_lockdown: per-OS confinement and --self-test
  runner/           cc_codemode: engine, prelude, wire protocol
```

## Command line

| Invocation | Behaviour | Exit |
| --- | --- | --- |
| `cc_codemode` | one session over stdio (below) | see [Exit codes](#exit-codes) |
| `cc_codemode --version` | prints `cc_codemode <runner> quickjs-ng <engine> protocol <n>` | 0 |
| `cc_codemode --self-test` | applies the lockdown, attempts what it must deny, runs real sessions under it, prints one JSON line (see [Self-test](#self-test)) | 0 only if the lockdown is `full`, every check was denied and every session passed, else 1 |
| `cc_codemode --grant-runner-access` (Windows only) | makes its own executable grant the confined child's capability read and execute access (see [Windows](#windows)), with the launcher's code; prints one line | 0 if the executable grants it, 1 if adding it failed |
| anything else | usage on stderr | 2 |

`--grant-runner-access` is the installer's step; on Linux and macOS it is an
unknown argument (usage, exit 2). On Windows, `--contained-child` is used internally to start the confined
child (and `--contained-child --sibling` for the self-test's idle second
child). Passing it by hand gains nothing, because the child checks its own
confinement.

**stdin, stdout and stderr must be pipes.** On Linux and macOS the lockdown
sets `RLIMIT_FSIZE` to 0, so a runner whose stdout or stderr is a regular file
is killed by `SIGXFSZ` the first time it writes. This applies to `--self-test`
as well.

The runner starts with an empty environment and needs nothing from it. On
Windows the launcher passes only `SystemRoot`, `SystemDrive` and `windir` to
the child.

## Start-up order

1. Install the panic hook (see [Exit codes](#exit-codes)) and close every
   inherited descriptor above 2.
2. Apply thread-scoped confinement: Linux fixes the time zone to UTC (so glibc
   never opens `/etc/localtime` later), clears `READ_IMPLIES_EXEC`, then
   `no_new_privs`, drops every capability, and applies Landlock; macOS cuts
   off the inherited Mach ports (exception, registered, bootstrap and debug
   control ports); Windows verifies the AppContainer and that it is a
   less-privileged one.
3. Start the stdin reader thread and the watchdog thread. Each makes its
   first allocation before signalling that it has started, so no allocator
   arena is created later.
4. Apply process-wide confinement: Linux rlimits and seccomp (with TSYNC);
   macOS rlimits and Seatbelt; Windows job and mitigation verification.
5. If the level is not `full`, write `ready` and exit 3.
6. Create the runtime: allocator heap limit, stack limit, interrupt handler.
7. Load the prelude.
8. Write `ready`.
9. Read `init`, then exactly one `exec`. Run the event loop, write `done` and
   exit.

## Wire protocol

The protocol is NDJSON: one JSON object per line, UTF-8, `\n`-terminated.

- **Frame size.** A frame is at most **8 MiB** (8,388,608 bytes, newline
  excluded) in either direction.
- **Parsing.** Host frames are parsed strictly:
  - an unknown `type`, a missing or mistyped field, or invalid JSON is a
    protocol violation;
  - unknown extra fields are ignored;
  - nesting deeper than 128 levels is invalid JSON (serde_json's limit);
  - `\uXXXX` escapes of unpaired surrogates are replaced with U+FFFD before
    parsing, the same as `String.prototype.toWellFormed`.
- **Key order.** Keys in runner frames are written in alphabetical order.

The protocol version is **2** (2 added `init.limits.return_budget_chars` and the `history`, `outputs`, `loadOutput` and `keep` host calls). The host refuses a runner of another version, at its self-test (`--version`) and at every `ready`.

### Order

```
runner: ready
host:   init
host:   exec
runner: (call | output | store)*   host: (result | cancel)*   (interleaved)
runner: done
```

- `cancel` may arrive at any point after `ready`. If it arrives before
  `exec`, the runner writes `done` with kind `cancelled` straight away.
- `done` may come from the watchdog thread instead of the interpreter (see
  [CPU budget and cancel](#cpu-budget-and-cancel)). It is still exactly one
  `done` and still the last frame: the watchdog holds stdout from writing it
  until the process has exited.
- After `ready`, every ending except the cases below writes **exactly one
  `done`**, which is always the last frame:
  - stdin closing before `done` (exit 5);
  - a kernel kill (signals listed under [Exit codes](#exit-codes)).
- The process exits right after `done`. Calls still in flight and timers
  still pending are abandoned.
- These are protocol violations, each answered by `done` with kind `internal`,
  name `ProtocolError` and exit 1:
  - any frame other than `init` or `cancel` first;
  - any frame other than `exec` or `cancel` second;
  - a second `init` or `exec`;
  - a `result` for an id that is not pending;
  - an oversized frame;
  - an invalid frame.

### Runner → host

**`ready`**

```json
{"type":"ready","protocol":2,"engine":"quickjs-ng 0.16.2","runner":"0.1.0","lockdown":{...}}
```

`lockdown` is described under [Lockdown report](#lockdown-report). The host
must not send `exec` unless `lockdown.level == "full"`. A runner whose level is
not `full` exits 3 by itself.

**`call`**: a tool or host call. Ids start at 1 and increase by one.

```json
{"type":"call","id":1,"target":"tool","name":"<raw catalog name>","args":{...},"at":[3,13]}
{"type":"call","id":2,"target":"host","name":"searchTools","args":{"query":"…","limit":8,"namespace":null},"at":[7,7]}
```

- `target: "tool"`: `name` is the catalog entry's raw `name`, even when the
  script used the id. `args` is the script's single argument, or `{}` when it
  passed none. An argument that is not a plain JSON object (a string, an
  array, a number, `null`, a boolean) is a catchable `TypeError` and sends
  no frame: the host takes only an object.
- A `name` longer than 256 bytes of UTF-8 is a catchable `RangeError`,
  checked before anything is copied, and an empty one a `TypeError` (the
  host's rule; catalog names are host-chosen and far shorter).
- `args` is measured as the host measures it, not as the script's JSON (see
  [Limits shared with the host](#limits-shared-with-the-host)).
- `target: "host"`: `name` is one of the entries below, with these `args`
  (an omitted option is absent):

  | `name` | `args` |
  | --- | --- |
  | `searchTools` | `{query, limit, namespace}` (`limit` defaults to 8) |
  | `describeTool` | `{name}` |
  | `describeNamespace` | `{name}` |
  | `models.embed` | `{texts}` |
  | `models.rank` | `{query, candidates, top}` |
  | `models.classify` | `{texts, labels}` |
  | `history` | `{start, limit, role, tool, row, offset}` |
  | `outputs` | `{limit, tool}` |
  | `loadOutput` | `{handle, offset, limit}` |
  | `keep` | `{value, label}` |

- Host calls count toward `max_calls`.
- `at` is the call site: `[line, column]` of the position in the script the
  call was made from, or absent. See [Call sites](#call-sites).

#### Call sites

`at` is a display hint, written by a process that runs model-written code.
The host may use it to place a call in the script's structure and for
nothing else.

- **Units.** `line` is 1-based in the script as sent in `exec`, its lines
  split at `\n`, `\r\n` and a lone `\r`. `column` is 1-based in UTF-16 code
  units of that line. Both are integers; the column always names the first
  unit of a character of that line.
- **Which frame.** The innermost stack frame compiled from the script's own
  text when the call was made: a call in a helper function is placed in the
  helper, a call through a native (`Reflect.apply(tools.x, …)`) on the
  script's call of the native, a call from code the script made with `eval`
  or `Function` on the script's `eval(…)` or `Function(…)` call.
- **Which token.** QuickJS-NG keeps the position of the last located token
  evaluated before the call: always inside the call expression, usually the
  callee's last name (`read` in `await tools.read({…})`, `r` in `r({…})`),
  but a variable read in the arguments moves it there (`q` in
  `tools.read({ x: q.y })`), possibly onto a later line. Match a site to the
  innermost call expression that contains it.
- **Absent** when no script frame is on the stack (a call the runtime makes:
  `promise.then(tools.x)`, `setTimeout(tools.x, 0, {})`), when the position
  is not a character of the script's text, and for every call of a script
  that contains U+2028 or U+2029 (QuickJS counts those as line breaks in
  code but not inside comments, so a line could not be mapped back).
- **Not forgeable by the script.** The prelude reads the engine's structured
  call sites (file, line, column), never a stack string, so a function's
  `name` cannot inject a position; it installs its own frame limit for the
  capture and puts the script's back, so `Error.stackTraceLimit` neither
  hides nor moves a site; frames of `eval` or `Function` code have another
  file name and are skipped. What a script can do is choose where its calls
  are made, and make a call from a runtime callback to send none.
- The runner converts QuickJS's position (script line + 2, column in UTF-8
  bytes) itself; `runner/src/site.rs`. The cost per call does not grow with
  the script or the line: an index built once with the script (4 bytes a
  line, 8 bytes a KiB) gives the line's start, and counting UTF-16 units
  reads at most 2 × 1,027 bytes. Measured, 5,000 calls on macOS arm64:
  46–47 ms interpreter CPU for a one-line script, 49–56 ms with 256 KiB of
  text, a 1 MiB line or 100,000 lines before the call.

**`output`**: in script order.

```json
{"type":"output","kind":"text","text":"…"}
{"type":"output","kind":"log","level":"log|info|warn|error|debug","text":"…"}
{"type":"output","kind":"image","image":{"type":"image","mediaType":"image/png","data":"<base64>"}}
```

- Each frame is one output item.
- Characters are counted as Unicode scalar values of `text`; for an image,
  the length of `data`.
- Sizes are checked before the frame is built. A string whose length alone
  shows it cannot fit (one item at most 8 MiB − 64 KiB once escaped, at most
  the remaining character budget) is refused without being copied; a
  shorter one is copied once and its escaped size computed before
  serialization (an image's `data`, at most 6,990,508 characters, twice: once
  for the checks below, once for the frame). So the runner's own memory for
  output stays within a small multiple of one frame, whatever the heap limit.
- `image()` applies the host's rules before the output budget, each as a
  catchable error that writes no frame:

  | Rule | Error |
  | --- | --- |
  | `mediaType` is `image/png`, `image/jpeg`, `image/gif` or `image/webp`, exactly | `TypeError` |
  | `data` is at most (5 MiB + 2) / 3 × 4 = 6,990,508 characters | `RangeError`, checked before `data` is copied |
  | `data` is standard base64: `A-Z a-z 0-9 + /`, `=` padding to a multiple of 4, zero bits after the last byte | `TypeError` |
  | `data` decodes to at most 5 MiB (5,242,880 bytes) | `RangeError` |
  | the decoded bytes start with the type's file header: PNG `89 50 4E 47 0D 0A 1A 0A`, JPEG `FF D8 FF`, GIF `GIF87a` or `GIF89a`, WEBP `RIFF` then `WEBP` at offset 8 | `TypeError` |

  The host decodes with Dart's `base64.decode`, which also takes the
  URL-safe alphabet and `%3D` padding; the runner refuses both, so whatever
  it writes the host accepts.

**`store`**: the script stored or deleted a value. The host persists it for
later sessions.

```json
{"type":"store","key":"k","value":<json>}
{"type":"store","key":"k","delete":true}
```

- One script makes at most **2,000** store operations, writes and deletes
  together; the next one is a catchable `RangeError` (`This script reached its
  limit of 2000 store operations`) and writes no frame.
- The values one script writes total at most 16 × `store_total_bytes` (each
  write counts, also when it overwrites a key); beyond that a write is a
  catchable `RangeError`.
- With `store_total_bytes` 0 (a session that may not change stored values) a
  delete is refused like a write.
- A value is measured as the host measures it (see
  [Limits shared with the host](#limits-shared-with-the-host)), against
  `store_value_bytes`, the running total of stored values and the 16 ×
  write cap alike.

**`done`**

```json
{"type":"done","ok":true,"value":<json>,"stats":{...}}
{"type":"done","ok":false,"error":{"kind":"…","name":"…","message":"…","stack":"…","line":3,"column":7},"stats":{...}}
```

- `value` is the script's return value. It is absent when the script returned
  `undefined`, called `exit()` or failed. A return value is not repeated as
  an `output` frame.
- `error.line` and `error.column` locate the error in the script (1-based).
  They are `null` when unknown.
- `error.stack` uses frames of the form `at fn (repl.js:L:C)`. Prelude frames
  are removed. Frames of code the script made with `eval` or `Function` read
  `eval:L:C`, numbered within that code, and `error.line` and
  `error.column` name the script's own innermost frame. A stack the script
  reads itself (`e.stack`) is unmapped: the script's frames read
  `<script>:L:C` with L two more than the script's line.
- `name`, `message` and `stack` are each capped at 64 KiB (the prelude cuts
  each at 65,536 UTF-16 units before it encodes them).
- `stats` is `{cpu_ms, peak_heap_bytes, calls, output_chars, output_items}`.
- A `done` from the watchdog has `stack` empty, `line` and `column` null, and
  `cpu_ms` measured as the process's CPU time since `exec`.

Error kinds:

| `kind` | `name` | Cause | Catchable by the script |
| --- | --- | --- | --- |
| `script_error` | the thrown error's name (`Uncaught` for a non-Error), or `TypeError` for a return value that is not JSON | uncaught throw, rejected promise, syntax error, failure in a microtask or timer callback | yes |
| `cpu_exceeded` | `CpuLimitExceeded` | interpreter CPU time over `cpu_ms` (or, from the watchdog, process CPU time over `cpu_ms` + 0.5 s) | no |
| `memory_exceeded` | `MemoryLimitExceeded` | heap over `heap_bytes` | no |
| `output_exceeded` | `OutputLimitExceeded` | output over `max_output_chars` or `max_output_items`, one item over the frame size, or a return value over 8 MiB − 64 KiB | no |
| `stalled` | `Stalled` | awaiting a promise while no call, timer or job is pending | no |
| `cancelled` | `Cancelled` | host `cancel` | no |
| `internal` | `ProtocolError` or `InternalError` | host violation (exit 1) or runner fault | no |

An uncatchable error skips `catch` and `finally`. Stack overflow is a
catchable `RangeError` and ends up as `script_error` if it is not caught.

**Which ending wins.** A script can end itself three ways: `exit()`, its
promise settling with a value, or an uncaught error (`script_error`). The
runner can end it four ways: `output_exceeded`, `memory_exceeded`,
`cpu_exceeded` and `cancelled`. The host has a fifth, the wall-clock kill.
Once any of these is recorded no more script code runs (the error is
uncatchable, and a native call that was running, such as a typed-array sort,
calls back into the script no more), but the native call itself can run on.
So the runner decides the ending when the script actually stops, not when
the first reason was recorded:

- **A script's own ending never hides a limit or a cancel.** `exit()`, a
  value and a `script_error` stand only if, when the script stopped, there
  was no `cancel`, the heap was not exhausted and the interpreter's CPU time
  was within `cpu_ms`, checked in that order. Otherwise the ending is
  `cancelled`, `memory_exceeded` or `cpu_exceeded`. This holds when the
  interpreter writes `done` and when the watchdog does: the watchdog fires
  only after the budget ran out or a cancel was ignored, so it never writes
  a success.
- **Between the runner's endings, the first one recorded stands.** Each is a
  failure (`ok: false`) the host cannot take for success, and the process
  still ends at the same CPU bound, so a later reason would only rename it.
  A script that overflowed its output and then sat in a native call until
  the watchdog fired ends as `output_exceeded`.
- **The host's wall-clock kill ends everything.** The process is killed, no
  `done` is written after it, and the host records the timeout, whatever the
  runner had recorded.

| First | Then | Ending |
| --- | --- | --- |
| `exit()`, a value or a `script_error` | `cancel` arrives, the heap runs out, or CPU passes `cpu_ms` before the script stops | `cancelled`, `memory_exceeded` or `cpu_exceeded` |
| `exit()`, a value or a `script_error` | nothing before the script stops | that ending (`ok: true`, the value or no value; or `script_error`) |
| `output_exceeded`, `memory_exceeded`, `cpu_exceeded` or `cancelled` | any other reason | the first |
| anything | the host's wall-clock kill | no `done`; the host's timeout |

`exit_cannot_hide_an_overrun_or_a_cancel` in `tests/protocol.rs` calls
`exit()` from a typed-array sort's comparator and requires `cpu_exceeded`
with a 50 ms budget and `cancelled` after a `cancel`; `exit_ends_successfully`
requires a plain `exit()` to stay `ok`.

### Limits shared with the host

The host (`code_sandbox_process.dart`, constants in `CodeModeLimits`) ends a
session as a protocol violation when a frame breaks one of its rules. The
runner refuses the same things first, as an error the script can catch or as
the script's own `output_exceeded`, so a runner that keeps its rules never
trips the host's. Each pair, runner first:

| What | Runner | Host | Why the runner's side never trips the host's |
| --- | --- | --- | --- |
| Call name | 1..=256 UTF-8 bytes (`MAX_CALL_NAME_BYTES`), else `RangeError`/`TypeError` | non-empty, at most `maxCallNameBytes` 256 | same bound |
| Call arguments | a JSON object of at most `max_call_args_bytes` as Dart encodes it, else `TypeError`/`RangeError` | a map, at most `maxCallArgumentBytes` 1 MiB + 4,096 slack by `jsonEncode` | same measure, stricter bound |
| Calls | `max_calls` (the host sends `maxNestedCalls` + 1,000) | `call_cap` past the same number | same number |
| Output characters | `max_output_chars` = `interpreterOutputBytes` 16 Mi; Unicode scalars of text, `data.length` of an image | over 16 Mi + `maxFrameBytes` 8 Mi is `output` | the runner stops at the cap; the host allows a frame more |
| Output items | `max_output_items` = `interpreterOutputItems` 100,000 | over 100,001 is `output` | the runner stops at the cap |
| Image | the five rules above | `imageProblem`: the same five | same rules; the runner's base64 is stricter |
| Frame | at most 8 MiB, newline excluded (`MAX_FRAME_BYTES`); one item at most 8 MiB − 64 KiB escaped | `frame_too_large` over `maxFrameBytes` 8 MiB, newline excluded | same bound |
| Nesting depth | at most 127 levels for every value it parses (arguments, stored and return values): serde_json's recursion limit of 128 refuses the 128th, as a catchable `TypeError` | `maxFrameDepth` 130: `kRunnerMaxJsonDepth` 128 for the value, one for the frame, one for a field | a value sits one level inside its frame, so a frame is at most 128 deep |
| Store operations | 2,000 writes and deletes (`MAX_STORE_OPS`), then `RangeError` | `store_overrun` past `maxStoreFrames` 2,000 | same number, both counting deletes |
| Store key | at most 512 UTF-8 bytes (`MAX_STORE_KEY_BYTES`) | at most `maxStoreKeyBytes` 512 | same bound |
| Stored value | at most `store_value_bytes` as Dart encodes it | at most `maxStoreValueBytes` 256 KiB + 4,096 slack by `jsonEncode` | same measure, stricter bound |
| Stored total | at most `store_total_bytes` across current keys, values as Dart encodes them, initial values included | `store_overrun` over `maxStoreTotalBytes` 1 MiB + 64 KiB slack across current keys | same measure and bookkeeping (a delete or an overwrite frees the old size), stricter bound |
| Values written | at most 16 × `store_total_bytes` per script, overwrites included | no counterpart | only the runner's; it bounds what a script can make the host persist and changes nothing the host checks |
| Store in a read-only session | budget 0: every write and delete is a `RangeError` | a store frame is `protocol` | nothing is written |

"As Dart encodes it" is the UTF-8 length of Dart's `jsonEncode` of the value
the host decodes, which the runner computes (`src/hostjson.rs`). It differs
from the script's own JSON in numbers only: Dart reads an integer outside
the 64-bit range as a double and writes every integral double below 10^21
with `.0`, so `1e20` (21 characters from `JSON.stringify`) is 23. Measured
the script's way, a megabyte of such numbers would be about 9% over the
host's cap. The runner parses numbers exactly (serde_json's
`float_roundtrip`), so the value the host decodes is the one the script
wrote, and so is its length. Initial store values are measured the same way,
which matches the host's count of their saved text because that text is
always the host's own `jsonEncode` of a stored value; anything else that
ever writes the store must save it the same way, or the two running totals
drift apart.

### Host → runner

**`init`**

```json
{"type":"init","limits":{...},"catalog":[{"id":"…","name":"…","namespace":"…","description":"…"}],"store":{"key":<json>}}
```

- `catalog` lists the tools the script may call.
  - The script can name a tool by `id` or by raw `name`.
  - If two entries map the same key, the first one wins.
- `store` holds the values from earlier sessions.

`limits` (every key is required; all values are non-negative integers):

| Key | Meaning | Accepted range |
| --- | --- | --- |
| `wall_ms` | wall budget; enforced by the host, reported by `limits()` | any |
| `cpu_ms` | interpreter CPU time | 1..=120000 |
| `heap_bytes` | QuickJS heap | 4 MiB..=1 GiB |
| `stack_bytes` | QuickJS stack (the thread has 8 MiB) | 64 KiB..=4 MiB |
| `max_calls` | `call` frames, tool and host together | any |
| `max_call_args_bytes` | serialized `args` of one call | ≤ 8 MiB − 64 KiB |
| `max_output_chars` | total output characters | any |
| `max_output_items` | total `output` frames | any |
| `store_value_bytes` | serialized size of one stored value | ≤ 8 MiB − 64 KiB |
| `store_total_bytes` | serialized size of all stored values | any |
| `return_budget_chars` | characters of output the host's result keeps whole; only reported by `limits()` | any |

A value outside its range is a protocol violation.

**`exec`**: `{"type":"exec","code":"…"}`. The code is the body of an async
function, so top-level `await` and `return` work.

**`result`**: the answer to one `call`.

```json
{"type":"result","id":1,"ok":true,"payload":<json>,"credit_ms":0}
{"type":"result","id":1,"ok":false,"payload":{"message":"…","status":"denied"}}
```

- With `ok: true`, the call's promise resolves to `payload`.
- With `ok: false`, it rejects with an `Error(message)`, and `.status` is set
  when `status` is a string.
- `credit_ms` is optional. It adds wall time back to what `limits()` reports,
  for time the host spent waiting on people.

**`cancel`**: `{"type":"cancel"}`. Stops the script at the next interrupt
check or right away if it is waiting; if the script is inside a long native
call, the watchdog ends it within about 0.3 s.

### CPU budget and cancel

The interpreter enforces `cpu_ms` and `cancel` from QuickJS's interrupt
handler, which QuickJS polls every 10,000 interpreter steps. One step can be
a long native call: a typed array's default `sort`, `fill` or `includes` over
hundreds of megabytes, `'x'.repeat(1e8)`, `Array.prototype.join` of a large
array. A loop of such calls polls the handler seconds or minutes apart.

So a watchdog thread looks every 50 ms at the process's CPU time and at the
cancel flag. If the interpreter has not ended the script 0.5 s of CPU after
its budget ran out, or 250 ms after a `cancel`, the watchdog writes `done`
and ends the process with exit code 0. The kind follows
[Which ending wins](#runner--host): a limit or cancel already recorded, or
else `cancelled`, then `memory_exceeded`, then `cpu_exceeded`; never a
success, even when the script had called `exit()`.

**Whose CPU time.** The interpreter compares its own thread's CPU time with
`cpu_ms`; that includes turning tool results into JavaScript values. The
watchdog compares the whole process's CPU time with `cpu_ms` + 0.5 s; that
also includes the stdin reader thread reading and parsing every frame the
host sends. A script that receives very large tool results therefore pays
for parsing them, and can be ended as `cpu_exceeded` by the watchdog before
its interpreter time reaches the budget. Stats' `cpu_ms` is the
interpreter's time, or the process's time when the watchdog ended it.
The watchdog reads only the process CPU clock and waits with a timeout, both
on every allowlist.

Measured with a 1 s budget and a 256 MiB heap (release, macOS arm64), CPU
time when the script ended:

| Script (a loop of the call, or one call over a large array) | Before | After |
| --- | --- | --- |
| `Array.prototype.join`, `eval` of a large source, `String.prototype.indexOf`, `normalize`, `padStart`, `repeat`, `replaceAll`, `toUpperCase`, typed-array `join`, `lastIndexOf` | killed by `SIGXCPU` at 135 s | 1.50–1.55 s |
| typed-array `reverse` | 109 s | 1.50 s |
| `Array.prototype.flat` | 82 s | 1.54 s |
| string concatenation and `join` | 45 s | 1.53 s |
| typed-array `sort` in a loop, `includes`, `indexOf` | 14–34 s | 1.53–1.54 s |
| typed-array `copyWithin`, `fill`, `set`, `slice`; `ArrayBuffer.slice` | 4–7 s | 1.51–1.54 s |

The other 20 scripts measured (regular expressions, `Atomics`, `BigInt`,
`JSON`, `Map`, `Date`, default sorts and others) already ended within the
budget or at the heap limit, before and after.

## Exit codes

| Code | Meaning | Frames written |
| --- | --- | --- |
| 0 | session ended | `ready` … `done` |
| 1 | host protocol violation | `done` with kind `internal`, name `ProtocolError` |
| 2 | usage | none |
| 3 | lockdown not `full` (or, on Windows, the confined child could not be started) | `ready` only |
| 4 | runtime or prelude set-up failed, or the runner panicked, also after the lockdown (one line on stderr: `cc_codemode: internal error: …`) | none, or the frames before the panic |
| 5 | stdin closed before `done` (or stdout write failed) | none after the last frame |

The kernel backstops end the process by signal:
- `SIGSYS`: a system call outside the seccomp allowlist;
- `SIGABRT` (Linux, macOS): `abort()`, from an allocation failure in the
  runner's own Rust code or a failed QuickJS assertion. Rust prints
  `memory allocation of N bytes failed` on stderr first. On Linux the
  allowlist admits exactly this: `tgkill` addressed to the runner's own
  process with `SIGABRT`, so it can no longer be mistaken for `SIGSYS`;
- `SIGXCPU` at 135 s of process CPU time, then `SIGKILL` at 140 s;
- `SIGXFSZ`: stdout or stderr is a regular file;
- `SIGSEGV`, `SIGBUS`: a fault in the runner itself, nothing on stderr (below).

A fault in the runner itself ends it with the fault's signal, on Linux and
macOS alike: `SIGSEGV` for an access to unmapped memory, `SIGBUS` for one
past the end of a mapped file. Nothing is written to stderr. std's handler sees
the fault first; when it is not a stack overflow it puts the default action
back and the fault repeats (on Linux the allowlist admits exactly that
`sigaction`). A stack overflow in Rust code is std's
`thread '…' has overflowed its stack` on stderr, then `SIGABRT` (std's
behaviour; the tests do not exercise it).

A panic never aborts: the hook writes one line to stderr (formatted into a
fixed buffer, so it works when the panic came from running out of memory)
and exits with 4, also after the lockdown.

`faults_and_panics_after_the_lockdown` (in `runner/src/main.rs`, test-only)
pins these three: it starts the test binary again, applies the panic hook
and the lockdown exactly as `run` does, then writes to address 16, reads a
mapped page past the end of its file, or panics, and requires `SIGSEGV`,
`SIGBUS` and exit 4.

On Windows, the launcher exits with the child's exit code. The job kills the
child if the launcher dies, and also when it has used 135 s of user-mode CPU
time. By reading, not run: a panic is exit 4 there too; an access violation
ends the child with `STATUS_ACCESS_VIOLATION` (`0xC0000005`, as an exit code
3221225477), which the launcher passes on.

## Lockdown report

`ready.lockdown`, and `selftest.lockdown`:

```json
{"level":"full|partial|none","os":"linux|macos|windows",
 "controls":[{"name":"seccomp","required":true,"status":"applied|unavailable|failed","detail":"…"}],
 "failed":["…"]}
```

- `level` is `full` only when:
  - something was applied;
  - no required control is anything other than `applied`;
  - no optional control `failed`.
- `level` is `none` when nothing was applied.
- `failed` names every control that blocks `full`.

**Optional controls.** A required control must be `applied`. An optional
control blocks `full` only by reporting `failed`; `unavailable` never does.
Each optional control says which it reports:

| Control | `unavailable` | `failed` |
| --- | --- | --- |
| `landlock` (Linux) | the kernel has no Landlock, or a container refuses the version query | the kernel offered Landlock and applying it failed: something is wrong with this host, so the runner refuses |
| `shadow_stack`, `signature_policy` (Windows) | whenever it is not in force, with a short detail (not offered, could not be set, or read back off) | never: hardening the lockdown does not depend on |

Controls by OS:

| OS | Control (required unless marked optional) | What it denies |
| --- | --- | --- |
| Linux | `close_inherited_fds` | access to any inherited descriptor above 2 |
| | `personality` | `READ_IMPLIES_EXEC` (readable mappings that are also executable): cleared if set, and the lockdown fails if it stays set. The kernel already clears it whenever it executes a 64-bit program, so `setarch -X` does not reach the runner (tested on x86_64 and aarch64); the filter then refuses `personality` |
| | `no_new_privs` | privilege gain through exec (verified with `PR_GET_NO_NEW_PRIVS`) |
| | `capabilities` | every capability a runner started as root (or with file capabilities) would hold: the effective, permitted and inheritable sets are cleared with `capset`, the ambient set with `PR_CAP_AMBIENT_CLEAR_ALL`, and, when `CAP_SETPCAP` is held, the bounding set with `PR_CAPBSET_DROP`. All are read back. Unprivileged, there is nothing to clear and the read-back is empty; the bounding set stays as it was, which grants nothing under `no_new_privs` without `execve` |
| | `landlock` (optional, see above) | every file system right the kernel's ABI knows; TCP bind and connect (ABI ≥ 4); abstract UNIX sockets and signals outside the domain (ABI ≥ 6) |
| | `not_dumpable` | ptrace attach and core dumps by the same user |
| | `rlimits` | core files (`CORE`=0), writing to files (`FSIZE`=0), new processes (`NPROC`=0), more than 3 descriptors (`NOFILE`=3), more than 3 GiB of address space (`AS`), more than 135/140 s of CPU |
| | `seccomp` | every system call except the list below. Any other call kills the process. Applied to all threads (TSYNC). x86_64 and aarch64. |
| macOS | `close_inherited_fds` | as above |
| | `mach_ports` | sending to a Mach port inherited from the parent: the task and thread exception ports (a parent's crash handler) set to null, the registered ports cleared, the bootstrap and debug control special ports set to null and the bootstrap port's send right dropped; each read back |
| | `rlimits` | `CORE`=0, `FSIZE`=0, CPU 135/140 s |
| | `seatbelt` | see [macOS profile](#macos-profile); verified with `sandbox_check` |
| Windows | `appcontainer` | the user's files, registry, network and named objects, and every other runner: an AppContainer of its own (see [Windows](#windows)), whose token carries exactly one capability, `controlCenterCodeModeRunner` (verified from the token) |
| | `lpac` | everything that grants ALL APPLICATION PACKAGES access (an all-users install, parts of the Windows directory and ProgramData, brokers that admit that group): the child is a less-privileged AppContainer. Two readings, either of which may say yes: `GetTokenInformation(TokenIsLessPrivilegedAppContainer)` (a class documented as reserved), then, whenever that did not say yes, the token's `WIN://NOALLAPPPKG` attribute. A refusal's detail says what each reading said |
| | `job_object` | more than one process, more than 3 GiB of committed memory, more than 135 s of user-mode CPU time, any UI access (`JOB_OBJECT_UILIMIT_ALL`), outliving the launcher (kill on close); every limit read back |
| | `mitigations` | dynamic code, win32k system calls, child processes, legacy extension points, remote and low-label images (and System32 searched first), non-system fonts, invalid handle use (strict handle checks raise), Control Flow Guard in force, address randomisation forced (bottom-up, high-entropy, force-relocate in its plain mode; see [Windows](#windows)); heap corruption terminates. Every policy is read back with `GetProcessMitigationPolicy`; heap termination, which has no query, the child turns on itself. |
| | `signature_policy` (optional, never blocks) | loading any image Microsoft did not sign. The child sets it on itself once it is running (at creation it would refuse the runner's own executable) and reads it back |
| | `shadow_stack` (optional, never blocks; `unavailable` where the processor or Windows has none, or where it reads back off for this image) | return-address overwrites, through hardware shadow stacks in compatibility mode (the mode an executable without the CET marking tolerates); set at creation, read back |

The Linux allowlist (unconditional unless a condition is given):

| Call | Condition | Why |
| --- | --- | --- |
| `read` | fd 0 | stdin |
| `write` | fd 1 or 2 | stdout, stderr |
| `mmap` | anonymous, not `PROT_EXEC` | the allocators |
| `mprotect` | not `PROT_EXEC` | guard pages, the allocators |
| `munmap`, `mremap`, `brk` | | the allocators |
| `madvise` | advice `WILLNEED`, `DONTNEED`, `FREE`, `HUGEPAGE`, `NOHUGEPAGE` or `DONTDUMP` | the allocators return and tune memory; the rest (`MADV_HWPOISON`, `MADV_DOFORK`, `MADV_WIPEONFORK`, `MADV_COLLAPSE`, `MADV_REMOVE` and others) kill the process. A unit test pins the list. It also refuses `MADV_GUARD_INSTALL` (102), which recent glibc may use when it creates a thread; that is safe only because no thread is created after the filter (`clone` is denied as well), and `threads_stay_at_three` pins that |
| `futex` | `op & 0x7f` is `WAIT`, `WAKE`, `WAIT_BITSET` or `WAKE_BITSET` (the private and realtime flags are outside the mask) | std's locks, channels and timed waits; the priority-inheritance and requeue operations kill the process |
| `clock_gettime` | clock id 0..=11 compared as an unsigned 32-bit number | the static clocks (`CLOCK_THREAD_CPUTIME_ID` for the budget, `CLOCK_PROCESS_CPUTIME_ID` for the watchdog, monotonic and realtime). Negative ids, the CPU clocks of other processes and threads, are refused: the kernel hands them out without a permission check |
| `gettimeofday` | | the vDSO falls back to it on a clocksource it cannot read (hpet, acpi_pm); takes no clock id |
| `gettid`, `getpid` | | std's thread handles; `abort()`. No arguments; the caller's own ids |
| `tgkill` | tgid = this process's pid (fixed when the filter is built) and signal `SIGABRT` | `abort()`. A tid outside this thread group is refused by the kernel |
| `rt_sigaction` | signal `SIGSEGV` or `SIGBUS` | std's fault handler puts the default action back before the fault repeats, so a fault ends the runner with its own signal instead of `SIGSYS`. The new action is a pointer the filter cannot inspect |
| `sched_yield`, `rt_sigreturn`, `rt_sigprocmask`, `sigaltstack`, `restart_syscall` | | std, glibc |
| `getrandom` | | hash seeds |
| `exit`, `exit_group` | | |

`clock_getres` and `clock_nanosleep` are not on the list, and nothing on it
takes a pid except `tgkill`, which is pinned to this process. `mremap` can
duplicate an existing executable mapping (`MREMAP_DONTUNMAP`) with the
protection it already has; it cannot make writable memory executable,
because `mmap` and `mprotect` with `PROT_EXEC` are refused, so it opens no
writable-and-executable path. A unit test pins
the list by number for each architecture.

A Windows launcher that cannot start the child reports the step that failed
(`appcontainer`, `runner_access`, `job_object`, `stdio`,
`process_attributes` or `launch`), writes `ready` with that report and exits
3.

### macOS profile

`(deny default)` does not cover several operation classes, so the profile
(`lockdown/src/macos.rs`) denies them by name and adds two filters:

| Rule | Closes |
| --- | --- |
| `(deny process-info*)` | `proc_listallpids`, `proc_pidinfo`, `proc_pidpath`, `proc_pid_rusage` and `sysctl(KERN_PROCARGS2)` on other processes; the last returned another process's arguments and whole environment |
| `(deny file-test-existence)` | `access()` as an existence oracle for any path |
| `(deny process-codesigning*)`, `(deny dynamic-code-generation)`, `(deny system-info)`, `(deny iokit-get-properties)` | code-signing operations, `MAP_JIT`, system information, I/O Registry properties (serial number, platform UUID) |
| `(deny syscall-mig …)` | the kernel MIG routines on the host and processor-set ports (per-core CPU load, memory statistics, kernel version, task and thread lists, clocks) and the I/O Kit main port and registry lookups |
| `(deny syscall-unix …)` | `getppid`, `getpriority`/`setpriority`, `gethostuuid`, `getfsstat`, `proc_info`, `memorystatus_control`, System V IPC, and (already refused by the rules above) `socket`, `socketpair`, `fork`, `vfork`, `posix_spawn`, `execve` |
| `(deny syscall-unix …)`, process groups and events | `getpgid` and `getsid` of any pid (each told live pids from dead ones, so they enumerated processes), `setpgid` and `setsid` (leaving the server's process group or session, which the server's group kill relies on), `kqueue` and every `kevent*` call (`EVFILT_PROC` watched any process fork, exec and exit) |
| `(deny syscall-unix …)`, metadata | `memorystatus_get_level` (the machine's memory pressure), `getlogin`/`setlogin`, the audit identity and session (`getauid`, `getaudit_addr`, `audit_session_self`, `audit_session_join`, `audit_session_port` and the setters), `audit`/`auditon`/`auditctl`, and the kernel trace points (`kdebug_trace*`, `kdebug_typefilter`) |
| `(deny syscall-mig …)`, Mach ports | `task_get_special_port`, `task_get_exception_ports`, `thread_get_exception_ports` and `mach_ports_lookup`: the ways back to a port the `mach_ports` control removed, and to `TASK_ACCESS_PORT`, which an unprivileged process cannot clear |

Nothing in the runner uses a kernel event queue: it links only libSystem
and libiconv and creates no dispatch source. A program that did (anything
built on libdispatch's sources, CoreFoundation's run loop) would stop with
`SIGTRAP` under this profile, and the self-test and test suite would show
it.

**Inherited Mach ports.** A process on macOS inherits send rights that no
Seatbelt operation mediates, so the `mach_ports` control removes them before
the profile is applied, and the profile denies the routines that would
fetch them again:

| Port | Treatment |
| --- | --- |
| task and thread exception ports | set to null for every exception type, read back. A crash still reaches the host-level handler (the system crash reporter), as for every process; the runner cannot send that handler a message of its own |
| registered ports (`mach_ports_register`) | cleared, read back; `mach_ports_lookup` denied |
| bootstrap port (launchd) | set to null, the send right dropped, read back. The profile already denied its name lookups; launchd answers other requests, which now have nowhere to go |
| debug control port | set to null, read back |
| `TASK_ACCESS_PORT` | cannot be changed without privilege (`KERN_NO_ACCESS`); reading it is denied (`task_get_special_port`) |
| audit session port | `audit_session_self` and `audit_session_port` denied |
| host port (`mach_host_self`) | the unprivileged host name port. The profile denies the routines listed above; any other routine on it is not mediated (see SECURITY.md, "Not claimed") |
| own task and thread ports, reply ports | the process's own kernel objects, which the runtime needs |

The self-test's `mach_ports` check takes whatever it can still reach (the
`bootstrap_port` global, then each getter), sends it a message, and must
find nothing to send to.

Measured with a native probe of about 110 operations run under this
profile (and the reviewer's programs), what remains allowed, and why:

- **Whether a pid exists, through `kill(pid, 0)` and `csops`.** Seatbelt
  checks both only after the kernel has looked the pid up, so a dead pid
  answers `ESRCH` and a live one `EPERM` (or, for `csops`, its code-signing
  flags). A `syscall-unix` rule by number does not stop either: both were
  measured with the rule in place, and `kill` must stay usable for the
  runner's own `abort()`. So a script cannot signal another process, but
  native code in the runner could tell live pids from dead ones. Nothing
  else about the process is readable.
- **Signals to itself.** `kill(self)`, `raise`, `abort()` (tested:
  `abort_works_under_the_lockdown` ends with `SIGABRT` under the full
  profile), and `kill(0)`/`kill(-1)`, which reach only the runner (tested: a
  sibling in the same process group survives `SIGTERM` to the group).
- **Thread creation.** Seatbelt has no operation for it; a new thread is in
  the same sandbox and the same process.
- **The process's own state.** Its uid and gid, values cached before the
  lockdown (the environment is empty; libc's locale cache), its own Mach task
  and the commpage clock (`mach_absolute_time`). The runner needs these.
- **The open stdio descriptors.** Seatbelt does not re-check them.
- **Memory.** macOS gives an unprivileged process no way to bound its own
  memory: lowering `RLIMIT_AS` or `RLIMIT_DATA` fails with `EINVAL`,
  `memorystatus_control` limits need privilege (`EPERM`), and
  `task_set_phys_footprint_limit` returns `KERN_NO_ACCESS`. The
  interpreter's allocator limit bounds the script's heap; native memory
  outside it is bounded only by the host's wall-clock kill.

Nothing the runner needs is denied: the full test suite and the self-test
run under this profile.

### Windows

None of this has run on Windows yet; it is type-checked for x86_64 and
aarch64.

- **One AppContainer per launch.** The name is `ControlCenter.CodeMode.`
  followed by 128 bits from `BCryptGenRandom` (system RNG). The launcher
  registers a profile for that name with `CreateAppContainerProfile`, which
  returns the SID; CreateProcessW needs the profile's registry mapping and
  fails with `ERROR_FILE_NOT_FOUND` for a SID that is only derived. A name
  that already exists is refused, not joined. The launcher deletes the
  profile (`DeleteAppContainerProfile`) once the child is gone, so no profile
  folder, registry entry or named-object directory outlives the child unless
  the launcher itself is killed first. Two runners never have
  the same package SID, so the AppContainer access check stops one from
  opening the other's process (the self-test checks this; see below).
- **A less-privileged AppContainer.** The launcher opts the child out of ALL
  APPLICATION PACKAGES (`PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY`).
  Many objects grant that group read access: Program Files (so an all-users
  install), much of the Windows directory and ProgramData, and brokers that
  admit any packaged app. The child reaches none of them through that
  group. It keeps whatever grants ALL RESTRICTED APPLICATION PACKAGES, its
  own package SID or its capability: System32 and the known DLLs grant that
  group, as do some other system objects (registry keys, named pipes, ALPC
  ports) not inventoried here. The `lpac` control reads the opt-out back
  from the token; it is the proof. The `all_packages_object` and
  `install_dir_read` probes (see [Self-test](#self-test)) corroborate it.
- **Access to its own executable.** The child needs read and execute on
  `cc_codemode.exe`. Every child carries one capability,
  `controlCenterCodeModeRunner` (SID from `DeriveCapabilitySidsFromName`), and
  the executable's DACL grants that capability `FILE_GENERIC_READ |
  FILE_GENERIC_EXECUTE`. The launcher adds that ACE when it is missing; when it
  is missing and the user may not change the DACL (an all-users install), the
  launch fails with control `runner_access`, whose detail names the command
  that adds it: `"<path>\cc_codemode.exe" --grant-runner-access`, run as an
  administrator. The installer (`windows/installer/control_center.iss`) runs
  that command, hidden and waited for, after it copies the files, in both its
  per-user and all-users modes, for the runner inside the embedded server
  (`{app}\cc_server\bin\codemode\cc_codemode.exe`). Inno Setup does not
  check that command's exit code, so a failed grant shows only at the first
  launch, as `runner_access` with the command to run. The portable zip,
  unpacked on NTFS, needs nothing: the person who unpacks it owns the file,
  so the launcher can add the ACE itself. A volume without DACLs (FAT,
  exFAT) has not been tried.
  The capability names nothing else, and an AppContainer process's own
  security descriptor grants its package SID, not its capabilities, so the
  shared capability does not let one runner open another.
- **Access to the system.** Windows grants ALL RESTRICTED APPLICATION
  PACKAGES read access to System32 and the known DLLs, which the loader
  needs; that is all a less-privileged AppContainer gets from the system.
  The runner is statically linked, so it needs nothing else beside its
  executable. Nothing in this repository grants either group anything.
- **Imports from System32 only.** The executable is linked with
  `/DEPENDENTLOADFLAG:0x800` (`LOAD_LIBRARY_SEARCH_SYSTEM32`, set in
  `runner/build.rs`), so the loader resolves its imports in System32 and
  never beside the executable, where a planted `kernel32`-named DLL would
  otherwise be found first for a non-known DLL. DLLs loaded at run time
  (`userenv`, `bcrypt`, `ws2_32`, `kernelbase`) use
  `LOAD_LIBRARY_SEARCH_SYSTEM32` too. `scripts/release/windows_natives.sh`
  checks the load config's dependent load flag and holds the import table to
  an allowlist.
- **Mitigations beyond the required set.** The launcher forces address
  randomisation (bottom-up, high entropy, and force-relocate in its plain
  "always on" mode, which relocates a DLL linked without `/DYNAMICBASE` that
  still carries relocations; one with no relocation section would still load
  at its base, and every DLL the runner loads is part of Windows; required,
  in `mitigations`) and, where the processor and Windows have user-mode
  shadow stacks, turns them on in compatibility mode (optional control
  `shadow_stack`: compatibility mode is the one an executable without the
  CET marking tolerates). The child sets the Microsoft-signed-only image
  policy on itself once it runs (optional control `signature_policy`; set at
  creation it would refuse the runner's own unsigned-by-Microsoft image).
  Neither optional control blocks `full` (see
  [Optional controls](#lockdown-report)).
- **Build.** `-Ccontrol-flow-guard` for the Rust code and `/guard:cf /GS` for
  QuickJS-NG (`CFLAGS_<target>`); `runner/build.rs` refuses a Windows build
  without them, and `scripts/release/windows_natives.sh` checks the image
  with `dumpbin`. Control Flow Guard covers the whole image (Rust and
  QuickJS-NG); the loader enforces it and the child reads it back. It is the
  only forward-edge (indirect call) protection in force on any platform; see
  "What of that is in force" under [Build and install](#build-and-install).

**Landlock is defence in depth, not a requirement.** On Linux, seccomp is the
required control and Landlock is optional: a kernel without it (`ENOSYS`), one
booted without it in `lsm=` (`EOPNOTSUPP`), or a container whose seccomp
profile refuses the version query (`EPERM`) reports `landlock` as
`unavailable` and the level stays `full`. A failure after the version query
succeeded is `failed`, and the level is not `full` (the rule under
[Optional controls](#lockdown-report)). Running without Landlock is safe because the seccomp
allowlist alone already denies everything Landlock would: it contains no call
that opens a file or directory, creates a socket, or starts a process or
thread (`open`, `openat`, `socket`, `connect`, `clone`, `execve` and the rest
all kill the process), so a script cannot reach the file system or the network
whether Landlock is there or not. A unit test pins the allowlist by system call
number for each architecture, and another fails if any opening or spawning call
is ever added. Landlock still matters if the allowlist were ever widened by
mistake, which is why it is applied whenever the kernel has it, and it is
tested on its own: `landlock_alone_denies_files_network_and_signals` starts
the test binary again, applies only `no_new_privs` and Landlock (no seccomp),
and requires opening a file, creating a file, TCP connect and bind (ABI ≥ 4)
and signalling the parent (ABI ≥ 6) to be refused; it says so and passes on a
kernel without Landlock. A runner on a kernel without seccomp, by contrast, is
`partial` and refuses to run.

## Self-test

`cc_codemode --self-test` proves both halves of what the host relies on, and
prints one JSON line:

```json
{"selftest":{"ok":true,"os":"linux","build":"release","lockdown":{...},
 "checks":[{"name":"file_read","denied":true,"detail":"killed by SIGSYS (seccomp)"}, ...],
 "session":{"passed":true,"runs":13,"detail":"8 sessions returned the expected value and exited 0; 5 ended as they must (cpu_exceeded, memory_exceeded, output_exceeded, cancelled, script_error)"}}}
```

- **`checks`: the lockdown denies.** Each check is attempted from native
  code under the full lockdown and must be refused. On Linux each runs in its
  own forked child, because a refusal kills the process; on macOS in the
  confined process itself; on Windows in a confined child of the launcher.

  | OS | Checks |
  | --- | --- |
  | all | `file_read`, `file_create`, `network`, `process` |
  | Linux | `cpu_clock` (the CPU clock of pid 1), `futex_pi` (`FUTEX_LOCK_PI`), `madvise_advice` (`MADV_RANDOM`, an advice value outside the allowlist), `landlock` (open `/etc/hosts` with the thread-scoped controls applied and no seccomp filter; run only when the report says Landlock was applied, so it is absent where the kernel has none) |
  | macOS | `process_args` (`KERN_PROCARGS2` of a sibling `/bin/cat`), `process_info` (`proc_pidinfo` of it), `file_exists` (`access("/etc/hosts")`), `mach_lookup` (the notification center), `host_statistics` (CPU load), `signal` (`kill(sibling, 0)`), `process_group` (`getpgid` of the parent, `getsid` of the sibling), `process_watch` (`kqueue` with `EVFILT_PROC` on the parent), `leave_group` (`setpgid`), `new_session` (`setsid`), `memory_pressure` (`memorystatus_get_level`), `login_name` (`getlogin`), `audit_session` (`getaudit_addr`, `audit_session_self`), `kdebug` (`kdebug_trace`), `mach_ports` (send to every inherited port still reachable) |
  | Windows | `windows_write` (create a file in `Windows\Temp`, which every user may), `sibling_vm_read` and `sibling_dup_handle` (`OpenProcess` on a second confined child, which the launcher itself can open), `install_dir_read` (read another file beside the runner or in the directory above it), `all_packages_object` (read a file the launcher created granting only ALL APPLICATION PACKAGES read access). Only `ERROR_ACCESS_DENIED` counts as denied for these. The last two each have a positive control the child must pass first, or the check is not attempted and fails: `install_dir_read` reads the runner's own executable (granted to the capability; its path covers every directory the neighbour's path crosses), `all_packages_object` reads a file in the same directory granted only to the runner capability. So a refusal is the access entry's, not traversal's. What they prove differs by install: in a per-user install the files sit under the user's profile and grant only the user, which refuses every AppContainer, less-privileged or not, so `install_dir_read` shows only that the install is closed to the runner; in an all-users install under Program Files, which grants ALL APPLICATION PACKAGES, the refusal shows the opt-out at work. `all_packages_object` tests the opt-out in every install. `file_read` and `file_create` use a directory under the user's profile (`AppData\Local`), found from the token, since the host passes no `USERPROFILE` or `TEMP`. |

  On Linux every check runs the way production does: the child closes its
  descriptors, prepares the allocator, applies the thread-scoped controls,
  starts a second thread and waits until it has allocated, then applies the
  filter to both threads (TSYNC) and makes the attempt from that thread
  (`landlock` alone stops before the filter).
- **`session`: scripts still run.** The self-test process, before it confines
  itself, starts this same executable with no arguments (the production path,
  including the Windows launcher) with an empty environment and piped stdio,
  plays the host for one canned session and requires `ready` at level `full`,
  the expected `call`, `output` and `store` frames, `done` with `ok: true` and
  the expected value, and exit code 0. The script uses the wall clock, local
  time, timers, a promise chain, a JSON round trip, a 1.5 MB string build, one
  tool call, one `searchTools` call, `store`/`load` and `text`. It runs 8
  times in a row, because some failures depend on timing (a thread's first
  wait can come before or after the lockdown); each session has 20 s before it
  is killed. Then one session for each bad ending, so those code paths run
  under the real lockdown too: `cpu_exceeded` (a 100 ms budget),
  `memory_exceeded` (a 16 MiB heap), `output_exceeded`, `cancelled` (cancel
  while busy) and `script_error` (an uncaught `TypeError` whose `line` and
  stack must point into the script). Each must end with that `done` and exit
  0. Any failure ends the check, and `detail` says which run and what
  happened, for example `run 1 of 8: stdout closed before done: killed by
  signal 31 (SIGSYS: a system call outside the seccomp allowlist)`.
- **`build`** is `release`, or `debug` for a build with debug assertions.
  It does not affect `ok`; `cc_codemode_verify` (`scripts/lib/codemode.sh`)
  refuses to stage or package anything but `release`. `--version` and the
  `ready` frame do not carry it.
- **`ok`** is true only when the level is `full`, every check was denied and
  `session.passed` is true; the exit code is 0 exactly then. The session
  object says `passed`, not `ok`, so a consumer that matches `"ok":true` in
  the text only ever sees the overall verdict.

This exists because the lockdown can be too strict as well as too loose: a
filter missing one system call that the C library reaches only on some hosts
(the vDSO's `gettimeofday` fallback on a VM clocksource, `gettid` on a
thread's first wait) left the denials passing while every real session died.

## Script environment

The intrinsics are `Date`, `RegExp`, `JSON`, `Proxy`, `Map`/`Set`, typed
arrays, `Promise`, `WeakRef` and `eval`/`Function`, plus the ECMAScript base.
Code these evaluate runs inside the same confinement. Local time is UTC on
Linux and macOS: Linux fixes `TZ` to `UTC0` and loads it before confinement,
because glibc would otherwise open `/etc/localtime` after it; on macOS the
sandbox denies the zone file and libc falls back to UTC. There are no host
objects, no module loader, no `Performance` and no `Atomics.wait`.

All intrinsics are deep-frozen, and the prelude's override shims keep
assignments to instance properties working. The script's globals, all frozen
and non-writable:

| Global | Effect |
| --- | --- |
| `tools.<id or name>(args?)` | `call` with `target:"tool"`. An unknown name rejects and suggests the three closest ids. |
| `ALL_TOOLS` | frozen copy of `init.catalog` |
| `searchTools(query, {limit, namespace}?)`, `describeTool(name)`, `describeNamespace(name)` | host calls |
| `models.embed(texts)`, `models.rank(query, candidates, {top}?)`, `models.classify(texts, labels)` | host calls |
| `history({start, limit, role, tool, row, offset}?)`, `outputs({limit, tool}?)`, `loadOutput(handle, {offset, limit}?)`, `keep(value, label)` | host calls; a non-object options value or a non-string handle or label rejects with a `TypeError` before any call |
| `text(value)` | `output` text. A non-string is written as indented JSON. |
| `image(block)` | `output` image. Needs a `{type:"image", mediaType, data}` block that keeps the host's image rules (see `output` above); one that breaks them is a catchable `TypeError` or `RangeError`. |
| `console.log/info/warn/error/debug(...args)` | `output` log |
| `store(key, value)` / `store(key)` | `store` frame. Omitting `value` deletes the key. A key is at most 512 bytes of UTF-8; the size limits are catchable `RangeError`s. |
| `load(key)` | a fresh copy of a stored value, or `undefined` |
| `storedKeys()` | `[{key, bytes}]` sorted by key: the keys `load` can read (`init.store` and this script's writes) and the UTF-8 size of each value's JSON |
| `setTimeout(fn, ms, ...args)`, `clearTimeout(id)`, `sleep(ms)` | timers, at most 10,000 pending |
| `limits()` | `{wallMsRemaining, cpuMsRemaining, callsRemaining, returnBudgetChars, outputItemsRemaining}`; `returnBudgetChars` is `init.limits.return_budget_chars` |
| `exit()` | ends the script with `done` ok and no value |

The call limit and the argument-size limit are catchable `RangeError`s.
Arguments that are not JSON are a catchable `TypeError`.

## Build and install

```bash
scripts/natives/build_codemode.sh [DEST_DIR]   # also run by scripts/natives/build_natives.sh
```

- **Build.** `cargo build --release --locked` with `CARGO_TARGET_DIR=build/cargo/codemode`.
- **Install.** The binary is installed to:
  - macOS: `~/Library/Application Support/com.alev.control-center/codemode/cc_codemode`
  - Linux: `${XDG_DATA_HOME:-~/.local/share}/control_center/codemode/cc_codemode`
  - `DEST_DIR/codemode/cc_codemode` when `DEST_DIR` is given.
- **Signing and self-test.** On macOS each copy is ad-hoc signed. The script
  runs `--version` and `--self-test` on every installed copy and fails if the
  self-test fails.
- **Bundles.** In a bundle the runner sits at `bin/codemode/cc_codemode`
  (`cc_codemode.exe` on Windows).
- **Hardening.** QuickJS-NG's C code is built with
  `-fstack-protector-strong -D_FORTIFY_SOURCE=2`, plus `-fcf-protection=full`
  on x86_64 Linux and `-mbranch-protection=standard` on aarch64 Linux, through
  `CFLAGS_<target>` (the cc crate's per-target variable). The script fails
  unless the compiled `quickjs.o` references `__stack_chk_fail`, on Linux also
  a fortified `__*_chk` call, and carries the IBT/SHSTK (x86_64) or BTI/PAC
  (aarch64) property. CI and the release build (whose bundle the server
  image copies) build through this script.
  QuickJS's assertions stay on; see PROVENANCE.md.
- **What of that is in force.** The object property does not reach the
  executable: Rust's own objects carry no IBT or BTI marking (stable Rust has
  no flag for it), and the linker keeps the property only when every object
  has it, so no loader turns on branch-target enforcement for the runner
  (`readelf -n` on the executable shows no feature note). Per platform, today:

  | Platform | In force |
  | --- | --- |
  | Linux aarch64 | stack protector and fortified calls in QuickJS-NG; return-address signing (PAC) in QuickJS-NG's functions on processors with pointer authentication, which needs no property. Not BTI. Rust code signs no return addresses |
  | Linux x86_64 | stack protector and fortified calls in QuickJS-NG. The IBT landing pads and shadow-stack compatibility are compiled in and inert: neither IBT nor user shadow stacks are enabled for an executable without the property |
  | macOS arm64 | stack protector in QuickJS-NG. clang folds the fortified calls back to plain ones (destination sizes unknown), and the `arm64` (not `arm64e`) ABI signs no return addresses |
  | Windows | `/GS` in QuickJS-NG and Control Flow Guard for the whole image, which the loader enforces and the child reads back; shadow stacks where available (see [Windows](#windows)) |
- **Paths.** The build remaps the home directory, the cargo home, the
  checkout and the target directory (`--remap-path-prefix` for Rust,
  `-ffile-prefix-map` for QuickJS-NG) and fails if the executable still
  contains the home directory, the checkout, the cargo home or the target
  directory. The Windows build does the same in both path styles, as bytes
  and as UTF-16, and fails if `cl` ignored `/d1trimfile` (warning D9002).
  The check itself lives in `scripts/lib/codemode.sh`, so every staging and
  packaging step (`cc_codemode_verify`) repeats it on whatever runner it is
  given, built here or restored from a cache, together with the generic
  markers `/Users/`, `/home/` (outside the remapped `/build/home/`),
  `C:\Users\`, and a cargo registry path outside `/build/cargo/` (cargo
  names workspace sources by relative path, so an unremapped build's
  absolute paths are its dependencies' sources in the cargo home). A runner
  built elsewhere is caught by the markers, not by that machine's prefixes.
  Verification also requires the self-test's `build` field to
  be `release`.

Windows builds must use the static C runtime and Control Flow Guard:
`build.rs` refuses to build without `RUSTFLAGS="-Ctarget-feature=+crt-static
-Ccontrol-flow-guard"` and `CFLAGS_<target>` containing `/guard:cf`. It also
sets an 8 MiB main thread stack and `/DEPENDENTLOADFLAG:0x800`.

## Tests

```bash
cd packages/cc_natives/native/codemode
cargo test --locked             # unit tests, then integration tests against the built binary
cargo test --release --locked
target/release/cc_codemode --self-test | cat
```

- `runner/tests/protocol.rs` drives the real binary over pipes, with its real
  lockdown. It covers every frame, limit, error kind and protocol violation,
  plus the containment of the script environment. Each rule in
  [Limits shared with the host](#limits-shared-with-the-host) has a test
  that the runner refuses what the host would end a session for (the image
  rules one by one, call names, argument shape, sizes as Dart measures them),
  and `the_watchdog_reports_the_right_kind_inside_a_long_native_call` ends a
  script stuck in one native call as CPU, as memory after the heap ran out,
  and as output after an output limit was hit.
- `src/hostjson.rs` pins Dart's `jsonEncode` lengths with cases measured in
  Dart; 6,000 random numbers of every magnitude were also compared against
  Dart once, with no difference.
- The lockdown unit tests check that each self-test probe succeeds when
  unconfined, so a denial is caused by the lockdown and not by a broken probe,
  and that a failed session check makes the verdict false.
- The runner's unit tests drive the session check against fake runners (one
  killed by `SIGSYS`, one at partial lockdown, a wrong value, a hang, garbage
  on stdout); `protocol.rs` runs the real `--self-test` and requires it to
  pass, sessions included, with exactly this platform's checks.
- Lockdown controls each have a test in a fresh copy of the test binary:
  `capabilities_are_dropped` (Linux; as root it reports the sets it
  cleared), `madvise_advice_is_pinned` (Linux), and on macOS
  `mach_ports_clears_an_exception_handler` (sets a handler, applies the
  control, requires it gone) and `abort_works_under_the_lockdown` (the full
  lockdown, then `abort()`, must end with `SIGABRT`).
- Linux: `landlock_alone_denies_files_network_and_signals` (above), and
  `read_implies_exec_is_cleared_by_the_personality_control`, which sets the
  flag in a fresh copy of the test binary and requires the step to clear it
  (skipped, with a line saying so, in a container whose seccomp profile
  refuses that persona, such as Docker's default).
- After the lockdown: `faults_and_panics_after_the_lockdown` (runner, Unix;
  `SIGSEGV`, `SIGBUS`, exit 4; see [Exit codes](#exit-codes)),
  `sigaction_only_for_the_fault_signals` (Linux; `sigaction` passes the filter
  for `SIGSEGV` and `SIGBUS` and is `SIGSYS` for others), and
  `threads_stay_at_three` (`protocol.rs`, Linux; counts the runner's threads
  through `/proc` after `ready` and while a script runs).

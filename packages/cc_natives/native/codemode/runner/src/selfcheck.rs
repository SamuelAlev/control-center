//! The positive half of `--self-test`: proves that real sessions work under
//! the lockdown, not only that the lockdown denies what it must.
//!
//! The self-test process, still unconfined, starts this same executable with
//! no arguments (the production path, including the Windows launcher), plays
//! the host for one canned session over pipes and checks every frame. It does
//! so [`RUNS`] times in a row, because some failures depend on timing: a
//! system call the allowlist lacks may only be reached when one thread wins a
//! race. Then it runs one session for each way a script can end badly
//! (CPU budget, heap limit, output limit, cancel, an uncaught error), so the
//! code paths that only those endings reach also run under the real
//! lockdown. Any failure fails the check, with a reason that names what
//! happened.

use std::io::{BufRead, BufReader, Read, Write};
use std::path::Path;
use std::process::{Child, ChildStdin, Command, ExitStatus, Stdio};
use std::sync::mpsc::{self, Receiver, RecvTimeoutError};
use std::time::{Duration, Instant};

use lockdown::selftest::SessionCheck;
use serde_json::{json, Value};

/// Sessions per self-test.
pub const RUNS: u32 = 8;

/// Longest one session may take, from start to exit, before it is killed.
pub const SESSION_TIMEOUT: Duration = Duration::from_secs(20);

/// Longest detail text, so a runaway stderr cannot bloat the report.
const DETAIL_CAP: usize = 1024;

/// The canned script. It touches what has broken under the lockdown before
/// (the wall clock, local time, a thread's first wait) and what a script
/// commonly uses: timers, promise chains, JSON, a large allocation and string
/// build, a tool call, a host call, the store and output.
const SCRIPT: &str = r#"const t0 = Date.now();
const local = [typeof new Date().getTimezoneOffset(), typeof String(new Date())];
await sleep(5);
const timer = await new Promise((resolve) => setTimeout(() => resolve('fired'), 1));
const chain = await Promise.resolve(2).then((x) => x + 1).then((x) => x * 7);
const rows = [];
for (let i = 0; i < 20000; i++) rows.push({ i, s: 'row' + i });
const big = JSON.stringify(rows) + 'x'.repeat(1 << 20);
const round = JSON.parse(JSON.stringify({ a: [1, 'two', { three: null }] }));
const doubled = await tools.selftest_double({ n: 21 });
const found = await searchTools('double');
store('selftest', { saved: true });
const loaded = load('selftest');
text('selftest');
return { clock: t0 > 0 && Date.now() >= t0, local, timer, chain, big: big.length, round, doubled, found: found.length, loaded };"#;

/// What [`SCRIPT`] must return.
fn expected_value() -> Value {
    json!({
        "clock": true,
        "local": ["number", "string"],
        "timer": "fired",
        "chain": 21,
        "big": 1_566_357,
        "round": {"a": [1, "two", {"three": null}]},
        "doubled": {"value": 42},
        "found": 1,
        "loaded": {"saved": true},
    })
}

const TOOL_ID: &str = "selftest_double";
const TOOL_NAME: &str = "selftest__double";

fn init_frame() -> Value {
    init_with(json!({}))
}

/// `init` with some limits replaced.
fn init_with(overrides: Value) -> Value {
    let mut init = json!({
        "type": "init",
        "limits": {
            "wall_ms": SESSION_TIMEOUT.as_millis() as u64,
            "cpu_ms": 10_000,
            "heap_bytes": 64u64 << 20,
            "stack_bytes": 512u64 << 10,
            "max_calls": 10,
            "max_call_args_bytes": 65_536,
            "max_output_chars": 10_000,
            "max_output_items": 10,
            "store_value_bytes": 1024,
            "store_total_bytes": 4096,
            "return_budget_chars": 10_000,
        },
        "catalog": [catalog_entry()],
        "store": {},
    });
    if let Some(o) = overrides.as_object() {
        for (k, v) in o {
            init["limits"][k] = v.clone();
        }
    }
    init
}

/// A session that must end badly in one particular way.
struct Unhappy {
    /// The `done.error.kind` it must end with.
    kind: &'static str,
    /// Limits replaced in `init`.
    limits: Value,
    script: &'static str,
    /// Sends `cancel` once the first output frame arrives.
    cancel_on_output: bool,
    /// Further checks on `done.error`.
    check: fn(&Value) -> Result<(), String>,
}

fn no_more(_: &Value) -> Result<(), String> {
    Ok(())
}

/// One session per bad ending, each run once after the happy sessions.
fn unhappy_sessions() -> Vec<Unhappy> {
    vec![
        Unhappy {
            kind: "cpu_exceeded",
            limits: json!({"cpu_ms": 100}),
            script: "let n = 0; for (;;) n++;",
            cancel_on_output: false,
            check: no_more,
        },
        Unhappy {
            kind: "memory_exceeded",
            limits: json!({"heap_bytes": 16u64 << 20}),
            script: "const keep = []; for (;;) keep.push('x'.repeat(1 << 16) + keep.length);",
            cancel_on_output: false,
            check: no_more,
        },
        Unhappy {
            kind: "output_exceeded",
            limits: json!({"max_output_chars": 100, "max_output_items": 1000}),
            script: "for (;;) text('0123456789');",
            cancel_on_output: false,
            check: no_more,
        },
        Unhappy {
            kind: "cancelled",
            limits: json!({}),
            script: "text('spinning'); let n = 0; for (;;) n++;",
            cancel_on_output: true,
            check: no_more,
        },
        Unhappy {
            kind: "script_error",
            limits: json!({}),
            script: "const a = [3, 1, 2].sort();\nfunction fail() { throw new TypeError('boom ' + a.join('')); }\nfail();",
            cancel_on_output: false,
            check: |e| {
                let stack = e["stack"].as_str().unwrap_or("");
                if e["name"] == "TypeError" && e["message"] == "boom 123" && e["line"] == 2 && stack.contains("repl.js:2:") {
                    Ok(())
                } else {
                    Err(format!("unexpected error: {}", cap(e.to_string())))
                }
            },
        },
    ]
}

fn catalog_entry() -> Value {
    json!({"id": TOOL_ID, "name": TOOL_NAME, "namespace": "selftest", "description": "Doubles n."})
}

/// Runs [`RUNS`] sessions of the running executable.
pub fn check() -> SessionCheck {
    match std::env::current_exe() {
        Ok(exe) => check_with(&exe, RUNS, SESSION_TIMEOUT),
        Err(e) => SessionCheck::not_run(&format!("cannot locate this executable: {e}")),
    }
}

/// Runs `runs` sessions of `exe` in a row and stops at the first failure.
pub fn check_with(exe: &Path, runs: u32, timeout: Duration) -> SessionCheck {
    for run in 1..=runs {
        if let Err(e) = one_session(exe, timeout) {
            return SessionCheck {
                passed: false,
                runs: run,
                detail: cap(format!("run {run} of {runs}: {e}")),
            };
        }
    }
    let unhappy = unhappy_sessions();
    let kinds: Vec<&str> = unhappy.iter().map(|u| u.kind).collect();
    for (i, u) in unhappy.iter().enumerate() {
        if let Err(e) = unhappy_session(exe, timeout, u) {
            return SessionCheck {
                passed: false,
                runs: runs + i as u32 + 1,
                detail: cap(format!("the session that must end in {}: {e}", u.kind)),
            };
        }
    }
    SessionCheck {
        passed: true,
        runs: runs + unhappy.len() as u32,
        detail: format!(
            "{runs} sessions returned the expected value and exited 0; {} ended as they must ({})",
            unhappy.len(),
            kinds.join(", ")
        ),
    }
}

fn cap(mut text: String) -> String {
    if text.len() > DETAIL_CAP {
        let mut end = DETAIL_CAP;
        while !text.is_char_boundary(end) {
            end -= 1;
        }
        text.truncate(end);
        text.push('…');
    }
    text
}

/// The runner's environment: empty, as the host starts it, except on Windows,
/// where the launcher passes these three on to the confined child.
fn command(exe: &Path) -> Command {
    let mut cmd = Command::new(exe);
    cmd.env_clear()
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    #[cfg(windows)]
    for name in ["SystemRoot", "SystemDrive", "windir"] {
        if let Some(value) = std::env::var_os(name) {
            cmd.env(name, value);
        }
    }
    cmd
}

enum Line {
    Frame(Value),
    Garbage(String),
    Closed,
}

/// A started runner: its stdin, its frames as they arrive, and its stderr.
struct Runner {
    child: Child,
    stdin: Option<ChildStdin>,
    frames: Receiver<Line>,
    stderr: Receiver<String>,
    timeout: Duration,
    deadline: Instant,
    /// The threads reading stdout and stderr. They own the pipe
    /// descriptors, and `Drop` joins them: on macOS the self-test closes
    /// every inherited descriptor right after the sessions, and a reader
    /// still running then would close a descriptor number that by then
    /// belongs to something else.
    readers: Vec<std::thread::JoinHandle<()>>,
}

impl Runner {
    fn start(exe: &Path, timeout: Duration) -> Result<Runner, String> {
        let mut child = command(exe).spawn().map_err(|e| format!("could not start the runner: {e}"))?;
        let stdout = child.stdout.take().ok_or("no stdout pipe")?;
        let mut stderr = child.stderr.take().ok_or("no stderr pipe")?;
        let (tx, frames) = mpsc::channel();
        let out_reader = std::thread::spawn(move || {
            let mut lines = BufReader::new(stdout);
            loop {
                let mut line = String::new();
                let item = match lines.read_line(&mut line) {
                    Ok(0) | Err(_) => Line::Closed,
                    Ok(_) => match serde_json::from_str::<Value>(&line) {
                        Ok(v) => Line::Frame(v),
                        Err(_) => Line::Garbage(line.trim_end().to_string()),
                    },
                };
                let closed = matches!(item, Line::Closed);
                if tx.send(item).is_err() || closed {
                    return;
                }
            }
        });
        let (etx, stderr_rx) = mpsc::channel();
        let err_reader = std::thread::spawn(move || {
            let mut text = String::new();
            let _ = stderr.read_to_string(&mut text);
            let _ = etx.send(text);
        });
        Ok(Runner {
            stdin: child.stdin.take(),
            child,
            frames,
            stderr: stderr_rx,
            timeout,
            deadline: Instant::now() + timeout,
            readers: vec![out_reader, err_reader],
        })
    }

    fn send(&mut self, frame: &Value) -> Result<(), String> {
        let mut line = serde_json::to_vec(frame).map_err(|e| e.to_string())?;
        line.push(b'\n');
        let stdin = self.stdin.as_mut().ok_or("stdin already closed")?;
        stdin
            .write_all(&line)
            .and_then(|()| stdin.flush())
            .map_err(|_| self.ended("the runner stopped reading"))
    }

    fn next(&mut self) -> Result<Value, String> {
        let left = self.deadline.saturating_duration_since(Instant::now());
        match self.frames.recv_timeout(left) {
            Ok(Line::Frame(v)) => Ok(v),
            Ok(Line::Garbage(text)) => Err(format!("the runner wrote a line that is not JSON: {}", cap(text))),
            Ok(Line::Closed) | Err(RecvTimeoutError::Disconnected) => Err(self.ended("stdout closed before done")),
            Err(RecvTimeoutError::Timeout) => Err(self.timed_out()),
        }
    }

    fn timed_out(&mut self) -> String {
        let _ = self.child.kill();
        let _ = self.child.wait();
        format!("no done within {} ms; killed", self.timeout.as_millis())
    }

    /// Why the runner ended early: waits for it (up to the deadline) and
    /// names how it exited, with the end of its stderr.
    fn ended(&mut self, what: &str) -> String {
        match self.wait() {
            Ok(status) => {
                let err = self.stderr_text();
                let err = if err.is_empty() { String::new() } else { format!("; stderr: {err}") };
                format!("{what}: {}{err}", describe(status))
            }
            Err(e) => format!("{what}: {e}"),
        }
    }

    fn wait(&mut self) -> Result<ExitStatus, String> {
        loop {
            match self.child.try_wait() {
                Ok(Some(status)) => return Ok(status),
                Ok(None) if Instant::now() >= self.deadline => return Err(self.timed_out()),
                Ok(None) => std::thread::sleep(Duration::from_millis(5)),
                Err(e) => return Err(format!("waiting for the runner: {e}")),
            }
        }
    }

    fn stderr_text(&self) -> String {
        let text = self.stderr.recv_timeout(Duration::from_millis(500)).unwrap_or_default();
        let text = text.trim();
        let start = text.len().saturating_sub(400);
        let start = (start..=text.len()).find(|i| text.is_char_boundary(*i)).unwrap_or(text.len());
        text[start..].to_string()
    }
}

impl Drop for Runner {
    fn drop(&mut self) {
        // A session that failed half-way must not leave a process behind.
        if let Ok(None) = self.child.try_wait() {
            let _ = self.child.kill();
            let _ = self.child.wait();
        }
        // The runner has exited (it starts no processes that could keep
        // the pipes open), so both readers reach end of file.
        self.stdin = None;
        for reader in self.readers.drain(..) {
            let _ = reader.join();
        }
    }
}

/// How a process ended, in words an operator can act on.
pub fn describe(status: ExitStatus) -> String {
    #[cfg(unix)]
    {
        use std::os::unix::process::ExitStatusExt;
        if let Some(signal) = status.signal() {
            let name = match signal {
                libc::SIGSYS => " (SIGSYS: a system call outside the seccomp allowlist)",
                libc::SIGKILL => " (SIGKILL)",
                libc::SIGSEGV => " (SIGSEGV)",
                libc::SIGABRT => " (SIGABRT)",
                libc::SIGXCPU => " (SIGXCPU: CPU time limit)",
                libc::SIGXFSZ => " (SIGXFSZ: wrote to a regular file)",
                _ => "",
            };
            return format!("killed by signal {signal}{name}");
        }
    }
    match status.code() {
        #[cfg(windows)]
        Some(code) if code < 0 => format!("exit code {:#010x}", code as u32),
        Some(code) => format!("exit code {code}"),
        None => "ended without an exit code".to_string(),
    }
}

/// One session that must end with `done` of kind `u.kind` and exit 0.
fn unhappy_session(exe: &Path, timeout: Duration, u: &Unhappy) -> Result<(), String> {
    let mut r = Runner::start(exe, timeout)?;
    let ready = r.next()?;
    if ready["type"] != "ready" || ready["lockdown"]["level"] != "full" {
        return Err(format!("not ready at level full: {}", cap(ready.to_string())));
    }
    r.send(&init_with(u.limits.clone()))?;
    r.send(&json!({"type": "exec", "code": u.script}))?;
    let mut cancelled = false;
    let done = loop {
        let frame = r.next()?;
        match frame["type"].as_str() {
            Some("output") => {
                if u.cancel_on_output && !cancelled {
                    r.send(&json!({"type": "cancel"}))?;
                    cancelled = true;
                }
            }
            Some("done") => break frame,
            _ => return Err(format!("unexpected frame: {}", cap(frame.to_string()))),
        }
    };
    if done["ok"] != false || done["error"]["kind"] != u.kind {
        return Err(format!("ended with {}", cap(done.to_string())));
    }
    (u.check)(&done["error"])?;
    r.stdin = None;
    let status = r.wait()?;
    if !status.success() {
        return Err(format!("after done: {}", describe(status)));
    }
    Ok(())
}

/// One canned session. `Ok` only for `ready` at level full, the expected
/// calls, output and store frames, `done` with the expected value, and exit
/// code 0.
fn one_session(exe: &Path, timeout: Duration) -> Result<(), String> {
    let mut r = Runner::start(exe, timeout)?;
    let ready = r.next()?;
    if ready["type"] != "ready" {
        return Err(format!("first frame is not ready: {}", cap(ready.to_string())));
    }
    let level = &ready["lockdown"]["level"];
    if level != "full" {
        return Err(format!(
            "ready reported lockdown level {level} (failed: {})",
            ready["lockdown"]["failed"]
        ));
    }
    r.send(&init_frame())?;
    r.send(&json!({"type": "exec", "code": SCRIPT}))?;
    let (mut texts, mut stores) = (Vec::new(), Vec::new());
    let done = loop {
        let frame = r.next()?;
        match frame["type"].as_str() {
            Some("call") => {
                let payload = match (frame["target"].as_str(), frame["name"].as_str()) {
                    (Some("tool"), Some(TOOL_NAME)) => {
                        json!({"value": frame["args"]["n"].as_i64().unwrap_or(0) * 2})
                    }
                    (Some("host"), Some("searchTools")) => json!([catalog_entry()]),
                    _ => return Err(format!("unexpected call: {}", cap(frame.to_string()))),
                };
                r.send(&json!({"type": "result", "id": frame["id"], "ok": true, "payload": payload}))?;
            }
            Some("output") => texts.push(frame["text"].clone()),
            Some("store") => stores.push(frame),
            Some("done") => break frame,
            _ => return Err(format!("unexpected frame: {}", cap(frame.to_string()))),
        }
    };
    if done["ok"] != true {
        return Err(format!("the script failed: {}", cap(done["error"].to_string())));
    }
    if done["value"] != expected_value() {
        return Err(format!("unexpected value: {}", cap(done["value"].to_string())));
    }
    if texts != [json!("selftest")] {
        return Err(format!("unexpected output: {texts:?}"));
    }
    if stores != [json!({"type": "store", "key": "selftest", "value": {"saved": true}})] {
        return Err(format!("unexpected store frames: {stores:?}"));
    }
    r.stdin = None;
    let status = r.wait()?;
    if !status.success() {
        return Err(format!("after done: {}", describe(status)));
    }
    Ok(())
}

#[cfg(all(test, unix))]
pub(crate) mod tests {
    use super::*;
    use std::os::unix::fs::PermissionsExt;
    use std::path::PathBuf;
    use std::sync::OnceLock;

    const READY_FULL: &str = r#"{"type":"ready","protocol":1,"lockdown":{"level":"full","failed":[]}}"#;

    /// Shell scripts standing in for the runner, by name. All of them are
    /// written once, before any test starts one: a script written while
    /// another test's spawn is between fork and exec can inherit our write
    /// descriptor, and exec then fails with "text file busy".
    pub(crate) fn fake(name: &str) -> PathBuf {
        static DIR: OnceLock<PathBuf> = OnceLock::new();
        let dir = DIR.get_or_init(|| {
            let dir = std::env::temp_dir().join(format!("cc_codemode_selfcheck_{}", std::process::id()));
            std::fs::create_dir_all(&dir).unwrap();
            let scripts = [
                ("sigsys", format!("printf '%s\\n' '{READY_FULL}'\nread -r init\nkill -s SYS $$")),
                (
                    "partial",
                    r#"printf '%s\n' '{"type":"ready","lockdown":{"level":"partial","failed":["seccomp"]}}'; exit 3"#
                        .to_string(),
                ),
                (
                    "wrong",
                    format!(
                        "printf '%s\\n' '{READY_FULL}'\nread -r init\nread -r exec\nprintf '%s\\n' '{{\"type\":\"done\",\"ok\":true,\"value\":1}}'"
                    ),
                ),
                ("hang", format!("printf '%s\\n' '{READY_FULL}'\nexec sleep 30")),
                ("garbage", "echo 'not json'".to_string()),
            ];
            for (name, body) in scripts {
                let path = dir.join(name);
                std::fs::write(&path, format!("#!/bin/sh\n{body}\n")).unwrap();
                std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o755)).unwrap();
            }
            dir
        });
        dir.join(name)
    }

    fn failed(check: &SessionCheck) -> &str {
        assert!(!check.passed, "{check:?}");
        &check.detail
    }

    #[test]
    fn a_runner_killed_by_seccomp_fails_and_names_the_signal() {
        let exe = fake("sigsys");
        let c = check_with(&exe, 8, Duration::from_secs(10));
        let detail = failed(&c);
        assert_eq!(c.runs, 1);
        assert!(detail.starts_with("run 1 of 8: "), "{detail}");
        assert!(detail.contains(&format!("killed by signal {}", libc::SIGSYS)), "{detail}");
        assert!(detail.contains("SIGSYS"), "{detail}");
    }

    #[test]
    fn a_partial_lockdown_fails() {
        let exe = fake("partial");
        let detail = failed(&check_with(&exe, 1, Duration::from_secs(10))).to_string();
        assert!(detail.contains("\"partial\"") && detail.contains("seccomp"), "{detail}");
    }

    #[test]
    fn a_wrong_value_fails() {
        let exe = fake("wrong");
        let detail = failed(&check_with(&exe, 1, Duration::from_secs(10))).to_string();
        assert!(detail.contains("unexpected value: 1"), "{detail}");
    }

    #[test]
    fn a_hung_runner_is_killed_at_the_deadline() {
        let exe = fake("hang");
        let started = Instant::now();
        let detail = failed(&check_with(&exe, 1, Duration::from_millis(500))).to_string();
        assert!(detail.contains("no done within"), "{detail}");
        assert!(started.elapsed() < Duration::from_secs(10));
    }

    #[test]
    fn garbage_on_stdout_fails() {
        let exe = fake("garbage");
        let detail = failed(&check_with(&exe, 1, Duration::from_secs(10))).to_string();
        assert!(detail.contains("not JSON"), "{detail}");
    }

    #[test]
    fn long_details_are_capped() {
        let text = cap("é".repeat(2000));
        assert!(text.len() <= DETAIL_CAP + '…'.len_utf8());
    }
}

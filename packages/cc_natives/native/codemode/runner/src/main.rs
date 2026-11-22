//! cc_codemode: runs one model-written JavaScript script in QuickJS-NG.
//!
//! Start-up order, failing closed at every step:
//! 1. close inherited descriptors above 2;
//! 2. apply the thread-scoped lockdown, then start the stdin reader thread;
//! 3. apply the process-wide lockdown;
//! 4. create the runtime (heap limit, stack limit, interrupt handler);
//! 5. evaluate the embedded prelude;
//! 6. send `ready`;
//! 7. read `init`, then exactly one `exec`, run it and send `done`.
//!
//! If the lockdown is not `full`, the runner sends `ready` with the real
//! level and what failed, and exits without reading a script.
//! README.md documents the wire protocol and exit codes.

mod alloc;
mod cputime;
mod engine;
mod hostjson;
mod io;
mod protocol;
mod selfcheck;
mod site;
mod watchdog;

use std::sync::atomic::AtomicBool;
use std::sync::Arc;

use lockdown::{Level, LockdownReport};

// Exit codes: 0 = `done` written (whatever the script's outcome); 1 = the
// host broke the protocol and `done` with kind `internal` was written
// (engine::Finish); 5 = stdin closed before `done` (io).
/// Bad command line.
const EXIT_USAGE: i32 = 2;
/// Lockdown is not `full`; `ready` says why. No script was read.
const EXIT_LOCKDOWN: i32 = 3;
/// The runtime or prelude could not be set up, or the runner failed
/// internally (a panic); `ready` or `done` may be missing. One line on
/// stderr says what happened.
const EXIT_INTERNAL: i32 = 4;

/// Longest panic line written to stderr.
const PANIC_LINE_BYTES: usize = 1024;

/// A fixed buffer that keeps one line: newlines become spaces and the rest
/// is cut at the capacity. Formatting a panic into it allocates nothing, so
/// the hook works when the panic came from running out of memory.
struct OneLine {
    buf: [u8; PANIC_LINE_BYTES],
    len: usize,
}

impl std::fmt::Write for OneLine {
    fn write_str(&mut self, s: &str) -> std::fmt::Result {
        for b in s.bytes() {
            if self.len == self.buf.len() - 1 {
                break;
            }
            self.buf[self.len] = if b == b'\n' || b == b'\r' { b' ' } else { b };
            self.len += 1;
        }
        Ok(())
    }
}

/// A panic ends the runner with one line on stderr and exit code 4, never
/// with `abort()`. On Linux an abort is SIGABRT (now permitted for this
/// process only), but a panic is the runner's own fault, and the host and
/// an operator must be able to tell it apart from a kernel kill: SIGSYS
/// means a system call outside the allowlist, exit 4 means an internal
/// error. Writing to stderr and exiting are both on every allowlist.
fn install_panic_hook() {
    std::panic::set_hook(Box::new(|info| {
        use std::fmt::Write;
        let mut line = OneLine {
            buf: [0; PANIC_LINE_BYTES],
            len: 0,
        };
        let _ = write!(line, "cc_codemode: internal error: {info}");
        line.buf[line.len] = b'\n';
        io::write_stderr_raw(&line.buf[..line.len + 1]);
        io::exit_now(EXIT_INTERNAL);
    }));
}

fn main() {
    install_panic_hook();
    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(String::as_str) {
        None => {}
        Some("--version") if args.len() == 2 => {
            println!(
                "cc_codemode {} {} protocol {}",
                env!("CARGO_PKG_VERSION"),
                engine::ENGINE,
                protocol::PROTOCOL_VERSION
            );
            return;
        }
        Some("--self-test") => {
            std::process::exit(lockdown::selftest::run(&args, &selfcheck::check))
        }
        #[cfg(windows)]
        Some(lockdown::windows::CONTAINED_FLAG) => match args.get(2).map(String::as_str) {
            None => {}
            Some("--self-test") => {
                std::process::exit(lockdown::windows::selftest_child(&args[3..]))
            }
            Some(lockdown::windows::SIBLING_FLAG) if args.len() == 3 => lockdown::windows::sibling_child(),
            Some(_) => usage(),
        },
        // The installer's step: one line, exit 0 or 1. Not a flag elsewhere.
        #[cfg(windows)]
        Some(lockdown::windows::GRANT_ACCESS_FLAG) if args.len() == 2 => {
            std::process::exit(lockdown::windows::grant_runner_access())
        }
        Some(_) => usage(),
    }

    // Windows: the process the host started is only a launcher. It runs this
    // same executable inside an AppContainer and job, passes its stdio
    // handles down, waits, and exits with the child's code.
    #[cfg(windows)]
    if !lockdown::windows::is_contained_child(&args) {
        std::process::exit(lockdown::windows::launch_contained(&[], &|report| {
            io::write_frame(&protocol::ready_frame(
                engine::ENGINE,
                env!("CARGO_PKG_VERSION"),
                &report.to_json(),
            ));
        }));
    }

    std::process::exit(run());
}

fn usage() -> ! {
    #[cfg(windows)]
    eprintln!("usage: cc_codemode [--version | --self-test | {}]", lockdown::windows::GRANT_ACCESS_FLAG);
    #[cfg(not(windows))]
    eprintln!("usage: cc_codemode [--version | --self-test]");
    std::process::exit(EXIT_USAGE);
}

/// Steps 1 to 3: the lockdown, with the reader and watchdog threads started
/// between its two halves.
fn lock_down() -> (LockdownReport, std::sync::mpsc::Receiver<io::Event>, Arc<engine::Shared>) {
    let mut report = LockdownReport::new();
    lockdown::close_inherited_descriptors(&mut report);
    lockdown::prepare_allocator_for_threads();
    lockdown::apply_thread_scoped(&mut report);
    let cancel = Arc::new(AtomicBool::new(false));
    let shared = engine::Shared::new(cancel.clone());
    // Both threads are started after the thread-scoped controls, so they
    // inherit them, and before the process-wide ones, which then cover them
    // too. They are the last threads the runner creates: on Linux the filter
    // denies clone and clone3, and must keep doing so while the allowlist
    // admits only the `madvise` advice in linux::MADVISE_ADVICE. Recent
    // glibc may install a thread stack's guard with MADV_GUARD_INSTALL (102)
    // when it creates a thread; doing that after the filter would be SIGSYS
    // on those distributions. `threads_stay_at_three` (tests/protocol.rs)
    // pins the count.
    let rx = io::spawn_reader(cancel);
    watchdog::spawn(shared.clone());
    lockdown::apply_process_wide(&mut report);
    (report, rx, shared)
}

fn run() -> i32 {
    let (report, rx, shared) = lock_down();

    let lockdown_json = report.to_json();
    if report.level() != Level::Full {
        io::write_frame(&protocol::ready_frame(
            engine::ENGINE,
            env!("CARGO_PKG_VERSION"),
            &lockdown_json,
        ));
        return EXIT_LOCKDOWN;
    }

    let (_rt, ctx) = match engine::new_runtime(&shared) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("cc_codemode: {e}");
            return EXIT_INTERNAL;
        }
    };
    let code = ctx.with(|ctx| {
        let session = match engine::Session::new(ctx, shared) {
            Ok(s) => s,
            Err(e) => {
                eprintln!("cc_codemode: prelude: {e}");
                return EXIT_INTERNAL;
            }
        };
        io::write_frame(&protocol::ready_frame(
            engine::ENGINE,
            env!("CARGO_PKG_VERSION"),
            &lockdown_json,
        ));
        session.run(&rx).exit_code()
    });
    // `done` is written and flushed. Exit without tearing down the
    // interpreter: freeing a large heap only delays the exit.
    io::exit_now(code)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fmt::Write;

    /// A file mapping one page longer than its file: reading it faults with
    /// SIGBUS. Set up before the lockdown, which allows neither `open` nor a
    /// file mapping; the file is gone before the lockdown starts.
    #[cfg(unix)]
    fn past_end_of_file() -> *const u8 {
        let path = std::env::temp_dir().join(format!("cc_codemode_bus_{}", std::process::id()));
        let file =
            std::fs::OpenOptions::new().read(true).write(true).create_new(true).open(&path).unwrap();
        file.set_len(4096).unwrap();
        use std::os::fd::AsRawFd;
        // SAFETY: maps one page of a file we own, read-only.
        let p = unsafe { libc::mmap(std::ptr::null_mut(), 4096, libc::PROT_READ, libc::MAP_SHARED, file.as_raw_fd(), 0) };
        assert_ne!(p, libc::MAP_FAILED);
        file.set_len(0).unwrap();
        std::fs::remove_file(&path).unwrap();
        p as *const u8
    }

    /// The child of `faults_and_panics_after_the_lockdown`: the runner's
    /// panic hook and lockdown, exactly as `run` applies them, then one fault
    /// or panic. Runs only when that test starts it.
    #[cfg(unix)]
    #[test]
    #[ignore = "started by faults_and_panics_after_the_lockdown"]
    fn crash_child() {
        let Ok(kind) = std::env::var("CC_CODEMODE_CRASH") else { return };
        install_panic_hook();
        let bus = past_end_of_file();
        let (report, _rx, _shared) = lock_down();
        if report.level() != Level::Full {
            io::write_stderr_raw(b"lockdown not full\n");
            io::exit_now(90);
        }
        io::write_stderr_raw(b"lockdown full\n");
        match kind.as_str() {
            // SAFETY: none; the point is the fault. Address 16 is in the
            // unmapped first page on both systems.
            "segv" => unsafe { std::ptr::write_volatile(std::hint::black_box(16usize) as *mut u8, 1) },
            // SAFETY: as above; the page lies past the end of its file.
            "bus" => unsafe { std::ptr::read_volatile(std::hint::black_box(bus)); },
            "panic" => panic!("after the lockdown"),
            _ => {}
        }
        io::exit_now(91);
    }

    /// What the host sees when the runner faults or panics once it is locked
    /// down (README, Exit codes). Each case runs `crash_child` in a fresh
    /// copy of this test binary; stdin stays open so the reader thread does
    /// not end the process first.
    #[cfg(unix)]
    #[test]
    fn faults_and_panics_after_the_lockdown() {
        use std::io::Read;
        use std::os::unix::process::ExitStatusExt;
        use std::process::{Command, Stdio};
        // The self-check tests write their scripts once; a spawn here while
        // they are being written could carry the write descriptor across
        // fork and make their exec fail with "text file busy".
        let _ = crate::selfcheck::tests::fake("hang");
        for kind in ["segv", "bus", "panic"] {
            let mut child = Command::new(std::env::current_exe().unwrap())
                .args(["--exact", "tests::crash_child", "--ignored", "--nocapture", "--test-threads=1"])
                .env("CC_CODEMODE_CRASH", kind)
                .stdin(Stdio::piped())
                .stdout(Stdio::null())
                .stderr(Stdio::piped())
                .spawn()
                .unwrap();
            let stdin = child.stdin.take();
            let mut err = String::new();
            child.stderr.take().unwrap().read_to_string(&mut err).unwrap();
            let status = child.wait().unwrap();
            drop(stdin);
            assert!(err.starts_with("lockdown full\n"), "{kind}: {status}: {err}");
            match kind {
                // The kernel's default action, once std's handler has put it
                // back: the signal itself, on both systems.
                "segv" => assert_eq!(status.signal(), Some(libc::SIGSEGV), "{status}: {err}"),
                "bus" => assert_eq!(status.signal(), Some(libc::SIGBUS), "{status}: {err}"),
                // The hook's line and exit 4.
                _ => {
                    assert_eq!(status.code(), Some(EXIT_INTERNAL), "{status}: {err}");
                    assert!(err.ends_with("cc_codemode: internal error: panicked at runner/src/main.rs:")
                        || err.contains("\ncc_codemode: internal error: panicked at "), "{err}");
                    assert!(err.trim_end().ends_with(": after the lockdown"), "{err}");
                }
            }
        }
    }

    #[test]
    fn panic_line_is_one_bounded_line() {
        let mut line = OneLine {
            buf: [0; PANIC_LINE_BYTES],
            len: 0,
        };
        let _ = write!(line, "first\nsecond\r{}", "x".repeat(5000));
        let text = std::str::from_utf8(&line.buf[..line.len]).unwrap();
        assert!(text.starts_with("first second x"));
        assert!(!text.contains('\n') && !text.contains('\r'));
        // One byte stays free for the newline the hook appends.
        assert_eq!(line.len, PANIC_LINE_BYTES - 1);
    }
}

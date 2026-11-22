//! Stdio. One reader thread turns stdin lines into [`Event`]s; the
//! interpreter thread writes frames to stdout.
//!
//! The reader thread is started after the thread-scoped lockdown and before
//! the process-wide one. It sets the shared cancel flag itself when a
//! `cancel` frame arrives, so a script stuck in a loop is interrupted without
//! waiting for the interpreter thread to read the queue. When stdin closes
//! the host has gone away, and the reader ends the whole process at once.

use std::io::{Read, Write};
use std::sync::atomic::{AtomicBool, AtomicI32, Ordering};
use std::sync::mpsc::{self, Receiver, Sender};
use std::sync::Arc;

use crate::protocol::{parse_host_frame, HostFrame, MAX_FRAME_BYTES};

/// Exit code when stdin closes before `done` was written.
pub const EXIT_STDIN_CLOSED: i32 = 5;

/// Exit code the reader uses when stdin closes. Becomes the session's own
/// exit code once `done` is written, so a host that closes stdin right after
/// reading `done` sees the same code either way.
static EOF_EXIT_CODE: AtomicI32 = AtomicI32::new(EXIT_STDIN_CLOSED);

/// Records the exit code to use if stdin closes from now on.
pub fn set_eof_exit_code(code: i32) {
    EOF_EXIT_CODE.store(code, Ordering::SeqCst);
}

/// Something the reader thread saw.
#[derive(Debug)]
pub enum Event {
    Frame(HostFrame),
    /// The host broke the protocol; the text says how.
    Violation(String),
}

/// Starts the reader. Returns once the thread has made its first heap
/// allocation, so no allocator setup happens after the process-wide
/// lockdown.
pub fn spawn_reader(cancel: Arc<AtomicBool>) -> Receiver<Event> {
    let (tx, rx) = mpsc::channel();
    let (started_tx, started_rx) = mpsc::channel::<()>();
    std::thread::Builder::new()
        .name("stdin".into())
        .spawn(move || {
            let buf: Vec<u8> = Vec::with_capacity(64 * 1024);
            let _ = started_tx.send(());
            reader_loop(buf, tx, cancel)
        })
        .expect("spawn stdin reader");
    let _ = started_rx.recv();
    rx
}

/// Ends the process at once.
pub fn exit_now(code: i32) -> ! {
    // SAFETY: _exit ends the process without running destructors or atexit
    // handlers, which is what we want while the other thread may be inside
    // the interpreter.
    unsafe { libc::_exit(code) }
}

fn reader_loop(mut line: Vec<u8>, tx: Sender<Event>, cancel: Arc<AtomicBool>) -> ! {
    let stdin = std::io::stdin();
    let mut input = stdin.lock();
    let mut chunk = vec![0u8; 64 * 1024];
    let mut too_long = false;
    loop {
        let n = match input.read(&mut chunk) {
            Ok(0) => exit_now(EOF_EXIT_CODE.load(Ordering::SeqCst)),
            Ok(n) => n,
            Err(e) if e.kind() == std::io::ErrorKind::Interrupted => continue,
            Err(_) => exit_now(EOF_EXIT_CODE.load(Ordering::SeqCst)),
        };
        let mut rest = &chunk[..n];
        while let Some(pos) = rest.iter().position(|b| *b == b'\n') {
            if !too_long {
                line.extend_from_slice(&rest[..pos]);
            }
            rest = &rest[pos + 1..];
            let event = if too_long || line.len() > MAX_FRAME_BYTES {
                Event::Violation(format!("frame exceeds {MAX_FRAME_BYTES} bytes"))
            } else {
                match std::str::from_utf8(&line) {
                    Err(_) => Event::Violation("frame is not UTF-8".into()),
                    Ok(text) => match parse_host_frame(text.trim_end_matches('\r')) {
                        Ok(frame) => Event::Frame(frame),
                        Err(e) => Event::Violation(e),
                    },
                }
            };
            line.clear();
            too_long = false;
            if matches!(event, Event::Frame(HostFrame::Cancel)) {
                cancel.store(true, Ordering::SeqCst);
            }
            let fatal = matches!(event, Event::Violation(_));
            if tx.send(event).is_err() {
                exit_now(0);
            }
            if fatal {
                // Nothing after a violation is trusted; stop reading and let
                // the interpreter thread report and exit.
                loop {
                    std::thread::park();
                }
            }
        }
        if !too_long {
            if line.len() + rest.len() > MAX_FRAME_BYTES {
                too_long = true;
                line.clear();
                // Release the oversized buffer's memory.
                line.shrink_to(64 * 1024);
            } else {
                line.extend_from_slice(rest);
            }
        }
    }
}

/// Writes bytes to stderr with one system call per attempt and no
/// allocation, for the panic hook.
pub fn write_stderr_raw(bytes: &[u8]) {
    #[cfg(unix)]
    {
        let mut off = 0;
        while off < bytes.len() {
            // SAFETY: the slice is valid for its length.
            let n = unsafe { libc::write(2, bytes[off..].as_ptr().cast(), bytes.len() - off) };
            if n <= 0 {
                return;
            }
            off += n as usize;
        }
    }
    #[cfg(windows)]
    {
        let _ = std::io::stderr().write_all(bytes);
    }
}

/// Set by whichever thread writes `done` first: the interpreter thread, or
/// the watchdog when the interpreter overran.
static DONE_WRITTEN: AtomicBool = AtomicBool::new(false);

/// Writes `done`. The exit code is recorded first, so a host that closes
/// stdin as soon as it reads `done` still sees this code.
pub fn write_done(frame: &str, exit_code: i32) {
    let stdout = std::io::stdout();
    let mut out = stdout.lock();
    // The watchdog ends the process while it holds stdout, so once this
    // thread holds it no `done` has been written.
    if DONE_WRITTEN.swap(true, Ordering::SeqCst) {
        return;
    }
    set_eof_exit_code(exit_code);
    write_locked(&mut out, frame);
}

/// For the watchdog: writes `done` unless the interpreter thread already
/// did, then ends the process without letting go of stdout, so no frame of
/// the interpreter's can follow it. Returns only if `done` was already
/// written.
pub fn write_done_and_exit(frame: &str, exit_code: i32) {
    let stdout = std::io::stdout();
    let mut out = stdout.lock();
    if DONE_WRITTEN.swap(true, Ordering::SeqCst) {
        return;
    }
    set_eof_exit_code(exit_code);
    write_locked(&mut out, frame);
    exit_now(exit_code)
}

/// Writes one frame and a newline, then flushes. A write error means the
/// host is gone.
pub fn write_frame(frame: &str) {
    let stdout = std::io::stdout();
    let mut out = stdout.lock();
    write_locked(&mut out, frame);
}

fn write_locked(out: &mut std::io::StdoutLock<'_>, frame: &str) {
    debug_assert!(!frame.contains('\n'));
    let ok = out.write_all(frame.as_bytes()).is_ok()
        && out.write_all(b"\n").is_ok()
        && out.flush().is_ok();
    if !ok {
        exit_now(EXIT_STDIN_CLOSED);
    }
}

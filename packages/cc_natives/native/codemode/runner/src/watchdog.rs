//! The backstop for the CPU budget and `cancel`.
//!
//! The interpreter checks both itself, but only when QuickJS polls its
//! interrupt handler, which it does every few thousand interpreter steps. A
//! loop whose every step is one long native call (`'x'.repeat(1e8)`, a
//! typed-array `fill` or `includes` over hundreds of megabytes) reaches that
//! poll seconds or minutes apart. The watchdog thread looks at the process's
//! CPU time and the cancel flag every [`TICK`]; when the interpreter has not
//! ended the script on its own [`CPU_GRACE_NS`] after the budget ran out, or
//! [`CANCEL_GRACE`] after a `cancel`, it writes `done` itself and ends the
//! process. The `done` names the ending the interpreter would have named
//! ([`Shared::stop_reason`]): a script whose heap ran out before its CPU
//! budget did is `memory_exceeded`, even when the watchdog ends it, and a
//! script that called `exit()` but then stayed in native code is
//! `cpu_exceeded` or `cancelled`, never a success.
//!
//! The thread is started before the process-wide lockdown, like the stdin
//! reader, and needs nothing the lockdown denies: a timed wait and the
//! process CPU clock.

use std::sync::atomic::Ordering;
use std::sync::Arc;
use std::time::{Duration, Instant};

use crate::cputime::process_cpu_ns;
use crate::engine::{Abort, Shared};
use crate::io::write_done_and_exit;
use crate::protocol::{done_frame, ErrorKind, ScriptError, Stats};

/// How often the watchdog looks.
const TICK: Duration = Duration::from_millis(50);

/// Process CPU time past the budget the interpreter gets to stop on its own
/// (it needs up to 0.2 s of its own to describe the error).
pub const CPU_GRACE_NS: u64 = 500_000_000;

/// Wall time after a `cancel` the interpreter gets to stop on its own.
const CANCEL_GRACE: Duration = Duration::from_millis(250);

/// Starts the watchdog thread. Returns once the thread has made its first
/// heap allocation, so no allocator setup happens after the process-wide
/// lockdown (as for the stdin reader).
pub fn spawn(shared: Arc<Shared>) {
    let (started_tx, started_rx) = std::sync::mpsc::channel::<()>();
    std::thread::Builder::new()
        .name("watchdog".into())
        .spawn(move || {
            let first: Vec<u8> = Vec::with_capacity(4096);
            let _ = started_tx.send(());
            drop(first);
            watch(&shared)
        })
        .expect("spawn watchdog");
    let _ = started_rx.recv();
}

fn watch(shared: &Shared) {
    let mut cancel_seen: Option<Instant> = None;
    loop {
        std::thread::park_timeout(TICK);
        if cancel_seen.is_none() && shared.cancel.load(Ordering::SeqCst) {
            cancel_seen = Some(Instant::now());
        }
        let deadline = shared.watchdog_deadline_ns.load(Ordering::SeqCst);
        let overran = deadline != 0 && process_cpu_ns() >= deadline;
        let ignored_cancel = cancel_seen.is_some_and(|t| t.elapsed() >= CANCEL_GRACE);
        if !overran && !ignored_cancel {
            continue;
        }
        let error = |kind, name: &str, message: String| ScriptError {
            kind,
            name: name.into(),
            message,
            stack: String::new(),
            line: None,
            column: None,
        };
        let error = match shared.stop_reason() {
            // `stop_reason` never returns `Exit` or `None` (the script's own
            // endings): the watchdog fires only after the budget ran out or
            // a cancel was ignored.
            Abort::Exit | Abort::None | Abort::Cpu => Some(error(
                ErrorKind::CpuExceeded,
                "CpuLimitExceeded",
                format!(
                    "The script used more than its {} ms CPU budget",
                    shared.cpu_budget_ms.load(Ordering::SeqCst)
                ),
            )),
            Abort::Cancelled => Some(error(ErrorKind::Cancelled, "Cancelled", "The script was cancelled".into())),
            Abort::Memory => Some(error(
                ErrorKind::MemoryExceeded,
                "MemoryLimitExceeded",
                format!(
                    "The script exceeded its heap limit of {} bytes",
                    shared.heap_budget_bytes.load(Ordering::SeqCst)
                ),
            )),
            Abort::Output => Some(error(
                ErrorKind::OutputExceeded,
                "OutputLimitExceeded",
                shared.output_message.lock().unwrap_or_else(|e| e.into_inner()).clone(),
            )),
        };
        let started = shared.exec_process_cpu_ns.load(Ordering::SeqCst);
        let stats = Stats {
            cpu_ms: process_cpu_ns().saturating_sub(started) / 1_000_000,
            peak_heap_bytes: shared.heap.peak() as u64,
            calls: shared.calls.load(Ordering::SeqCst),
            output_chars: shared.output_chars.load(Ordering::SeqCst),
            output_items: shared.output_items.load(Ordering::SeqCst),
        };
        // Exit code 0, as for every `done` the interpreter writes itself.
        write_done_and_exit(&done_frame(None, error.as_ref(), stats), 0);
        // The interpreter wrote `done` first and the process is ending.
        return;
    }
}

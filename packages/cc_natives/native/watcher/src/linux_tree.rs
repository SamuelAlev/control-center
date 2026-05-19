//! Linux-only: the ignore-aware watch-install walk.
//!
//! inotify has no recursive mode, so every directory needs its own watch —
//! which is exactly the opportunity to SKIP ignored subtrees (`node_modules`,
//! `build`, …) instead of scanning them the way `package:watcher` must.
//!
//! Walk order is watch-then-read, breadth-first:
//!  * watch-then-read is gap-free — a child created mid-walk is caught by
//!    either the parent's already-installed watch or the walk itself;
//!  * breadth-first means a `max_watches` budget truncates the DEEP tail
//!    (build trees), never the shallow source dirs people actually edit.
//! Hitting the budget (or ENOSPC) sets DEGRADED plus a one-shot RESCAN and
//! keeps the partial coverage — it never tears the watch down.

#![cfg(target_os = "linux")]

use std::collections::VecDeque;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{Receiver, RecvTimeoutError};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use notify::{RecommendedWatcher, RecursiveMode, Watcher};

use crate::queue::{FLAG_DEGRADED, FLAG_RESCAN};
use crate::watcher::WatchContext;

/// Runs on the walker thread: installs the initial tree, then serves
/// new-directory jobs until `shutdown` flips.
pub fn walker_main(
    ctx: Arc<WatchContext>,
    watcher: Arc<Mutex<RecommendedWatcher>>,
    jobs: Receiver<PathBuf>,
    root: PathBuf,
    max_watches: u32,
    shutdown: Arc<AtomicBool>,
) {
    install_subtree(&ctx, &watcher, root, max_watches, &shutdown);
    loop {
        match jobs.recv_timeout(Duration::from_millis(200)) {
            Ok(dir) => install_subtree(&ctx, &watcher, dir, max_watches, &shutdown),
            Err(RecvTimeoutError::Timeout) => {
                if shutdown.load(Ordering::Relaxed) {
                    return;
                }
            }
            Err(RecvTimeoutError::Disconnected) => return,
        }
    }
}

fn install_subtree(
    ctx: &WatchContext,
    watcher: &Mutex<RecommendedWatcher>,
    start: PathBuf,
    max_watches: u32,
    shutdown: &AtomicBool,
) {
    let budget = if max_watches == 0 {
        u32::MAX
    } else {
        max_watches
    };
    let mut pending = VecDeque::from([start]);
    while let Some(dir) = pending.pop_front() {
        if shutdown.load(Ordering::Relaxed) {
            return;
        }
        if let Some(name) = dir.file_name().and_then(|n| n.to_str()) {
            if ctx.ignore.is_ignored_name(name) {
                continue;
            }
        }
        if ctx.queue.watch_count.load(Ordering::Relaxed) >= budget {
            ctx.queue.set_flags(FLAG_DEGRADED | FLAG_RESCAN);
            return;
        }
        // WATCH before READ: gap-free for children created mid-walk.
        {
            let mut guard = watcher.lock().unwrap();
            if guard.watch(&dir, RecursiveMode::NonRecursive).is_err() {
                // ENOSPC / vanished dir: partial coverage, signalled, keep
                // going — the rest of the tree still deserves watches.
                ctx.queue.set_flags(FLAG_DEGRADED | FLAG_RESCAN);
                continue;
            }
        }
        ctx.queue.watch_count.fetch_add(1, Ordering::Relaxed);
        let entries = match std::fs::read_dir(&dir) {
            Ok(entries) => entries,
            Err(_) => continue,
        };
        for entry in entries.flatten() {
            let is_dir = entry
                .file_type()
                .map(|t| t.is_dir() && !t.is_symlink())
                .unwrap_or(false);
            if is_dir {
                pending.push_back(entry.path());
            }
        }
    }
}

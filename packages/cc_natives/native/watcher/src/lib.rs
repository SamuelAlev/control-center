//! cc_watcher — Control Center's native recursive file watcher.
//!
//! FIRST-PARTY source (not vendored): the C ABI in `cc_watcher.h` is consumed
//! by `packages/cc_natives/lib/src/watch/` over `dart:ffi`. Built by
//! `scripts/natives/build_watcher.sh`; a missing dylib degrades the consumer
//! to `package:watcher`, never breaks it.
//!
//! Per-OS backends (all via the `notify` crate):
//!  * macOS — FSEvents, kernel-recursive: NO walk at any point; the ignore
//!    rules are pure event filtering.
//!  * Windows — ReadDirectoryChangesW, kernel-recursive: same, no walk.
//!  * Linux — inotify is per-directory, so an ignore-aware breadth-first walk
//!    installs watches on the library's OWN thread (`linux_tree.rs`) — never
//!    the caller's; that is what lets `node_modules`/`build` be skipped
//!    entirely instead of scanned.
//!
//! Every extern "C" body is wrapped in `catch_unwind`: a panic becomes a
//! NULL/0 return plus `cc_watch_last_error`, never an unwind across FFI.

mod ignore;
mod queue;
mod watcher;
#[cfg(target_os = "linux")]
mod linux_tree;

use std::cell::RefCell;
use std::ffi::{c_char, CStr, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

use notify::RecommendedWatcher;
// Only the kernel-recursive backends install their watch here; on Linux the
// per-directory `watch()` calls (and therefore the `Watcher` trait) live in
// `linux_tree.rs`, so importing them here would be an unused-import warning.
#[cfg(not(target_os = "linux"))]
use notify::{RecursiveMode, Watcher};

use crate::ignore::IgnoreSet;
use crate::queue::{Queue, FLAG_ROOT_GONE};
use crate::watcher::WatchContext;

pub const ABI_VERSION: u32 = 1;

thread_local! {
    static LAST_ERROR: RefCell<Option<CString>> = const { RefCell::new(None) };
}

fn set_last_error(message: String) {
    LAST_ERROR.with(|slot| {
        *slot.borrow_mut() =
            Some(CString::new(message).unwrap_or_else(|_| {
                CString::new("error message contained NUL").unwrap()
            }));
    });
}

/// Mirror of `CcWatchDrain` in cc_watcher.h.
#[repr(C)]
pub struct CcWatchDrain {
    pub buf: *const u8,
    pub len: usize,
    pub flags: u32,
    pub dropped: u32,
    pub watch_count: u32,
}

pub struct CcWatch {
    ctx: Arc<WatchContext>,
    /// Kept for the whole handle lifetime; dropping stops notify's threads.
    watcher: Option<Arc<Mutex<RecommendedWatcher>>>,
    #[cfg(target_os = "linux")]
    walker: Option<std::thread::JoinHandle<()>>,
    shutdown: Arc<AtomicBool>,
    given_root: PathBuf,
}

#[no_mangle]
pub extern "C" fn cc_watch_abi_version() -> u32 {
    ABI_VERSION
}

#[no_mangle]
pub extern "C" fn cc_watch_last_error() -> *const c_char {
    LAST_ERROR.with(|slot| {
        slot.borrow()
            .as_ref()
            .map(|s| s.as_ptr())
            .unwrap_or(std::ptr::null())
    })
}

/// # Safety
/// `root_utf8` and `ignore_dirs_utf8` must be valid NUL-terminated UTF-8
/// strings for the duration of the call.
#[no_mangle]
pub unsafe extern "C" fn cc_watch_create(
    root_utf8: *const c_char,
    ignore_dirs_utf8: *const c_char,
    queue_cap: u32,
    max_watches: u32,
) -> *mut CcWatch {
    let result = catch_unwind(|| {
        if root_utf8.is_null() {
            set_last_error("root path is null".into());
            return std::ptr::null_mut();
        }
        let root = match CStr::from_ptr(root_utf8).to_str() {
            Ok(s) => PathBuf::from(s),
            Err(_) => {
                set_last_error("root path is not valid UTF-8".into());
                return std::ptr::null_mut();
            }
        };
        let ignore_raw = if ignore_dirs_utf8.is_null() {
            ""
        } else {
            CStr::from_ptr(ignore_dirs_utf8).to_str().unwrap_or("")
        };
        match create_watch(root, ignore_raw, queue_cap, max_watches) {
            Ok(watch) => Box::into_raw(Box::new(watch)),
            Err(message) => {
                set_last_error(message);
                std::ptr::null_mut()
            }
        }
    });
    result.unwrap_or_else(|_| {
        set_last_error("cc_watch_create panicked".into());
        std::ptr::null_mut()
    })
}

fn create_watch(
    root: PathBuf,
    ignore_raw: &str,
    queue_cap: u32,
    max_watches: u32,
) -> Result<CcWatch, String> {
    if !root.is_dir() {
        return Err(format!("root is not a directory: {}", root.display()));
    }
    let canonical_root = root
        .canonicalize()
        .map_err(|e| format!("cannot canonicalize {}: {e}", root.display()))?;

    let queue = Arc::new(Queue::new(queue_cap));
    #[cfg(target_os = "linux")]
    let (job_tx, job_rx) = std::sync::mpsc::channel::<PathBuf>();

    let ctx = Arc::new(WatchContext {
        given_root: root.clone(),
        canonical_root,
        ignore: IgnoreSet::parse(ignore_raw),
        queue: Arc::clone(&queue),
        #[cfg(target_os = "linux")]
        dir_jobs: Some(job_tx),
        #[cfg(not(target_os = "linux"))]
        dir_jobs: None,
    });

    let handler_ctx = Arc::clone(&ctx);
    let watcher = notify::recommended_watcher(move |result| {
        handler_ctx.on_event(result);
    })
    .map_err(|e| format!("failed to create watcher: {e}"))?;
    let watcher = Arc::new(Mutex::new(watcher));
    let shutdown = Arc::new(AtomicBool::new(false));

    #[cfg(not(target_os = "linux"))]
    {
        // Kernel-recursive backends (FSEvents / RDCW): one watch, no walk.
        // max_watches is a Linux (inotify) concern only.
        let _ = max_watches;
        watcher
            .lock()
            .unwrap()
            .watch(&root, RecursiveMode::Recursive)
            .map_err(|e| format!("failed to watch {}: {e}", root.display()))?;
        queue
            .watch_count
            .store(1, std::sync::atomic::Ordering::Relaxed);
        Ok(CcWatch {
            ctx,
            watcher: Some(watcher),
            shutdown,
            given_root: root,
        })
    }

    #[cfg(target_os = "linux")]
    {
        // Per-directory inotify: the ignore-aware walk runs on OUR thread so
        // create never blocks the caller.
        let walker = std::thread::Builder::new()
            .name("cc_watcher-walk".into())
            .spawn({
                let ctx = Arc::clone(&ctx);
                let watcher = Arc::clone(&watcher);
                let shutdown = Arc::clone(&shutdown);
                let root = root.clone();
                move || {
                    linux_tree::walker_main(
                        ctx, watcher, job_rx, root, max_watches, shutdown,
                    )
                }
            })
            .map_err(|e| format!("failed to spawn walker thread: {e}"))?;
        Ok(CcWatch {
            ctx,
            watcher: Some(watcher),
            walker: Some(walker),
            shutdown,
            given_root: root,
        })
    }
}

/// # Safety
/// `w` must be a live handle from `cc_watch_create`; `out` must point to a
/// writable `CcWatchDrain`.
#[no_mangle]
pub unsafe extern "C" fn cc_watch_drain(
    w: *mut CcWatch,
    out: *mut CcWatchDrain,
) -> i32 {
    if w.is_null() || out.is_null() {
        return 0;
    }
    let watch = &*w;
    let result = catch_unwind(AssertUnwindSafe(|| {
        // Root liveness: one stat per drain tick, on the CALLING (Dart)
        // thread. Deliberate — a kernel backend does not reliably report the
        // deletion of the watched root itself and this is what makes
        // ROOT_GONE dependable. The cost is a single stat per handle per tick
        // (~1µs; at 76 handles on a 500ms pump that is well under a
        // millisecond per second), which is worth paying to avoid a dead
        // watch that never re-arms.
        if !watch.given_root.exists() {
            watch.ctx.queue.set_flags(FLAG_ROOT_GONE);
        }
        match watch.ctx.queue.drain() {
            None => 0,
            Some(drained) => {
                (*out).buf = drained.buf_ptr;
                (*out).len = drained.buf_len;
                (*out).flags = drained.flags;
                (*out).dropped = drained.dropped;
                (*out).watch_count = drained.watch_count;
                1
            }
        }
    }));
    result.unwrap_or_else(|_| {
        set_last_error("cc_watch_drain panicked".into());
        0
    })
}

/// # Safety
/// `w` must be a handle from `cc_watch_create` (or NULL), not used after.
#[no_mangle]
pub unsafe extern "C" fn cc_watch_destroy(w: *mut CcWatch) {
    if w.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| {
        let mut watch = Box::from_raw(w);
        watch.shutdown.store(true, Ordering::Relaxed);
        // Dropping the watcher stops notify's threads (and, on Linux, closes
        // the inotify fd — every watch descriptor with it).
        watch.watcher.take();
        #[cfg(target_os = "linux")]
        if let Some(walker) = watch.walker.take() {
            let _ = walker.join();
        }
        drop(watch);
    }));
}

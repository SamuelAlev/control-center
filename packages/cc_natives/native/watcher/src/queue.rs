//! The bounded, deduplicating change queue shared between the notify event
//! thread(s) and the FFI drain call.
//!
//! A `HashSet<PathBuf>` capped at `cap`: pushing past the cap clears the set
//! (memory stays bounded), raises the RESCAN flag and counts the drop — the
//! consumer treats "rescan needed" exactly like a relevant change, so
//! overflow degrades to one conservative reindex, never a missed one.
//! `drain` serializes into a buffer OWNED HERE and reused, so the pointer
//! handed to Dart stays valid until the next drain on the same handle.

use std::collections::HashSet;
use std::path::PathBuf;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::Mutex;

pub const FLAG_RESCAN: u32 = 1;
pub const FLAG_ROOT_GONE: u32 = 2;
#[allow(dead_code)] // set by the Linux walker (cfg-gated module)
pub const FLAG_DEGRADED: u32 = 4;

#[derive(Default)]
struct Inner {
    paths: HashSet<PathBuf>,
    flags: u32,
    dropped: u32,
    /// Reused drain serialization buffer; valid until the next drain.
    drain_buf: Vec<u8>,
}

pub struct Queue {
    inner: Mutex<Inner>,
    cap: usize,
    /// Live OS watches (Linux: dirs; macOS/Windows: 1). Atomic so the Linux
    /// walker thread can bump it without the queue lock.
    pub watch_count: AtomicU32,
}

/// One drained batch, borrowed from the queue's reusable buffer.
pub struct Drained {
    pub buf_ptr: *const u8,
    pub buf_len: usize,
    pub flags: u32,
    pub dropped: u32,
    pub watch_count: u32,
}

impl Queue {
    pub fn new(cap: u32) -> Self {
        Self {
            inner: Mutex::new(Inner::default()),
            cap: if cap == 0 { usize::MAX } else { cap as usize },
            watch_count: AtomicU32::new(0),
        }
    }

    pub fn push(&self, path: PathBuf) {
        let mut inner = self.inner.lock().unwrap();
        if inner.paths.len() >= self.cap {
            // Overflow: drop the whole set, keep memory bounded, signal a
            // rescan. Counting continues so the consumer can see the volume.
            inner.dropped = inner.dropped.saturating_add(inner.paths.len() as u32 + 1);
            inner.paths.clear();
            inner.flags |= FLAG_RESCAN;
            return;
        }
        inner.paths.insert(path);
    }

    pub fn set_flags(&self, flags: u32) {
        let mut inner = self.inner.lock().unwrap();
        inner.flags |= flags;
    }

    /// Serializes and clears pending state. Returns `None` when nothing is
    /// pending. The returned pointers reference the queue's own reusable
    /// buffer — valid until the next `drain`.
    pub fn drain(&self) -> Option<Drained> {
        let mut inner = self.inner.lock().unwrap();
        if inner.paths.is_empty() && inner.flags == 0 && inner.dropped == 0 {
            return None;
        }
        let paths: Vec<PathBuf> = inner.paths.drain().collect();
        inner.drain_buf.clear();
        for (i, path) in paths.iter().enumerate() {
            if i > 0 {
                inner.drain_buf.push(0);
            }
            // Non-UTF-8 paths are represented lossily; the Dart side decodes
            // with allowMalformed and its affectsIndex gate re-filters.
            inner
                .drain_buf
                .extend_from_slice(path.to_string_lossy().as_bytes());
        }
        let flags = inner.flags;
        let dropped = inner.dropped;
        inner.flags = 0;
        inner.dropped = 0;
        Some(Drained {
            buf_ptr: inner.drain_buf.as_ptr(),
            buf_len: inner.drain_buf.len(),
            flags,
            dropped,
            watch_count: self.watch_count.load(Ordering::Relaxed),
        })
    }
}

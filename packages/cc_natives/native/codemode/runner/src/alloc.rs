//! The interpreter's allocator. It enforces the heap limit itself, instead of
//! QuickJS's `JS_SetMemoryLimit`, so that running out of memory is observed
//! here and can be reported as `memory_exceeded` even when the script
//! catches the resulting `InternalError`.
//!
//! Once the limit is hit, a small reserve is opened so the interpreter can
//! still build the errors it throws while the script is being stopped. The
//! interrupt handler sees [`HeapStats::exhausted`] and ends the script.

use std::alloc::{self, Layout};
use std::ptr;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::Arc;

use rquickjs::allocator::Allocator;

/// Headroom granted after the limit is first hit.
pub const RESERVE_BYTES: usize = 4 * 1024 * 1024;

const ALIGN: usize = 16;
const HEADER: usize = 16;

/// Counters shared between the allocator and the engine.
#[derive(Debug, Default)]
pub struct HeapStats {
    used: AtomicUsize,
    peak: AtomicUsize,
    limit: AtomicUsize,
    exhausted: AtomicBool,
}

impl HeapStats {
    /// Creates counters with the given limit.
    pub fn new(limit: usize) -> Arc<HeapStats> {
        let s = HeapStats::default();
        s.limit.store(limit, Ordering::Relaxed);
        Arc::new(s)
    }

    /// Changes the limit. Used once `init` arrives.
    pub fn set_limit(&self, limit: usize) {
        self.limit.store(limit, Ordering::Relaxed);
    }

    /// Bytes currently allocated by the interpreter.
    pub fn used(&self) -> usize {
        self.used.load(Ordering::Relaxed)
    }

    /// Highest value of [`HeapStats::used`] so far.
    pub fn peak(&self) -> usize {
        self.peak.load(Ordering::Relaxed)
    }

    /// Whether an allocation was ever refused for exceeding the limit.
    pub fn exhausted(&self) -> bool {
        self.exhausted.load(Ordering::Relaxed)
    }

    /// Resets the peak to the current use, so stats cover the script only.
    pub fn reset_peak(&self) {
        self.peak.store(self.used(), Ordering::Relaxed);
    }

    fn admit(&self, extra: usize) -> bool {
        let used = self.used.load(Ordering::Relaxed);
        let mut limit = self.limit.load(Ordering::Relaxed);
        if self.exhausted() {
            limit = limit.saturating_add(RESERVE_BYTES);
        }
        match used.checked_add(extra) {
            Some(total) if total <= limit => true,
            _ => {
                self.exhausted.store(true, Ordering::Relaxed);
                false
            }
        }
    }

    fn add(&self, n: usize) {
        let now = self.used.fetch_add(n, Ordering::Relaxed) + n;
        if now > self.peak.load(Ordering::Relaxed) {
            self.peak.store(now, Ordering::Relaxed);
        }
    }

    fn sub(&self, n: usize) {
        self.used.fetch_sub(n, Ordering::Relaxed);
    }
}

/// Heap-limited allocator over the global allocator. Each block carries a
/// header with its usable size.
pub struct LimitedAllocator {
    stats: Arc<HeapStats>,
}

impl LimitedAllocator {
    /// An allocator that reports into `stats`.
    pub fn new(stats: Arc<HeapStats>) -> Self {
        LimitedAllocator { stats }
    }
}

fn round(size: usize) -> Option<usize> {
    size.checked_add(ALIGN - 1).map(|s| s & !(ALIGN - 1))
}

fn layout_for(size: usize) -> Option<Layout> {
    Layout::from_size_align(size.checked_add(HEADER)?, ALIGN).ok()
}

/// # Safety
/// `ptr` must come from this allocator.
unsafe fn header(ptr: *mut u8) -> *mut usize {
    // SAFETY: every block starts HEADER bytes before the pointer we handed out.
    unsafe { ptr.sub(HEADER) as *mut usize }
}

// SAFETY: blocks are ALIGN-aligned, at least the requested size, and
// usable_size reports exactly the size stored in the header.
unsafe impl Allocator for LimitedAllocator {
    fn alloc(&mut self, size: usize) -> *mut u8 {
        let Some(size) = round(size.max(1)) else {
            return ptr::null_mut();
        };
        let Some(layout) = layout_for(size) else {
            return ptr::null_mut();
        };
        if !self.stats.admit(size) {
            return ptr::null_mut();
        }
        // SAFETY: layout has a non-zero size.
        let base = unsafe { alloc::alloc(layout) };
        if base.is_null() {
            self.stats.exhausted.store(true, Ordering::Relaxed);
            return ptr::null_mut();
        }
        self.stats.add(size);
        // SAFETY: base has room for the header.
        unsafe {
            (base as *mut usize).write(size);
            base.add(HEADER)
        }
    }

    fn calloc(&mut self, count: usize, size: usize) -> *mut u8 {
        let Some(total) = count.checked_mul(size) else {
            return ptr::null_mut();
        };
        let Some(total) = round(total.max(1)) else {
            return ptr::null_mut();
        };
        let Some(layout) = layout_for(total) else {
            return ptr::null_mut();
        };
        if !self.stats.admit(total) {
            return ptr::null_mut();
        }
        // SAFETY: layout has a non-zero size.
        let base = unsafe { alloc::alloc_zeroed(layout) };
        if base.is_null() {
            self.stats.exhausted.store(true, Ordering::Relaxed);
            return ptr::null_mut();
        }
        self.stats.add(total);
        // SAFETY: base has room for the header.
        unsafe {
            (base as *mut usize).write(total);
            base.add(HEADER)
        }
    }

    unsafe fn dealloc(&mut self, ptr: *mut u8) {
        // SAFETY: ptr came from this allocator (trait contract).
        unsafe {
            let h = header(ptr);
            let size = h.read();
            self.stats.sub(size);
            alloc::dealloc(h as *mut u8, layout_for(size).expect("valid layout"));
        }
    }

    unsafe fn realloc(&mut self, ptr: *mut u8, new_size: usize) -> *mut u8 {
        if ptr.is_null() {
            return self.alloc(new_size);
        }
        let Some(new_size) = round(new_size.max(1)) else {
            return ptr::null_mut();
        };
        let Some(new_layout) = layout_for(new_size) else {
            return ptr::null_mut();
        };
        // SAFETY: ptr came from this allocator (trait contract).
        let h = unsafe { header(ptr) };
        // SAFETY: as above.
        let old_size = unsafe { h.read() };
        if new_size > old_size && !self.stats.admit(new_size - old_size) {
            return ptr::null_mut();
        }
        let old_layout = layout_for(old_size).expect("valid layout");
        // SAFETY: h is the block start with old_layout; new size is non-zero.
        let base = unsafe { alloc::realloc(h as *mut u8, old_layout, new_layout.size()) };
        if base.is_null() {
            self.stats.exhausted.store(true, Ordering::Relaxed);
            return ptr::null_mut();
        }
        if new_size > old_size {
            self.stats.add(new_size - old_size);
        } else {
            self.stats.sub(old_size - new_size);
        }
        // SAFETY: base has room for the header.
        unsafe {
            (base as *mut usize).write(new_size);
            base.add(HEADER)
        }
    }

    unsafe fn usable_size(ptr: *mut u8) -> usize {
        // SAFETY: ptr came from this allocator (trait contract).
        unsafe { header(ptr).read() }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn enforces_limit_and_opens_reserve() {
        let stats = HeapStats::new(1024);
        let mut a = LimitedAllocator::new(stats.clone());
        let p = a.alloc(512);
        assert!(!p.is_null());
        assert_eq!(stats.used(), 512);
        assert!(a.alloc(1024).is_null());
        assert!(stats.exhausted());
        // The reserve now admits a small allocation.
        let q = a.alloc(1024);
        assert!(!q.is_null());
        unsafe {
            a.dealloc(p);
            a.dealloc(q);
        }
        assert_eq!(stats.used(), 0);
        assert_eq!(stats.peak(), 1536);
    }

    #[test]
    fn realloc_tracks_growth_and_shrink() {
        let stats = HeapStats::new(1 << 20);
        let mut a = LimitedAllocator::new(stats.clone());
        let p = a.alloc(10);
        unsafe {
            p.write(7);
            let p = a.realloc(p, 1000);
            assert_eq!(p.read(), 7);
            assert_eq!(stats.used(), 1008);
            let p = a.realloc(p, 20);
            assert_eq!(stats.used(), 32);
            assert_eq!(LimitedAllocator::usable_size(p), 32);
            a.dealloc(p);
        }
        assert_eq!(stats.used(), 0);
    }
}

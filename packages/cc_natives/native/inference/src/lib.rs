//! cc_inference — Control Center's native inference leaf.
//!
//! FIRST-PARTY source (not vendored): the C ABI in `cc_inference.h` is consumed
//! by `packages/cc_natives/lib/src/inference/` over `dart:ffi`. Built by
//! `scripts/natives/build_inference.sh`; a missing dylib is a broken install —
//! `cc_server`'s native preflight refuses to boot, there is no degraded mode.
//!
//! ## One library, one runtime
//!
//! Both on-device ML workloads live here — speech (sherpa-onnx) and sentence
//! embeddings (ONNX Runtime) — because they STATICALLY link a single ONNX
//! Runtime between them. That is the point: one self-contained artifact, no
//! loader-path search, no version skew between header and runtime, and no way
//! for two runtimes to collide by base name in one process.
//!
//! ## Layering
//!
//! Built on the raw C API (`sherpa-onnx-sys`) rather than the safe
//! `sherpa-onnx` wrapper crate, so no wrapper defaults sit between this code
//! and the engine — every config field it sets is visible here.
//!
//! Numeric post-processing (mean pooling, L2 normalization, PCM conversion,
//! per-speaker chunking) stays in DART. This crate owns the model graph, not
//! the arithmetic around it, which is what keeps embeddings comparable with
//! what is already stored in sqlite_vector.
//!
//! ## Safety conventions (uniform across every module)
//!
//! * Every `extern "C"` body is wrapped in `catch_unwind`: a panic becomes a
//!   NULL/-1 return plus [`cc_inference_last_error`], never an unwind across FFI.
//! * Handles are opaque `Box::into_raw` pointers; each has a NULL-safe
//!   `*_destroy`.
//! * Strings returned to Dart are `CString::into_raw` and MUST come back
//!   through [`cc_string_destroy`].
//! * Errors are reported out-of-band via a thread-local, so a failing call can
//!   return a plain NULL/-1 without an out-param.

mod asr;
mod diarize;
mod embed;
mod ort_sys;
mod speaker;
mod vad;

use std::cell::RefCell;
use std::ffi::{c_char, CStr, CString};

/// The C ABI version this library speaks; mirrored by
/// `CC_INFERENCE_ABI_VERSION` in cc_inference.h and `ccInferenceAbiVersion` in
/// the Dart bindings. Bump on ANY change to a signature or struct below — the
/// Dart side refuses to bind on a mismatch rather than misreading memory.
pub const ABI_VERSION: u32 = 1;

thread_local! {
    static LAST_ERROR: RefCell<Option<CString>> = const { RefCell::new(None) };
}

/// Records `message` as this thread's most recent failure.
pub(crate) fn set_last_error(message: String) {
    LAST_ERROR.with(|slot| {
        *slot.borrow_mut() = Some(
            CString::new(message)
                .unwrap_or_else(|_| CString::new("error message contained NUL").unwrap()),
        );
    });
}

/// Clears this thread's error slot. Called at the top of each fallible entry
/// point so a stale message from an earlier call cannot be mistaken for the
/// cause of a later one.
pub(crate) fn clear_last_error() {
    LAST_ERROR.with(|slot| *slot.borrow_mut() = None);
}

/// Reads a required UTF-8 C string argument, or records why it was unusable.
pub(crate) fn required_str<'a>(ptr: *const c_char, name: &str) -> Result<&'a str, String> {
    if ptr.is_null() {
        return Err(format!("{name} is null"));
    }
    unsafe { CStr::from_ptr(ptr) }
        .to_str()
        .map_err(|_| format!("{name} is not valid UTF-8"))
}

/// Reads an optional UTF-8 C string argument; NULL and invalid UTF-8 both
/// become `""`, which is how the sherpa C API spells "not set".
pub(crate) fn optional_str<'a>(ptr: *const c_char) -> &'a str {
    if ptr.is_null() {
        return "";
    }
    unsafe { CStr::from_ptr(ptr) }.to_str().unwrap_or("")
}

/// Narrows a caller-supplied sample count to the `i32` sherpa's C API takes.
///
/// A count past `i32::MAX` (37 hours at 16 kHz) would otherwise wrap silently
/// and decode a garbage slice, so it becomes an error at the boundary instead.
pub(crate) fn sample_count(n: isize, what: &str) -> Result<i32, String> {
    i32::try_from(n).map_err(|_| format!("{what}: {n} samples exceeds the i32 the engine accepts"))
}

/// Hands `text` to the caller as a malloc'd C string to be freed with
/// [`cc_string_destroy`]. Interior NULs are replaced rather than failing the
/// whole call — losing a byte of a transcript beats losing the transcript.
pub(crate) fn into_c_string(text: String) -> *mut c_char {
    let sanitized = text.replace('\0', " ");
    match CString::new(sanitized) {
        Ok(s) => s.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// The ABI version this library speaks.
#[no_mangle]
pub extern "C" fn cc_inference_abi_version() -> u32 {
    ABI_VERSION
}

/// Thread-local message describing the most recent failure on this thread;
/// NULL when none. Owned by the library; valid until the next failing call on
/// the same thread.
#[no_mangle]
pub extern "C" fn cc_inference_last_error() -> *const c_char {
    LAST_ERROR.with(|slot| {
        slot.borrow()
            .as_ref()
            .map(|s| s.as_ptr())
            .unwrap_or(std::ptr::null())
    })
}

/// Frees a string this library returned (e.g. from `cc_asr_transcribe`).
/// NULL-safe.
///
/// # Safety
/// `s` must be a pointer this library returned and not yet freed.
#[no_mangle]
pub unsafe extern "C" fn cc_string_destroy(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    drop(CString::from_raw(s));
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The header is the contract Dart binds against; a bump on one side only
    /// would let Dart misread native memory.
    #[test]
    fn header_abi_version_matches_rust() {
        let header = include_str!("../cc_inference.h");
        let line = header
            .lines()
            .find(|l| l.contains("#define CC_INFERENCE_ABI_VERSION"))
            .expect("cc_inference.h must define CC_INFERENCE_ABI_VERSION");
        let value: u32 = line
            .split_whitespace()
            .nth(2)
            .and_then(|v| v.trim_end_matches('u').parse().ok())
            .expect("CC_INFERENCE_ABI_VERSION must be a number");
        assert_eq!(value, ABI_VERSION);
    }

    /// Every opaque handle in the header must have a matching destroy entry
    /// point — a create with no destroy is a leak the Dart side cannot fix.
    #[test]
    fn every_handle_has_a_destructor() {
        let header = include_str!("../cc_inference.h");
        for handle in ["CcEmbedder", "CcAsr", "CcVad", "CcDiarizer", "CcSpeakerEmbedder"] {
            let snake = match handle {
                "CcEmbedder" => "cc_embedder_destroy",
                "CcAsr" => "cc_asr_destroy",
                "CcVad" => "cc_vad_destroy",
                "CcDiarizer" => "cc_diar_destroy",
                _ => "cc_spk_destroy",
            };
            assert!(header.contains(snake), "{handle} has no {snake} in the header");
        }
    }

    #[test]
    fn last_error_round_trips_and_clears() {
        clear_last_error();
        assert!(cc_inference_last_error().is_null());
        set_last_error("boom".into());
        let msg = unsafe { CStr::from_ptr(cc_inference_last_error()) };
        assert_eq!(msg.to_str().unwrap(), "boom");
        clear_last_error();
        assert!(cc_inference_last_error().is_null());
    }

    /// sherpa's C API counts samples in an `i32`; a larger count must be an
    /// error at the boundary rather than a silent wrap into a garbage slice.
    #[test]
    fn sample_count_rejects_what_would_wrap() {
        assert_eq!(sample_count(16_000, "x").unwrap(), 16_000);
        assert_eq!(sample_count(i32::MAX as isize, "x").unwrap(), i32::MAX);
        assert!(sample_count(i32::MAX as isize + 1, "cc_asr_transcribe").is_err());
        let message = sample_count(i32::MAX as isize + 1, "cc_asr_transcribe").unwrap_err();
        assert!(message.contains("cc_asr_transcribe"), "{message}");
    }

    #[test]
    fn destroying_a_null_string_is_safe() {
        unsafe { cc_string_destroy(std::ptr::null_mut()) };
    }

    #[test]
    fn interior_nul_is_sanitized_not_dropped() {
        let ptr = into_c_string("a\0b".into());
        assert!(!ptr.is_null());
        let text = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_owned();
        assert_eq!(text, "a b");
        unsafe { cc_string_destroy(ptr) };
    }
}

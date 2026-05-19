//! Silero voice-activity detection over the sherpa-onnx C API.
//!
//! Backs BOTH Dart consumers, which use the same handle differently:
//!
//! * `silero_vad_detector.dart` — streaming: push a chunk, read the live
//!   `is_detected` flag, drain the segment queue so it cannot grow.
//! * `meeting_offline_vad.dart` — offline: push 512-sample windows over a whole
//!   recording, draining `front`/`pop` to collect speech spans, then `flush`.
//!
//! [`cc_vad_front`] reports a segment's start and length only. The Dart side
//! never reads the segment's samples (it converts the range to milliseconds), so
//! no audio buffer needs to cross the FFI boundary.

use std::ffi::{c_char, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;

use sherpa_onnx_sys::vad as sys;

use crate::{clear_last_error, required_str, sample_count, set_last_error};

/// Silero's frame size. A package default rather than a tuning choice — the
/// v5 model requires exactly 512 samples per frame at 16 kHz.
const WINDOW_SIZE: i32 = 512;

/// Upper bound on a single speech segment before the detector force-splits it.
const MAX_SPEECH_DURATION: f32 = 5.0;

/// A live voice-activity detector.
pub struct CcVad {
    vad: *const sys::VoiceActivityDetector,
}

// Created and driven from one Dart isolate's thread; the Box only has to move
// between calls on that thread.
unsafe impl Send for CcVad {}

impl Drop for CcVad {
    fn drop(&mut self) {
        unsafe { sys::SherpaOnnxDestroyVoiceActivityDetector(self.vad) };
    }
}

/// Creates a detector from the Silero model at `model_utf8`.
///
/// # Safety
/// `model_utf8` must be a valid NUL-terminated UTF-8 string.
#[no_mangle]
pub unsafe extern "C" fn cc_vad_create(
    model_utf8: *const c_char,
    threshold: f32,
    min_silence_s: f32,
    min_speech_s: f32,
    sample_rate: i32,
    buffer_size_s: f32,
) -> *mut CcVad {
    clear_last_error();
    catch_unwind(AssertUnwindSafe(|| {
        let model = match required_str(model_utf8, "model") {
            Ok(m) => m,
            Err(e) => {
                set_last_error(e);
                return ptr::null_mut();
            }
        };
        let Ok(model_c) = CString::new(model) else {
            set_last_error("model path contains a NUL byte".into());
            return ptr::null_mut();
        };
        let empty = CString::new("").unwrap();
        let cpu = CString::new("cpu").unwrap();

        // Zeroed then fully populated: every `char*` sherpa reads must point at
        // a real string (it wraps them in std::string), including the TEN-VAD
        // block we do not use.
        let mut config: sys::VadModelConfig = std::mem::zeroed();
        config.silero_vad.model = model_c.as_ptr();
        config.silero_vad.threshold = threshold;
        config.silero_vad.min_silence_duration = min_silence_s;
        config.silero_vad.min_speech_duration = min_speech_s;
        config.silero_vad.window_size = WINDOW_SIZE;
        config.silero_vad.max_speech_duration = MAX_SPEECH_DURATION;
        config.ten_vad.model = empty.as_ptr();
        config.ten_vad.window_size = WINDOW_SIZE;
        config.sample_rate = sample_rate;
        config.num_threads = 1;
        config.provider = cpu.as_ptr();
        // Off: sherpa logs a line per frame when this is on, and detection is
        // unaffected by it.
        config.debug = 0;

        let vad = sys::SherpaOnnxCreateVoiceActivityDetector(&config, buffer_size_s);
        if vad.is_null() {
            set_last_error("sherpa-onnx could not create the voice activity detector".into());
            return ptr::null_mut();
        }
        Box::into_raw(Box::new(CcVad { vad }))
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_vad_create panicked".into());
        ptr::null_mut()
    })
}

/// Feeds float samples in `[-1, 1]`.
///
/// # Safety
/// `samples` must hold at least `n` floats; `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_vad_accept(handle: *mut CcVad, samples: *const f32, n: isize) {
    if handle.is_null() || samples.is_null() || n <= 0 {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| {
        match sample_count(n, "cc_vad_accept") {
            Ok(n) => sys::SherpaOnnxVoiceActivityDetectorAcceptWaveform((*handle).vad, samples, n),
            Err(e) => set_last_error(e),
        }
    }));
}

/// 1 when speech is currently detected, else 0.
///
/// # Safety
/// `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_vad_is_detected(handle: *const CcVad) -> i32 {
    if handle.is_null() {
        return 0;
    }
    catch_unwind(AssertUnwindSafe(|| {
        sys::SherpaOnnxVoiceActivityDetectorDetected((*handle).vad)
    }))
    .unwrap_or(0)
}

/// 1 when the segment queue is empty, else 0.
///
/// # Safety
/// `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_vad_is_empty(handle: *const CcVad) -> i32 {
    if handle.is_null() {
        return 1;
    }
    catch_unwind(AssertUnwindSafe(|| {
        sys::SherpaOnnxVoiceActivityDetectorEmpty((*handle).vad)
    }))
    .unwrap_or(1)
}

/// Reads the queued segment's sample range into `out_start` / `out_len`.
/// Returns 1 when a segment was read, 0 when the queue is empty.
///
/// # Safety
/// `handle` must be live; the out pointers must be writable.
#[no_mangle]
pub unsafe extern "C" fn cc_vad_front(
    handle: *const CcVad,
    out_start: *mut i32,
    out_len: *mut i32,
) -> i32 {
    if handle.is_null() || out_start.is_null() || out_len.is_null() {
        return 0;
    }
    catch_unwind(AssertUnwindSafe(|| {
        if sys::SherpaOnnxVoiceActivityDetectorEmpty((*handle).vad) != 0 {
            return 0;
        }
        let segment = sys::SherpaOnnxVoiceActivityDetectorFront((*handle).vad);
        if segment.is_null() {
            return 0;
        }
        *out_start = (*segment).start;
        *out_len = (*segment).n;
        sys::SherpaOnnxDestroySpeechSegment(segment);
        1
    }))
    .unwrap_or(0)
}

/// Drops the queued segment.
///
/// # Safety
/// `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_vad_pop(handle: *mut CcVad) {
    if handle.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| {
        sys::SherpaOnnxVoiceActivityDetectorPop((*handle).vad)
    }));
}

/// Clears queued segments and the detector's internal state.
///
/// # Safety
/// `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_vad_clear(handle: *mut CcVad) {
    if handle.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| {
        sys::SherpaOnnxVoiceActivityDetectorClear((*handle).vad)
    }));
}

/// Flushes any trailing speech into the queue (end of a recording).
///
/// # Safety
/// `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_vad_flush(handle: *mut CcVad) {
    if handle.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| {
        sys::SherpaOnnxVoiceActivityDetectorFlush((*handle).vad)
    }));
}

/// Frees the detector. NULL-safe.
///
/// # Safety
/// `handle` must come from `cc_vad_create` and not be used afterwards.
#[no_mangle]
pub unsafe extern "C" fn cc_vad_destroy(handle: *mut CcVad) {
    if handle.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| drop(Box::from_raw(handle))));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creating_from_a_missing_model_fails_cleanly() {
        let path = CString::new("/nonexistent/silero.onnx").unwrap();
        let handle = unsafe { cc_vad_create(path.as_ptr(), 0.5, 0.25, 0.1, 16000, 30.0) };
        assert!(handle.is_null());
        assert!(!crate::cc_inference_last_error().is_null());
    }

    #[test]
    fn creating_from_a_null_model_fails_cleanly() {
        let handle = unsafe { cc_vad_create(ptr::null(), 0.5, 0.25, 0.1, 16000, 30.0) };
        assert!(handle.is_null());
    }

    /// A null handle must behave like a spent detector, never dereference.
    #[test]
    fn null_handle_operations_are_safe() {
        unsafe {
            cc_vad_accept(ptr::null_mut(), ptr::null(), 0);
            cc_vad_pop(ptr::null_mut());
            cc_vad_clear(ptr::null_mut());
            cc_vad_flush(ptr::null_mut());
            cc_vad_destroy(ptr::null_mut());
            assert_eq!(cc_vad_is_detected(ptr::null()), 0);
            assert_eq!(cc_vad_is_empty(ptr::null()), 1);
            let (mut start, mut len) = (0, 0);
            assert_eq!(cc_vad_front(ptr::null(), &mut start, &mut len), 0);
        }
    }
}

//! Offline speaker diarization (pyannote segmentation + WeSpeaker embeddings +
//! fast clustering) over the sherpa-onnx C API.
//!
//! A direct port of `meeting_diarization_service.dart`'s worker body. The
//! per-speaker audio gathering and the L2 normalization of each voiceprint stay
//! in Dart; this exposes only the native model invocation.

use std::ffi::{c_char, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;

use sherpa_onnx_sys::offline_speaker_diarization as sys;

use crate::{clear_last_error, required_str, sample_count, set_last_error};

/// One diarized span. Mirrors `CcDiarSegment` in cc_inference.h and the Dart
/// `CcDiarSegment` struct; seconds, as sherpa reports them (Dart converts to ms).
#[repr(C)]
#[derive(Clone, Copy)]
pub struct CcDiarSegment {
    pub start_s: f32,
    pub end_s: f32,
    pub speaker: i32,
}

/// A configured diarizer.
pub struct CcDiarizer {
    diarizer: *const sys::OfflineSpeakerDiarization,
}

unsafe impl Send for CcDiarizer {}

impl Drop for CcDiarizer {
    fn drop(&mut self) {
        unsafe { sys::SherpaOnnxDestroyOfflineSpeakerDiarization(self.diarizer) };
    }
}

/// Creates a diarizer from the pyannote segmentation model and the WeSpeaker
/// embedding model.
///
/// `clustering_threshold` is used with `num_clusters = -1`, i.e. infer the
/// speaker count from the audio — we never know it ahead of time.
///
/// # Safety
/// Both model path arguments must be valid NUL-terminated UTF-8 strings.
#[no_mangle]
pub unsafe extern "C" fn cc_diar_create(
    segmentation_model: *const c_char,
    embedding_model: *const c_char,
    num_threads: i32,
    clustering_threshold: f32,
    min_duration_on_s: f32,
    min_duration_off_s: f32,
) -> *mut CcDiarizer {
    clear_last_error();
    catch_unwind(AssertUnwindSafe(|| {
        let build = || -> Result<(CString, CString), String> {
            let seg = required_str(segmentation_model, "segmentation_model")?;
            let emb = required_str(embedding_model, "embedding_model")?;
            let seg_c =
                CString::new(seg).map_err(|_| "segmentation model path contains a NUL byte")?;
            let emb_c =
                CString::new(emb).map_err(|_| "embedding model path contains a NUL byte")?;
            Ok((seg_c, emb_c))
        };
        let (seg_c, emb_c) = match build() {
            Ok(v) => v,
            Err(e) => {
                set_last_error(e);
                return ptr::null_mut();
            }
        };
        let cpu = CString::new("cpu").unwrap();

        let mut config: sys::OfflineSpeakerDiarizationConfig = std::mem::zeroed();
        config.segmentation.pyannote.model = seg_c.as_ptr();
        config.segmentation.num_threads = num_threads;
        config.segmentation.debug = 0;
        config.segmentation.provider = cpu.as_ptr();
        config.embedding.model = emb_c.as_ptr();
        config.embedding.num_threads = num_threads;
        config.embedding.debug = 0;
        config.embedding.provider = cpu.as_ptr();
        config.clustering.num_clusters = -1;
        config.clustering.threshold = clustering_threshold;
        config.min_duration_on = min_duration_on_s;
        config.min_duration_off = min_duration_off_s;

        let diarizer = sys::SherpaOnnxCreateOfflineSpeakerDiarization(&config);
        if diarizer.is_null() {
            set_last_error(
                "sherpa-onnx could not create the diarizer (check the segmentation and embedding models)"
                    .into(),
            );
            return ptr::null_mut();
        }
        Box::into_raw(Box::new(CcDiarizer { diarizer }))
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_diar_create panicked".into());
        ptr::null_mut()
    })
}

/// Diarizes a complete 16 kHz mono recording.
///
/// On success writes a library-owned array into `out_segments` (+ its length
/// into `out_count`) and returns 0; the caller frees it with
/// `cc_diar_segments_destroy`. A recording with no detected speech is success
/// with a count of 0 and a NULL array. Returns -1 on failure.
///
/// # Safety
/// `samples` must hold at least `n` floats; the out pointers must be writable.
#[no_mangle]
pub unsafe extern "C" fn cc_diar_process(
    handle: *mut CcDiarizer,
    samples: *const f32,
    n: isize,
    out_segments: *mut *mut CcDiarSegment,
    out_count: *mut isize,
) -> i32 {
    clear_last_error();
    catch_unwind(AssertUnwindSafe(|| {
        if handle.is_null() || samples.is_null() || out_segments.is_null() || out_count.is_null() {
            set_last_error("cc_diar_process received a null pointer".into());
            return -1;
        }
        *out_segments = ptr::null_mut();
        *out_count = 0;
        if n <= 0 {
            return 0;
        }

        let n = match sample_count(n, "cc_diar_process") {
            Ok(n) => n,
            Err(e) => {
                set_last_error(e);
                return -1;
            }
        };
        let result =
            sys::SherpaOnnxOfflineSpeakerDiarizationProcess((*handle).diarizer, samples, n);
        if result.is_null() {
            set_last_error("diarization produced no result".into());
            return -1;
        }
        let count = sys::SherpaOnnxOfflineSpeakerDiarizationResultGetNumSegments(result);
        if count <= 0 {
            sys::SherpaOnnxOfflineSpeakerDiarizationDestroyResult(result);
            return 0;
        }
        let native = sys::SherpaOnnxOfflineSpeakerDiarizationResultSortByStartTime(result);
        if native.is_null() {
            sys::SherpaOnnxOfflineSpeakerDiarizationDestroyResult(result);
            set_last_error("diarization returned no segment array".into());
            return -1;
        }

        // Copy into our own allocation so ownership is simple and symmetric:
        // sherpa's array is freed here, ours is freed by
        // cc_diar_segments_destroy.
        let mut segments = Vec::with_capacity(count as usize);
        for i in 0..count as usize {
            let s = *native.add(i);
            segments.push(CcDiarSegment {
                start_s: s.start,
                end_s: s.end,
                speaker: s.speaker,
            });
        }
        sys::SherpaOnnxOfflineSpeakerDiarizationDestroySegment(native);
        sys::SherpaOnnxOfflineSpeakerDiarizationDestroyResult(result);

        let boxed = segments.into_boxed_slice();
        *out_count = boxed.len() as isize;
        *out_segments = Box::into_raw(boxed) as *mut CcDiarSegment;
        0
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_diar_process panicked".into());
        -1
    })
}

/// Frees a segment array from `cc_diar_process`. NULL-safe.
///
/// # Safety
/// `segments`/`count` must be exactly what `cc_diar_process` returned.
#[no_mangle]
pub unsafe extern "C" fn cc_diar_segments_destroy(segments: *mut CcDiarSegment, count: isize) {
    if segments.is_null() || count <= 0 {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| {
        drop(Box::from_raw(std::slice::from_raw_parts_mut(
            segments,
            count as usize,
        )));
    }));
}

/// Frees the diarizer and its models. NULL-safe.
///
/// # Safety
/// `handle` must come from `cc_diar_create` and not be used afterwards.
#[no_mangle]
pub unsafe extern "C" fn cc_diar_destroy(handle: *mut CcDiarizer) {
    if handle.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| drop(Box::from_raw(handle))));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creating_from_missing_models_fails_cleanly() {
        let seg = CString::new("/nonexistent/seg.onnx").unwrap();
        let emb = CString::new("/nonexistent/emb.onnx").unwrap();
        let handle = unsafe { cc_diar_create(seg.as_ptr(), emb.as_ptr(), 2, 0.5, 0.3, 0.5) };
        assert!(handle.is_null());
        assert!(!crate::cc_inference_last_error().is_null());
    }

    #[test]
    fn creating_with_null_paths_fails_cleanly() {
        let handle = unsafe { cc_diar_create(ptr::null(), ptr::null(), 2, 0.5, 0.3, 0.5) };
        assert!(handle.is_null());
    }

    #[test]
    fn processing_a_null_handle_returns_an_error() {
        let mut segments: *mut CcDiarSegment = ptr::null_mut();
        let mut count: isize = 0;
        let rc = unsafe {
            cc_diar_process(ptr::null_mut(), ptr::null(), 0, &mut segments, &mut count)
        };
        assert_eq!(rc, -1);
    }

    #[test]
    fn destroying_null_is_safe() {
        unsafe {
            cc_diar_destroy(ptr::null_mut());
            cc_diar_segments_destroy(ptr::null_mut(), 0);
            cc_diar_segments_destroy(ptr::null_mut(), 5);
        }
    }

    /// The struct Dart mirrors field-for-field; a layout change here silently
    /// corrupts every diarized span, so pin it.
    #[test]
    fn segment_layout_is_stable() {
        assert_eq!(std::mem::size_of::<CcDiarSegment>(), 12);
        assert_eq!(std::mem::align_of::<CcDiarSegment>(), 4);
    }
}

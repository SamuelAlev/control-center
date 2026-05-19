//! WeSpeaker speaker-embedding extraction over the sherpa-onnx C API.
//!
//! Produces the voiceprints behind the VoiceProfiles feature: one vector per
//! speaker cluster, matched across meetings by cosine similarity in
//! `voice_profile_matching.dart`.
//!
//! The vector is returned RAW. `meeting_diarization_service.dart` L2-normalizes
//! it in Dart, exactly as before — the stored profiles and the thresholds
//! (`kVoiceAutoApplyThreshold`, `kVoiceSuggestThreshold`) are calibrated against
//! that normalization, so it must not move here.

use std::ffi::{c_char, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;

use sherpa_onnx_sys::speaker_embedding as sys;

use crate::{clear_last_error, required_str, sample_count, set_last_error};

/// A loaded speaker-embedding extractor.
pub struct CcSpeakerEmbedder {
    extractor: *const sys::SpeakerEmbeddingExtractor,
}

unsafe impl Send for CcSpeakerEmbedder {}

impl Drop for CcSpeakerEmbedder {
    fn drop(&mut self) {
        unsafe { sys::SherpaOnnxDestroySpeakerEmbeddingExtractor(self.extractor) };
    }
}

/// Creates an extractor from the WeSpeaker model at `model_utf8`.
///
/// # Safety
/// `model_utf8` must be a valid NUL-terminated UTF-8 string.
#[no_mangle]
pub unsafe extern "C" fn cc_spk_create(
    model_utf8: *const c_char,
    num_threads: i32,
) -> *mut CcSpeakerEmbedder {
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
        let cpu = CString::new("cpu").unwrap();

        let mut config: sys::SpeakerEmbeddingExtractorConfig = std::mem::zeroed();
        config.model = model_c.as_ptr();
        config.num_threads = num_threads;
        config.debug = 0;
        config.provider = cpu.as_ptr();

        let extractor = sys::SherpaOnnxCreateSpeakerEmbeddingExtractor(&config);
        if extractor.is_null() {
            set_last_error("sherpa-onnx could not create the speaker embedding extractor".into());
            return ptr::null_mut();
        }
        Box::into_raw(Box::new(CcSpeakerEmbedder { extractor }))
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_spk_create panicked".into());
        ptr::null_mut()
    })
}

/// The embedding width this model produces (the buffer `cc_spk_compute` needs).
/// Returns -1 on a null handle.
///
/// # Safety
/// `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_spk_dim(handle: *const CcSpeakerEmbedder) -> i32 {
    if handle.is_null() {
        return -1;
    }
    catch_unwind(AssertUnwindSafe(|| {
        sys::SherpaOnnxSpeakerEmbeddingExtractorDim((*handle).extractor)
    }))
    .unwrap_or(-1)
}

/// Computes one voiceprint from `samples`, writing `cc_spk_dim` floats into
/// `out`.
///
/// Returns 0 on success, **1 when the audio is too short** for the model to
/// produce an embedding (the caller skips that speaker — not an error), and -1
/// on failure.
///
/// # Safety
/// `samples` must hold at least `n` floats; `out` must hold at least
/// `out_capacity` floats; `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_spk_compute(
    handle: *mut CcSpeakerEmbedder,
    samples: *const f32,
    n: isize,
    sample_rate: i32,
    out: *mut f32,
    out_capacity: isize,
) -> i32 {
    clear_last_error();
    catch_unwind(AssertUnwindSafe(|| {
        if handle.is_null() || samples.is_null() || out.is_null() {
            set_last_error("cc_spk_compute received a null pointer".into());
            return -1;
        }
        if n <= 0 {
            return 1;
        }
        let extractor = (*handle).extractor;
        let dim = sys::SherpaOnnxSpeakerEmbeddingExtractorDim(extractor);
        if dim <= 0 {
            set_last_error("speaker embedding model reports a non-positive dimension".into());
            return -1;
        }
        if dim as isize > out_capacity {
            set_last_error(format!(
                "output buffer holds {out_capacity} floats but the model produces {dim}"
            ));
            return -1;
        }

        let stream = sys::SherpaOnnxSpeakerEmbeddingExtractorCreateStream(extractor);
        if stream.is_null() {
            set_last_error("could not create a speaker embedding stream".into());
            return -1;
        }
        let n = match sample_count(n, "cc_spk_compute") {
            Ok(n) => n,
            Err(e) => {
                set_last_error(e);
                sherpa_onnx_sys::online_asr::SherpaOnnxDestroyOnlineStream(stream);
                return -1;
            }
        };
        sherpa_onnx_sys::online_asr::SherpaOnnxOnlineStreamAcceptWaveform(
            stream,
            sample_rate,
            samples,
            n,
        );
        sherpa_onnx_sys::online_asr::SherpaOnnxOnlineStreamInputFinished(stream);

        let outcome = if sys::SherpaOnnxSpeakerEmbeddingExtractorIsReady(extractor, stream) == 0 {
            // Not enough audio for a voiceprint. Expected on very short spans,
            // so it is a distinct return code rather than an error.
            1
        } else {
            let embedding = sys::SherpaOnnxSpeakerEmbeddingExtractorComputeEmbedding(extractor, stream);
            if embedding.is_null() {
                set_last_error("speaker embedding computation returned nothing".into());
                -1
            } else {
                ptr::copy_nonoverlapping(embedding, out, dim as usize);
                sys::SherpaOnnxSpeakerEmbeddingExtractorDestroyEmbedding(embedding);
                0
            }
        };
        sherpa_onnx_sys::online_asr::SherpaOnnxDestroyOnlineStream(stream);
        outcome
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_spk_compute panicked".into());
        -1
    })
}

/// Frees the extractor. NULL-safe.
///
/// # Safety
/// `handle` must come from `cc_spk_create` and not be used afterwards.
#[no_mangle]
pub unsafe extern "C" fn cc_spk_destroy(handle: *mut CcSpeakerEmbedder) {
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
        let path = CString::new("/nonexistent/wespeaker.onnx").unwrap();
        let handle = unsafe { cc_spk_create(path.as_ptr(), 2) };
        assert!(handle.is_null());
        assert!(!crate::cc_inference_last_error().is_null());
    }

    #[test]
    fn creating_from_a_null_model_fails_cleanly() {
        assert!(unsafe { cc_spk_create(ptr::null(), 2) }.is_null());
    }

    #[test]
    fn null_handle_operations_are_safe() {
        let mut out = [0f32; 4];
        unsafe {
            assert_eq!(cc_spk_dim(ptr::null()), -1);
            assert_eq!(
                cc_spk_compute(ptr::null_mut(), ptr::null(), 0, 16000, out.as_mut_ptr(), 4),
                -1
            );
            cc_spk_destroy(ptr::null_mut());
        }
    }
}

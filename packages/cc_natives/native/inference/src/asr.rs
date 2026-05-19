//! Offline speech recognition (Whisper + transducer) over the sherpa-onnx C API.
//!
//! Drives the recognizer for `sherpa_onnx_transcriber.dart`'s worker isolate:
//! build an `OfflineRecognizerConfig`, create a recognizer, then per window
//! create a stream → accept waveform → decode → read the text → free the
//! stream.
//!
//! ## Every `char*` must point at a real string
//!
//! sherpa's C++ side wraps incoming `const char*` config fields in
//! `std::string`, which dereferences them — a NULL is a crash, not a default.
//! [`Config`] therefore starts from a zeroed struct and points EVERY `char*` at
//! a shared empty string before the caller's values are applied.

use std::ffi::{c_char, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;

use sherpa_onnx_sys::offline_asr as sys;

use crate::{
    clear_last_error, into_c_string, optional_str, required_str, sample_count, set_last_error,
};

/// Threads per decode. We are off the UI thread on a worker isolate, so a few
/// threads keep each window's decode well under real time and stop a backlog
/// building when both meeting channels (mic + system audio) feed the
/// recognizer.
const DECODE_THREADS: i32 = 4;

/// Builds an `OfflineRecognizerConfig`.
///
/// The caller owns `owned`, the arena the config's strings live in: sherpa
/// copies them into C++ strings during create, but they must stay alive until
/// then. Pushing to that `Vec` never invalidates an earlier pointer — a
/// `CString`'s heap buffer does not move when the `Vec` reallocates.
struct Config {
    raw: sys::OfflineRecognizerConfig,
}

impl Config {
    /// Starts from a zeroed config with every `char*` pointing at `""` and the
    /// scalar defaults this app decodes with: greedy search, 16 kHz / 80
    /// features, 4 active paths, 1.5 hotwords score, no blank penalty.
    fn new(owned: &mut Vec<CString>) -> Self {
        owned.push(CString::new("").unwrap());
        let e = owned.last().unwrap().as_ptr();

        let mut raw: sys::OfflineRecognizerConfig = unsafe { std::mem::zeroed() };

        raw.feat_config.sample_rate = 16000;
        raw.feat_config.feature_dim = 80;

        let m = &mut raw.model_config;
        m.transducer.encoder = e;
        m.transducer.decoder = e;
        m.transducer.joiner = e;
        m.paraformer.model = e;
        m.nemo_ctc.model = e;
        m.whisper.encoder = e;
        m.whisper.decoder = e;
        m.whisper.language = e;
        m.whisper.task = e;
        m.tdnn.model = e;
        m.tokens = e;
        m.provider = e;
        m.model_type = e;
        m.modeling_unit = e;
        m.bpe_vocab = e;
        m.telespeech_ctc = e;
        m.sense_voice.model = e;
        m.sense_voice.language = e;
        m.moonshine.preprocessor = e;
        m.moonshine.encoder = e;
        m.moonshine.uncached_decoder = e;
        m.moonshine.cached_decoder = e;
        m.moonshine.merged_decoder = e;
        m.fire_red_asr.encoder = e;
        m.fire_red_asr.decoder = e;
        m.dolphin.model = e;
        m.zipformer_ctc.model = e;
        m.canary.encoder = e;
        m.canary.decoder = e;
        m.canary.src_lang = e;
        m.canary.tgt_lang = e;
        m.wenet_ctc.model = e;
        m.omnilingual.model = e;
        m.medasr.model = e;
        m.funasr_nano.encoder_adaptor = e;
        m.funasr_nano.llm = e;
        m.funasr_nano.embedding = e;
        m.funasr_nano.tokenizer = e;
        m.funasr_nano.system_prompt = e;
        m.funasr_nano.user_prompt = e;
        m.funasr_nano.language = e;
        m.funasr_nano.hotwords = e;
        m.fire_red_asr_ctc.model = e;
        m.qwen3_asr.conv_frontend = e;
        m.qwen3_asr.encoder = e;
        m.qwen3_asr.decoder = e;
        m.qwen3_asr.tokenizer = e;
        m.qwen3_asr.hotwords = e;
        m.cohere_transcribe.encoder = e;
        m.cohere_transcribe.decoder = e;
        m.cohere_transcribe.language = e;
        m.num_threads = DECODE_THREADS;
        m.debug = 0;

        raw.lm_config.model = e;
        raw.lm_config.scale = 1.0;
        raw.decoding_method = e;
        raw.max_active_paths = 4;
        raw.hotwords_file = e;
        raw.hotwords_score = 1.5;
        raw.rule_fsts = e;
        raw.rule_fars = e;
        raw.blank_penalty = 0.0;
        raw.hr.dict_dir = e;
        raw.hr.lexicon = e;
        raw.hr.rule_fsts = e;

        Self { raw }
    }
}

/// Interns `value` into `owned` and returns a pointer valid for its lifetime.
fn intern(owned: &mut Vec<CString>, value: &str) -> Result<*const c_char, String> {
    let s = CString::new(value).map_err(|_| format!("path contains a NUL byte: {value}"))?;
    owned.push(s);
    Ok(owned.last().unwrap().as_ptr())
}

/// A loaded offline recognizer.
pub struct CcAsr {
    recognizer: *const sys::OfflineRecognizer,
}

// The recognizer is created on, and used from, a single Dart isolate's thread;
// sherpa's own handle is internally synchronized for decode. Marking it Send
// lets the handle be stored in a Box that Dart moves between calls.
unsafe impl Send for CcAsr {}

impl CcAsr {
    fn create(config: &sys::OfflineRecognizerConfig) -> Result<Self, String> {
        let recognizer = unsafe { sys::SherpaOnnxCreateOfflineRecognizer(config) };
        if recognizer.is_null() {
            return Err(
                "sherpa-onnx could not create the recognizer (check the model files and tokens)"
                    .into(),
            );
        }
        Ok(Self { recognizer })
    }

    /// Decodes one window of 32-bit float samples in `[-1, 1]`.
    unsafe fn transcribe(&self, samples: *const f32, n: i32, sample_rate: i32) -> Result<String, String> {
        let stream = sys::SherpaOnnxCreateOfflineStream(self.recognizer);
        if stream.is_null() {
            return Err("sherpa-onnx could not create a decode stream".into());
        }
        sys::SherpaOnnxAcceptWaveformOffline(stream, sample_rate, samples, n);
        sys::SherpaOnnxDecodeOfflineStream(self.recognizer, stream);

        let json = sys::SherpaOnnxGetOfflineStreamResultAsJson(stream);
        let text = if json.is_null() {
            Err("recognizer returned no result".to_owned())
        } else {
            let raw = std::ffi::CStr::from_ptr(json).to_string_lossy().into_owned();
            sys::SherpaOnnxDestroyOfflineStreamResultJson(json);
            parse_text(&raw)
        };
        sys::SherpaOnnxDestroyOfflineStream(stream);
        text
    }
}

impl Drop for CcAsr {
    fn drop(&mut self) {
        unsafe { sys::SherpaOnnxDestroyOfflineRecognizer(self.recognizer) };
    }
}

/// Pulls `text` out of the recognizer's result JSON.
///
/// The JSON document (not the result struct) is the interface we bind to: it is
/// documented and stable, whereas the struct's field layout would have to be
/// mirrored by hand and re-checked on every sherpa bump.
fn parse_text(json: &str) -> Result<String, String> {
    let value: serde_json::Value =
        serde_json::from_str(json).map_err(|e| format!("malformed recognizer result: {e}"))?;
    match value.get("text").and_then(|t| t.as_str()) {
        Some(text) => Ok(text.trim().to_owned()),
        None => Err("recognizer result has no `text` field".into()),
    }
}

/// Creates a Whisper recognizer. `language` may be empty for auto-detection on
/// multilingual models ('en' pins english-only ones like base.en).
///
/// # Safety
/// All string arguments must be valid NUL-terminated UTF-8 (or NULL where
/// optional).
#[no_mangle]
pub unsafe extern "C" fn cc_asr_create_whisper(
    encoder: *const c_char,
    decoder: *const c_char,
    tokens: *const c_char,
    language: *const c_char,
) -> *mut CcAsr {
    clear_last_error();
    catch_unwind(AssertUnwindSafe(|| {
        match build_whisper(encoder, decoder, tokens, language) {
            Ok(asr) => Box::into_raw(Box::new(asr)),
            Err(e) => {
                set_last_error(e);
                ptr::null_mut()
            }
        }
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_asr_create_whisper panicked".into());
        ptr::null_mut()
    })
}

unsafe fn build_whisper(
    encoder: *const c_char,
    decoder: *const c_char,
    tokens: *const c_char,
    language: *const c_char,
) -> Result<CcAsr, String> {
    let mut owned = Vec::new();
    let mut config = Config::new(&mut owned);
    let m = &mut config.raw.model_config;
    m.whisper.encoder = intern(&mut owned, required_str(encoder, "encoder")?)?;
    m.whisper.decoder = intern(&mut owned, required_str(decoder, "decoder")?)?;
    // Empty language → Whisper auto-detects (multilingual models); 'en' pins
    // english-only models like base.en.
    m.whisper.language = intern(&mut owned, optional_str(language))?;
    m.whisper.task = intern(&mut owned, "transcribe")?;
    m.tokens = intern(&mut owned, required_str(tokens, "tokens")?)?;
    m.model_type = intern(&mut owned, "whisper")?;
    m.provider = intern(&mut owned, "cpu")?;
    config.raw.decoding_method = intern(&mut owned, "greedy_search")?;
    CcAsr::create(&config.raw)
}

/// Creates a transducer recognizer. `joiner` may be empty for models that have
/// none.
///
/// `model_type` is left EMPTY on purpose so sherpa-onnx auto-routes from the
/// encoder's own `model_type` metadata: NeMo Parakeet encoders
/// (`EncDecRNNTBPEModel` / `EncDecHybridRNNTCTCBPEModel`) take the NeMo
/// recognizer, while Zipformer/conformer encoders take the k2 one. Hardcoding
/// `"transducer"` forces the k2 path, whose decoder init reads `vocab_size`
/// from the *decoder* ONNX — which NeMo models carry on the *encoder* instead —
/// so it fails with `'vocab_size' does not exist in the metadata` and tears
/// down the recognizer for every Parakeet model.
///
/// # Safety
/// All string arguments must be valid NUL-terminated UTF-8 (or NULL where
/// optional).
#[no_mangle]
pub unsafe extern "C" fn cc_asr_create_transducer(
    encoder: *const c_char,
    decoder: *const c_char,
    joiner: *const c_char,
    tokens: *const c_char,
) -> *mut CcAsr {
    clear_last_error();
    catch_unwind(AssertUnwindSafe(|| {
        match build_transducer(encoder, decoder, joiner, tokens) {
            Ok(asr) => Box::into_raw(Box::new(asr)),
            Err(e) => {
                set_last_error(e);
                ptr::null_mut()
            }
        }
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_asr_create_transducer panicked".into());
        ptr::null_mut()
    })
}

unsafe fn build_transducer(
    encoder: *const c_char,
    decoder: *const c_char,
    joiner: *const c_char,
    tokens: *const c_char,
) -> Result<CcAsr, String> {
    let mut owned = Vec::new();
    let mut config = Config::new(&mut owned);
    let m = &mut config.raw.model_config;
    m.transducer.encoder = intern(&mut owned, required_str(encoder, "encoder")?)?;
    m.transducer.decoder = intern(&mut owned, required_str(decoder, "decoder")?)?;
    m.transducer.joiner = intern(&mut owned, optional_str(joiner))?;
    m.tokens = intern(&mut owned, required_str(tokens, "tokens")?)?;
    m.provider = intern(&mut owned, "cpu")?;
    // model_type stays "" — see the doc comment above for why.
    config.raw.decoding_method = intern(&mut owned, "greedy_search")?;
    CcAsr::create(&config.raw)
}

/// Decodes one window and returns its text as a malloc'd UTF-8 string the
/// caller frees with `cc_string_destroy`. NULL on failure.
///
/// # Safety
/// `samples` must hold at least `n` floats; `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_asr_transcribe(
    handle: *mut CcAsr,
    samples: *const f32,
    n: isize,
    sample_rate: i32,
) -> *mut c_char {
    clear_last_error();
    catch_unwind(AssertUnwindSafe(|| {
        if handle.is_null() || samples.is_null() {
            set_last_error("cc_asr_transcribe received a null pointer".into());
            return ptr::null_mut();
        }
        if n <= 0 {
            return into_c_string(String::new());
        }
        let n = match sample_count(n, "cc_asr_transcribe") {
            Ok(n) => n,
            Err(e) => {
                set_last_error(e);
                return ptr::null_mut();
            }
        };
        match (*handle).transcribe(samples, n, sample_rate) {
            Ok(text) => into_c_string(text),
            Err(e) => {
                set_last_error(e);
                ptr::null_mut()
            }
        }
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_asr_transcribe panicked".into());
        ptr::null_mut()
    })
}

/// Frees the recognizer and its model weights. NULL-safe.
///
/// # Safety
/// `handle` must come from a `cc_asr_create_*` and not be used afterwards.
#[no_mangle]
pub unsafe extern "C" fn cc_asr_destroy(handle: *mut CcAsr) {
    if handle.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| drop(Box::from_raw(handle))));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_text_from_a_result_document() {
        let json = r#"{"text": "  hello world  ", "tokens": ["a"], "timestamps": [0.1]}"#;
        assert_eq!(parse_text(json).unwrap(), "hello world");
    }

    #[test]
    fn parses_unicode_and_escapes() {
        let json = r#"{"text": "café \"quoted\"\nline"}"#;
        assert_eq!(parse_text(json).unwrap(), "café \"quoted\"\nline");
    }

    #[test]
    fn rejects_a_document_without_text() {
        assert!(parse_text(r#"{"tokens": []}"#).is_err());
        assert!(parse_text("not json").is_err());
    }

    /// Every `char*` in a fresh config must be non-NULL: sherpa dereferences
    /// them into `std::string`, so a zeroed field is a segfault, not a default.
    #[test]
    fn a_fresh_config_has_no_null_strings() {
        let mut owned = Vec::new();
        let config = Config::new(&mut owned);
        let m = &config.raw.model_config;
        for (name, ptr) in [
            ("transducer.encoder", m.transducer.encoder),
            ("transducer.decoder", m.transducer.decoder),
            ("transducer.joiner", m.transducer.joiner),
            ("whisper.encoder", m.whisper.encoder),
            ("whisper.language", m.whisper.language),
            ("whisper.task", m.whisper.task),
            ("tokens", m.tokens),
            ("provider", m.provider),
            ("model_type", m.model_type),
            ("modeling_unit", m.modeling_unit),
            ("bpe_vocab", m.bpe_vocab),
            ("telespeech_ctc", m.telespeech_ctc),
            ("paraformer.model", m.paraformer.model),
            ("nemo_ctc.model", m.nemo_ctc.model),
            ("tdnn.model", m.tdnn.model),
            ("sense_voice.model", m.sense_voice.model),
            ("moonshine.preprocessor", m.moonshine.preprocessor),
            ("canary.src_lang", m.canary.src_lang),
            ("qwen3_asr.tokenizer", m.qwen3_asr.tokenizer),
            ("funasr_nano.llm", m.funasr_nano.llm),
            ("cohere_transcribe.language", m.cohere_transcribe.language),
            ("decoding_method", config.raw.decoding_method),
            ("hotwords_file", config.raw.hotwords_file),
            ("rule_fsts", config.raw.rule_fsts),
            ("rule_fars", config.raw.rule_fars),
            ("lm_config.model", config.raw.lm_config.model),
            ("hr.dict_dir", config.raw.hr.dict_dir),
            ("hr.lexicon", config.raw.hr.lexicon),
            ("hr.rule_fsts", config.raw.hr.rule_fsts),
        ] {
            assert!(!ptr.is_null(), "{name} must not be NULL");
        }
    }

    /// Decoding defaults, pinned so a future edit cannot silently change
    /// transcription behaviour.
    #[test]
    fn config_scalar_defaults_are_pinned() {
        let mut owned = Vec::new();
        let config = Config::new(&mut owned);
        assert_eq!(config.raw.feat_config.sample_rate, 16000);
        assert_eq!(config.raw.feat_config.feature_dim, 80);
        assert_eq!(config.raw.max_active_paths, 4);
        assert_eq!(config.raw.hotwords_score, 1.5);
        assert_eq!(config.raw.blank_penalty, 0.0);
        assert_eq!(config.raw.model_config.num_threads, 4);
        assert_eq!(config.raw.model_config.debug, 0);
    }

    #[test]
    fn creating_with_null_paths_fails_cleanly() {
        let handle =
            unsafe { cc_asr_create_whisper(ptr::null(), ptr::null(), ptr::null(), ptr::null()) };
        assert!(handle.is_null());
        assert!(!crate::cc_inference_last_error().is_null());
    }

    #[test]
    fn destroying_null_is_safe() {
        unsafe { cc_asr_destroy(ptr::null_mut()) };
    }
}

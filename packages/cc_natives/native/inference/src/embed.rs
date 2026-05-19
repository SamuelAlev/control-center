//! BERT-style sentence embedder over the ONNX Runtime C API.
//!
//! The ONNX Runtime it calls is the one STATICALLY LINKED into this cdylib by
//! the sherpa-onnx prebuilt archive — the same runtime the speech side uses, so
//! the process holds exactly one.
//!
//! Scope is deliberately narrow: create a session from a model file, run it on
//! three int64 `[1, seq_len]` inputs, hand back `last_hidden_state` as f32.
//! Tokenization (`package:dart_wordpiece`) and pooling (attention-masked mean +
//! L2 normalization) stay in Dart — this owns the model graph, not the
//! arithmetic around it, which is what keeps vectors comparable with the ones
//! already in sqlite_vector.

use std::ffi::{c_char, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;
use std::sync::OnceLock;

use crate::ort_sys as ort;
use crate::{clear_last_error, required_str, set_last_error};

/// The ONNX Runtime API table, resolved once per process.
///
/// `GetApi(ORT_API_VERSION)` is the documented handshake. Statically linked,
/// header and object code come from the same 1.27.1 release, so this cannot
/// fail from version skew — but it is still checked, because a NULL here would
/// otherwise surface as a null-deref on the first call.
fn api() -> Result<&'static ort::OrtApi, String> {
    static API: OnceLock<usize> = OnceLock::new();
    let addr = *API.get_or_init(|| unsafe {
        let base = ort::OrtGetApiBase();
        if base.is_null() {
            return 0;
        }
        match (*base).GetApi {
            Some(get) => get(ort::ORT_API_VERSION) as usize,
            None => 0,
        }
    });
    if addr == 0 {
        return Err(format!(
            "ONNX Runtime rejected API version {} (statically linked runtime is too old)",
            ort::ORT_API_VERSION
        ));
    }
    Ok(unsafe { &*(addr as *const ort::OrtApi) })
}

/// Turns a non-NULL `OrtStatus` into an owned error string and releases it.
/// NULL status = success, which is the ONNX Runtime convention.
unsafe fn check(api: &ort::OrtApi, status: ort::OrtStatusPtr, context: &str) -> Result<(), String> {
    if status.is_null() {
        return Ok(());
    }
    let message = match api.GetErrorMessage {
        Some(get) => {
            let raw = get(status);
            if raw.is_null() {
                "unknown ONNX Runtime error".to_owned()
            } else {
                std::ffi::CStr::from_ptr(raw).to_string_lossy().into_owned()
            }
        }
        None => "unknown ONNX Runtime error".to_owned(),
    };
    if let Some(release) = api.ReleaseStatus {
        release(status);
    }
    Err(format!("{context}: {message}"))
}

/// The process-wide `OrtEnv`.
///
/// ONNX Runtime hands back the SAME environment for every `CreateEnv` call and
/// ignores later arguments, so releasing one embedder's env would pull it out
/// from under every other live session. It is therefore created once and
/// deliberately never released — one env for the life of the process.
fn env() -> Result<*mut ort::OrtEnv, String> {
    static ENV: OnceLock<usize> = OnceLock::new();
    let addr = *ENV.get_or_init(|| {
        let Ok(api) = api() else { return 0 };
        let mut out: *mut ort::OrtEnv = ptr::null_mut();
        let name = CString::new("cc_inference").unwrap();
        unsafe {
            let Some(create) = api.CreateEnv else { return 0 };
            let status = create(
                ort::OrtLoggingLevel::ORT_LOGGING_LEVEL_WARNING,
                name.as_ptr(),
                &mut out,
            );
            if check(api, status, "CreateEnv").is_err() {
                return 0;
            }
        }
        out as usize
    });
    if addr == 0 {
        return Err("failed to create the ONNX Runtime environment".to_owned());
    }
    Ok(addr as *mut ort::OrtEnv)
}

/// Encodes a model path the way `CreateSession` wants it on this platform.
///
/// The C parameter is `const ORTCHAR_T*`: `char*` on Unix, but `wchar_t*` on
/// Windows. The committed bindings were generated on macOS, so the field is
/// typed `*const c_char` there; on Windows we build a UTF-16 buffer and cast
/// the pointer, which is ABI-identical and what the runtime actually reads.
#[cfg(windows)]
struct ModelPath(Vec<u16>);
#[cfg(not(windows))]
struct ModelPath(CString);

impl ModelPath {
    #[cfg(windows)]
    fn new(path: &str) -> Result<Self, String> {
        use std::os::windows::ffi::OsStrExt;
        let mut wide: Vec<u16> = std::ffi::OsStr::new(path).encode_wide().collect();
        wide.push(0);
        Ok(Self(wide))
    }

    #[cfg(not(windows))]
    fn new(path: &str) -> Result<Self, String> {
        CString::new(path)
            .map(Self)
            .map_err(|_| "model path contains a NUL byte".to_owned())
    }

    fn as_ptr(&self) -> *const c_char {
        self.0.as_ptr() as *const c_char
    }
}

/// A loaded embedding model: the session plus the input/output names the model
/// actually declares.
pub struct CcEmbedder {
    api: &'static ort::OrtApi,
    session: *mut ort::OrtSession,
    session_options: *mut ort::OrtSessionOptions,
    memory_info: *mut ort::OrtMemoryInfo,
    /// Input names in the model's own order. Discovered rather than hardcoded:
    /// MiniLM is exported both with and without `token_type_ids` and feeding
    /// an input the graph does not declare is an error.
    input_names: Vec<CString>,
    /// The first output name (`last_hidden_state` for every sentence-transformer
    /// export we ship, but read from the model rather than assumed).
    output_name: CString,
}

impl CcEmbedder {
    fn open(model_path: &str, num_threads: i32) -> Result<Self, String> {
        let api = api()?;
        let env = env()?;
        let path = ModelPath::new(model_path)?;

        unsafe {
            let mut session_options: *mut ort::OrtSessionOptions = ptr::null_mut();
            check(
                api,
                (api.CreateSessionOptions.ok_or("CreateSessionOptions missing")?)(
                    &mut session_options,
                ),
                "CreateSessionOptions",
            )?;
            // Guard rails: from here on every early return must release what we
            // have already built, so failures cannot leak a session.
            let cleanup = |so: *mut ort::OrtSessionOptions,
                           s: *mut ort::OrtSession,
                           mi: *mut ort::OrtMemoryInfo| {
                if let (Some(r), false) = (api.ReleaseSessionOptions, so.is_null()) {
                    r(so)
                }
                if let (Some(r), false) = (api.ReleaseSession, s.is_null()) {
                    r(s)
                }
                if let (Some(r), false) = (api.ReleaseMemoryInfo, mi.is_null()) {
                    r(mi)
                }
            };

            if num_threads > 0 {
                if let Some(set) = api.SetIntraOpNumThreads {
                    let status = set(session_options, num_threads);
                    if let Err(e) = check(api, status, "SetIntraOpNumThreads") {
                        cleanup(session_options, ptr::null_mut(), ptr::null_mut());
                        return Err(e);
                    }
                }
            }

            let mut session: *mut ort::OrtSession = ptr::null_mut();
            let create_session = match api.CreateSession {
                Some(f) => f,
                None => {
                    cleanup(session_options, ptr::null_mut(), ptr::null_mut());
                    return Err("CreateSession missing".into());
                }
            };
            let status = create_session(env, path.as_ptr(), session_options, &mut session);
            if let Err(e) = check(api, status, "CreateSession") {
                cleanup(session_options, ptr::null_mut(), ptr::null_mut());
                return Err(e);
            }

            let mut memory_info: *mut ort::OrtMemoryInfo = ptr::null_mut();
            let status = (match api.CreateCpuMemoryInfo {
                Some(f) => f,
                None => {
                    cleanup(session_options, session, ptr::null_mut());
                    return Err("CreateCpuMemoryInfo missing".into());
                }
            })(
                ort::OrtAllocatorType::OrtArenaAllocator,
                ort::OrtMemType::OrtMemTypeDefault,
                &mut memory_info,
            );
            if let Err(e) = check(api, status, "CreateCpuMemoryInfo") {
                cleanup(session_options, session, ptr::null_mut());
                return Err(e);
            }

            match Self::read_io_names(api, session) {
                Ok((input_names, output_name)) => Ok(Self {
                    api,
                    session,
                    session_options,
                    memory_info,
                    input_names,
                    output_name,
                }),
                Err(e) => {
                    cleanup(session_options, session, memory_info);
                    Err(e)
                }
            }
        }
    }

    /// Reads the model's declared input names and its first output name, using
    /// the default allocator (whose strings we must hand back to it).
    unsafe fn read_io_names(
        api: &ort::OrtApi,
        session: *mut ort::OrtSession,
    ) -> Result<(Vec<CString>, CString), String> {
        let mut allocator: *mut ort::OrtAllocator = ptr::null_mut();
        check(
            api,
            (api.GetAllocatorWithDefaultOptions
                .ok_or("GetAllocatorWithDefaultOptions missing")?)(&mut allocator),
            "GetAllocatorWithDefaultOptions",
        )?;
        let free = api.AllocatorFree.ok_or("AllocatorFree missing")?;

        let take = |raw: *mut c_char| -> CString {
            let owned = std::ffi::CStr::from_ptr(raw).to_owned();
            free(allocator, raw as *mut std::ffi::c_void);
            owned
        };

        let mut input_count: usize = 0;
        check(
            api,
            (api.SessionGetInputCount.ok_or("SessionGetInputCount missing")?)(
                session,
                &mut input_count,
            ),
            "SessionGetInputCount",
        )?;
        if input_count == 0 {
            return Err("model declares no inputs".into());
        }
        let get_input_name = api.SessionGetInputName.ok_or("SessionGetInputName missing")?;
        let mut input_names = Vec::with_capacity(input_count);
        for index in 0..input_count {
            let mut raw: *mut c_char = ptr::null_mut();
            check(
                api,
                get_input_name(session, index, allocator, &mut raw),
                "SessionGetInputName",
            )?;
            input_names.push(take(raw));
        }

        let mut output_count: usize = 0;
        check(
            api,
            (api
                .SessionGetOutputCount
                .ok_or("SessionGetOutputCount missing")?)(session, &mut output_count),
            "SessionGetOutputCount",
        )?;
        if output_count == 0 {
            return Err("model declares no outputs".into());
        }
        let mut raw: *mut c_char = ptr::null_mut();
        check(
            api,
            (api
                .SessionGetOutputName
                .ok_or("SessionGetOutputName missing")?)(session, 0, allocator, &mut raw),
            "SessionGetOutputName",
        )?;
        let output_name = take(raw);

        Ok((input_names, output_name))
    }

    /// Runs the encoder over one sequence and copies `last_hidden_state` into
    /// `out`, returning the hidden size.
    unsafe fn run(
        &self,
        input_ids: *const i64,
        attention_mask: *const i64,
        token_type_ids: *const i64,
        seq_len: usize,
        out: *mut f32,
        out_capacity: usize,
    ) -> Result<i32, String> {
        let api = self.api;
        let shape: [i64; 2] = [1, seq_len as i64];
        let byte_len = seq_len * std::mem::size_of::<i64>();

        let create_tensor = api
            .CreateTensorWithDataAsOrtValue
            .ok_or("CreateTensorWithDataAsOrtValue missing")?;
        let release_value = api.ReleaseValue.ok_or("ReleaseValue missing")?;

        // Build one tensor per input the MODEL declares, in the model's order.
        let mut tensors: Vec<*mut ort::OrtValue> = Vec::with_capacity(self.input_names.len());
        let mut name_ptrs: Vec<*const c_char> = Vec::with_capacity(self.input_names.len());
        let mut build = || -> Result<(), String> {
            for name in &self.input_names {
                let data = match name.to_bytes() {
                    b"input_ids" => input_ids,
                    b"attention_mask" => attention_mask,
                    b"token_type_ids" => token_type_ids,
                    other => {
                        return Err(format!(
                            "model declares an input this embedder cannot supply: {}",
                            String::from_utf8_lossy(other)
                        ))
                    }
                };
                let mut tensor: *mut ort::OrtValue = ptr::null_mut();
                check(
                    api,
                    create_tensor(
                        self.memory_info,
                        data as *mut std::ffi::c_void,
                        byte_len,
                        shape.as_ptr(),
                        shape.len(),
                        ort::ONNXTensorElementDataType::ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64,
                        &mut tensor,
                    ),
                    "CreateTensorWithDataAsOrtValue",
                )?;
                tensors.push(tensor);
                name_ptrs.push(name.as_ptr());
            }
            Ok(())
        };
        let built = build();
        let release_all = |tensors: &[*mut ort::OrtValue]| {
            for t in tensors {
                if !t.is_null() {
                    release_value(*t);
                }
            }
        };
        if let Err(e) = built {
            release_all(&tensors);
            return Err(e);
        }

        let output_names = [self.output_name.as_ptr()];
        let mut output: *mut ort::OrtValue = ptr::null_mut();
        let run = match api.Run {
            Some(f) => f,
            None => {
                release_all(&tensors);
                return Err("Run missing".into());
            }
        };
        let status = run(
            self.session,
            ptr::null(),
            name_ptrs.as_ptr(),
            tensors.as_ptr() as *const *const ort::OrtValue,
            tensors.len(),
            output_names.as_ptr(),
            1,
            &mut output,
        );
        release_all(&tensors);
        check(api, status, "Run")?;
        if output.is_null() {
            return Err("session returned no output tensor".into());
        }

        let result = self.copy_hidden_state(output, seq_len, out, out_capacity);
        release_value(output);
        result
    }

    /// Validates the output tensor's shape against the sequence we fed and the
    /// buffer Dart allocated, then copies it out.
    unsafe fn copy_hidden_state(
        &self,
        output: *mut ort::OrtValue,
        seq_len: usize,
        out: *mut f32,
        out_capacity: usize,
    ) -> Result<i32, String> {
        let api = self.api;
        let mut info: *mut ort::OrtTensorTypeAndShapeInfo = ptr::null_mut();
        check(
            api,
            (api
                .GetTensorTypeAndShape
                .ok_or("GetTensorTypeAndShape missing")?)(output, &mut info),
            "GetTensorTypeAndShape",
        )?;
        let release_info = api.ReleaseTensorTypeAndShapeInfo;
        let finish = |info: *mut ort::OrtTensorTypeAndShapeInfo| {
            if let (Some(r), false) = (release_info, info.is_null()) {
                r(info)
            }
        };

        let mut rank: usize = 0;
        if let Err(e) = check(
            api,
            (match api.GetDimensionsCount {
                Some(f) => f,
                None => {
                    finish(info);
                    return Err("GetDimensionsCount missing".into());
                }
            })(info, &mut rank),
            "GetDimensionsCount",
        ) {
            finish(info);
            return Err(e);
        }
        if rank != 3 {
            finish(info);
            return Err(format!(
                "expected a [batch, seq, hidden] output, got a rank-{rank} tensor"
            ));
        }
        let mut dims = [0i64; 3];
        if let Err(e) = check(
            api,
            (match api.GetDimensions {
                Some(f) => f,
                None => {
                    finish(info);
                    return Err("GetDimensions missing".into());
                }
            })(info, dims.as_mut_ptr(), 3),
            "GetDimensions",
        ) {
            finish(info);
            return Err(e);
        }
        finish(info);

        if dims[0] != 1 || dims[1] != seq_len as i64 || dims[2] <= 0 {
            return Err(format!(
                "unexpected output shape [{}, {}, {}] for a sequence of {seq_len}",
                dims[0], dims[1], dims[2]
            ));
        }
        let hidden = dims[2] as usize;
        let total = seq_len * hidden;
        if total > out_capacity {
            return Err(format!(
                "output buffer holds {out_capacity} floats but the model produced {total}"
            ));
        }

        let mut data: *mut std::ffi::c_void = ptr::null_mut();
        check(
            api,
            (api
                .GetTensorMutableData
                .ok_or("GetTensorMutableData missing")?)(output, &mut data),
            "GetTensorMutableData",
        )?;
        if data.is_null() {
            return Err("output tensor has no data".into());
        }
        ptr::copy_nonoverlapping(data as *const f32, out, total);
        Ok(hidden as i32)
    }
}

impl Drop for CcEmbedder {
    fn drop(&mut self) {
        unsafe {
            if let Some(release) = self.api.ReleaseSession {
                release(self.session);
            }
            if let Some(release) = self.api.ReleaseSessionOptions {
                release(self.session_options);
            }
            if let Some(release) = self.api.ReleaseMemoryInfo {
                release(self.memory_info);
            }
        }
    }
}

/// Loads the ONNX model at `model_path_utf8`. `num_threads` <= 0 leaves the
/// runtime's own intra-op default. Returns NULL on failure (see
/// `cc_inference_last_error`).
///
/// # Safety
/// `model_path_utf8` must be a valid NUL-terminated UTF-8 string.
#[no_mangle]
pub unsafe extern "C" fn cc_embedder_create(
    model_path_utf8: *const c_char,
    num_threads: i32,
) -> *mut CcEmbedder {
    clear_last_error();
    catch_unwind(AssertUnwindSafe(|| {
        let path = match required_str(model_path_utf8, "model_path") {
            Ok(p) => p,
            Err(e) => {
                set_last_error(e);
                return ptr::null_mut();
            }
        };
        match CcEmbedder::open(path, num_threads) {
            Ok(embedder) => Box::into_raw(Box::new(embedder)),
            Err(e) => {
                set_last_error(e);
                ptr::null_mut()
            }
        }
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_embedder_create panicked".into());
        ptr::null_mut()
    })
}

/// Runs the encoder over one tokenized sequence.
///
/// Writes `seq_len * hidden` floats of `last_hidden_state` into `out_hidden`
/// (row-major, one row per token) and reports `hidden` through
/// `out_hidden_size`. Returns 0 on success, -1 on failure.
///
/// Pooling is the CALLER's job — this returns per-token vectors, exactly as the
/// runtime produced them.
///
/// # Safety
/// The three id arrays must each hold at least `seq_len` `int64`s; `out_hidden`
/// must hold at least `out_capacity` floats; `handle` must be live.
#[no_mangle]
pub unsafe extern "C" fn cc_embedder_run(
    handle: *mut CcEmbedder,
    input_ids: *const i64,
    attention_mask: *const i64,
    token_type_ids: *const i64,
    seq_len: isize,
    out_hidden: *mut f32,
    out_capacity: isize,
    out_hidden_size: *mut i32,
) -> i32 {
    clear_last_error();
    catch_unwind(AssertUnwindSafe(|| {
        if handle.is_null() || out_hidden.is_null() || out_hidden_size.is_null() {
            set_last_error("cc_embedder_run received a null pointer".into());
            return -1;
        }
        if input_ids.is_null() || attention_mask.is_null() || token_type_ids.is_null() {
            set_last_error("cc_embedder_run received a null input array".into());
            return -1;
        }
        if seq_len <= 0 || out_capacity <= 0 {
            set_last_error("cc_embedder_run needs a positive seq_len and capacity".into());
            return -1;
        }
        match (*handle).run(
            input_ids,
            attention_mask,
            token_type_ids,
            seq_len as usize,
            out_hidden,
            out_capacity as usize,
        ) {
            Ok(hidden) => {
                *out_hidden_size = hidden;
                0
            }
            Err(e) => {
                set_last_error(e);
                -1
            }
        }
    }))
    .unwrap_or_else(|_| {
        set_last_error("cc_embedder_run panicked".into());
        -1
    })
}

/// Frees the session. NULL-safe.
///
/// # Safety
/// `handle` must come from `cc_embedder_create` and not be used afterwards.
#[no_mangle]
pub unsafe extern "C" fn cc_embedder_destroy(handle: *mut CcEmbedder) {
    if handle.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| drop(Box::from_raw(handle))));
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The statically linked runtime must accept the header version we were
    /// generated from. If this fails, `src/ort_sys.rs` and the archive pinned
    /// in native_pins.env have drifted apart.
    #[test]
    fn ort_api_table_resolves() {
        let api = api().expect("statically linked ONNX Runtime must serve its own API version");
        assert!(api.CreateSession.is_some());
        assert!(api.Run.is_some());
    }

    #[test]
    fn creating_from_a_missing_model_fails_cleanly() {
        let path = CString::new("/nonexistent/model.onnx").unwrap();
        let handle = unsafe { cc_embedder_create(path.as_ptr(), 1) };
        assert!(handle.is_null());
        assert!(!crate::cc_inference_last_error().is_null());
    }

    #[test]
    fn creating_from_a_null_path_fails_cleanly() {
        let handle = unsafe { cc_embedder_create(ptr::null(), 1) };
        assert!(handle.is_null());
    }

    #[test]
    fn running_a_null_handle_returns_an_error() {
        let mut hidden = 0i32;
        let mut out = [0f32; 4];
        let rc = unsafe {
            cc_embedder_run(
                ptr::null_mut(),
                ptr::null(),
                ptr::null(),
                ptr::null(),
                1,
                out.as_mut_ptr(),
                4,
                &mut hidden,
            )
        };
        assert_eq!(rc, -1);
    }

    #[test]
    fn destroying_null_is_safe() {
        unsafe { cc_embedder_destroy(ptr::null_mut()) };
    }
}

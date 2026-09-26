# cc_inference

One native library and one statically linked ONNX Runtime behind [`cc_inference.h`](cc_inference.h). Sherpa-onnx handles offline ASR (Whisper/transducer), Silero VAD and speaker diarization/voiceprints; the ONNX Runtime C API handles 384-dimensional MiniLM sentence embeddings. Build from the repo root with `scripts/natives/build_inference.sh`. [PROVENANCE.md](PROVENANCE.md) records upstream versions, licenses, checksum pins and the binding regeneration procedure.

## Native boundary

- Tokenization (`dart_wordpiece`), attention-masked pooling, L2 normalization and PCM16 conversion stay in Dart; the native owns model execution. `embedding_equivalence_test.dart` pins stored vector compatibility.
- Initialize **every** sherpa `char*` config field to a real string, including unused fields: the C++ side constructs `std::string` from them and NULL would crash.
- `build.rs` restricts exports to `cc_*`, and the build script checks symbols with `nm`; leaking `OrtGetApiBase` or `SherpaOnnx*` could cause global-loader symbol interposition. Do not ship separate ONNX Runtime dylibs.
- Every `extern "C"` body catches panics, returning NULL/-1 and `cc_inference_last_error()`.

`inference_library.dart` resolves the path by **file stat**, not `DynamicLibrary.open`: probing a large sherpa-linked dylib by opening it can hang a JIT Dart host. The actual load happens lazily in the worker isolate, and failure reports `init_error`. Dart statics are isolate-local, so each isolate opens the resolved path supplied in its init message.

`cargo test` checks ABI/header agreement, config defaults and NULL/error paths. Model-dependent behavior is covered by Dart tests with installed models.

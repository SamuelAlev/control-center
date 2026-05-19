# cc_inference

Control Center's on-device inference native: **one** dylib, **one** ONNX
Runtime, covering both ML workloads behind the C ABI in `cc_inference.h`.

| Workload | Engine | Dart consumer |
|---|---|---|
| Offline ASR (Whisper + transducer) | sherpa-onnx | `SherpaOnnxTranscriber` |
| Silero VAD (streaming + offline) | sherpa-onnx | `SileroVadDetector`, `MeetingOfflineVad` |
| Speaker diarization (pyannote + WeSpeaker + clustering) | sherpa-onnx | `MeetingDiarizationService` |
| Speaker embeddings (voiceprints) | sherpa-onnx | `MeetingDiarizationService` |
| Sentence embeddings (MiniLM, 384-d) | ONNX Runtime C API | `TextEmbedder` |

Built by `scripts/natives/build_inference.sh`. See `PROVENANCE.md` for what is
statically linked, how it is pinned, and how to regenerate `src/ort_sys.rs`.

## One library, one runtime

Both workloads share a single statically linked ONNX Runtime, so the shipped
artifact is self-contained: no loader-path search, no version skew between the
generated headers and the runtime they call, and no chance of two runtimes
colliding by base name inside one process (which is how Windows resolves a DLL
dependency).

## Design rules

**The arithmetic stays in Dart.** Tokenization (`package:dart_wordpiece`),
attention-masked mean pooling, L2 normalization and PCM16 conversion all live on
the Dart side. This crate owns the model graph, not the math around it — which
is what keeps embeddings comparable with what is already stored in
sqlite_vector, pinned bit-for-bit by `embedding_equivalence_test.dart`.

**Every `char*` in a sherpa config must point at a real string.** sherpa's C++
side wraps them in `std::string`, so a NULL is a segfault, not a default. `asr.rs`
starts from a zeroed struct and points *every* field at `""` before applying the
caller's values; a test asserts none is NULL.

**Nothing leaks out of the dylib.** `build.rs` restricts exports to `cc_*`
(macOS `-exported_symbol`, Linux version script), and the build script asserts
with `nm` that no `OrtGetApiBase`/`SherpaOnnx*` symbol escapes. On Linux the
loader resolves symbols globally, first-loaded-wins, so an exported runtime
symbol could interpose on — or be interposed by — another ONNX Runtime in the
process.

**Panics never cross the boundary.** Every `extern "C"` body is wrapped in
`catch_unwind`; a panic becomes a NULL/-1 return plus `cc_inference_last_error()`.

## Loading

Resolution is a **file stat**, never a `DynamicLibrary.open`
(`inference_library.dart`). Probing by open risks hanging a JIT Dart host at
boot — `dlopen` of a large sherpa-linked dylib has been measured wedging
indefinitely under `dart run` / `dart test` while taking milliseconds under AOT.
The real load happens lazily on the worker isolate that needs it, where a
failure surfaces as an actionable `init_error`.

Bindings are **per-isolate** — Dart statics do not cross isolate boundaries, so
each isolate opens the dylib for itself (cheap; dyld returns the already-mapped
image). Worker isolates are handed the resolved path explicitly in their `init`
message.

## Tests

`cargo test` covers the ABI/header agreement, the config defaults ported from the
Dart package, error paths, and NULL-safety. Model-dependent behaviour is covered
on the Dart side, where the models actually live.

/* cc_inference — Control Center's native inference leaf.
 *
 * ONE cdylib covering both on-device ML workloads, over ONE statically linked
 * ONNX Runtime:
 *   * speech — offline ASR (Whisper + transducer), Silero VAD, pyannote
 *     diarization, WeSpeaker voiceprints (sherpa-onnx);
 *   * text  — BERT sentence embeddings for semantic search (ONNX Runtime).
 *
 * The C ABI contract mirrored 1:1 by
 * packages/cc_natives/lib/src/inference/cc_inference_bindings.dart.
 * Bump CC_INFERENCE_ABI_VERSION on ANY change to these signatures or structs;
 * the Dart side refuses to bind on a mismatch rather than misreading memory.
 *
 * Conventions throughout:
 *   * Handles are opaque; every create has a NULL-safe destroy.
 *   * A NULL / -1 return means failure — call cc_inference_last_error().
 *   * Strings returned by this library are freed with cc_string_destroy.
 *   * Audio is 32-bit float mono in [-1, 1]; PCM16 conversion stays in Dart.
 *   * Pooling, L2 normalization and per-speaker chunking stay in Dart, so the
 *     arithmetic behind stored vectors is unchanged by this boundary.
 */
#ifndef CC_INFERENCE_H
#define CC_INFERENCE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CC_INFERENCE_ABI_VERSION 1u

/* The ABI version this library speaks. */
uint32_t cc_inference_abi_version(void);

/* Thread-local message describing the most recent failure on this thread;
 * NULL when none. Owned by the library; valid until the next failing call on
 * the same thread. */
const char* cc_inference_last_error(void);

/* Frees a string this library returned (e.g. cc_asr_transcribe). NULL-safe. */
void cc_string_destroy(char* s);

/* ── Text embedder ─────────────────────────────────────────────────────────
 * BERT-style sentence-transformer encoder (all-MiniLM-L6-v2, 384-d).
 * Tokenization stays in Dart (package:dart_wordpiece), as does the
 * attention-masked mean pooling + L2 normalization applied to the output. */

typedef struct CcEmbedder CcEmbedder;

/* Loads the ONNX model at `model_path_utf8`. `num_threads` <= 0 leaves the
 * runtime's own intra-op default. NULL on failure. */
CcEmbedder* cc_embedder_create(const char* model_path_utf8, int32_t num_threads);

/* Runs the encoder over one tokenized sequence of `seq_len` tokens.
 *
 * Writes `seq_len * hidden` floats of last_hidden_state into `out_hidden`
 * (row-major, one row per token) and reports `hidden` via `out_hidden_size`.
 * `out_capacity` is the float capacity of `out_hidden`; a model whose output
 * would not fit is an error rather than an overflow. Inputs the model does not
 * declare are skipped, so both the 2- and 3-input MiniLM exports work.
 * Returns 0 on success, -1 on failure. */
int32_t cc_embedder_run(CcEmbedder* handle,
                        const int64_t* input_ids,
                        const int64_t* attention_mask,
                        const int64_t* token_type_ids,
                        intptr_t seq_len,
                        float* out_hidden,
                        intptr_t out_capacity,
                        int32_t* out_hidden_size);

void cc_embedder_destroy(CcEmbedder* handle);

/* ── Offline ASR ───────────────────────────────────────────────────────────*/

typedef struct CcAsr CcAsr;

/* Whisper. `language` may be "" for auto-detection on multilingual models
 * ('en' pins english-only ones like base.en). */
CcAsr* cc_asr_create_whisper(const char* encoder,
                             const char* decoder,
                             const char* tokens,
                             const char* language);

/* Transducer. `joiner` may be "" for models without one.
 *
 * model_type is deliberately left EMPTY so sherpa-onnx auto-routes on the
 * encoder's own metadata: NeMo Parakeet encoders take the NeMo recognizer,
 * Zipformer/conformer encoders take the k2 one. Forcing "transducer" sends
 * NeMo models down the k2 path, which reads `vocab_size` from the decoder ONNX
 * (NeMo carries it on the encoder) and fails at init. */
CcAsr* cc_asr_create_transducer(const char* encoder,
                                const char* decoder,
                                const char* joiner,
                                const char* tokens);

/* Decodes one window; returns malloc'd UTF-8 to free with cc_string_destroy,
 * or NULL on failure. An empty window yields "" rather than an error. */
char* cc_asr_transcribe(CcAsr* handle,
                        const float* samples,
                        intptr_t n,
                        int32_t sample_rate);

/* Frees the recognizer and its (hundreds of MB of) weights. NULL-safe. */
void cc_asr_destroy(CcAsr* handle);

/* ── Silero VAD ────────────────────────────────────────────────────────────
 * Serves both the streaming detector and the offline span scanner. */

typedef struct CcVad CcVad;

CcVad* cc_vad_create(const char* model_utf8,
                     float threshold,
                     float min_silence_s,
                     float min_speech_s,
                     int32_t sample_rate,
                     float buffer_size_s);

void    cc_vad_accept(CcVad* handle, const float* samples, intptr_t n);
int32_t cc_vad_is_detected(const CcVad* handle);
int32_t cc_vad_is_empty(const CcVad* handle);

/* Reads the queued segment's sample range; 1 = read, 0 = queue empty. Only the
 * range crosses the boundary — the caller converts it to milliseconds and never
 * needs the samples themselves. */
int32_t cc_vad_front(const CcVad* handle, int32_t* out_start, int32_t* out_len);

void cc_vad_pop(CcVad* handle);
void cc_vad_clear(CcVad* handle);
void cc_vad_flush(CcVad* handle);
void cc_vad_destroy(CcVad* handle);

/* ── Speaker diarization ───────────────────────────────────────────────────*/

/* One diarized span, in seconds. */
typedef struct {
  float   start_s;
  float   end_s;
  int32_t speaker;
} CcDiarSegment;

typedef struct CcDiarizer CcDiarizer;

/* num_clusters is fixed at -1 (infer the speaker count from the audio via
 * `clustering_threshold`) — the count is never known ahead of time. */
CcDiarizer* cc_diar_create(const char* segmentation_model,
                           const char* embedding_model,
                           int32_t num_threads,
                           float clustering_threshold,
                           float min_duration_on_s,
                           float min_duration_off_s);

/* Diarizes a complete 16 kHz mono recording. On success writes a library-owned
 * array + its length and returns 0; free it with cc_diar_segments_destroy.
 * No detected speech is success with count 0 and a NULL array. -1 on failure. */
int32_t cc_diar_process(CcDiarizer* handle,
                        const float* samples,
                        intptr_t n,
                        CcDiarSegment** out_segments,
                        intptr_t* out_count);

void cc_diar_segments_destroy(CcDiarSegment* segments, intptr_t count);
void cc_diar_destroy(CcDiarizer* handle);

/* ── Speaker embeddings (voiceprints) ──────────────────────────────────────*/

typedef struct CcSpeakerEmbedder CcSpeakerEmbedder;

CcSpeakerEmbedder* cc_spk_create(const char* model_utf8, int32_t num_threads);

/* The embedding width this model produces; -1 on a null handle. */
int32_t cc_spk_dim(const CcSpeakerEmbedder* handle);

/* Computes one voiceprint into `out` (cc_spk_dim floats, `out_capacity` is its
 * capacity). Returns 0 on success, 1 when the audio is too short to embed (the
 * caller skips that speaker — not an error), -1 on failure. The vector is NOT
 * normalized; the caller's L2 normalization is what stored profiles and the
 * match thresholds are calibrated against. */
int32_t cc_spk_compute(CcSpeakerEmbedder* handle,
                       const float* samples,
                       intptr_t n,
                       int32_t sample_rate,
                       float* out,
                       intptr_t out_capacity);

void cc_spk_destroy(CcSpeakerEmbedder* handle);

#ifdef __cplusplus
}
#endif

#endif /* CC_INFERENCE_H */

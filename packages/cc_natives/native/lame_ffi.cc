// Tiny C ABI over libmp3lame (LAME), built into liblame_ffi and loaded by the
// app / cc_server via dart:ffi (see
// packages/cc_natives/lib/src/audio/lame/lame_ffi_bindings.dart).
//
// Control Center records meetings and captures agent/session audio as raw
// interleaved PCM16; shipping that off-device or persisting it is wasteful
// (~1.4 Mbit/s per stereo 48 kHz stream). This shim wraps LAME's streaming
// encoder so we can turn those PCM blocks into a frame-aligned MP3 byte stream
// incrementally (encode chunk → append bytes → flush at end) without pulling a
// Flutter plugin or an ffmpeg dependency into the pure-Dart server binary.
//
// libmp3lame provenance: LAME 3.100 (the last upstream release), LGPL-2.1. It
// is NOT vendored into this repo — scripts/natives/build_lame.sh either links
// this shim against a system libmp3lame (Homebrew `lame`, apt `libmp3lame-dev`)
// or downloads + builds the 3.100 source, statically linking the resulting
// libmp3lame.a into liblame_ffi so the dylib is self-contained and embeddable.
// The core MP3 patents expired in 2017, so distributing an MP3 encoder is
// unencumbered.
//
// Contract: CBR (VBR off) for stream stability; interleaved PCM16, `channels`
// channels. All calls for one handle must come from the same thread (the Dart
// main isolate); the encoder is stateful and NOT reentrant. The caller owns the
// output buffer and must size it to LAME's worst case
// (>= 1.25 * frames + 7200 bytes) — see Mp3Encoder.

#include <cstdlib>

#include <lame/lame.h>

extern "C" {

// Creates a CBR MP3 encoder for [sample_rate] Hz / [channels] channels at
// [bitrate_kbps]. Sets in == out sample rate (no resampling) and forces CBR
// (VBR off) so the produced stream stays frame-stable for incremental append.
// Returns the opaque lame_global_flags* handle, or null on failure.
void* cc_lame_create(int sample_rate, int channels, int bitrate_kbps) {
  lame_global_flags* gf = lame_init();
  if (gf == nullptr) {
    return nullptr;
  }
  lame_set_in_samplerate(gf, sample_rate);
  lame_set_out_samplerate(gf, sample_rate);
  lame_set_num_channels(gf, channels);
  lame_set_brate(gf, bitrate_kbps);
  lame_set_VBR(gf, vbr_off);  // CBR: stable frames for streaming/append
  if (lame_init_params(gf) < 0) {
    lame_close(gf);
    return nullptr;
  }
  return gf;
}

// Encodes [frames] interleaved PCM16 samples-per-channel from [pcm_interleaved]
// into [out] (capacity [out_cap] bytes). Returns the number of MP3 bytes
// written (0 is valid — LAME buffers internally until a frame completes), or a
// negative LAME error code (-1 out buffer too small, -2 malloc, -3 params not
// initialised, -4 psycho-acoustic init).
int cc_lame_encode(void* h, const short* pcm_interleaved, int frames,
                   unsigned char* out, int out_cap) {
  if (h == nullptr || pcm_interleaved == nullptr || out == nullptr) {
    return -1;
  }
  auto* gf = static_cast<lame_global_flags*>(h);
  // lame_encode_buffer_interleaved takes a non-const short*; it does not mutate
  // the input, so the const_cast is safe.
  return lame_encode_buffer_interleaved(
      gf, const_cast<short*>(pcm_interleaved), frames, out, out_cap);
}

// Flushes LAME's internal buffers, padding the final frame, into [out]
// (capacity [out_cap] bytes; should be >= 7200). Returns bytes written (may be
// 0) or a negative error code. Call once when the stream ends.
int cc_lame_flush(void* h, unsigned char* out, int out_cap) {
  if (h == nullptr || out == nullptr) {
    return -1;
  }
  return lame_encode_flush(static_cast<lame_global_flags*>(h), out, out_cap);
}

// Destroys the encoder created by cc_lame_create (frees all LAME state).
void cc_lame_destroy(void* h) {
  if (h == nullptr) {
    return;
  }
  lame_close(static_cast<lame_global_flags*>(h));
}

// Static libmp3lame version string for FFI smoke tests; do not free.
const char* cc_lame_version(void) { return get_lame_version(); }

}  // extern "C"

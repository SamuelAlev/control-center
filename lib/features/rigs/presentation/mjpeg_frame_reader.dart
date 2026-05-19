// JPEG resynchronisation for a rig's watch lane.
//
// The server relays an open-ended `video/x-motion-jpeg` body: JPEG frames
// concatenated with no framing between them, which is literally what every
// surface produces (the guest agent's ffmpeg, Chromium's screencast, and the
// host transcode of Android's H.264). This finds frame boundaries by scanning
// for the SOI/EOI markers rather than trusting a multipart boundary, so a
// truncated or oddly-framed part cannot desynchronise the stream permanently.
//
// Split out of the widget because it is the hot path — it runs on the UI
// isolate for every chunk of a 24 fps 1080p stream — and because a pure object
// over bytes is testable, which the widget is not.
library;

import 'dart:typed_data';

/// Accumulates stream chunks and yields complete JPEG frames.
///
/// **Incremental by construction.** The first version rebuilt the whole
/// accumulated buffer (`BytesBuilder.toBytes()`, a full copy) on every chunk
/// and rescanned all of it from byte zero for both markers — O(n·m) per chunk
/// on the UI isolate, which at 1080p/24 fps is megabytes per second of memcpy
/// and scanning between the user and a smooth frame. This keeps one growable
/// buffer, remembers where the in-progress frame starts and how far each scan
/// reached, and drops consumed bytes off the front.
class MjpegFrameReader {
  /// Creates a reader.
  ///
  /// [maxBufferBytes] bounds a stream that never yields a complete JPEG (a
  /// wrong content type, a truncated relay): without it the buffer grows
  /// without limit for as long as the panel stays open. One frame is the
  /// working set; the default is far above any real frame and far below a
  /// problem.
  MjpegFrameReader({this.maxBufferBytes = 32 * 1024 * 1024});

  static const int _marker = 0xFF;
  static const int _soi = 0xD8;
  static const int _eoi = 0xD9;

  /// Buffer ceiling before the reader resynchronises by dropping everything.
  final int maxBufferBytes;

  Uint8List _buffer = Uint8List(0);
  int _length = 0;

  /// Where the frame being assembled starts, or -1 when no SOI is held.
  int _frameStart = -1;

  /// Where the next SOI scan resumes (only meaningful when [_frameStart] < 0).
  int _soiFrom = 0;

  /// Where the next EOI scan resumes (only meaningful when [_frameStart] >= 0).
  int _eoiFrom = 0;

  /// Bytes currently held (a frame in progress plus any unscanned tail).
  int get bufferedBytes => _length;

  /// Appends [chunk] and returns the NEWEST complete frame it completed, or
  /// null when no frame finished.
  ///
  /// Deliberately newest-only: TCP routinely coalesces several frames into one
  /// chunk, and painting the older ones costs a decode each for pictures that
  /// are already stale. Returning the first SOI with the LAST EOI would be
  /// worse still — that slice contains several images and `Image.memory`
  /// decodes only up to the first EOI, so the widget painted the OLDEST frame
  /// and dropped the rest.
  Uint8List? add(List<int> chunk) {
    _append(chunk);
    if (_length > maxBufferBytes) {
      // Resynchronise rather than grow: whatever is arriving is not a JPEG
      // stream, and the next SOI starts a clean frame.
      reset();
      return null;
    }

    Uint8List? newest;
    var consumed = 0;
    while (true) {
      if (_frameStart < 0) {
        final soi = _find(_soi, _soiFrom);
        if (soi < 0) {
          // Nothing but junk after what we already took. Keep only the last
          // byte, in case a marker pair straddles this chunk boundary — and
          // never keep LESS than what a completed frame already consumed.
          final tail = _length > 0 ? _length - 1 : 0;
          consumed = tail > consumed ? tail : consumed;
          _soiFrom = 0;
          break;
        }
        _frameStart = soi;
        _eoiFrom = soi + 2;
      }
      final eoi = _find(_eoi, _eoiFrom);
      if (eoi < 0) {
        // Drop the junk BEFORE the frame we are assembling, keep the frame.
        consumed = _frameStart;
        _eoiFrom = _length > _frameStart + 2 ? _length - 1 : _frameStart + 2;
        break;
      }
      // `fromList` copies: the slice must outlive the next compaction, and a
      // view into a buffer we are about to memmove is a decoded picture of
      // whatever landed there afterwards.
      newest = Uint8List.fromList(
        Uint8List.sublistView(_buffer, _frameStart, eoi + 2),
      );
      consumed = eoi + 2;
      _frameStart = -1;
      _soiFrom = consumed;
    }

    if (consumed > 0) {
      _buffer.setRange(0, _length - consumed, _buffer, consumed);
      _length -= consumed;
      if (_frameStart >= 0) {
        _frameStart -= consumed;
      }
      _soiFrom = _clamp(_soiFrom - consumed);
      _eoiFrom = _clamp(_eoiFrom - consumed);
    }
    return newest;
  }

  /// Drops everything held (a reconnect starts a new stream).
  void reset() {
    _length = 0;
    _frameStart = -1;
    _soiFrom = 0;
    _eoiFrom = 0;
  }

  int _clamp(int value) => value < 0 ? 0 : (value > _length ? _length : value);

  void _append(List<int> chunk) {
    final needed = _length + chunk.length;
    if (needed > _buffer.length) {
      var capacity = _buffer.isEmpty ? 64 * 1024 : _buffer.length;
      while (capacity < needed) {
        capacity *= 2;
      }
      _buffer = Uint8List(capacity)..setRange(0, _length, _buffer);
    }
    _buffer.setRange(_length, needed, chunk);
    _length = needed;
  }

  /// Index of `0xFF <second>` at or after [from], or -1.
  int _find(int second, int from) {
    for (var i = from < 0 ? 0 : from; i + 1 < _length; i++) {
      if (_buffer[i] == _marker && _buffer[i + 1] == second) {
        return i;
      }
    }
    return -1;
  }
}

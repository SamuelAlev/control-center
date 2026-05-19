// Frame resynchronisation for a rig's watch lane.
//
// The server relays an open-ended body of images concatenated with no framing
// between them, which is literally what every surface produces (the guest
// agent's ffmpeg, Chromium's screencast, the host transcode of Android's
// H.264, and a polled browser engine's stills). This finds frame boundaries by
// scanning for the format's own start and end markers rather than trusting a
// multipart boundary, so a truncated or oddly-framed part cannot
// desynchronise the stream permanently.
//
// TWO formats, one algorithm. Most lanes are JPEG; WebKit's is PNG, because
// classic WebDriver has no format parameter and answers PNG — and carrying
// those bytes as they are beats both a host transcode (an ffmpeg the host may
// not have, for a browser) and a server-side decode (real CPU on the isolate
// that answers RPCs). The stream says which it is in its content type.
//
// Split out of the widget because it is the hot path — it runs on the UI
// isolate for every chunk of a 24 fps 1080p stream — and because a pure object
// over bytes is testable, which the widget is not.
library;

import 'dart:typed_data';

/// The two-byte JPEG start-of-image marker.
const List<int> kJpegSoi = [0xFF, 0xD8];

/// The two-byte JPEG end-of-image marker.
const List<int> kJpegEoi = [0xFF, 0xD9];

/// The eight-byte PNG signature.
const List<int> kPngSignature = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
];

/// PNG's terminating `IEND` chunk type plus its (constant) CRC.
///
/// The chunk's length field is always zero, so `IEND` + CRC is a fixed
/// eight-byte tail — unique enough to scan for and self-delimiting, which is
/// what makes a concatenated PNG stream framable at all.
const List<int> kPngIend = [0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82];

/// Accumulates stream chunks and yields complete frames.
///
/// **Incremental by construction.** The first version rebuilt the whole
/// accumulated buffer (`BytesBuilder.toBytes()`, a full copy) on every chunk
/// and rescanned all of it from byte zero for both markers — O(n·m) per chunk
/// on the UI isolate, which at 1080p/24 fps is megabytes per second of memcpy
/// and scanning between the user and a smooth frame. This keeps one growable
/// buffer, remembers where the in-progress frame starts and how far each scan
/// reached, and drops consumed bytes off the front.
class RigFrameReader {
  /// Creates a reader for a format delimited by [startPattern]/[endPattern].
  ///
  /// [maxBufferBytes] bounds a stream that never yields a complete frame (a
  /// wrong content type, a truncated relay): without it the buffer grows
  /// without limit for as long as the panel stays open. One frame is the
  /// working set; the default is far above any real frame and far below a
  /// problem.
  RigFrameReader({
    required this.startPattern,
    required this.endPattern,
    this.maxBufferBytes = 32 * 1024 * 1024,
  }) {
    // Thrown, not asserted: `assert` is stripped in release, so a one-byte
    // marker would slip through in the shipped app and frame every byte.
    if (startPattern.length < 2) {
      throw ArgumentError.value(
        startPattern,
        'startPattern',
        'a one-byte start marker cannot frame',
      );
    }
    if (endPattern.length < 2) {
      throw ArgumentError.value(
        endPattern,
        'endPattern',
        'a one-byte end marker cannot frame',
      );
    }
  }

  /// A reader for the lane the stream's [contentType] declares.
  ///
  /// Defaults to JPEG: that is what every lane but WebKit's serves, and it is
  /// also the honest fallback for a server too old to declare anything else.
  factory RigFrameReader.forContentType(String? contentType) =>
      (contentType ?? '').contains('png')
      ? RigFrameReader(startPattern: kPngSignature, endPattern: kPngIend)
      : RigFrameReader(startPattern: kJpegSoi, endPattern: kJpegEoi);

  /// The byte sequence a frame begins with.
  final List<int> startPattern;

  /// The byte sequence a frame ends with, inclusive.
  final List<int> endPattern;

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
        final soi = _find(startPattern, _soiFrom);
        if (soi < 0) {
          // Nothing but junk after what we already took. Keep only the last
          // few bytes, in case a marker straddles this chunk boundary — and
          // never keep LESS than what a completed frame already consumed.
          final keep = startPattern.length - 1;
          final tail = _length > keep ? _length - keep : 0;
          consumed = tail > consumed ? tail : consumed;
          _soiFrom = 0;
          break;
        }
        _frameStart = soi;
        _eoiFrom = soi + startPattern.length;
      }
      final eoi = _find(endPattern, _eoiFrom);
      if (eoi < 0) {
        // Drop the junk BEFORE the frame we are assembling, keep the frame.
        consumed = _frameStart;
        final resume = _frameStart + startPattern.length;
        final keep = endPattern.length - 1;
        _eoiFrom = _length - keep > resume ? _length - keep : resume;
        break;
      }
      // `fromList` copies: the slice must outlive the next compaction, and a
      // view into a buffer we are about to memmove is a decoded picture of
      // whatever landed there afterwards.
      final frameEnd = eoi + endPattern.length;
      newest = Uint8List.fromList(
        Uint8List.sublistView(_buffer, _frameStart, frameEnd),
      );
      consumed = frameEnd;
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

  /// Index of [pattern] at or after [from], or -1.
  int _find(List<int> pattern, int from) {
    final last = _length - pattern.length;
    outer:
    for (var i = from < 0 ? 0 : from; i <= last; i++) {
      for (var j = 0; j < pattern.length; j++) {
        if (_buffer[i + j] != pattern[j]) {
          continue outer;
        }
      }
      return i;
    }
    return -1;
  }
}

/// A reader for the JPEG lane every surface but WebKit serves.
///
/// Kept as its own type because it is what the viewer and its tests name, and
/// because "the MJPEG reader" is the thing anyone looking for this reaches
/// for first.
class MjpegFrameReader extends RigFrameReader {
  /// Creates a JPEG reader.
  MjpegFrameReader({super.maxBufferBytes})
    : super(startPattern: kJpegSoi, endPattern: kJpegEoi);
}

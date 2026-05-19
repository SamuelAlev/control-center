import 'dart:typed_data';

/// Repackages the continuous MP3 byte stream of a soundscape session into a
/// sliding window of short HLS media segments + a live `.m3u8` playlist.
///
/// This is a SECOND packaging of the exact same encoded bytes the progressive
/// stream serves — there is no second encode. Bytes are cut into ~[segmentBytes]
/// chunks (an MP3 decoder resyncs on the next frame header, so a cut mid-frame
/// is harmless) and only the last [window] segments are retained. Used by the
/// mobile/relay HLS transport; the desktop + web progressive stream never needs
/// it.
class HlsSegmenter {
  /// Creates a segmenter keeping [window] segments of ~[segmentBytes] each.
  /// The default ~96 KB ≈ 6 s at 128 kbps CBR.
  HlsSegmenter({
    this.segmentBytes = 96 * 1024,
    this.window = 4,
    this.targetDurationSeconds = 6,
  });

  /// Approximate byte size that triggers cutting a new segment.
  final int segmentBytes;

  /// How many finished segments to retain (older ones age out).
  final int window;

  /// The `#EXT-X-TARGETDURATION` advertised in the playlist.
  final int targetDurationSeconds;

  final List<Uint8List> _segments = [];
  final BytesBuilder _current = BytesBuilder(copy: false);

  /// The media sequence number of `_segments[0]` (monotonic, never reused).
  int _firstIndex = 0;

  /// Appends freshly-encoded MP3 [bytes], cutting a segment when the current
  /// one reaches [segmentBytes].
  void add(List<int> bytes) {
    _current.add(bytes);
    if (_current.length >= segmentBytes) {
      _cut();
    }
  }

  void _cut() {
    if (_current.isEmpty) {
      return;
    }
    _segments.add(_current.takeBytes());
    while (_segments.length > window) {
      _segments.removeAt(0);
      _firstIndex++;
    }
  }

  /// Renders the live media playlist. Each segment URI is `seg?<segmentQuery>&n=<i>`,
  /// relative to `/soundscape/playlist.m3u8`, so it resolves to `/soundscape/seg`
  /// carrying the same signed auth query the playlist was fetched with.
  String playlist(String segmentQuery) {
    // Ensure at least one segment is available so a fresh player has something
    // to fetch immediately.
    if (_segments.isEmpty) {
      _cut();
    }
    final b = StringBuffer()
      ..writeln('#EXTM3U')
      ..writeln('#EXT-X-VERSION:3')
      ..writeln('#EXT-X-TARGETDURATION:$targetDurationSeconds')
      ..writeln('#EXT-X-MEDIA-SEQUENCE:$_firstIndex');
    for (var i = 0; i < _segments.length; i++) {
      b
        ..writeln('#EXTINF:$targetDurationSeconds.0,')
        ..writeln('seg?$segmentQuery&n=${_firstIndex + i}');
    }
    return b.toString();
  }

  /// The bytes of segment [index], or null if it has aged out of the window.
  List<int>? segment(int index) {
    final pos = index - _firstIndex;
    if (pos < 0 || pos >= _segments.length) {
      return null;
    }
    return _segments[pos];
  }
}

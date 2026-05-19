import 'dart:io';
import 'dart:typed_data';

/// Streaming WAV writer for 16-bit PCM. Writes a placeholder RIFF/WAVE header
/// up front, appends PCM chunks as they arrive, and patches the two size fields
/// on [close]. Used to retain a meeting's per-channel audio for the offline
/// diarization step.
///
/// Writes are synchronous (each chunk is a few KB, a handful of times a second)
/// so [add] can be called straight from a stream callback without ordering
/// gymnastics.
class WavStreamWriter {
  WavStreamWriter._(this._raf, this.sampleRate, this.channels);

  final RandomAccessFile _raf;

  /// Sample rate of the written audio.
  final int sampleRate;

  /// Channel count of the written audio.
  final int channels;

  int _dataBytes = 0;
  bool _closed = false;

  /// Opens [path] for writing and emits a 44-byte placeholder header.
  static Future<WavStreamWriter> create(
    String path, {
    int sampleRate = 16000,
    int channels = 1,
  }) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final raf = await file.open(mode: FileMode.write);
    final writer = WavStreamWriter._(raf, sampleRate, channels);
    raf.writeFromSync(writer._header(0));
    return writer;
  }

  /// Appends a chunk of little-endian 16-bit PCM.
  void add(Uint8List pcm16) {
    if (_closed || pcm16.isEmpty) {
      return;
    }
    _raf.writeFromSync(pcm16);
    _dataBytes += pcm16.length;
  }

  /// Patches the RIFF + data chunk sizes and closes the file.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    // ChunkSize @ offset 4 = 36 + dataBytes; Subchunk2Size @ offset 40 = dataBytes.
    await _raf.setPosition(4);
    await _raf.writeFrom(_u32(36 + _dataBytes));
    await _raf.setPosition(40);
    await _raf.writeFrom(_u32(_dataBytes));
    await _raf.close();
  }

  Uint8List _header(int dataBytes) {
    final byteRate = sampleRate * channels * 2;
    final blockAlign = channels * 2;
    final b = BytesBuilder();
    b.add(_ascii('RIFF'));
    b.add(_u32(36 + dataBytes));
    b.add(_ascii('WAVE'));
    b.add(_ascii('fmt '));
    b.add(_u32(16)); // PCM fmt chunk size
    b.add(_u16(1)); // audio format = PCM
    b.add(_u16(channels));
    b.add(_u32(sampleRate));
    b.add(_u32(byteRate));
    b.add(_u16(blockAlign));
    b.add(_u16(16)); // bits per sample
    b.add(_ascii('data'));
    b.add(_u32(dataBytes));
    return b.toBytes();
  }

  static Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);

  static Uint8List _u32(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.little);
    return b.buffer.asUint8List();
  }

  static Uint8List _u16(int v) {
    final b = ByteData(2)..setUint16(0, v, Endian.little);
    return b.buffer.asUint8List();
  }
}

/// The decoded contents of a mono 16-bit PCM WAV file.
class WavData {
  /// Creates [WavData].
  const WavData({required this.samples, required this.sampleRate});

  /// Normalized samples in `[-1, 1]`.
  final Float32List samples;

  /// Source sample rate (Hz).
  final int sampleRate;
}

/// Reads a 16-bit PCM WAV file into normalized Float32 samples. Reads the
/// sample rate from the `fmt ` chunk and the audio from the `data` chunk; if
/// the file is multi-channel it averages channels to mono. Returns empty data
/// if the file is missing or has no `data` chunk.
Future<WavData> readWavToFloat32(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    return WavData(samples: Float32List(0), sampleRate: 16000);
  }
  final bytes = await file.readAsBytes();
  final view = ByteData.sublistView(bytes);
  if (bytes.length < 12 ||
      _readAscii(bytes, 0) != 'RIFF' ||
      _readAscii(bytes, 8) != 'WAVE') {
    return WavData(samples: Float32List(0), sampleRate: 16000);
  }

  var sampleRate = 16000;
  var channels = 1;
  var bitsPerSample = 16;
  var dataOffset = -1;
  var dataLength = 0;

  var pos = 12;
  while (pos + 8 <= bytes.length) {
    final chunkId = _readAscii(bytes, pos);
    final chunkSize = view.getUint32(pos + 4, Endian.little);
    final body = pos + 8;
    if (chunkId == 'fmt ' && body + 16 <= bytes.length) {
      channels = view.getUint16(body + 2, Endian.little);
      sampleRate = view.getUint32(body + 4, Endian.little);
      bitsPerSample = view.getUint16(body + 14, Endian.little);
    } else if (chunkId == 'data') {
      dataOffset = body;
      dataLength = chunkSize;
    }
    // Chunks are word-aligned (pad byte when the size is odd).
    pos = body + chunkSize + (chunkSize.isOdd ? 1 : 0);
  }

  if (dataOffset < 0 || bitsPerSample != 16 || channels < 1) {
    return WavData(samples: Float32List(0), sampleRate: sampleRate);
  }
  final end = (dataOffset + dataLength).clamp(0, bytes.length);
  final totalSamples = (end - dataOffset) ~/ 2;
  final frames = totalSamples ~/ channels;
  final out = Float32List(frames);
  for (var f = 0; f < frames; f++) {
    var sum = 0.0;
    for (var c = 0; c < channels; c++) {
      final s = view.getInt16(dataOffset + (f * channels + c) * 2, Endian.little);
      sum += s / 32768.0;
    }
    out[f] = sum / channels;
  }
  return WavData(samples: out, sampleRate: sampleRate);
}

String _readAscii(Uint8List bytes, int offset) {
  if (offset + 4 > bytes.length) {
    return '';
  }
  return String.fromCharCodes(bytes.sublist(offset, offset + 4));
}

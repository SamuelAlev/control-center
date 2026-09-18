import 'dart:convert';
import 'dart:typed_data';

/// Connect protocol end-stream flag (JSON error trailer).
const int kConnectEndStreamFlag = 0x02;

/// Connect protocol gzip flag. We never send or accept compressed frames.
const int kConnectCompressedFlag = 0x01;

/// One Connect-RPC frame (`flags` + 4-byte big-endian length + payload).
class ConnectFrame {
  /// Creates a frame.
  const ConnectFrame({required this.flags, required this.payload});

  /// Frame flags (bit 0 = compressed, bit 1 = end-stream).
  final int flags;

  /// Frame payload.
  final Uint8List payload;

  /// Whether this is the Connect end-stream trailer.
  bool get isEndStream => (flags & kConnectEndStreamFlag) != 0;

  /// Whether the payload is gzip-compressed.
  bool get isCompressed => (flags & kConnectCompressedFlag) != 0;
}

/// Encodes a protobuf payload as a Connect data frame.
Uint8List frameConnectMessage(List<int> payload, {int flags = 0}) {
  final out = Uint8List(5 + payload.length);
  out[0] = flags;
  final length = payload.length;
  out[1] = (length >> 24) & 0xff;
  out[2] = (length >> 16) & 0xff;
  out[3] = (length >> 8) & 0xff;
  out[4] = length & 0xff;
  out.setRange(5, out.length, payload);
  return out;
}

/// Incrementally splits a byte stream into Connect frames.
class ConnectFrameDecoder {
  final BytesBuilder _pending = BytesBuilder(copy: false);

  /// Adds [chunk] and returns every complete frame.
  List<ConnectFrame> add(List<int> chunk) {
    if (chunk.isEmpty) {
      return const [];
    }
    _pending.add(chunk);
    final buffer = _pending.takeBytes();
    var offset = 0;
    final out = <ConnectFrame>[];
    while (offset + 5 <= buffer.length) {
      final flags = buffer[offset];
      final length =
          (buffer[offset + 1] << 24) |
          (buffer[offset + 2] << 16) |
          (buffer[offset + 3] << 8) |
          buffer[offset + 4];
      if (length < 0 || offset + 5 + length > buffer.length) {
        break;
      }
      out.add(
        ConnectFrame(
          flags: flags,
          payload: Uint8List.sublistView(
            buffer,
            offset + 5,
            offset + 5 + length,
          ),
        ),
      );
      offset += 5 + length;
    }
    if (offset < buffer.length) {
      _pending.add(Uint8List.sublistView(buffer, offset));
    }
    return out;
  }
}

/// Parses a Connect end-stream JSON trailer into an error message, or null.
String? parseConnectEndStreamError(List<int> payload) {
  if (payload.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(utf8.decode(payload));
    if (decoded is! Map) {
      return null;
    }
    final error = decoded['error'];
    if (error is! Map) {
      return null;
    }
    final code = error['code']?.toString() ?? 'unknown';
    final message = error['message']?.toString() ?? 'Unknown error';
    return 'Connect error $code: $message';
  } on Object {
    return 'Failed to parse Connect end stream';
  }
}

/// First non-end-stream Connect payload in a unary response, or the raw body.
Uint8List decodeConnectUnaryBody(List<int> payload) {
  if (payload.length < 5) {
    return payload is Uint8List ? payload : Uint8List.fromList(payload);
  }
  var offset = 0;
  final data = payload is Uint8List ? payload : Uint8List.fromList(payload);
  while (offset + 5 <= data.length) {
    final flags = data[offset];
    final length =
        (data[offset + 1] << 24) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 8) |
        data[offset + 4];
    final end = offset + 5 + length;
    if (end > data.length) {
      break;
    }
    if ((flags & kConnectCompressedFlag) != 0) {
      break;
    }
    if ((flags & kConnectEndStreamFlag) == 0) {
      return Uint8List.sublistView(data, offset + 5, end);
    }
    offset = end;
  }
  return data;
}

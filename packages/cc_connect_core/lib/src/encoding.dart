import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Crockford base32 alphabet (no I, L, O, U), used for install ids and the
/// browser confirm code: unambiguous when read aloud or retyped.
const String crockfordAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// Encodes [bytes] as unpadded Crockford base32, most significant bit first.
String crockfordBase32(List<int> bytes) {
  final out = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final byte in bytes) {
    buffer = (buffer << 8) | (byte & 0xff);
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      out.write(crockfordAlphabet[(buffer >> bits) & 0x1f]);
    }
    buffer &= (1 << bits) - 1;
  }
  if (bits > 0) {
    out.write(crockfordAlphabet[(buffer << (5 - bits)) & 0x1f]);
  }
  return out.toString();
}

/// Unpadded base64url, the encoding of every binary field on the Connect wire.
String b64url(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

/// Decodes unpadded (or padded) base64url. Throws [FormatException] on
/// anything else.
Uint8List unb64url(String value) {
  if (!RegExp(r'^[A-Za-z0-9_-]*={0,2}$').hasMatch(value)) {
    throw const FormatException('not base64url');
  }
  final stripped = value.replaceAll('=', '');
  final padded = stripped.padRight(
    stripped.length + (4 - stripped.length % 4) % 4,
    '=',
  );
  return base64Url.decode(padded);
}

/// [length] bytes from the platform CSPRNG.
Uint8List randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList([
    for (var i = 0; i < length; i++) random.nextInt(256),
  ]);
}

/// Compares two strings in time independent of where they first differ.
bool constantTimeEquals(String a, String b) {
  final left = utf8.encode(a);
  final right = utf8.encode(b);
  var diff = left.length ^ right.length;
  final n = max(left.length, right.length);
  for (var i = 0; i < n; i++) {
    final x = i < left.length ? left[i] : 0;
    final y = i < right.length ? right[i] : 0;
    diff |= x ^ y;
  }
  return diff == 0;
}

/// Deterministic JSON: object keys sorted by code unit at every depth, no
/// insignificant whitespace. The byte string both the offline config signer
/// and every verifier hash, so two encoders can never disagree about it.
///
/// Only JSON values are accepted (maps with string keys, lists, strings,
/// finite numbers, booleans, null); anything else throws [ArgumentError].
String canonicalJson(Object? value) {
  final out = StringBuffer();
  void write(Object? v) {
    switch (v) {
      case null:
        out.write('null');
      case bool():
        out.write(v ? 'true' : 'false');
      case int():
        out.write(v.toString());
      case double():
        if (!v.isFinite) {
          throw ArgumentError('non-finite number in canonical JSON');
        }
        if (v == v.truncateToDouble() && v.abs() < 1e15) {
          out.write(v.toInt().toString());
        } else {
          out.write(jsonEncode(v));
        }
      case String():
        out.write(jsonEncode(v));
      case List<Object?>():
        out.write('[');
        for (var i = 0; i < v.length; i++) {
          if (i > 0) {
            out.write(',');
          }
          write(v[i]);
        }
        out.write(']');
      case Map<Object?, Object?>():
        final keys = <String>[];
        for (final key in v.keys) {
          if (key is! String) {
            throw ArgumentError('non-string key in canonical JSON');
          }
          keys.add(key);
        }
        keys.sort();
        out.write('{');
        for (var i = 0; i < keys.length; i++) {
          if (i > 0) {
            out.write(',');
          }
          out
            ..write(jsonEncode(keys[i]))
            ..write(':');
          write(v[keys[i]]);
        }
        out.write('}');
      default:
        throw ArgumentError('unsupported value in canonical JSON: $v');
    }
  }

  write(value);
  return out.toString();
}

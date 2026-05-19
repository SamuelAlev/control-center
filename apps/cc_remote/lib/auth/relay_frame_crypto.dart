import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// End-to-end authenticated encryption for the JSON-RPC frames the phone and
/// cc_server exchange THROUGH the (untrusted) signaling broker.
///
/// Mirrors the desktop/server `RelayFrameCrypto` (in `cc_rpc`) byte-for-byte —
/// we can't import that package (it drags in `dart:io`/transports that break
/// `flutter build web`), so the wire format is re-implemented here, exactly as
/// `PskHandshake` mirrors `RemoteControlCrypto`. The shared known-answer test
/// vector guards the two impls against drift.
///
/// Construction: **encrypt-then-MAC** built from HMAC-SHA256 only.
///  - `kEnc = HMAC-SHA256(psk, "cc-relay-enc-v1")`, `kMac = HMAC-SHA256(psk, "cc-relay-mac-v1")`
///  - keystream block `i = HMAC-SHA256(kEnc, nonce(16) || uint32_be(i))` (CTR)
///  - `ciphertext = plaintext XOR keystream`
///  - `tag = HMAC-SHA256(kMac, nonce || ciphertext)` (encrypt-then-MAC)
///  - wire = `base64url(nonce(16) || tag(32) || ciphertext)` without padding
class RelayFrameCrypto {
  RelayFrameCrypto._();

  /// Wire-format version. Bump together with the cc_rpc canonical on any change.
  static const int version = 1;

  static const int _nonceLength = 16;
  static const int _tagLength = 32;
  static const String _encLabel = 'cc-relay-enc-v1';
  static const String _macLabel = 'cc-relay-mac-v1';

  /// Seals [plaintext] (a JSON string) into a base64url (no padding) token.
  /// [nonceOverride] is for tests only — production seals use a fresh nonce.
  static String seal(String plaintext, String psk, {List<int>? nonceOverride}) {
    final nonce = nonceOverride != null
        ? Uint8List.fromList(nonceOverride)
        : _randomBytes(_nonceLength);
    final data = Uint8List.fromList(utf8.encode(plaintext));
    final cipher = _xorKeystream(data, _encKey(psk), nonce);
    final tag = _mac(_macKey(psk), nonce, cipher);

    final out = Uint8List(_nonceLength + _tagLength + cipher.length)
      ..setAll(0, nonce)
      ..setAll(_nonceLength, tag)
      ..setAll(_nonceLength + _tagLength, cipher);
    return base64Url.encode(out).replaceAll('=', '');
  }

  /// Opens a [sealed] token back to the plaintext JSON string. Throws
  /// [RelayFrameAuthException] when the tag does not verify (fail closed).
  static String open(String sealed, String psk) {
    final Uint8List bytes;
    try {
      bytes = base64Url.decode(base64Url.normalize(sealed));
    } catch (_) {
      throw const RelayFrameAuthException('relay frame is not valid base64url');
    }
    if (bytes.length < _nonceLength + _tagLength) {
      throw const RelayFrameAuthException('relay frame too short');
    }
    final nonce = bytes.sublist(0, _nonceLength);
    final tag = bytes.sublist(_nonceLength, _nonceLength + _tagLength);
    final cipher = bytes.sublist(_nonceLength + _tagLength);

    final expected = _mac(_macKey(psk), nonce, cipher);
    if (!_constantTimeEquals(expected, tag)) {
      throw const RelayFrameAuthException('relay frame authentication failed');
    }
    final clear = _xorKeystream(cipher, _encKey(psk), nonce);
    return utf8.decode(clear);
  }

  // --- internals (mirror cc_rpc RelayFrameCrypto) ------------------------

  static List<int> _encKey(String psk) =>
      Hmac(sha256, utf8.encode(psk)).convert(utf8.encode(_encLabel)).bytes;

  static List<int> _macKey(String psk) =>
      Hmac(sha256, utf8.encode(psk)).convert(utf8.encode(_macLabel)).bytes;

  static Uint8List _xorKeystream(
    Uint8List data,
    List<int> encKey,
    List<int> nonce,
  ) {
    final out = Uint8List(data.length);
    final hmac = Hmac(sha256, encKey);
    var offset = 0;
    var counter = 0;
    while (offset < data.length) {
      final block = hmac.convert([...nonce, ..._uint32be(counter)]).bytes;
      final take = data.length - offset < block.length
          ? data.length - offset
          : block.length;
      for (var i = 0; i < take; i++) {
        out[offset + i] = data[offset + i] ^ block[i];
      }
      offset += take;
      counter++;
    }
    return out;
  }

  static List<int> _mac(List<int> macKey, List<int> nonce, List<int> cipher) =>
      Hmac(sha256, macKey).convert([...nonce, ...cipher]).bytes;

  static List<int> _uint32be(int value) =>
      [(value >> 24) & 0xff, (value >> 16) & 0xff, (value >> 8) & 0xff, value & 0xff];

  static Uint8List _randomBytes(int n) {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => rnd.nextInt(256)));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// Thrown when a relayed frame fails authentication (tampered, wrong PSK, or
/// truncated). Mirrors the cc_rpc exception of the same name.
class RelayFrameAuthException implements Exception {
  /// Creates a [RelayFrameAuthException].
  const RelayFrameAuthException(this.message);

  /// Human-readable reason (carries no secret material).
  final String message;

  @override
  String toString() => 'RelayFrameAuthException: $message';
}

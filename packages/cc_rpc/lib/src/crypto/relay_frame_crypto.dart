import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// End-to-end authenticated encryption for the JSON-RPC frames that the phone
/// and cc_server exchange THROUGH the (untrusted) signaling broker.
///
/// When cc_server is not directly reachable from the phone, the two rendezvous
/// in a broker room and relay frames as opaque `signal` payloads. The broker is
/// a dumb relay — but, unlike the WebRTC path, there is no DTLS to keep it from
/// reading the relayed bytes. So every frame is sealed here: the broker only
/// ever sees ciphertext. Both peers derive the same keys from the shared PSK,
/// so no key exchange is needed.
///
/// Construction: **encrypt-then-MAC** built from HMAC-SHA256 only — the same
/// primitive (and the same "hand-rolled to stay dependency-free and web-safe"
/// stance) the codebase already uses for `RemoteControlCrypto`/`PskHandshake`,
/// rather than pulling a native-leaning cipher package that risks
/// `flutter build web`. The phone mirrors this byte-for-byte (it cannot import
/// this package), so the wire format below is a contract — change it on both
/// sides at once and bump [version].
///
///  - `kEnc = HMAC-SHA256(psk, "cc-relay-enc-v1")`, `kMac = HMAC-SHA256(psk, "cc-relay-mac-v1")`
///  - keystream block `i = HMAC-SHA256(kEnc, nonce(16) || uint32_be(i))` (CTR)
///  - `ciphertext = plaintext XOR keystream`
///  - `tag = HMAC-SHA256(kMac, nonce || ciphertext)` (encrypt-then-MAC)
///  - wire = `base64url(nonce(16) || tag(32) || ciphertext)` without padding
class RelayFrameCrypto {
  RelayFrameCrypto._();

  /// Wire-format version. Bump together with the phone mirror on any change.
  static const int version = 1;

  static const int _nonceLength = 16;
  static const int _tagLength = 32;
  static const String _encLabel = 'cc-relay-enc-v1';
  static const String _macLabel = 'cc-relay-mac-v1';

  /// Seals [plaintext] (a JSON string) into a base64url (no padding) token the
  /// broker can relay as an opaque payload. [nonceOverride] is for tests only —
  /// production callers MUST let a fresh random nonce be generated per frame.
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
  /// [RelayFrameAuthException] when the tag does not verify (tampered, wrong
  /// PSK, or truncated) — fail closed, never return unauthenticated bytes.
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

  // --- internals ---------------------------------------------------------

  static List<int> _encKey(String psk) =>
      Hmac(sha256, utf8.encode(psk)).convert(utf8.encode(_encLabel)).bytes;

  static List<int> _macKey(String psk) =>
      Hmac(sha256, utf8.encode(psk)).convert(utf8.encode(_macLabel)).bytes;

  /// HMAC-SHA256-CTR keystream XORed over [data]. Symmetric — the same call
  /// encrypts and decrypts.
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

  /// Encrypt-then-MAC tag over `nonce || ciphertext`.
  static List<int> _mac(List<int> macKey, List<int> nonce, List<int> cipher) =>
      Hmac(sha256, macKey).convert([...nonce, ...cipher]).bytes;

  static List<int> _uint32be(int value) =>
      [(value >> 24) & 0xff, (value >> 16) & 0xff, (value >> 8) & 0xff, value & 0xff];

  static Uint8List _randomBytes(int n) {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => rnd.nextInt(256)));
  }

  /// Constant-time byte comparison (no short-circuit on first difference).
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
/// truncated). Callers MUST treat the frame as hostile and drop it.
class RelayFrameAuthException implements Exception {
  /// Creates a [RelayFrameAuthException].
  const RelayFrameAuthException(this.message);

  /// Human-readable reason (safe to log; carries no secret material).
  final String message;

  @override
  String toString() => 'RelayFrameAuthException: $message';
}

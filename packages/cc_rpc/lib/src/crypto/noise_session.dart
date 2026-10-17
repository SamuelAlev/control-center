import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';

/// The single supported suite. No algorithm negotiation or insecure fallback.
const String ccNoiseProtocol = 'Noise_NNpsk0_25519_ChaChaPoly_SHA256';

SecretKeyData _ownedKey(List<int> bytes) =>
    SecretKeyData(Uint8List.fromList(bytes), overwriteWhenDestroyed: true);

/// Noise revision 34, NNpsk0: `-> psk, e; <- e, ee`.
///
/// Implements only the protocol state machine; all cryptographic primitives
/// come from crypto/cryptography. The first payload is not forward-secret and
/// MUST NOT carry application content. The channel handshake uses it only as
/// an empty PSK proof and requires a post-handshake client confirmation.
final class NoisePskHandshake {
  /// Begins an initiator or responder handshake using a 32-byte device [psk].
  /// The optional ephemeral key pair is owned and destroyed by this handshake.
  NoisePskHandshake({
    required this.initiator,
    required List<int> psk,
    List<int> prologue = const [],
    SimpleKeyPair? ephemeralKeyPair,
  }) : _psk = _ownedKey(psk),
       _ephemeral = ephemeralKeyPair {
    if (psk.length != 32) {
      _psk.destroy();
      throw ArgumentError('Noise requires a 32-byte pairing secret');
    }
    final protocol = utf8.encode(ccNoiseProtocol);
    _hash = Uint8List.fromList(hashes.sha256.convert(protocol).bytes);
    _chainingKey = _ownedKey(_hash);
    _mixHash(prologue);
  }

  /// Whether this side writes the first handshake message.
  final bool initiator;
  final SecretKeyData _psk;
  late SecretKeyData _chainingKey;
  late Uint8List _hash;
  SimpleKeyPair? _ephemeral;
  SimplePublicKey? _remoteEphemeral;
  NoiseCipherState? _cipher;
  NoiseSession? _session;
  Uint8List? _identityBinding;
  int _step = 0;
  bool _destroyed = false;

  static final _dh = X25519();
  static final _hkdf2 = Hkdf(hmac: Hmac.sha256(), outputLength: 64);
  static final _hkdf3 = Hkdf(hmac: Hmac.sha256(), outputLength: 96);

  /// Transcript immediately before the responder's encrypted payload. It binds
  /// the suite, prologue, both ephemeral keys and the initiator's PSK proof.
  /// The responder signs this value with its pinned Ed25519 identity.
  Uint8List get identityBinding => Uint8List.fromList(_identityBinding!);

  /// Emits the next handshake message. The first initiator payload must be
  /// empty; a responder can build its signed payload from [payloadBuilder].
  Future<Uint8List> writeMessage(
    List<int> payload, {
    Future<List<int>> Function(Uint8List transcript)? payloadBuilder,
  }) async {
    _requireStep(initiator ? 0 : 1);
    try {
      if (initiator) {
        await _mixPsk();
      }
      final ephemeral = _ephemeral ??= await _dh.newKeyPair();
      final public = await ephemeral.extractPublicKey();
      _mixHash(public.bytes);
      await _mixKey(public.bytes);
      if (!initiator) {
        await _mixDh();
        _identityBinding = Uint8List.fromList(_hash);
      }
      final clear = payloadBuilder == null
          ? payload
          : await payloadBuilder(identityBinding);
      if (clear.length > 65535 - 32 - 16) {
        throw const NoiseProtocolException('Handshake payload too large');
      }
      final sealed = await _cipher!.encrypt(clear, associatedData: _hash);
      _mixHash(sealed);
      final message = Uint8List(32 + sealed.length)
        ..setRange(0, 32, public.bytes)
        ..setRange(32, 32 + sealed.length, sealed);
      _step++;
      if (_step == 2) {
        await _split();
      }
      return message;
    } catch (_) {
      destroy();
      rethrow;
    }
  }

  /// Authenticates and decrypts the peer's next handshake message.
  Future<Uint8List> readMessage(List<int> message) async {
    _requireStep(initiator ? 1 : 0);
    try {
      if (message.length < 48 || message.length > 65535) {
        throw const NoiseProtocolException('Invalid handshake length');
      }
      if (!initiator) {
        await _mixPsk();
      }
      final bytes = message is Uint8List
          ? message
          : Uint8List.fromList(message);
      final public = Uint8List.sublistView(bytes, 0, 32);
      _remoteEphemeral = SimplePublicKey(public, type: KeyPairType.x25519);
      _mixHash(public);
      await _mixKey(public);
      if (initiator) {
        await _mixDh();
        _identityBinding = Uint8List.fromList(_hash);
      }
      final sealed = Uint8List.sublistView(bytes, 32);
      final clear = await _cipher!.decrypt(sealed, associatedData: _hash);
      _mixHash(sealed);
      _step++;
      if (_step == 2) {
        await _split();
      }
      return clear;
    } catch (_) {
      destroy();
      rethrow;
    }
  }

  /// Transfers ownership of the traffic keys; the handshake retains no secret.
  NoiseSession takeSession() {
    if (_step != 2 || _session == null || _destroyed) {
      throw const NoiseProtocolException('Handshake not complete');
    }
    final session = _session!;
    _session = null;
    destroy();
    return session;
  }

  void _requireStep(int expected) {
    if (_destroyed || _step != expected) {
      throw const NoiseProtocolException('Invalid handshake state');
    }
  }

  void _mixHash(List<int> data) {
    final input = Uint8List(_hash.length + data.length)
      ..setRange(0, _hash.length, _hash)
      ..setRange(_hash.length, _hash.length + data.length, data);
    _hash = Uint8List.fromList(hashes.sha256.convert(input).bytes);
  }

  Future<SecretKeyData> _derive(List<int> input, {bool triple = false}) async {
    final key = _ownedKey(input);
    try {
      return await (triple ? _hkdf3 : _hkdf2).deriveKey(
        secretKey: key,
        nonce: _chainingKey.bytes,
      );
    } finally {
      key.destroy();
    }
  }

  Future<void> _mixKey(List<int> input) async {
    final derived = await _derive(input);
    try {
      _chainingKey.destroy();
      _chainingKey = _ownedKey(derived.bytes.sublist(0, 32));
      _cipher?.destroy();
      _cipher = NoiseCipherState(derived.bytes.sublist(32, 64));
    } finally {
      derived.destroy();
    }
  }

  Future<void> _mixPsk() async {
    final derived = await _derive(_psk.bytes, triple: true);
    try {
      _chainingKey.destroy();
      _chainingKey = _ownedKey(derived.bytes.sublist(0, 32));
      _mixHash(derived.bytes.sublist(32, 64));
      _cipher?.destroy();
      _cipher = NoiseCipherState(derived.bytes.sublist(64, 96));
    } finally {
      derived.destroy();
      _psk.destroy();
    }
  }

  Future<void> _mixDh() async {
    final shared = await _dh.sharedSecretKey(
      keyPair: _ephemeral!,
      remotePublicKey: _remoteEphemeral!,
    );
    try {
      final bytes = await shared.extractBytes();
      var nonzero = 0;
      for (final byte in bytes) {
        nonzero |= byte;
      }
      if (nonzero == 0) {
        throw const NoiseProtocolException('Invalid ephemeral key');
      }
      await _mixKey(bytes);
    } finally {
      shared.destroy();
    }
  }

  Future<void> _split() async {
    final derived = await _derive(const []);
    try {
      final c2s = NoiseCipherState(derived.bytes.sublist(0, 32));
      final s2c = NoiseCipherState(derived.bytes.sublist(32, 64));
      _session = NoiseSession(
        outgoing: initiator ? c2s : s2c,
        incoming: initiator ? s2c : c2s,
        handshakeHash: Uint8List.fromList(_hash),
      );
    } finally {
      derived.destroy();
      _ephemeral?.destroy();
      _ephemeral = null;
      _chainingKey.destroy();
      _cipher?.destroy();
      _cipher = null;
    }
  }

  /// Releases handshake keys and any session retained by this handshake.
  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    _psk.destroy();
    _chainingKey.destroy();
    _ephemeral?.destroy();
    _ephemeral = null;
    _cipher?.destroy();
    _cipher = null;
    _session?.destroy();
    _session = null;
  }
}

/// Directional Noise traffic keys. Ownership belongs to one secure channel.
final class NoiseSession {
  /// Owns directional cipher states and their shared handshake transcript.
  NoiseSession({
    required this.outgoing,
    required this.incoming,
    required this.handshakeHash,
  });

  /// Cipher state used for messages sent to the peer.
  final NoiseCipherState outgoing;

  /// Cipher state used for messages received from the peer.
  final NoiseCipherState incoming;

  /// Final handshake transcript hash for session binding.
  final Uint8List handshakeHash;

  /// Destroys both directional traffic keys.
  void destroy() {
    outgoing.destroy();
    incoming.destroy();
  }
}

/// Noise CipherState with an implicit, strictly ordered nonce. Callers serialize
/// each direction. A duplicate, gap or direction swap fails authentication.
final class NoiseCipherState {
  /// Creates a directional cipher from an owned copy of [key].
  NoiseCipherState(List<int> key) : _key = _ownedKey(key);

  static final _aead = Chacha20.poly1305Aead();

  /// Maximum encrypted Noise record length in bytes, including its MAC.
  static const int maxMessageBytes = 65535;

  /// Number of records between traffic-key rotations.
  static const int rekeyInterval = 1 << 20;
  // Below both the JS integer ceiling and the protocol's reserved max nonce.
  /// Maximum supported nonce count before this direction fails closed.
  static const int maxMessages = 0xffffffff;
  SecretKeyData _key;
  int _nonce = 0;
  int _lastRekey = -1;
  bool _destroyed = false;

  /// Encrypts the next record using this direction's implicit nonce.
  Future<Uint8List> encrypt(
    List<int> plaintext, {
    List<int> associatedData = const [],
  }) async {
    _check(plaintext.length + 16);
    await _rekeyIfNeeded();
    final box = await _aead.encrypt(
      plaintext,
      secretKey: _key,
      nonce: _nonceBytes(_nonce),
      aad: associatedData,
    );
    _nonce++;
    return Uint8List(box.cipherText.length + 16)
      ..setRange(0, box.cipherText.length, box.cipherText)
      ..setRange(
        box.cipherText.length,
        box.cipherText.length + 16,
        box.mac.bytes,
      );
  }

  /// Authenticates and decrypts the next record in this direction.
  Future<Uint8List> decrypt(
    List<int> ciphertext, {
    List<int> associatedData = const [],
  }) async {
    _check(ciphertext.length);
    if (ciphertext.length < 16) {
      throw const NoiseProtocolException('Truncated secure record');
    }
    await _rekeyIfNeeded();
    final bytes = ciphertext is Uint8List
        ? ciphertext
        : Uint8List.fromList(ciphertext);
    final box = SecretBox(
      Uint8List.sublistView(bytes, 0, bytes.length - 16),
      nonce: _nonceBytes(_nonce),
      mac: Mac(Uint8List.sublistView(bytes, bytes.length - 16)),
    );
    final clear = await _aead.decrypt(
      box,
      secretKey: _key,
      aad: associatedData,
    );
    _nonce++;
    return clear is Uint8List ? clear : Uint8List.fromList(clear);
  }

  void _check(int bytes) {
    if (_destroyed || _nonce >= maxMessages) {
      throw const NoiseProtocolException('Secure session exhausted or closed');
    }
    if (bytes > maxMessageBytes) {
      throw const NoiseProtocolException('Secure record too large');
    }
  }

  Future<void> _rekeyIfNeeded() async {
    if (_nonce == 0 || _nonce % rekeyInterval != 0 || _lastRekey == _nonce) {
      return;
    }
    // Noise REKEY: first 32 bytes of ENCRYPT(k, 2^64-1, empty, zeros[32]).
    // It never resets the transport nonce.
    final nonce = Uint8List(12)..fillRange(4, 12, 255);
    final box = await _aead.encrypt(
      Uint8List(32),
      secretKey: _key,
      nonce: nonce,
    );
    final old = _key;
    _key = _ownedKey(box.cipherText);
    _lastRekey = _nonce;
    old.destroy();
  }

  static Uint8List _nonceBytes(int nonce) {
    final bytes = Uint8List(12);
    ByteData.sublistView(bytes).setUint32(4, nonce, Endian.little);
    return bytes;
  }

  /// Erases this direction's traffic key on a best-effort basis.
  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    _key.destroy();
  }
}

/// A protocol failure that makes the current Noise session unusable.
final class NoiseProtocolException implements Exception {
  /// Describes the failure without including plaintext or key material.
  const NoiseProtocolException(this.message);

  /// A non-secret description of the protocol failure.
  final String message;
  @override
  String toString() => 'NoiseProtocolException: $message';
}

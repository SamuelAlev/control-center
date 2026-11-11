import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// An Ed25519 key that signs git commits in OpenSSH's signature format
/// (`gpg.format=ssh`, [PROTOCOL.sshsig]), the format GitHub, GitLab and
/// Bitbucket verify against a signing key on the committer's account.
///
/// Pure Dart: no `ssh-keygen`, no agent socket and no key file ever exists.
/// The 32-byte seed is the whole private key.
///
/// [PROTOCOL.sshsig]: https://github.com/openssh/openssh-portable/blob/master/PROTOCOL.sshsig
final class SshSigningKey {
  SshSigningKey._(this._keyPair, this._seed, this.publicKey);

  static final Ed25519 _ed25519 = Ed25519();

  /// A new random key.
  static Future<SshSigningKey> generate() async {
    final keyPair = await _ed25519.newKeyPair();
    return _of(keyPair, await keyPair.extractPrivateKeyBytes());
  }

  /// The key whose private half is the 32-byte [seed]. Throws
  /// [ArgumentError] for any other length.
  static Future<SshSigningKey> fromSeed(List<int> seed) async {
    if (seed.length != 32) {
      throw ArgumentError.value(seed.length, 'seed', 'not a 32-byte seed');
    }
    return _of(await _ed25519.newKeyPairFromSeed(seed), seed);
  }

  static Future<SshSigningKey> _of(
    SimpleKeyPair keyPair,
    List<int> seed,
  ) async {
    final public = await keyPair.extractPublicKey();
    return SshSigningKey._(
      keyPair,
      Uint8List.fromList(seed),
      SshSignature.publicKeyLine(public.bytes),
    );
  }

  final SimpleKeyPair _keyPair;
  final Uint8List _seed;

  /// The public key as `ssh-ed25519 <base64>`, with no comment: what a forge
  /// account registers as a signing key.
  final String publicKey;

  /// The private key. Store it like any other credential.
  Uint8List get seed => Uint8List.fromList(_seed);

  /// `SHA256:<base64>`, as forges and `ssh-keygen -l` print it.
  String get fingerprint => SshSignature.fingerprintOf(publicKey);

  /// The armored signature of [message] in the `git` namespace, as git
  /// stores it in a commit's `gpgsig` header.
  Future<String> sign(List<int> message) async {
    final signature = await _ed25519.sign(
      SshSignature._signedData(message, SshSignature._sha512),
      keyPair: _keyPair,
    );
    final blob = BytesBuilder()
      ..add(SshSignature._magic)
      ..add(SshSignature._uint32(SshSignature._version))
      ..add(SshSignature._string(SshSignature._publicKeyBlob(publicKey)))
      ..add(SshSignature._string(utf8.encode(SshSignature.namespace)))
      ..add(SshSignature._string(const []))
      ..add(SshSignature._string(ascii.encode(SshSignature._sha512)))
      ..add(
        SshSignature._string([
          ...SshSignature._string(ascii.encode(SshSignature._keyType)),
          ...SshSignature._string(signature.bytes),
        ]),
      );
    final encoded = base64.encode(blob.takeBytes());
    final lines = [
      for (var i = 0; i < encoded.length; i += 70)
        encoded.substring(i, i + 70 > encoded.length ? encoded.length : i + 70),
    ];
    return '${SshSignature._begin}\n${lines.join('\n')}\n${SshSignature._end}\n';
  }
}

/// Reads and checks OpenSSH signatures over git objects.
// A namespace over stateless checks.
// ignore: avoid_classes_with_only_static_members
abstract final class SshSignature {
  /// The namespace git signs objects in.
  static const String namespace = 'git';

  static const String _keyType = 'ssh-ed25519';
  static const String _sha512 = 'sha512';
  static const String _sha256 = 'sha256';
  static const int _version = 1;
  static const String _begin = '-----BEGIN SSH SIGNATURE-----';
  static const String _end = '-----END SSH SIGNATURE-----';
  static final List<int> _magic = ascii.encode('SSHSIG');
  static final RegExp _keyLine = RegExp(r'^ssh-ed25519 ([A-Za-z0-9+/]+=*)$');

  /// `ssh-ed25519 <base64>` for the raw 32-byte Ed25519 public key [bytes].
  static String publicKeyLine(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentError.value(bytes.length, 'bytes', 'not an Ed25519 key');
    }
    final blob = [..._string(ascii.encode(_keyType)), ..._string(bytes)];
    return '$_keyType ${base64.encode(blob)}';
  }

  /// [key] reduced to `ssh-ed25519 <base64>` (an OpenSSH public key line may
  /// carry a trailing comment), or null when it is not an Ed25519 key.
  static String? normalizePublicKey(String key) {
    final parts = key.trim().split(RegExp(r'\s+'));
    if (parts.length < 2 || parts.first != _keyType) {
      return null;
    }
    final line = '$_keyType ${parts[1]}';
    try {
      _rawPublicKey(line);
    } on FormatException {
      return null;
    }
    return line;
  }

  /// `SHA256:<base64>` of [publicKey] (`ssh-ed25519 <base64>`).
  static String fingerprintOf(String publicKey) {
    final digest = crypto.sha256.convert(_publicKeyBlob(publicKey)).bytes;
    return 'SHA256:${base64.encode(digest).replaceAll('=', '')}';
  }

  /// The `ssh-ed25519 <base64>` key that signed [message] with the armored
  /// [signature] in the [namespace] namespace, or null when [signature] is
  /// not a valid Ed25519 SSH signature of exactly [message].
  ///
  /// The key is the one the signature itself names: a caller decides whether
  /// that key is one it trusts.
  static Future<String?> signerOf(String signature, List<int> message) async {
    final _ParsedSignature parsed;
    try {
      parsed = _parse(signature);
    } on FormatException {
      return null;
    }
    final valid = await Ed25519().verify(
      _signedData(message, parsed.hashAlgorithm),
      signature: Signature(
        parsed.signature,
        publicKey: SimplePublicKey(parsed.publicKey, type: KeyPairType.ed25519),
      ),
    );
    return valid ? publicKeyLine(parsed.publicKey) : null;
  }

  /// What an SSH signature signs: the preamble, the namespace, and the
  /// message's hash under [hashAlgorithm].
  static List<int> _signedData(List<int> message, String hashAlgorithm) {
    final digest = hashAlgorithm == _sha256
        ? crypto.sha256.convert(message).bytes
        : crypto.sha512.convert(message).bytes;
    return [
      ..._magic,
      ..._string(utf8.encode(namespace)),
      ..._string(const []),
      ..._string(ascii.encode(hashAlgorithm)),
      ..._string(digest),
    ];
  }

  static _ParsedSignature _parse(String armored) {
    final lines = [
      for (final line in const LineSplitter().convert(armored.trim()))
        line.trim(),
    ];
    if (lines.length < 3 || lines.first != _begin || lines.last != _end) {
      throw const FormatException('not an armored SSH signature');
    }
    final reader = _Reader(
      base64.decode(lines.sublist(1, lines.length - 1).join()),
    );
    if (!_listEquals(reader.take(_magic.length), _magic) ||
        reader.uint32() != _version) {
      throw const FormatException('not an SSHSIG version 1 signature');
    }
    final key = _Reader(reader.string());
    if (ascii.decode(key.string(), allowInvalid: true) != _keyType) {
      throw const FormatException('not an Ed25519 key');
    }
    final publicKey = key.string();
    key.end();
    if (utf8.decode(reader.string(), allowMalformed: true) != namespace) {
      throw const FormatException('not in the git namespace');
    }
    reader.string(); // reserved
    final hashAlgorithm = ascii.decode(reader.string(), allowInvalid: true);
    if (hashAlgorithm != _sha512 && hashAlgorithm != _sha256) {
      throw const FormatException('unsupported hash algorithm');
    }
    final sig = _Reader(reader.string());
    if (ascii.decode(sig.string(), allowInvalid: true) != _keyType) {
      throw const FormatException('not an Ed25519 signature');
    }
    final signature = sig.string();
    sig.end();
    reader.end();
    if (publicKey.length != 32 || signature.length != 64) {
      throw const FormatException('malformed Ed25519 signature');
    }
    return _ParsedSignature(publicKey, signature, hashAlgorithm);
  }

  static List<int> _publicKeyBlob(String publicKey) {
    _rawPublicKey(publicKey);
    return base64.decode(_keyLine.firstMatch(publicKey)!.group(1)!);
  }

  /// The 32 raw bytes of [publicKey] (`ssh-ed25519 <base64>`). Throws
  /// [FormatException] for anything else.
  static List<int> _rawPublicKey(String publicKey) {
    final match = _keyLine.firstMatch(publicKey);
    if (match == null) {
      throw const FormatException('not an ssh-ed25519 public key');
    }
    final reader = _Reader(base64.decode(match.group(1)!));
    if (ascii.decode(reader.string(), allowInvalid: true) != _keyType) {
      throw const FormatException('not an ssh-ed25519 public key');
    }
    final raw = reader.string();
    reader.end();
    if (raw.length != 32) {
      throw const FormatException('not an ssh-ed25519 public key');
    }
    return raw;
  }

  static List<int> _uint32(int value) => [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ];

  static List<int> _string(List<int> bytes) => [
    ..._uint32(bytes.length),
    ...bytes,
  ];

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

class _ParsedSignature {
  const _ParsedSignature(this.publicKey, this.signature, this.hashAlgorithm);

  final List<int> publicKey;
  final List<int> signature;
  final String hashAlgorithm;
}

/// Reads SSH wire fields, refusing anything truncated.
class _Reader {
  _Reader(this._bytes);

  final List<int> _bytes;
  int _offset = 0;

  List<int> take(int length) {
    if (length < 0 || _offset + length > _bytes.length) {
      throw const FormatException('truncated SSH signature');
    }
    final out = _bytes.sublist(_offset, _offset + length);
    _offset += length;
    return out;
  }

  int uint32() {
    final b = take(4);
    return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
  }

  List<int> string() => take(uint32());

  void end() {
    if (_offset != _bytes.length) {
      throw const FormatException('trailing bytes in SSH signature');
    }
  }
}

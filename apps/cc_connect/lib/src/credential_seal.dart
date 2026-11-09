import 'dart:convert';

import 'package:cc_connect/src/seal_cipher.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:crypto/crypto.dart' as crypto;

/// Upper bound on a seal string Connect will even try to parse.
const int maxSealLength = 8 * 1024;

/// The readable half of a seal. Nothing here is trusted on its own: every
/// field except [keyId] is bound into the AEAD's associated data, so editing
/// one makes the seal fail to decrypt.
final class SealHeader {
  /// Creates the header.
  const SealHeader({
    required this.provider,
    required this.accountId,
    required this.appId,
    required this.generation,
    required this.keyId,
  });

  /// `github`, `google` or `slack`.
  final ConnectProvider provider;

  /// GitHub numeric id, Google `sub`, Slack team id.
  final String accountId;

  /// GitHub App id, Google client id, Slack app id.
  final String appId;

  /// The client-secret generation current when the seal was made.
  final int generation;

  /// The keyring kid, or `kms`.
  final String keyId;

  /// The wire form.
  Map<String, Object?> toJson() => {
    'p': provider.name,
    'a': accountId,
    'app': appId,
    'g': generation,
    'k': keyId,
  };
}

/// Who may open a seal: the verified caller and the workspace it names.
final class SealBinding {
  /// Creates the binding.
  const SealBinding({required this.installId, required this.workspaceId});

  /// From the verified RFC 9421 signature, never from the seal or the body.
  final String installId;

  /// From the request body.
  final String workspaceId;
}

/// An opened seal.
final class OpenedSeal {
  /// Creates the value.
  const OpenedSeal(this.header, this.payload);

  /// The header.
  final SealHeader header;

  /// The decrypted payload (refresh token, and per provider the access
  /// token and its expiry).
  final Map<String, Object?> payload;

  /// A string field of [payload], or empty.
  String text(String key) {
    final value = payload[key];
    return value is String ? value : '';
  }

  /// A timestamp field of [payload], or null.
  DateTime? time(String key) {
    final value = payload[key];
    return value is String ? DateTime.tryParse(value)?.toUtc() : null;
  }
}

/// Builds and opens `credential_seal`s:
/// `v1.<b64url(header json)>.<b64url(ciphertext)>`.
///
/// The AEAD associated data is the canonical JSON of
/// `{v, provider, connect_origin, install_id, workspace_id, account_id,
/// app_id, secret_generation}`, so a seal copied to another server, another
/// workspace or another Connect never decrypts.
final class CredentialSealer {
  /// Creates the sealer for the Connect at [connectOrigin] (its canonical
  /// base URL).
  CredentialSealer({required this.connectOrigin, required this._cipher});

  /// The canonical base URL bound into every seal.
  final String connectOrigin;
  final SealCipher _cipher;

  List<int> _aad(
    ConnectProvider provider,
    String accountId,
    String appId,
    int generation,
    SealBinding binding,
  ) => utf8.encode(
    canonicalJson({
      'v': 1,
      'provider': provider.name,
      'connect_origin': connectOrigin,
      'install_id': binding.installId,
      'workspace_id': binding.workspaceId,
      'account_id': accountId,
      'app_id': appId,
      'secret_generation': generation,
    }),
  );

  /// Seals [payload].
  Future<String> seal({
    required ConnectProvider provider,
    required String accountId,
    required String appId,
    required int generation,
    required SealBinding binding,
    required Map<String, Object?> payload,
  }) async {
    final ciphertext = await _cipher.encrypt(
      utf8.encode(jsonEncode(payload)),
      _aad(provider, accountId, appId, generation, binding),
    );
    final header = SealHeader(
      provider: provider,
      accountId: accountId,
      appId: appId,
      generation: generation,
      keyId: ciphertext.keyId,
    );
    return 'v1.${b64url(utf8.encode(jsonEncode(header.toJson())))}'
        '.${b64url(ciphertext.bytes)}';
  }

  /// Reads a seal's header without decrypting. Throws
  /// [ConnectException] (`access_denied`) when malformed.
  SealHeader header(String seal) => _split(seal).header;

  /// Opens [seal] for [binding]. Throws [ConnectException]: `access_denied`
  /// when the seal is malformed, for another provider, or does not decrypt
  /// for this caller.
  Future<OpenedSeal> open(
    String seal, {
    required ConnectProvider provider,
    required SealBinding binding,
  }) async {
    final parts = _split(seal);
    final header = parts.header;
    if (header.provider != provider) {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    final List<int> plaintext;
    try {
      plaintext = await _cipher.decrypt(
        SealCiphertext(header.keyId, parts.ciphertext),
        _aad(
          header.provider,
          header.accountId,
          header.appId,
          header.generation,
          binding,
        ),
      );
    } on SealDecryptFailed {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(plaintext));
    } on FormatException {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    if (decoded is! Map<String, Object?>) {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    return OpenedSeal(header, decoded);
  }

  ({SealHeader header, List<int> ciphertext}) _split(String seal) {
    const denied = ConnectException(ConnectErrorCode.accessDenied);
    if (seal.length > maxSealLength) {
      throw denied;
    }
    final parts = seal.split('.');
    if (parts.length != 3 || parts[0] != 'v1') {
      throw denied;
    }
    try {
      final json = jsonDecode(utf8.decode(unb64url(parts[1])));
      final ciphertext = unb64url(parts[2]);
      if (json is! Map) {
        throw denied;
      }
      final provider = ConnectProvider.fromWire(json['p']);
      final account = json['a'];
      final app = json['app'];
      final generation = json['g'];
      final keyId = json['k'];
      if (provider == null ||
          provider == ConnectProvider.linear ||
          account is! String ||
          account.isEmpty ||
          app is! String ||
          app.isEmpty ||
          generation is! int ||
          generation < 1 ||
          keyId is! String ||
          keyId.isEmpty ||
          json.length != 5) {
        throw denied;
      }
      return (
        header: SealHeader(
          provider: provider,
          accountId: account,
          appId: app,
          generation: generation,
          keyId: keyId,
        ),
        ciphertext: ciphertext,
      );
    } on FormatException {
      throw denied;
    }
  }
}

/// The seal-handoff key for [seal]: SHA-256 of the exact seal string.
String sealDigest(String seal) =>
    crypto.sha256.convert(utf8.encode(seal)).toString();

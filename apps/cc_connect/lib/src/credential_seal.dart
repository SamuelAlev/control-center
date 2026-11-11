import 'dart:convert';

import 'package:cc_connect/src/connect_log.dart';
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

/// What a seal holds. Bound into the AEAD, so one kind never opens as
/// another.
enum SealKind {
  /// A grant a server keeps and hands back (refresh token, access token).
  grant,

  /// A one-repository child token Connect keeps for itself (reuse and
  /// revocation); it never leaves Connect.
  childRecord,
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
/// workspace or another Connect never decrypts. A record Connect keeps for
/// itself ([SealKind.childRecord]) also binds `kind`, so it never opens as a
/// grant seal, and a grant seal never opens as one of them.
final class CredentialSealer {
  /// Creates the sealer for the Connect at [connectOrigin] (its canonical
  /// base URL). [retryDelays] space the retries of a failed encryption.
  CredentialSealer({
    required this.connectOrigin,
    required this._cipher,
    required this._log,
    this.retryDelays = const [
      Duration(milliseconds: 100),
      Duration(milliseconds: 400),
    ],
  });

  /// The canonical base URL bound into every seal.
  final String connectOrigin;

  /// Waits between encryption attempts: a seal is made after the provider
  /// already rotated the refresh token, so giving up at once loses it.
  final List<Duration> retryDelays;
  final SealCipher _cipher;
  final ConnectLog _log;

  /// Writes `seal.refused` for [provider] (at most once a minute per
  /// reason).
  void refused(ConnectProvider provider, String reason) => _log.sampled(
    'seal.refused',
    '${provider.name}/$reason',
    {'provider': provider.name, 'reason': reason},
  );

  List<int> _aad(
    ConnectProvider provider,
    String accountId,
    String appId,
    int generation,
    SealBinding binding,
    SealKind kind,
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
      if (kind == SealKind.childRecord) 'kind': 'child',
    }),
  );

  /// Seals [payload] as a [kind].
  Future<String> seal({
    required ConnectProvider provider,
    required String accountId,
    required String appId,
    required int generation,
    required SealBinding binding,
    required Map<String, Object?> payload,
    SealKind kind = SealKind.grant,
  }) async {
    final plaintext = utf8.encode(jsonEncode(payload));
    final aad = _aad(provider, accountId, appId, generation, binding, kind);
    SealCiphertext? ciphertext;
    for (var attempt = 0; ciphertext == null; attempt++) {
      try {
        ciphertext = await _cipher.encrypt(plaintext, aad);
      } on Object catch (error, stack) {
        if (attempt >= retryDelays.length) {
          _log.exception('seal.encrypt_failed', error, stack, {
            'provider': provider.name,
            'count': attempt + 1,
          });
          rethrow;
        }
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
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

  /// Opens [seal] for [binding] as a [kind]. Throws [ConnectException]:
  /// `access_denied` when the seal is malformed, for another provider or
  /// kind, or does not decrypt for this caller.
  Future<OpenedSeal> open(
    String seal, {
    required ConnectProvider provider,
    required SealBinding binding,
    SealKind kind = SealKind.grant,
  }) async {
    final ({SealHeader header, List<int> ciphertext}) parts;
    try {
      parts = _split(seal);
    } on ConnectException {
      refused(provider, 'malformed');
      rethrow;
    }
    final header = parts.header;
    if (header.provider != provider) {
      refused(provider, 'provider');
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
          kind,
        ),
      );
    } on SealDecryptFailed {
      refused(provider, 'decrypt');
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

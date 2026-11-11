import 'dart:convert';

import 'package:cc_connect_core/src/encoding.dart';
import 'package:cc_connect_core/src/install_identity.dart';
import 'package:crypto/crypto.dart' as crypto;

/// The only signature label Connect issues or accepts.
const String connectSignatureLabel = 'sig1';

/// The RFC 9421 `tag` every Connect request signature carries.
const String connectSignatureTag = 'cc-connect/1';

/// How far a signature's `created` may sit from the verifier's clock.
const Duration connectSignatureSkew = Duration(seconds: 120);

/// The request body content type every signed call uses, including bodiless
/// ones (so the covered component list never varies).
const String connectContentType = 'application/json';

/// Upper bound on a signed request body, enforced by Connect before hashing.
const int connectMaxRequestBytes = 16 * 1024;

/// The covered components, in signing order. Fixed: a verifier accepts this
/// exact list and nothing else, so no request can be signed over less.
const List<String> _covered = [
  '@method',
  '@target-uri',
  'content-type',
  'content-digest',
];

/// The RFC 9530 `Content-Digest` value for [body].
String contentDigestFor(List<int> body) =>
    'sha-256=:${base64.encode(crypto.sha256.convert(body).bytes)}:';

String _signatureParams({
  required int created,
  required String nonce,
  required String keyId,
}) =>
    '(${_covered.map((c) => '"$c"').join(' ')})'
    ';created=$created'
    ';nonce="$nonce"'
    ';keyid="$keyId"'
    ';alg="ed25519"'
    ';tag="$connectSignatureTag"';

String _signatureBase({
  required String method,
  required String targetUri,
  required String contentType,
  required String contentDigest,
  required String params,
}) =>
    '"@method": ${method.toUpperCase()}\n'
    '"@target-uri": $targetUri\n'
    '"content-type": $contentType\n'
    '"content-digest": $contentDigest\n'
    '"@signature-params": $params';

/// Signs outbound Connect calls as one [ConnectInstallIdentity].
final class ConnectRequestSigner {
  /// Creates a signer for [identity].
  ConnectRequestSigner(this.identity, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Whose key signs.
  final ConnectInstallIdentity identity;
  final DateTime Function() _now;

  /// The headers to attach to a request with [method], [targetUri] and
  /// [body]: `content-type`, `content-digest`, `signature-input` and
  /// `signature`. [nonce] is generated when omitted (tests pin it).
  Future<Map<String, String>> sign({
    required String method,
    required Uri targetUri,
    required List<int> body,
    String? nonce,
  }) async {
    final created = _now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final usedNonce = nonce ?? b64url(randomBytes(16));
    final digest = contentDigestFor(body);
    final params = _signatureParams(
      created: created,
      nonce: usedNonce,
      keyId: identity.keyId,
    );
    final base = _signatureBase(
      method: method,
      targetUri: targetUri.toString(),
      contentType: connectContentType,
      contentDigest: digest,
      params: params,
    );
    final signature = await identity.sign(utf8.encode(base));
    return {
      'content-type': connectContentType,
      'content-digest': digest,
      'signature-input': '$connectSignatureLabel=$params',
      'signature': '$connectSignatureLabel=:${base64.encode(signature)}:',
    };
  }
}

/// Why a signed request was refused. Deliberately coarse on the wire: every
/// one of these answers `access_denied` except [stale], which answers
/// `stale_request` so an honest client with a drifting clock can say so.
enum ConnectSignatureFailure {
  /// A required header is missing or malformed.
  malformed,

  /// The body does not match `content-digest`.
  digest,

  /// `created` is outside the allowed skew.
  stale,

  /// The signature does not verify over the reconstructed base.
  signature,
}

/// Thrown by [verifyConnectRequest].
final class ConnectSignatureException implements Exception {
  /// Creates the exception.
  const ConnectSignatureException(this.failure);

  /// What failed.
  final ConnectSignatureFailure failure;

  @override
  String toString() => 'ConnectSignatureException(${failure.name})';
}

/// A request whose signature verified. The [installId] is recomputed from the
/// verified key, never read from the request.
final class VerifiedConnectRequest {
  /// Creates the result.
  const VerifiedConnectRequest({
    required this.installId,
    required this.keyId,
    required this.nonce,
    required this.created,
  });

  /// The caller's install id.
  final String installId;

  /// The caller's key id (base64url SPKI).
  final String keyId;

  /// The request nonce. The verifier checks its shape; the caller must still
  /// record it in a replay cache for at least twice [connectSignatureSkew].
  final String nonce;

  /// When the caller says it signed.
  final DateTime created;
}

final RegExp _nonceShape = RegExp(r'^[A-Za-z0-9_-]{22}$');

/// Verifies an inbound Connect request.
///
/// [targetUri] must be built from the verifier's own configured public URL
/// plus the request's path and query — never from `Host` or
/// `X-Forwarded-*` — so a signature made for another Connect cannot verify
/// here. [header] looks names up lower-cased. Throws
/// [ConnectSignatureException]; returns the caller identity otherwise.
Future<VerifiedConnectRequest> verifyConnectRequest({
  required String method,
  required Uri targetUri,
  required String? Function(String lowerCaseName) header,
  required List<int> body,
  DateTime Function()? now,
}) async {
  final contentType = header('content-type');
  final digest = header('content-digest');
  final input = header('signature-input');
  final signatureHeader = header('signature');
  if (contentType == null ||
      digest == null ||
      input == null ||
      signatureHeader == null) {
    throw const ConnectSignatureException(ConnectSignatureFailure.malformed);
  }
  if (contentType.trim().toLowerCase() != connectContentType) {
    throw const ConnectSignatureException(ConnectSignatureFailure.malformed);
  }
  if (!constantTimeEquals(digest.trim(), contentDigestFor(body))) {
    throw const ConnectSignatureException(ConnectSignatureFailure.digest);
  }

  final params = _parseSignatureInput(input.trim());
  final signatureBytes = _parseSignature(signatureHeader.trim());
  if (params == null || signatureBytes == null) {
    throw const ConnectSignatureException(ConnectSignatureFailure.malformed);
  }
  final clockSeconds =
      (now ?? DateTime.now)().toUtc().millisecondsSinceEpoch ~/ 1000;
  if ((params.created - clockSeconds).abs() > connectSignatureSkew.inSeconds) {
    throw const ConnectSignatureException(ConnectSignatureFailure.stale);
  }
  final createdAt = DateTime.fromMillisecondsSinceEpoch(
    params.created * 1000,
    isUtc: true,
  );
  final publicKey = publicKeyFromKeyId(params.keyId);
  if (publicKey == null) {
    throw const ConnectSignatureException(ConnectSignatureFailure.malformed);
  }
  final base = _signatureBase(
    method: method,
    targetUri: targetUri.toString(),
    contentType: connectContentType,
    contentDigest: contentDigestFor(body),
    params: _signatureParams(
      created: params.created,
      nonce: params.nonce,
      keyId: params.keyId,
    ),
  );
  final ok = await verifyEd25519(
    message: utf8.encode(base),
    signature: signatureBytes,
    publicKey: publicKey,
  );
  if (!ok) {
    throw const ConnectSignatureException(ConnectSignatureFailure.signature);
  }
  return VerifiedConnectRequest(
    installId: installIdForPublicKey(publicKey),
    keyId: params.keyId,
    nonce: params.nonce,
    created: createdAt,
  );
}

/// The install id a `signature-input` header names, before anything is
/// verified, or null when the header does not parse. It proves nothing: use
/// it only to refuse an install early (before the Ed25519 check), never to
/// admit one.
String? claimedInstallId(String? signatureInput) {
  final params = signatureInput == null
      ? null
      : _parseSignatureInput(signatureInput.trim());
  final publicKey = params == null ? null : publicKeyFromKeyId(params.keyId);
  return publicKey == null ? null : installIdForPublicKey(publicKey);
}

/// Parses exactly the `signature-input` this package emits. Anything else —
/// another label, a different component list, a missing or extra parameter, a
/// different `alg` or `tag` — is refused rather than interpreted.
({int created, String nonce, String keyId})? _parseSignatureInput(
  String value,
) {
  const prefix = '$connectSignatureLabel=';
  if (!value.startsWith(prefix)) {
    return null;
  }
  final rest = value.substring(prefix.length);
  final components = '(${_covered.map((c) => '"$c"').join(' ')})';
  if (!rest.startsWith(components)) {
    return null;
  }
  final paramText = rest.substring(components.length);
  final params = <String, String>{};
  final pattern = RegExp(r';([a-z]+)=("([^"\\]*)"|([0-9]+))');
  var consumed = 0;
  for (final match in pattern.allMatches(paramText)) {
    if (match.start != consumed) {
      return null;
    }
    consumed = match.end;
    final key = match.group(1)!;
    if (params.containsKey(key)) {
      return null;
    }
    params[key] = match.group(3) ?? match.group(4)!;
  }
  if (consumed != paramText.length) {
    return null;
  }
  if (params.length != 5 ||
      params['alg'] != 'ed25519' ||
      params['tag'] != connectSignatureTag) {
    return null;
  }
  final created = int.tryParse(params['created'] ?? '');
  final nonce = params['nonce'];
  final keyId = params['keyid'];
  if (created == null ||
      nonce == null ||
      keyId == null ||
      !_nonceShape.hasMatch(nonce)) {
    return null;
  }
  return (created: created, nonce: nonce, keyId: keyId);
}

List<int>? _parseSignature(String value) {
  final match = RegExp(
    '^$connectSignatureLabel=:([A-Za-z0-9+/]+={0,2}):\$',
  ).firstMatch(value);
  if (match == null) {
    return null;
  }
  try {
    final bytes = base64.decode(match.group(1)!);
    return bytes.length == 64 ? bytes : null;
  } on FormatException {
    return null;
  }
}

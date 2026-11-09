import 'dart:convert';

import 'package:cc_connect_core/src/encoding.dart';
import 'package:cc_connect_core/src/install_identity.dart';
import 'package:cryptography/cryptography.dart';

/// The wire protocol this package speaks. A config with another `protocol`
/// is refused: `/v1` is additive, a new number is not.
const int connectProtocolVersion = 1;

/// The Control Center-operated Connect.
const String hostedConnectOrigin = 'https://connect.usectrl.dev';

/// Ed25519 public keys (base64url, raw 32 bytes) trusted to sign the hosted
/// Connect's `/v1/config`.
///
/// The private half is generated and kept offline with the release signing
/// keys (`dart run cc_connect:config_tool keygen`, see RELEASING.md); only
/// the public half is compiled in. With the list empty a server refuses
/// hosted mode outright rather than trusting an unsigned config.
const List<String> hostedConfigRootKeys = <String>[
  'dBU1wToogsU1fdLLAXHVKa8bkjUhfBElRQQC1_YIpMY',
];

/// Domain-separation prefix for config signatures.
const String _configSignatureContext = 'cc-connect-config/v1\n';

/// The GitHub lane as Connect advertises it.
final class GitHubLaneConfig {
  /// Creates the lane config.
  const GitHubLaneConfig({
    required this.appId,
    required this.clientId,
    required this.appSlug,
    this.minSealGeneration = 1,
    this.acceptsNewAuthorizations = true,
  });

  /// Parses the lane; null when absent or malformed.
  static GitHubLaneConfig? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final appId = json['app_id'];
    final clientId = json['client_id'];
    final slug = json['app_slug'];
    if (appId is! int || clientId is! String || slug is! String) {
      return null;
    }
    if (clientId.isEmpty || slug.isEmpty || appId <= 0) {
      return null;
    }
    return GitHubLaneConfig(
      appId: appId,
      clientId: clientId,
      appSlug: slug,
      minSealGeneration: _int(json['min_seal_generation'], 1),
      acceptsNewAuthorizations: json['accepts_new_authorizations'] != false,
    );
  }

  /// The GitHub App id.
  final int appId;

  /// The App's OAuth client id.
  final String clientId;

  /// The App's URL slug (`github.com/apps/<slug>`), also its `@mention`.
  final String appSlug;

  /// Seals issued under an older secret generation must sign in again.
  final int minSealGeneration;

  /// False while sign-in is paused (pending verification, incident).
  final bool acceptsNewAuthorizations;

  /// The wire form.
  Map<String, Object?> toJson() => {
    'app_id': appId,
    'client_id': clientId,
    'app_slug': appSlug,
    'min_seal_generation': minSealGeneration,
    'accepts_new_authorizations': acceptsNewAuthorizations,
  };
}

/// A lane identified only by an OAuth client id (Google, Linear).
final class ClientIdLaneConfig {
  /// Creates the lane config.
  const ClientIdLaneConfig({
    required this.clientId,
    this.minSealGeneration = 1,
    this.acceptsNewAuthorizations = true,
  });

  /// Parses the lane; null when absent or malformed.
  static ClientIdLaneConfig? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final clientId = json['client_id'];
    if (clientId is! String || clientId.isEmpty) {
      return null;
    }
    return ClientIdLaneConfig(
      clientId: clientId,
      minSealGeneration: _int(json['min_seal_generation'], 1),
      acceptsNewAuthorizations: json['accepts_new_authorizations'] != false,
    );
  }

  /// The OAuth client id.
  final String clientId;

  /// Seals issued under an older secret generation must sign in again.
  final int minSealGeneration;

  /// False while sign-in is paused.
  final bool acceptsNewAuthorizations;

  /// The wire form.
  Map<String, Object?> toJson() => {
    'client_id': clientId,
    'min_seal_generation': minSealGeneration,
    'accepts_new_authorizations': acceptsNewAuthorizations,
  };
}

/// The Slack lane.
final class SlackLaneConfig {
  /// Creates the lane config.
  const SlackLaneConfig({
    required this.appId,
    required this.clientId,
    this.minSealGeneration = 1,
    this.acceptsNewAuthorizations = true,
  });

  /// Parses the lane; null when absent or malformed.
  static SlackLaneConfig? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final appId = json['app_id'];
    final clientId = json['client_id'];
    if (appId is! String || clientId is! String) {
      return null;
    }
    if (appId.isEmpty || clientId.isEmpty) {
      return null;
    }
    return SlackLaneConfig(
      appId: appId,
      clientId: clientId,
      minSealGeneration: _int(json['min_seal_generation'], 1),
      acceptsNewAuthorizations: json['accepts_new_authorizations'] != false,
    );
  }

  /// The Slack app id (`A…`).
  final String appId;

  /// The Slack OAuth client id.
  final String clientId;

  /// Seals issued under an older secret generation must sign in again.
  final int minSealGeneration;

  /// False while installs are paused (Marketplace review, incident).
  final bool acceptsNewAuthorizations;

  /// The wire form.
  Map<String, Object?> toJson() => {
    'app_id': appId,
    'client_id': clientId,
    'min_seal_generation': minSealGeneration,
    'accepts_new_authorizations': acceptsNewAuthorizations,
  };
}

/// How Connect serves GIF search.
enum KlipyLaneMode {
  /// Connect proxies search and trending; the key never leaves it.
  proxy,

  /// Connect hands out a rotatable app key in [ConnectConfig.klipy].
  key;

  /// Parses a wire value.
  static KlipyLaneMode? fromWire(Object? wire) {
    for (final mode in values) {
      if (mode.name == wire) {
        return mode;
      }
    }
    return null;
  }
}

/// The Klipy lane.
final class KlipyLaneConfig {
  /// Creates the lane config.
  const KlipyLaneConfig({required this.mode, this.appKey = ''});

  /// Parses the lane; null when absent or malformed.
  static KlipyLaneConfig? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final mode = KlipyLaneMode.fromWire(json['mode']);
    if (mode == null) {
      return null;
    }
    final key = json['app_key'];
    if (mode == KlipyLaneMode.key && (key is! String || key.isEmpty)) {
      return null;
    }
    return KlipyLaneConfig(mode: mode, appKey: key is String ? key : '');
  }

  /// How search is served.
  final KlipyLaneMode mode;

  /// The rotatable key, only in [KlipyLaneMode.key].
  final String appKey;

  /// The wire form.
  Map<String, Object?> toJson() => {
    'mode': mode.name,
    if (mode == KlipyLaneMode.key) 'app_key': appKey,
  };
}

/// A parsed `/v1/config`. Lanes a Connect does not serve are null.
final class ConnectConfig {
  /// Creates a config.
  const ConnectConfig({
    required this.epoch,
    required this.issuedAt,
    this.github,
    this.google,
    this.linear,
    this.slack,
    this.klipy,
    this.signature = '',
  });

  /// Parses a config payload. Throws [FormatException] when the payload is
  /// not a config this package understands.
  factory ConnectConfig.fromJson(Map<String, Object?> json) {
    if (json['protocol'] != connectProtocolVersion) {
      throw const FormatException('unsupported Connect protocol');
    }
    final epoch = json['epoch'];
    final issued = json['issued_at'];
    if (epoch is! int || epoch < 0 || issued is! String) {
      throw const FormatException('malformed Connect config');
    }
    final issuedAt = DateTime.tryParse(issued);
    if (issuedAt == null) {
      throw const FormatException('malformed Connect config issued_at');
    }
    final signature = json['signature'];
    return ConnectConfig(
      epoch: epoch,
      issuedAt: issuedAt.toUtc(),
      github: GitHubLaneConfig.tryParse(json['github']),
      google: ClientIdLaneConfig.tryParse(json['google']),
      linear: ClientIdLaneConfig.tryParse(json['linear']),
      slack: SlackLaneConfig.tryParse(json['slack']),
      klipy: KlipyLaneConfig.tryParse(json['klipy']),
      signature: signature is String ? signature : '',
    );
  }

  /// Monotonic counter; a server never adopts a lower epoch than it has seen.
  final int epoch;

  /// When the config was issued.
  final DateTime issuedAt;

  /// The GitHub lane, when served.
  final GitHubLaneConfig? github;

  /// The Google Calendar lane, when served.
  final ClientIdLaneConfig? google;

  /// The Linear lanes (`linear` and `linear_app` share one client id).
  final ClientIdLaneConfig? linear;

  /// The Slack lane, when served.
  final SlackLaneConfig? slack;

  /// The Klipy lane, when served.
  final KlipyLaneConfig? klipy;

  /// The detached signature (empty for an unsigned self-hosted config).
  final String signature;

  /// The signed payload, without [signature].
  Map<String, Object?> payload() => {
    'protocol': connectProtocolVersion,
    'epoch': epoch,
    'issued_at': issuedAt.toUtc().toIso8601String(),
    if (github != null) 'github': github!.toJson(),
    if (google != null) 'google': google!.toJson(),
    if (linear != null) 'linear': linear!.toJson(),
    if (slack != null) 'slack': slack!.toJson(),
    if (klipy != null) 'klipy': klipy!.toJson(),
  };

  /// The wire form, signature included when present.
  Map<String, Object?> toJson() => {
    ...payload(),
    if (signature.isNotEmpty) 'signature': signature,
  };

  /// The identifiers a server pins on first use of a self-hosted Connect. A
  /// change in any of them needs the owner's confirmation.
  Map<String, String> pinnedIdentifiers() => {
    if (github != null) ...{
      'github.app_id': '${github!.appId}',
      'github.client_id': github!.clientId,
    },
    if (google != null) 'google.client_id': google!.clientId,
    if (linear != null) 'linear.client_id': linear!.clientId,
    if (slack != null) ...{
      'slack.app_id': slack!.appId,
      'slack.client_id': slack!.clientId,
    },
  };
}

List<int> _signedBytes(Map<String, Object?> json) {
  final payload = Map<String, Object?>.of(json)..remove('signature');
  return utf8.encode('$_configSignatureContext${canonicalJson(payload)}');
}

/// Verifies [json]'s detached signature against any of [trustedKeys]
/// (base64url raw Ed25519 public keys). The signature covers the canonical
/// JSON of every other field, so an added, removed or edited field fails.
Future<bool> verifyConnectConfigSignature(
  Map<String, Object?> json, {
  List<String> trustedKeys = hostedConfigRootKeys,
}) async {
  final signature = json['signature'];
  if (signature is! String || signature.isEmpty) {
    return false;
  }
  final List<int> signatureBytes;
  try {
    signatureBytes = unb64url(signature);
  } on FormatException {
    return false;
  }
  final List<int> message;
  try {
    message = _signedBytes(json);
  } on ArgumentError {
    return false;
  }
  for (final key in trustedKeys) {
    final List<int> publicKey;
    try {
      publicKey = unb64url(key);
    } on FormatException {
      continue;
    }
    if (await verifyEd25519(
      message: message,
      signature: signatureBytes,
      publicKey: publicKey,
    )) {
      return true;
    }
  }
  return false;
}

/// Signs a config payload with a raw 32-byte Ed25519 [seed]. Used by the
/// offline signing tool and tests; never by a running service.
Future<String> signConnectConfig(
  Map<String, Object?> payload,
  List<int> seed,
) async {
  final keyPair = await Ed25519().newKeyPairFromSeed(seed);
  final signature = await Ed25519().sign(
    _signedBytes(payload),
    keyPair: keyPair,
  );
  return b64url(signature.bytes);
}

/// The raw public key (base64url) for an Ed25519 [seed].
Future<String> configPublicKeyForSeed(List<int> seed) async {
  final keyPair = await Ed25519().newKeyPairFromSeed(seed);
  final publicKey = await keyPair.extractPublicKey();
  return b64url(publicKey.bytes);
}

int _int(Object? value, int fallback) =>
    value is int && value >= 0 ? value : fallback;

import 'dart:convert';

import 'package:cc_connect/src/secrets.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// Why a Connect refused to start. The message names the offending variable
/// and never includes a secret value.
final class ConnectConfigException implements Exception {
  /// Creates the exception.
  const ConnectConfigException(this.message);

  /// What is wrong, for the operator.
  final String message;

  @override
  String toString() => 'ConnectConfigException: $message';
}

/// Where credential seals are encrypted.
enum SealBackend {
  /// AES-256-GCM under a local keyring (`CONNECT_SEAL_KEYS`).
  local,

  /// Cloud KMS symmetric AEAD (`CONNECT_KMS_KEY`).
  gcpKms,
}

/// Where short-lived state lives.
enum StateBackend {
  /// Process memory: one instance only.
  memory,

  /// Redis / Memorystore, shared by every instance.
  redis,
}

/// Where install bindings persist.
enum BindingBackend {
  /// A JSON file in `CONNECT_DATA_DIR`.
  file,

  /// Firestore (REST, metadata-server credentials).
  firestore,
}

/// The shared GitHub App's OAuth credentials (no RSA key, no webhook secret).
final class GitHubCredentials {
  /// Creates the credentials.
  const GitHubCredentials({
    required this.appId,
    required this.appSlug,
    required this.clientId,
    required this.clientSecret,
    this.acceptsNewAuthorizations = true,
    this.minSealGeneration = 1,
  });

  /// The App id.
  final int appId;

  /// The App slug (`github.com/apps/<slug>`).
  final String appSlug;

  /// The App's OAuth client id.
  final String clientId;

  /// The App's OAuth client secret, both generations.
  final DualSecret clientSecret;

  /// Self-hosted: whether new sign-ins are accepted.
  final bool acceptsNewAuthorizations;

  /// Self-hosted: seals below this generation must sign in again.
  final int minSealGeneration;
}

/// The Google web OAuth client.
final class GoogleCredentials {
  /// Creates the credentials.
  const GoogleCredentials({
    required this.clientId,
    required this.clientSecret,
    this.acceptsNewAuthorizations = true,
    this.minSealGeneration = 1,
  });

  /// The OAuth client id.
  final String clientId;

  /// The OAuth client secret, both generations.
  final DualSecret clientSecret;

  /// Self-hosted: whether new sign-ins are accepted.
  final bool acceptsNewAuthorizations;

  /// Self-hosted: seals below this generation must sign in again.
  final int minSealGeneration;
}

/// The public Linear OAuth client (no secret: Linear tokens never transit
/// Connect).
final class LinearCredentials {
  /// Creates the credentials.
  const LinearCredentials({
    required this.clientId,
    this.acceptsNewAuthorizations = true,
  });

  /// The OAuth client id.
  final String clientId;

  /// Self-hosted: whether new sign-ins are accepted.
  final bool acceptsNewAuthorizations;
}

/// The shared Slack app.
final class SlackCredentials {
  /// Creates the credentials.
  const SlackCredentials({
    required this.appId,
    required this.clientId,
    required this.clientSecret,
    required this.signingSecret,
    this.acceptsNewAuthorizations = true,
    this.minSealGeneration = 1,
  });

  /// The Slack app id (`A…`).
  final String appId;

  /// The OAuth client id.
  final String clientId;

  /// The OAuth client secret, both generations.
  final DualSecret clientSecret;

  /// The request signing secret, both generations.
  final DualSecret signingSecret;

  /// Self-hosted: whether new installs are accepted.
  final bool acceptsNewAuthorizations;

  /// Self-hosted: seals below this generation must sign in again.
  final int minSealGeneration;
}

/// The Klipy app key.
final class KlipyCredentials {
  /// Creates the credentials.
  const KlipyCredentials({required this.mode, required this.appKey});

  /// Proxy (key stays here) or key (handed out in `/v1/config`).
  final KlipyLaneMode mode;

  /// The app key, both generations.
  final DualSecret appKey;
}

/// Which installs may use this Connect. Closed by default.
final class InstallAccess {
  /// Creates the policy.
  const InstallAccess({
    this.allowAll = false,
    this.allowed = const {},
    this.denied = const {},
  });

  /// `CONNECT_ALLOWED_INSTALLS=*` (hosted only).
  final bool allowAll;

  /// Explicitly allowed install ids.
  final Set<String> allowed;

  /// Install ids refused even when [allowAll] (the kill switch).
  final Set<String> denied;

  /// Whether [installId] may call.
  bool permits(String installId) =>
      !denied.contains(installId) && (allowAll || allowed.contains(installId));
}

/// Rate ceilings. Per-install and per-IP are token buckets refilled per
/// minute; the global one per second.
final class ConnectRateLimits {
  /// Creates the limits.
  const ConnectRateLimits({
    this.perInstallPerMinute = 600,
    this.perIpPerMinute = 300,
    this.globalPerSecond = 500,
    this.slackEventsPerTeamPerMinute = 600,
    this.klipyPerInstallPerMinute = 120,
  });

  /// Signed calls per install per minute.
  final int perInstallPerMinute;

  /// Requests per client IP per minute (Slack hooks excepted).
  final int perIpPerMinute;

  /// Requests per second across the instance.
  final int globalPerSecond;

  /// Slack events queued per team per minute; the rest are dropped (and
  /// still answered 200, so Slack never disables the subscription).
  final int slackEventsPerTeamPerMinute;

  /// Klipy proxy calls per install per minute.
  final int klipyPerInstallPerMinute;
}

/// A hosted Connect's offline-signed `/v1/config`, from
/// `CONNECT_SIGNED_CONFIG` or `CONNECT_SIGNED_CONFIG_FILE`, served verbatim.
final class SignedConfigFile {
  /// Parses [bytes]; throws [ConnectConfigException].
  factory SignedConfigFile.parse(List<int> bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const ConnectConfigException('the signed config is not JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const ConnectConfigException(
        'the signed config is not a JSON object',
      );
    }
    final ConnectConfig parsed;
    try {
      parsed = ConnectConfig.fromJson(decoded);
    } on FormatException catch (error) {
      throw ConnectConfigException('the signed config: ${error.message}');
    }
    if (parsed.signature.isEmpty) {
      throw const ConnectConfigException(
        'the signed config carries no signature',
      );
    }
    for (final lane in const ['github', 'google', 'linear', 'slack', 'klipy']) {
      final present = decoded[lane] != null;
      final understood = switch (lane) {
        'github' => parsed.github != null,
        'google' => parsed.google != null,
        'linear' => parsed.linear != null,
        'slack' => parsed.slack != null,
        _ => parsed.klipy != null,
      };
      if (present && !understood) {
        throw ConnectConfigException(
          'the signed config: lane $lane is malformed',
        );
      }
    }
    return SignedConfigFile._(List.unmodifiable(bytes), decoded, parsed);
  }

  SignedConfigFile._(this.bytes, this.json, this.config);

  /// The exact file bytes (served verbatim).
  final List<int> bytes;

  /// The decoded JSON.
  final Map<String, Object?> json;

  /// The parsed config.
  final ConnectConfig config;
}

/// Everything a Connect needs, from the environment.
final class ConnectServiceConfig {
  /// Creates a config. Prefer [ConnectServiceConfig.fromEnvironment]; this
  /// constructor exists for tests and programmatic embedding and performs
  /// only the public-URL checks.
  ConnectServiceConfig({
    required String publicUrl,
    required this.access,
    this.host = '0.0.0.0',
    this.port = 8790,
    this.trustProxyHops = 0,
    this.github,
    this.google,
    this.linear,
    this.slack,
    this.klipy,
    this.githubAllowedOwners = const {},
    this.signedConfigPath,
    this.signedConfigInline,
    this.configEpoch = 1,
    this.configPublicKeys = const [],
    this.sealBackend = SealBackend.local,
    this.sealKeys,
    this.kmsKey = '',
    this.stateBackend = StateBackend.memory,
    this.redisUrl,
    this.redisCaFile = '',
    this.bindingBackend = BindingBackend.file,
    this.dataDir = 'data',
    this.firestoreProject = '',
    this.firestoreDatabase = '(default)',
    this.imageDigest = '',
    this.version = connectServiceVersion,
    this.logHmacKey,
    this.rateLimits = const ConnectRateLimits(),
  }) : publicBaseUrl = _checkedBaseUrl(publicUrl) {
    basePath = Uri.parse(publicBaseUrl).path;
  }

  /// Reads every `CONNECT_*` variable from [env]. Throws
  /// [ConnectConfigException] on anything that would start an open, unsafe
  /// or half-configured Connect.
  factory ConnectServiceConfig.fromEnvironment(
    Map<String, String> env, {
    SecretFileReader? readFile,
    DateTime Function()? clock,
  }) {
    try {
      return _fromEnvironment(env, readFile: readFile, clock: clock);
    } on ArgumentError catch (error) {
      throw ConnectConfigException('${error.message}');
    }
  }

  /// The canonical base URL ([canonicalConnectBaseUrl] of
  /// `CONNECT_PUBLIC_URL`): the RFC 9421 `@target-uri` base, the seal AAD
  /// `connect_origin` and the OAuth callback base.
  final String publicBaseUrl;

  /// The path prefix of [publicBaseUrl] (empty, or `/connect` when mounted).
  late final String basePath;

  /// Bind address.
  final String host;

  /// Bind port.
  final int port;

  /// How many reverse proxies append to `X-Forwarded-For` in front of this
  /// Connect (`CONNECT_TRUST_PROXY`). 0 ignores the header entirely.
  final int trustProxyHops;

  /// The GitHub lane, when complete.
  final GitHubCredentials? github;

  /// The Google lane, when complete.
  final GoogleCredentials? google;

  /// The Linear lanes, when complete.
  final LinearCredentials? linear;

  /// The Slack lane, when complete.
  final SlackCredentials? slack;

  /// The Klipy lane, when complete.
  final KlipyCredentials? klipy;

  /// Which installs may call.
  final InstallAccess access;

  /// When non-empty, scoped tokens are minted only for repositories owned by
  /// these numeric GitHub account ids.
  final Set<int> githubAllowedOwners;

  /// Hosted: the offline-signed config file, re-read as it changes.
  final String? signedConfigPath;

  /// Hosted: the offline-signed config itself, for hosts that cannot mount
  /// a file. Fixed for the process; a new one means a restart.
  final String? signedConfigInline;

  /// Self-hosted: the generated config's epoch.
  final int configEpoch;

  /// Optional Ed25519 public keys the signed config must verify against at
  /// boot (in addition to [hostedConfigRootKeys]).
  final List<String> configPublicKeys;

  /// Seal encryption backend.
  final SealBackend sealBackend;

  /// Local keyring (`kid:base64key,...`, first active).
  final SecretSource? sealKeys;

  /// Cloud KMS key resource name.
  final String kmsKey;

  /// State backend.
  final StateBackend stateBackend;

  /// Redis URL (may carry a password).
  final SecretSource? redisUrl;

  /// A PEM bundle trusted for `rediss://` (Memorystore's server CA).
  final String redisCaFile;

  /// Binding backend.
  final BindingBackend bindingBackend;

  /// Where the file binding store writes.
  final String dataDir;

  /// Firestore project.
  final String firestoreProject;

  /// Firestore database id.
  final String firestoreDatabase;

  /// The running image digest (`/v1/version`).
  final String imageDigest;

  /// The running version (`/v1/version`).
  final String version;

  /// Optional stable HMAC key for install ids in logs; a per-process random
  /// key otherwise.
  final SecretSource? logHmacKey;

  /// Rate ceilings.
  final ConnectRateLimits rateLimits;

  static String _checkedBaseUrl(String publicUrl) {
    final String base;
    try {
      base = canonicalConnectBaseUrl(publicUrl);
    } on FormatException {
      throw const ConnectConfigException(
        'CONNECT_PUBLIC_URL must be an absolute http(s) URL',
      );
    }
    final uri = Uri.parse(base);
    if (uri.scheme != 'https' &&
        !isLoopbackOrigin(canonicalConnectOrigin(base))) {
      throw const ConnectConfigException(
        'CONNECT_PUBLIC_URL must be https (plain http only on loopback)',
      );
    }
    final raw = Uri.parse(publicUrl.trim());
    if (raw.hasQuery || raw.hasFragment) {
      throw const ConnectConfigException(
        'CONNECT_PUBLIC_URL must not carry a query or fragment',
      );
    }
    return base;
  }
}

/// The version string `/v1/version` reports when `CONNECT_VERSION` is unset.
const String connectServiceVersion = '0.0.1';

ConnectServiceConfig _fromEnvironment(
  Map<String, String> env, {
  SecretFileReader? readFile,
  DateTime Function()? clock,
}) {
  String text(String name) => env[name]?.trim() ?? '';

  DualSecret? dual(String name, {String? generationName}) =>
      DualSecret.fromEnvironment(
        env,
        name,
        generationName: generationName,
        readFile: readFile,
        clock: clock,
      );

  SecretSource? secret(String name) =>
      SecretSource.fromEnvironment(env, name, readFile: readFile, clock: clock);

  bool flag(String name, {required bool fallback}) {
    final raw = text(name).toLowerCase();
    if (raw.isEmpty) {
      return fallback;
    }
    if (const {'1', 'true', 'yes', 'on'}.contains(raw)) {
      return true;
    }
    if (const {'0', 'false', 'no', 'off'}.contains(raw)) {
      return false;
    }
    throw ConnectConfigException('$name must be true or false');
  }

  int integer(String name, int fallback, {int min = 0, int? max}) {
    final raw = text(name);
    if (raw.isEmpty) {
      return fallback;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < min || (max != null && parsed > max)) {
      throw ConnectConfigException(
        '$name must be an integer${max == null ? ' >= $min' : ' in $min..$max'}',
      );
    }
    return parsed;
  }

  final publicUrl = text('CONNECT_PUBLIC_URL');
  if (publicUrl.isEmpty) {
    throw const ConnectConfigException('CONNECT_PUBLIC_URL is required');
  }

  // Access control: closed by default.
  final allowedRaw = text('CONNECT_ALLOWED_INSTALLS');
  if (allowedRaw.isEmpty) {
    throw const ConnectConfigException(
      'CONNECT_ALLOWED_INSTALLS is required (comma-separated install ids, '
      'or * on a hosted Connect with a signed config)',
    );
  }
  Set<String> installSet(String name, String raw) {
    final out = <String>{};
    for (final part in raw.split(',')) {
      final id = part.trim().toLowerCase();
      if (id.isEmpty) {
        continue;
      }
      if (!isInstallId(id)) {
        throw ConnectConfigException('$name: "$id" is not an install id');
      }
      out.add(id);
    }
    return out;
  }

  final allowAll = allowedRaw == '*';
  final signedPath = text('CONNECT_SIGNED_CONFIG_FILE');
  final signedInline = text('CONNECT_SIGNED_CONFIG');
  if (signedPath.isNotEmpty && signedInline.isNotEmpty) {
    throw const ConnectConfigException(
      'set CONNECT_SIGNED_CONFIG or CONNECT_SIGNED_CONFIG_FILE, not both',
    );
  }
  final signed = signedPath.isNotEmpty || signedInline.isNotEmpty;
  if (allowAll && !signed) {
    throw const ConnectConfigException(
      'CONNECT_ALLOWED_INSTALLS=* needs CONNECT_SIGNED_CONFIG or '
      'CONNECT_SIGNED_CONFIG_FILE (hosted only); a self-hosted Connect lists '
      'its installs',
    );
  }
  final access = InstallAccess(
    allowAll: allowAll,
    allowed: allowAll
        ? const {}
        : installSet('CONNECT_ALLOWED_INSTALLS', allowedRaw),
    denied: installSet('CONNECT_DENY_INSTALLS', text('CONNECT_DENY_INSTALLS')),
  );
  if (!access.allowAll && access.allowed.isEmpty) {
    throw const ConnectConfigException(
      'CONNECT_ALLOWED_INSTALLS names no install',
    );
  }

  final owners = <int>{};
  for (final part in text('CONNECT_GITHUB_ALLOWED_OWNERS').split(',')) {
    final raw = part.trim();
    if (raw.isEmpty) {
      continue;
    }
    final id = int.tryParse(raw);
    if (id == null || id <= 0) {
      throw ConnectConfigException(
        'CONNECT_GITHUB_ALLOWED_OWNERS: "$raw" is not a numeric account id',
      );
    }
    owners.add(id);
  }

  // Lanes. A lane is built only when every piece is present; a partial lane
  // is simply not served.
  GitHubCredentials? github;
  {
    final appIdRaw = text('CONNECT_GITHUB_APP_ID');
    final slug = text('CONNECT_GITHUB_APP_SLUG');
    final clientId = text('CONNECT_GITHUB_CLIENT_ID');
    final secretPair = dual(
      'CONNECT_GITHUB_CLIENT_SECRET',
      generationName: 'CONNECT_GITHUB_SECRET_GENERATION',
    );
    if (appIdRaw.isNotEmpty &&
        slug.isNotEmpty &&
        clientId.isNotEmpty &&
        secretPair != null) {
      final appId = int.tryParse(appIdRaw);
      if (appId == null || appId <= 0) {
        throw const ConnectConfigException(
          'CONNECT_GITHUB_APP_ID must be a positive integer',
        );
      }
      if (!RegExp(r'^[a-z0-9][a-z0-9-]{0,99}$').hasMatch(slug)) {
        throw const ConnectConfigException(
          'CONNECT_GITHUB_APP_SLUG is not a GitHub App slug',
        );
      }
      github = GitHubCredentials(
        appId: appId,
        appSlug: slug,
        clientId: clientId,
        clientSecret: secretPair,
        acceptsNewAuthorizations: flag(
          'CONNECT_GITHUB_ACCEPTS_NEW',
          fallback: true,
        ),
        minSealGeneration: integer(
          'CONNECT_GITHUB_MIN_SEAL_GENERATION',
          1,
          min: 1,
        ),
      );
    }
  }

  GoogleCredentials? google;
  {
    final clientId = text('CONNECT_GOOGLE_CLIENT_ID');
    final secretPair = dual(
      'CONNECT_GOOGLE_CLIENT_SECRET',
      generationName: 'CONNECT_GOOGLE_SECRET_GENERATION',
    );
    if (clientId.isNotEmpty && secretPair != null) {
      google = GoogleCredentials(
        clientId: clientId,
        clientSecret: secretPair,
        acceptsNewAuthorizations: flag(
          'CONNECT_GOOGLE_ACCEPTS_NEW',
          fallback: true,
        ),
        minSealGeneration: integer(
          'CONNECT_GOOGLE_MIN_SEAL_GENERATION',
          1,
          min: 1,
        ),
      );
    }
  }

  LinearCredentials? linear;
  {
    final clientId = text('CONNECT_LINEAR_CLIENT_ID');
    if (clientId.isNotEmpty) {
      linear = LinearCredentials(
        clientId: clientId,
        acceptsNewAuthorizations: flag(
          'CONNECT_LINEAR_ACCEPTS_NEW',
          fallback: true,
        ),
      );
    }
  }

  SlackCredentials? slack;
  {
    final appId = text('CONNECT_SLACK_APP_ID');
    final clientId = text('CONNECT_SLACK_CLIENT_ID');
    final secretPair = dual(
      'CONNECT_SLACK_CLIENT_SECRET',
      generationName: 'CONNECT_SLACK_SECRET_GENERATION',
    );
    final signing = dual('CONNECT_SLACK_SIGNING_SECRET');
    if (appId.isNotEmpty &&
        clientId.isNotEmpty &&
        secretPair != null &&
        signing != null) {
      slack = SlackCredentials(
        appId: appId,
        clientId: clientId,
        clientSecret: secretPair,
        signingSecret: signing,
        acceptsNewAuthorizations: flag(
          'CONNECT_SLACK_ACCEPTS_NEW',
          fallback: true,
        ),
        minSealGeneration: integer(
          'CONNECT_SLACK_MIN_SEAL_GENERATION',
          1,
          min: 1,
        ),
      );
    }
  }

  KlipyCredentials? klipy;
  {
    final key = dual('CONNECT_KLIPY_APP_KEY');
    final modeRaw = text('CONNECT_KLIPY_MODE');
    final mode = modeRaw.isEmpty
        ? KlipyLaneMode.proxy
        : KlipyLaneMode.fromWire(modeRaw);
    if (mode == null) {
      throw const ConnectConfigException('CONNECT_KLIPY_MODE is proxy or key');
    }
    if (key != null) {
      klipy = KlipyCredentials(mode: mode, appKey: key);
    }
  }

  // Backends.
  final sealBackend = switch (text('CONNECT_SEAL_BACKEND')) {
    '' || 'local' => SealBackend.local,
    'gcp-kms' => SealBackend.gcpKms,
    _ => throw const ConnectConfigException(
      'CONNECT_SEAL_BACKEND is local or gcp-kms',
    ),
  };
  final sealKeys = secret('CONNECT_SEAL_KEYS');
  final kmsKey = text('CONNECT_KMS_KEY');
  if (sealBackend == SealBackend.local && sealKeys == null) {
    throw const ConnectConfigException(
      'CONNECT_SEAL_KEYS (or CONNECT_SEAL_KEYS_FILE) is required for the '
      'local seal backend; generate one with `config_tool seal-key`',
    );
  }
  if (sealBackend == SealBackend.gcpKms &&
      !RegExp(
        r'^projects/[^/]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$',
      ).hasMatch(kmsKey)) {
    throw const ConnectConfigException(
      'CONNECT_KMS_KEY must be projects/.../locations/.../keyRings/.../'
      'cryptoKeys/<key>',
    );
  }

  final stateBackend = switch (text('CONNECT_STATE')) {
    '' || 'memory' => StateBackend.memory,
    'redis' => StateBackend.redis,
    _ => throw const ConnectConfigException('CONNECT_STATE is memory or redis'),
  };
  final redisUrl = secret('CONNECT_REDIS_URL');
  if (stateBackend == StateBackend.redis) {
    final url = Uri.tryParse(redisUrl?.value ?? '');
    if (url == null ||
        !(url.scheme == 'redis' || url.scheme == 'rediss') ||
        url.host.isEmpty) {
      throw const ConnectConfigException(
        'CONNECT_REDIS_URL must be redis:// or rediss:// when CONNECT_STATE=redis',
      );
    }
  }

  final bindingBackend = switch (text('CONNECT_BINDINGS')) {
    '' || 'file' => BindingBackend.file,
    'firestore' => BindingBackend.firestore,
    _ => throw const ConnectConfigException(
      'CONNECT_BINDINGS is file or firestore',
    ),
  };
  final firestoreProject = text('CONNECT_FIRESTORE_PROJECT');
  if (bindingBackend == BindingBackend.firestore &&
      !RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(firestoreProject)) {
    throw const ConnectConfigException(
      'CONNECT_FIRESTORE_PROJECT is required for CONNECT_BINDINGS=firestore',
    );
  }
  final firestoreDatabase = text('CONNECT_FIRESTORE_DATABASE').isEmpty
      ? '(default)'
      : text('CONNECT_FIRESTORE_DATABASE');
  if (!RegExp(
    r'^(\(default\)|[a-z][a-z0-9-]{2,62})$',
  ).hasMatch(firestoreDatabase)) {
    throw const ConnectConfigException(
      'CONNECT_FIRESTORE_DATABASE is not a database id',
    );
  }

  final configKeys = [
    for (final part in text('CONNECT_CONFIG_PUBLIC_KEYS').split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];
  if (!signed && configKeys.isNotEmpty) {
    // Keys to verify against mean this Connect is meant to serve a signed
    // config; serving the generated one instead would drop the signature.
    throw const ConnectConfigException(
      'CONNECT_CONFIG_PUBLIC_KEYS is set but no signed config was given '
      '(CONNECT_SIGNED_CONFIG_FILE or CONNECT_SIGNED_CONFIG)',
    );
  }
  if (signed && configKeys.isEmpty && hostedConfigRootKeys.isEmpty) {
    // A signed config nobody can verify is an unsigned one.
    throw const ConnectConfigException(
      'a signed config needs CONNECT_CONFIG_PUBLIC_KEYS: the key its '
      'signature is checked against',
    );
  }

  final logHmacKey = secret('CONNECT_LOG_HMAC_KEY');
  if (logHmacKey != null && logHmacKey.value.isEmpty) {
    throw ConnectConfigException(
      '${logHmacKey.name} could not be read or is empty',
    );
  }

  final config = ConnectServiceConfig(
    publicUrl: publicUrl,
    access: access,
    host: text('CONNECT_HOST').isEmpty ? '0.0.0.0' : text('CONNECT_HOST'),
    port: integer('CONNECT_PORT', 8790, max: 65535),
    trustProxyHops: _trustProxy(text('CONNECT_TRUST_PROXY')),
    github: github,
    google: google,
    linear: linear,
    slack: slack,
    klipy: klipy,
    githubAllowedOwners: owners,
    signedConfigPath: signedPath.isEmpty ? null : signedPath,
    signedConfigInline: signedInline.isEmpty ? null : signedInline,
    configEpoch: integer('CONNECT_CONFIG_EPOCH', 1, min: 1),
    configPublicKeys: configKeys,
    sealBackend: sealBackend,
    sealKeys: sealKeys,
    kmsKey: kmsKey,
    stateBackend: stateBackend,
    redisUrl: redisUrl,
    redisCaFile: text('CONNECT_REDIS_CA_FILE'),
    bindingBackend: bindingBackend,
    dataDir: text('CONNECT_DATA_DIR').isEmpty
        ? 'data'
        : text('CONNECT_DATA_DIR'),
    firestoreProject: firestoreProject,
    firestoreDatabase: firestoreDatabase,
    imageDigest: text('CONNECT_IMAGE_DIGEST'),
    version: text('CONNECT_VERSION').isEmpty
        ? connectServiceVersion
        : text('CONNECT_VERSION'),
    logHmacKey: logHmacKey,
    rateLimits: ConnectRateLimits(
      perInstallPerMinute: integer(
        'CONNECT_RATE_INSTALL_PER_MINUTE',
        600,
        min: 1,
      ),
      perIpPerMinute: integer('CONNECT_RATE_IP_PER_MINUTE', 300, min: 1),
      globalPerSecond: integer('CONNECT_RATE_GLOBAL_PER_SECOND', 500, min: 1),
      slackEventsPerTeamPerMinute: integer(
        'CONNECT_RATE_SLACK_TEAM_PER_MINUTE',
        600,
        min: 1,
      ),
      klipyPerInstallPerMinute: integer(
        'CONNECT_RATE_KLIPY_PER_MINUTE',
        120,
        min: 1,
      ),
    ),
  );
  return config;
}

int _trustProxy(String raw) {
  if (raw.isEmpty || raw == '0' || raw.toLowerCase() == 'false') {
    return 0;
  }
  final hops = int.tryParse(raw);
  if (hops == null || hops < 1 || hops > 8) {
    throw const ConnectConfigException(
      'CONNECT_TRUST_PROXY is the number of trusted proxy hops (1..8), or 0',
    );
  }
  return hops;
}

/// Checks that a signed config's lanes name exactly the credentials this
/// Connect holds. Throws [ConnectConfigException] on any difference: serving
/// a config whose client ids differ from the secrets in use would send people
/// to an app whose tokens this Connect cannot exchange.
void checkSignedConfigMatches(
  ConnectConfig signed,
  ConnectServiceConfig config,
) {
  final github = signed.github;
  if (github != null) {
    final creds = config.github;
    if (creds == null ||
        creds.appId != github.appId ||
        creds.clientId != github.clientId ||
        creds.appSlug != github.appSlug ||
        creds.clientSecret.currentValue.isEmpty) {
      throw const ConnectConfigException(
        'signed config github lane does not match CONNECT_GITHUB_*',
      );
    }
  }
  final google = signed.google;
  if (google != null) {
    final creds = config.google;
    if (creds == null ||
        creds.clientId != google.clientId ||
        creds.clientSecret.currentValue.isEmpty) {
      throw const ConnectConfigException(
        'signed config google lane does not match CONNECT_GOOGLE_*',
      );
    }
  }
  final linear = signed.linear;
  if (linear != null) {
    final creds = config.linear;
    if (creds == null || creds.clientId != linear.clientId) {
      throw const ConnectConfigException(
        'signed config linear lane does not match CONNECT_LINEAR_*',
      );
    }
  }
  final slack = signed.slack;
  if (slack != null) {
    final creds = config.slack;
    if (creds == null ||
        creds.appId != slack.appId ||
        creds.clientId != slack.clientId ||
        creds.clientSecret.currentValue.isEmpty ||
        creds.signingSecret.currentValue.isEmpty) {
      throw const ConnectConfigException(
        'signed config slack lane does not match CONNECT_SLACK_*',
      );
    }
  }
  final klipy = signed.klipy;
  if (klipy != null) {
    final creds = config.klipy;
    if (creds == null ||
        creds.mode != klipy.mode ||
        creds.appKey.currentValue.isEmpty) {
      throw const ConnectConfigException(
        'signed config klipy lane does not match CONNECT_KLIPY_*',
      );
    }
    if (klipy.mode == KlipyLaneMode.key &&
        !creds.appKey.values.contains(klipy.appKey)) {
      throw const ConnectConfigException(
        'signed config klipy.app_key is not the current or previous '
        'CONNECT_KLIPY_APP_KEY',
      );
    }
  }
}

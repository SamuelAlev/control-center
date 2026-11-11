import 'dart:convert';

import 'package:cc_connect/src/secrets.dart';
import 'package:cc_connect/src/sentry_reporter.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' show RSAPrivateKey;

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

/// The shared GitHub App's credentials: OAuth client and RSA private key (no
/// webhook secret).
final class GitHubCredentials {
  /// Creates the credentials.
  const GitHubCredentials({
    required this.appId,
    required this.appSlug,
    required this.clientId,
    required this.clientSecret,
    required this.privateKey,
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

  /// The App's RSA private key (PEM): signs the App JWT that mints
  /// one-repository installation tokens (`as: app`). It never leaves
  /// Connect; every mint is authorized by a person's sealed grant first.
  final SecretSource privateKey;

  /// Self-hosted: whether new sign-ins are accepted.
  final bool acceptsNewAuthorizations;

  /// Self-hosted: seals below this generation must sign in again.
  final int minSealGeneration;
}

final RegExp _pemBlock = RegExp(
  r'-----BEGIN ([A-Z0-9 ]+)-----(.*?)-----END \1-----',
  dotAll: true,
);

/// [raw] as a well-formed PEM, however it was pasted into an environment
/// variable. Hosts without secret files (Heroku, Fly) often hold a
/// multi-line PEM on one line: wrapped in quotes, with literal `\n` escapes,
/// with the line breaks turned into spaces, or base64-encoded whole. The body
/// is re-wrapped at 64 columns. Anything that is not a PEM comes back trimmed
/// and unchanged, so the key check still refuses it.
String normalizePem(String raw) {
  var text = raw.trim();
  if (text.length >= 2 &&
      (text.startsWith('"') && text.endsWith('"') ||
          text.startsWith("'") && text.endsWith("'"))) {
    text = text.substring(1, text.length - 1).trim();
  }
  if (!text.contains('-----BEGIN')) {
    try {
      final decoded = utf8.decode(
        base64.decode(text.replaceAll(RegExp(r'\s'), '')),
      );
      if (decoded.contains('-----BEGIN')) {
        text = decoded.trim();
      }
    } on FormatException {
      return text;
    }
  }
  final block = _pemBlock.firstMatch(
    text.replaceAll(r'\r', '').replaceAll(r'\n', '\n'),
  );
  if (block == null) {
    return text;
  }
  final label = block.group(1)!;
  final body = block.group(2)!.replaceAll(RegExp(r'\s'), '');
  final lines = [
    for (var i = 0; i < body.length; i += 64)
      body.substring(i, i + 64 > body.length ? body.length : i + 64),
  ];
  return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----\n';
}

/// Whether [pem] parses as the RSA key a GitHub App JWT is signed with, once
/// normalized ([normalizePem]).
bool isReadableGitHubAppKey(String pem) {
  if (pem.isEmpty) {
    return false;
  }
  try {
    RSAPrivateKey(normalizePem(pem));
    return true;
  } on Object {
    return false;
  }
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
    this.slackHookPerIpPerMinute = 600,
    this.slackHookGlobalPerSecond = 100,
    this.klipyPerInstallPerMinute = 120,
    this.klipyPerIpPerMinute = 240,
    this.loginsPerIpPer10Minutes = 60,
    this.githubTokensPerAccountPerHour = 30,
    int? githubTokensAccountCeilingPerHour,
    this.githubTokensPerIpPerHour = 600,
    this.githubExchangeCeilingPerHour = 500,
    this.githubAppMintsPerInstallPerHour = 120,
    this.githubAppMintsPerAccountPerHour = 240,
    this.githubAppCeilingPerHour = 3000,
    this.githubTokenCeilingPerHour = 1500,
    this.githubLiveChildrenWarn = 10,
    this.retiresPerIpPerHour = 10,
  }) : githubTokensAccountCeilingPerHour =
           githubTokensAccountCeilingPerHour ??
           githubTokensPerAccountPerHour * 4;

  /// Signed calls per install per minute.
  final int perInstallPerMinute;

  /// Requests per client IP per minute (Slack hooks have their own).
  final int perIpPerMinute;

  /// Requests per second across the instance (Slack hooks have their own).
  final int globalPerSecond;

  /// Slack hook requests per client IP per minute.
  final int slackHookPerIpPerMinute;

  /// Slack hook requests per second across the instance.
  final int slackHookGlobalPerSecond;

  /// Slack events queued per team per minute; the rest are dropped (and
  /// still answered 200, so Slack never disables the subscription).
  final int slackEventsPerTeamPerMinute;

  /// Klipy proxy calls per install per minute.
  final int klipyPerInstallPerMinute;

  /// Klipy proxy calls per client address per minute, across instances: the
  /// Klipy key's quota is shared by every server.
  final int klipyPerIpPerMinute;

  /// Sign-ins started per client address per 10 minutes (a login lives 10
  /// minutes), across instances: one address cannot fill the state store.
  final int loginsPerIpPer10Minutes;

  /// GitHub token-endpoint calls (code exchanges, refreshes, new children)
  /// per GitHub account and install per hour, across instances: one server
  /// spends only its own share of a person's budget.
  final int githubTokensPerAccountPerHour;

  /// GitHub token-endpoint calls per GitHub account per hour across every
  /// install (by default four shares).
  final int githubTokensAccountCeilingPerHour;

  /// GitHub token-endpoint calls per client address per hour.
  final int githubTokensPerIpPerHour;

  /// GitHub code exchanges (new sign-ins) per hour for the whole App. They
  /// have this budget of their own and never count against
  /// [githubTokenCeilingPerHour].
  final int githubExchangeCeilingPerHour;

  /// `as: app` installation-token mints per install per hour.
  final int githubAppMintsPerInstallPerHour;

  /// `as: app` installation-token mints per asking GitHub account per hour,
  /// across installs.
  final int githubAppMintsPerAccountPerHour;

  /// `as: app` installation-token mints (App JWT calls) per hour for the
  /// whole App.
  final int githubAppCeilingPerHour;

  /// Refreshes and new children per hour for the whole App; past it they
  /// answer `rate_limited`. Code exchanges have their own ceiling
  /// ([githubExchangeCeilingPerHour]).
  final int githubTokenCeilingPerHour;

  /// Live children one GitHub account holds across every install past which
  /// `github.token_cap` is logged.
  final int githubLiveChildrenWarn;

  /// `/v1/install/retire` calls per client address per hour.
  final int retiresPerIpPerHour;
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
    this.githubReviewBotInstalls = const {},
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
    this.sentryDsn,
    this.sentryEnvironment = '',
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

  /// Installs whose `as: app` mints may carry `bot` (`pull_requests: write`,
  /// reviews as the shared bot): `CONNECT_GITHUB_REVIEW_BOT_INSTALLS`. Every
  /// other install's bot holds at most `comment`.
  final Set<String> githubReviewBotInstalls;

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

  /// Optional Sentry DSN (`CONNECT_SENTRY_DSN`), checked by
  /// [SentryDsn.tryParse] at load.
  final SecretSource? sentryDsn;

  /// `CONNECT_SENTRY_ENVIRONMENT`; empty derives `hosted` (a signed config)
  /// or `self-hosted`.
  final String sentryEnvironment;

  /// Whether this Connect serves an offline-signed config (hosted).
  bool get servesSignedConfig =>
      signedConfigPath != null || signedConfigInline != null;

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

  final reviewBotRaw = text('CONNECT_GITHUB_REVIEW_BOT_INSTALLS');
  if (reviewBotRaw == '*') {
    throw const ConnectConfigException(
      'CONNECT_GITHUB_REVIEW_BOT_INSTALLS lists install ids; * is refused: '
      'the shared bot reviews only for servers the operator knows',
    );
  }
  final reviewBotInstalls = installSet(
    'CONNECT_GITHUB_REVIEW_BOT_INSTALLS',
    reviewBotRaw,
  );
  for (final id in reviewBotInstalls) {
    if (!access.permits(id)) {
      throw ConnectConfigException(
        'CONNECT_GITHUB_REVIEW_BOT_INSTALLS: "$id" is not allowed by '
        'CONNECT_ALLOWED_INSTALLS / CONNECT_DENY_INSTALLS',
      );
    }
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
    final privateKey = secret('CONNECT_GITHUB_APP_PRIVATE_KEY');
    if (appIdRaw.isNotEmpty &&
        slug.isNotEmpty &&
        clientId.isNotEmpty &&
        secretPair != null &&
        privateKey != null) {
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
      // A file-backed key is re-read on use (rotation); an unreadable file
      // only makes installation-token mints unavailable.
      if (!privateKey.isFileBacked &&
          !isReadableGitHubAppKey(privateKey.value)) {
        throw const ConnectConfigException(
          'CONNECT_GITHUB_APP_PRIVATE_KEY is not an RSA private key (PEM)',
        );
      }
      github = GitHubCredentials(
        appId: appId,
        appSlug: slug,
        clientId: clientId,
        clientSecret: secretPair,
        privateKey: privateKey,
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

  final sentryDsn = secret('CONNECT_SENTRY_DSN');
  if (sentryDsn != null && SentryDsn.tryParse(sentryDsn.value) == null) {
    throw ConnectConfigException(
      '${sentryDsn.name} is not a Sentry DSN (https://<key>@<host>/<project>)',
    );
  }
  final sentryEnvironment = text('CONNECT_SENTRY_ENVIRONMENT');
  if (sentryEnvironment.isNotEmpty &&
      !RegExp(r'^[A-Za-z0-9_.\-]{1,64}$').hasMatch(sentryEnvironment)) {
    throw const ConnectConfigException(
      'CONNECT_SENTRY_ENVIRONMENT is 1..64 letters, digits, _ . -',
    );
  }

  final accountShare = integer(
    'CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_PER_HOUR',
    30,
    min: 1,
  );
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
    githubReviewBotInstalls: reviewBotInstalls,
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
    sentryDsn: sentryDsn,
    sentryEnvironment: sentryEnvironment,
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
      slackHookPerIpPerMinute: integer(
        'CONNECT_RATE_SLACK_HOOK_IP_PER_MINUTE',
        600,
        min: 1,
      ),
      slackHookGlobalPerSecond: integer(
        'CONNECT_RATE_SLACK_HOOK_GLOBAL_PER_SECOND',
        100,
        min: 1,
      ),
      klipyPerInstallPerMinute: integer(
        'CONNECT_RATE_KLIPY_PER_MINUTE',
        120,
        min: 1,
      ),
      klipyPerIpPerMinute: integer(
        'CONNECT_RATE_KLIPY_IP_PER_MINUTE',
        240,
        min: 1,
      ),
      loginsPerIpPer10Minutes: integer(
        'CONNECT_RATE_LOGINS_IP_PER_10_MINUTES',
        60,
        min: 1,
      ),
      githubTokensPerAccountPerHour: accountShare,
      githubTokensAccountCeilingPerHour: integer(
        'CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_CEILING_PER_HOUR',
        accountShare * 4,
        min: accountShare,
      ),
      githubTokensPerIpPerHour: integer(
        'CONNECT_RATE_GITHUB_TOKENS_IP_PER_HOUR',
        600,
        min: 1,
      ),
      githubExchangeCeilingPerHour: integer(
        'CONNECT_RATE_GITHUB_EXCHANGE_CEILING_PER_HOUR',
        500,
        min: 1,
      ),
      githubAppMintsPerInstallPerHour: integer(
        'CONNECT_RATE_GITHUB_APP_MINTS_INSTALL_PER_HOUR',
        120,
        min: 1,
      ),
      githubAppMintsPerAccountPerHour: integer(
        'CONNECT_RATE_GITHUB_APP_MINTS_ACCOUNT_PER_HOUR',
        240,
        min: 1,
      ),
      githubAppCeilingPerHour: integer(
        'CONNECT_RATE_GITHUB_APP_CEILING_PER_HOUR',
        3000,
        min: 1,
      ),
      githubTokenCeilingPerHour: integer(
        'CONNECT_RATE_GITHUB_TOKEN_CEILING_PER_HOUR',
        1500,
        min: 1,
      ),
      githubLiveChildrenWarn: integer(
        'CONNECT_GITHUB_TOKEN_CAP_WARN',
        10,
        min: 1,
      ),
      retiresPerIpPerHour: integer(
        'CONNECT_RATE_RETIRE_IP_PER_HOUR',
        10,
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

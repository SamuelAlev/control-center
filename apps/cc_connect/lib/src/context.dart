import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/src/binding_store.dart';
import 'package:cc_connect/src/connect_log.dart';
import 'package:cc_connect/src/credential_seal.dart';
import 'package:cc_connect/src/provider_github.dart';
import 'package:cc_connect/src/provider_google.dart';
import 'package:cc_connect/src/provider_klipy.dart';
import 'package:cc_connect/src/provider_slack.dart';
import 'package:cc_connect/src/secrets.dart';
import 'package:cc_connect/src/service_config.dart';
import 'package:cc_connect/src/state_store.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:crypto/crypto.dart' as crypto;

/// How long a staged browser login lives.
const Duration loginTtl = Duration(minutes: 10);

/// How long a GitHub install ticket lives.
const Duration installTicketTtl = Duration(minutes: 15);

/// How long a seal handoff is replayable.
const Duration sealHandoffTtl = Duration(minutes: 5);

/// How long a request nonce is remembered (more than twice the signature
/// skew, so a nonce cannot be replayed at either edge of the window).
const Duration nonceTtl = Duration(minutes: 5);

/// How long a queued Slack reference waits for its server.
const Duration slackQueueTtl = Duration(minutes: 10);

/// How long GitHub reads made with a parent token are reused.
const Duration githubReadCacheTtl = Duration(minutes: 5);

/// Most wrong confirm codes (or verifiers) before a login is burned.
const int maxClaimAttempts = 5;

/// A verified caller.
final class ConnectCaller {
  /// Creates the caller.
  const ConnectCaller({required this.installId});

  /// Recomputed from the verified key.
  final String installId;

  /// The seal binding for [workspaceId].
  SealBinding binding(String workspaceId) =>
      SealBinding(installId: installId, workspaceId: workspaceId);
}

/// A browser OAuth flow between `/start` and `/claim`.
final class StagedLogin {
  /// Creates the login.
  StagedLogin({
    required this.id,
    required this.lane,
    required this.installId,
    required this.workspaceId,
    required this.codeChallenge,
    required this.purpose,
    required this.confirmCode,
    required this.expiresAt,
    this.installationId,
    this.providerCode = '',
    this.oidcNonce = '',
    this.slackTeamId = '',
    this.slackUserId = '',
  });

  /// Parses the stored form; null when malformed.
  static StagedLogin? tryParse(String id, String? raw) {
    if (raw == null) {
      return null;
    }
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map) {
      return null;
    }
    final map = json;
    final laneWire = json['lane'];
    final lane = ConnectOAuthLane.fromWire(
      laneWire is String ? laneWire : null,
    );
    final purpose = ConnectOAuthPurpose.fromWire(json['purpose']);
    final install = json['install_id'];
    final workspace = json['workspace_id'];
    final challenge = json['code_challenge'];
    final code = json['confirm_code'];
    final expires = json['expires_at'];
    if (lane == null ||
        purpose == null ||
        install is! String ||
        workspace is! String ||
        challenge is! String ||
        code is! String ||
        expires is! String) {
      return null;
    }
    String text(String key) {
      final value = map[key];
      return value is String ? value : '';
    }

    final installation = map['installation_id'];
    return StagedLogin(
      id: id,
      lane: lane,
      installId: install,
      workspaceId: workspace,
      codeChallenge: challenge,
      purpose: purpose,
      confirmCode: code,
      expiresAt: DateTime.tryParse(expires)?.toUtc() ?? DateTime.utc(1970),
      installationId: installation is int ? installation : null,
      providerCode: text('provider_code'),
      oidcNonce: text('oidc_nonce'),
      slackTeamId: text('slack_team_id'),
      slackUserId: text('slack_user_id'),
    );
  }

  /// The login id.
  final String id;

  /// The lane.
  final ConnectOAuthLane lane;

  /// Who started it.
  final String installId;

  /// For which workspace.
  final String workspaceId;

  /// The server's PKCE challenge.
  final String codeChallenge;

  /// Why.
  final ConnectOAuthPurpose purpose;

  /// The code `/done` shows.
  final String confirmCode;

  /// When it stops being claimable.
  final DateTime expiresAt;

  /// The installation named at start (GitHub `authorize_server`).
  final int? installationId;

  /// The provider's authorization code, once the callback ran.
  String providerCode;

  /// Slack: the OIDC nonce.
  String oidcNonce;

  /// Slack: the team the OIDC pre-check saw.
  String slackTeamId;

  /// Slack: the person the OIDC pre-check saw.
  String slackUserId;

  /// The stored form.
  String encode() => jsonEncode({
    'lane': lane.wire,
    'purpose': purpose.wire,
    'install_id': installId,
    'workspace_id': workspaceId,
    'code_challenge': codeChallenge,
    'confirm_code': confirmCode,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'installation_id': ?installationId,
    if (providerCode.isNotEmpty) 'provider_code': providerCode,
    if (oidcNonce.isNotEmpty) 'oidc_nonce': oidcNonce,
    if (slackTeamId.isNotEmpty) 'slack_team_id': slackTeamId,
    if (slackUserId.isNotEmpty) 'slack_user_id': slackUserId,
  });
}

/// Wakes long polls in this process when a reference is queued for their
/// install (other instances' pushes are picked up by the poll's tick).
final class InstallSignal {
  final Map<String, List<Completer<void>>> _waiters = {};

  /// Wakes every poll waiting for [installId].
  void notify(String installId) {
    final waiters = _waiters.remove(installId);
    if (waiters == null) {
      return;
    }
    for (final waiter in waiters) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
  }

  /// Waits for [notify] on [installId] or [timeout], whichever is first.
  Future<void> wait(String installId, Duration timeout) {
    final completer = Completer<void>();
    (_waiters[installId] ??= []).add(completer);
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future.whenComplete(() {
      timer.cancel();
      _waiters[installId]?.remove(completer);
      if (_waiters[installId]?.isEmpty ?? false) {
        _waiters.remove(installId);
      }
    });
  }
}

/// The `/v1/config` this Connect serves, and the lanes it therefore serves.
final class ServedConfig {
  /// Creates the source.
  ServedConfig(
    this._config, {
    required this.bootTime,
    required this.log,
    this._readBytes,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ConnectServiceConfig _config;

  /// When this Connect started (the self-hosted config's `issued_at`).
  final DateTime bootTime;

  /// The logger.
  final ConnectLog log;
  final DateTime Function() _clock;
  final SecretFileReader? _readBytes;
  SignedConfigFile? _signed;
  DateTime? _signedReadAt;

  List<int> _read(String path) {
    final reader = _readBytes;
    return reader != null
        ? utf8.encode(reader(path))
        : File(path).readAsBytesSync();
  }

  /// Loads and checks the signed config (hosted). Throws
  /// [ConnectConfigException] on a config this Connect cannot serve.
  Future<void> load() async {
    final inline = _config.signedConfigInline;
    if (inline != null) {
      _signed = await _check(utf8.encode(inline));
      return;
    }
    final path = _config.signedConfigPath;
    if (path == null) {
      return;
    }
    final List<int> bytes;
    try {
      bytes = _read(path);
    } on FileSystemException {
      throw const ConnectConfigException(
        'CONNECT_SIGNED_CONFIG_FILE is not readable',
      );
    }
    _signed = await _check(bytes);
    _signedReadAt = _clock();
  }

  Future<SignedConfigFile> _check(List<int> bytes) async {
    final signed = SignedConfigFile.parse(bytes);
    checkSignedConfigMatches(signed.config, _config);
    final keys = [..._config.configPublicKeys, ...hostedConfigRootKeys];
    if (keys.isEmpty ||
        !await verifyConnectConfigSignature(signed.json, trustedKeys: keys)) {
      throw const ConnectConfigException(
        'the signed config signature does not verify',
      );
    }
    return signed;
  }

  /// Re-reads the signed file at most every [secretRefreshInterval]; a new
  /// file that fails a check (or rolls the epoch back) is ignored and the
  /// last good one kept.
  Future<void> _refresh() async {
    final path = _config.signedConfigPath;
    final last = _signedReadAt;
    if (path == null ||
        (last != null && _clock().difference(last) < secretRefreshInterval)) {
      return;
    }
    _signedReadAt = _clock();
    try {
      final next = await _check(_read(path));
      final current = _signed;
      if (current != null && next.config.epoch < current.config.epoch) {
        log.event('config.rollback_ignored', {'epoch': next.config.epoch});
        return;
      }
      if (current == null || current.config.epoch != next.config.epoch) {
        log.event('config.reloaded', {'epoch': next.config.epoch});
      }
      _signed = next;
    } on Object {
      log.event('config.reload_failed');
    }
  }

  /// The config to serve: the signed file verbatim (hosted), or one
  /// generated from the complete lanes (self-hosted).
  Future<({ConnectConfig config, List<int>? verbatim})> current() async {
    await _refresh();
    final signed = _signed;
    if (signed != null) {
      return (config: signed.config, verbatim: signed.bytes);
    }
    return (config: _generated(), verbatim: null);
  }

  ConnectConfig _generated() {
    final github = _config.github;
    final google = _config.google;
    final linear = _config.linear;
    final slack = _config.slack;
    final klipy = _config.klipy;
    return ConnectConfig(
      epoch: _config.configEpoch,
      issuedAt: bootTime,
      github: github == null || github.clientSecret.currentValue.isEmpty
          ? null
          : GitHubLaneConfig(
              appId: github.appId,
              clientId: github.clientId,
              appSlug: github.appSlug,
              minSealGeneration: github.minSealGeneration,
              acceptsNewAuthorizations: github.acceptsNewAuthorizations,
            ),
      google: google == null || google.clientSecret.currentValue.isEmpty
          ? null
          : ClientIdLaneConfig(
              clientId: google.clientId,
              minSealGeneration: google.minSealGeneration,
              acceptsNewAuthorizations: google.acceptsNewAuthorizations,
            ),
      linear: linear == null
          ? null
          : ClientIdLaneConfig(
              clientId: linear.clientId,
              acceptsNewAuthorizations: linear.acceptsNewAuthorizations,
            ),
      slack:
          slack == null ||
              slack.clientSecret.currentValue.isEmpty ||
              slack.signingSecret.currentValue.isEmpty
          ? null
          : SlackLaneConfig(
              appId: slack.appId,
              clientId: slack.clientId,
              minSealGeneration: slack.minSealGeneration,
              acceptsNewAuthorizations: slack.acceptsNewAuthorizations,
            ),
      klipy: klipy == null || klipy.appKey.currentValue.isEmpty
          ? null
          : KlipyLaneConfig(
              mode: klipy.mode,
              appKey: klipy.mode == KlipyLaneMode.key
                  ? klipy.appKey.currentValue
                  : '',
            ),
    );
  }
}

/// Everything a route needs.
final class ConnectContext {
  /// Creates the context.
  ConnectContext({
    required this.config,
    required this.state,
    required this.bindings,
    required this.sealer,
    required this.http,
    required this.log,
    required this.served,
    required this.clock,
    this.pollTimeout = const Duration(seconds: 25),
  }) : github = config.github == null
           ? null
           : GitHubApi(http, config.github!, clock: clock),
       google = config.google == null
           ? null
           : GoogleApi(http, config.google!, clock: clock),
       slack = config.slack == null
           ? null
           : SlackApi(http, config.slack!, clock: clock),
       klipy = config.klipy == null ? null : KlipyApi(http, config.klipy!),
       _cacheHmac = crypto.Hmac(crypto.sha256, randomBytes(32));

  /// The service config.
  final ConnectServiceConfig config;

  /// Short-lived state.
  final StateStore state;

  /// Install bindings.
  final BindingStore bindings;

  /// Seals.
  final CredentialSealer sealer;

  /// Upstream HTTP.
  final UpstreamHttp http;

  /// Logs.
  final ConnectLog log;

  /// The served config.
  final ServedConfig served;

  /// The clock.
  final DateTime Function() clock;

  /// How long `/v1/events/poll` holds a request open.
  final Duration pollTimeout;

  /// GitHub calls, when the lane is configured.
  final GitHubApi? github;

  /// Google calls, when the lane is configured.
  final GoogleApi? google;

  /// Slack calls, when the lane is configured.
  final SlackApi? slack;

  /// Klipy calls, when the lane is configured.
  final KlipyApi? klipy;

  /// Wakes long polls.
  final InstallSignal signal = InstallSignal();
  final crypto.Hmac _cacheHmac;

  /// UTC now.
  DateTime now() => clock().toUtc();

  /// A cache key for reads made with [token]: an HMAC under a per-process
  /// key, so the cache never holds (or reveals) the token.
  String tokenCacheKey(String token) =>
      _cacheHmac.convert(utf8.encode(token)).toString();

  static const ConnectException _unavailable = ConnectException(
    ConnectErrorCode.providerUnavailable,
  );

  /// The served GitHub lane and its credentials, or `provider_unavailable`.
  Future<(GitHubLaneConfig, GitHubCredentials, GitHubApi)> githubLane() async {
    final lane = (await served.current()).config.github;
    final creds = config.github;
    final api = github;
    if (lane == null ||
        creds == null ||
        api == null ||
        creds.clientSecret.currentValue.isEmpty) {
      throw _unavailable;
    }
    return (lane, creds, api);
  }

  /// The served Google lane, or `provider_unavailable`.
  Future<(ClientIdLaneConfig, GoogleCredentials, GoogleApi)>
  googleLane() async {
    final lane = (await served.current()).config.google;
    final creds = config.google;
    final api = google;
    if (lane == null ||
        creds == null ||
        api == null ||
        creds.clientSecret.currentValue.isEmpty) {
      throw _unavailable;
    }
    return (lane, creds, api);
  }

  /// The served Linear lane, or `provider_unavailable`.
  Future<(ClientIdLaneConfig, LinearCredentials)> linearLane() async {
    final lane = (await served.current()).config.linear;
    final creds = config.linear;
    if (lane == null || creds == null) {
      throw _unavailable;
    }
    return (lane, creds);
  }

  /// The served Slack lane, or `provider_unavailable`.
  Future<(SlackLaneConfig, SlackCredentials, SlackApi)> slackLane() async {
    final lane = (await served.current()).config.slack;
    final creds = config.slack;
    final api = slack;
    if (lane == null ||
        creds == null ||
        api == null ||
        creds.clientSecret.currentValue.isEmpty ||
        creds.signingSecret.currentValue.isEmpty) {
      throw _unavailable;
    }
    return (lane, creds, api);
  }

  /// The Klipy proxy, or `provider_unavailable` (not served, or in key
  /// mode where the server calls Klipy itself).
  Future<KlipyApi> klipyProxy() async {
    final lane = (await served.current()).config.klipy;
    final api = klipy;
    if (lane == null ||
        lane.mode != KlipyLaneMode.proxy ||
        api == null ||
        config.klipy?.mode != KlipyLaneMode.proxy) {
      throw _unavailable;
    }
    return api;
  }

  /// Reads a staged login.
  Future<StagedLogin?> login(String id) async {
    if (!isLoginId(id)) {
      return null;
    }
    final login = StagedLogin.tryParse(id, await state.get('login:$id'));
    if (login == null || !now().isBefore(login.expiresAt)) {
      return null;
    }
    return login;
  }

  /// Writes a staged login back for the rest of its lifetime.
  Future<void> saveLogin(StagedLogin login) async {
    final remaining = login.expiresAt.difference(now());
    if (remaining <= Duration.zero) {
      return;
    }
    await state.set('login:${login.id}', login.encode(), remaining);
  }

  /// Burns a login (and its attempt counter).
  Future<void> burnLogin(String id) async {
    await state.delete('login:$id');
    await state.delete('attempts:$id');
  }
}

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
import 'package:cc_connect/src/quota.dart';
import 'package:cc_connect/src/secrets.dart';
import 'package:cc_connect/src/service_config.dart';
import 'package:cc_connect/src/state_store.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:crypto/crypto.dart' as crypto;

/// How long a staged browser login lives.
const Duration loginTtl = Duration(minutes: 10);

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
  const ConnectCaller({
    required this.installId,
    this.address = '',
    this.wideAddress = '',
    this.network = '',
  });

  /// Recomputed from the verified key.
  final String installId;

  /// The client address the request came from, as budgets key it
  /// (`ConnectService.ipBucketKey`: the address, or an IPv6 /64).
  final String address;

  /// The client address for budgets one host could otherwise spread over
  /// many /64s: the address, or an IPv6 /48.
  final String wideAddress;

  /// The same address truncated for logs (`truncateIp`).
  final String network;

  /// The seal binding for [workspaceId].
  SealBinding binding(String workspaceId) =>
      SealBinding(installId: installId, workspaceId: workspaceId);
}

/// Where a staged login stands. A login moves forward only through
/// [StagedLogin.advance]; nothing is encoded as an empty string.
sealed class LoginPhase {
  const LoginPhase();
}

/// Started; the provider has not redirected back yet.
final class AwaitingProvider extends LoginPhase {
  /// Creates the phase.
  const AwaitingProvider();
}

/// Slack: the Sign in with Slack pre-check passed; the bot install is next.
final class SlackPrechecked extends LoginPhase {
  /// Creates the phase.
  const SlackPrechecked({required this.teamId, required this.userId});

  /// The team the pre-check saw.
  final String teamId;

  /// The person the pre-check saw.
  final String userId;
}

/// The provider redirected back with its authorization code; the login can
/// be claimed.
final class Authorized extends LoginPhase {
  /// Creates the phase.
  const Authorized({required this.providerCode, this.slack});

  /// The provider's one-time authorization code.
  final String providerCode;

  /// Slack: what the pre-check saw; null for every other lane.
  final SlackPrechecked? slack;
}

/// A browser OAuth flow between `/start` and `/claim`.
final class StagedLogin {
  /// Creates a login at [AwaitingProvider].
  StagedLogin({
    required this.id,
    required this.lane,
    required this.installId,
    required this.workspaceId,
    required this.codeChallenge,
    required this.confirmCode,
    required this.expiresAt,
    required this.startNetwork,
    this.oidcNonce = '',
  }) : phase = const AwaitingProvider(),
       storedAs = null;

  StagedLogin._({
    required this.id,
    required this.lane,
    required this.installId,
    required this.workspaceId,
    required this.codeChallenge,
    required this.confirmCode,
    required this.expiresAt,
    required this.startNetwork,
    required this.oidcNonce,
    required this.phase,
    required this.storedAs,
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
    final install = json['install_id'];
    final workspace = json['workspace_id'];
    final challenge = json['code_challenge'];
    final code = json['confirm_code'];
    final expires = json['expires_at'];
    final network = json['start_network'];
    if (lane == null ||
        network is! String ||
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

    final providerCode = text('provider_code');
    final team = text('slack_team_id');
    final slack = team.isEmpty
        ? null
        : SlackPrechecked(teamId: team, userId: text('slack_user_id'));
    if (lane == ConnectOAuthLane.slack &&
        providerCode.isNotEmpty &&
        slack == null) {
      // A Slack login authorized without its pre-check is not one this
      // Connect made.
      return null;
    }
    return StagedLogin._(
      id: id,
      lane: lane,
      installId: install,
      workspaceId: workspace,
      codeChallenge: challenge,
      confirmCode: code,
      expiresAt: DateTime.tryParse(expires)?.toUtc() ?? DateTime.utc(1970),
      startNetwork: network,
      oidcNonce: text('oidc_nonce'),
      phase: providerCode.isNotEmpty
          ? Authorized(providerCode: providerCode, slack: slack)
          : slack ?? const AwaitingProvider(),
      storedAs: raw,
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

  /// The code `/done` shows.
  final String confirmCode;

  /// When it stops being claimable.
  final DateTime expiresAt;

  /// The truncated address (`truncateIp`) the server started it from, for
  /// the consent page's proximity hint only: it never changes what the
  /// flow allows.
  final String startNetwork;

  /// Slack: the OIDC nonce (empty for every other lane).
  final String oidcNonce;

  /// Where the login stands.
  final LoginPhase phase;

  /// The stored form this copy was read as, for compare-and-set; null for a
  /// login not stored yet.
  final String? storedAs;

  /// The provider's authorization code, once the login is [Authorized].
  String? get providerCode => switch (phase) {
    Authorized(:final providerCode) => providerCode,
    _ => null,
  };

  /// Slack: what the pre-check saw, once it passed.
  SlackPrechecked? get slackPrecheck => switch (phase) {
    SlackPrechecked() && final checked => checked,
    Authorized(:final slack) => slack,
    AwaitingProvider() => null,
  };

  /// The redirect hop this login waits for next, or null once [Authorized].
  ConnectCallbackHop? get nextHop => switch (phase) {
    AwaitingProvider() => ConnectCallbackHop.first,
    SlackPrechecked() => ConnectCallbackHop.bot,
    Authorized() => null,
  };

  /// The one transition function: this login moved to [next] by the
  /// provider's redirect. Throws [StateError] for any move the flow does not
  /// make (a second callback, a bot install before the pre-check, a
  /// pre-check on a lane without one).
  StagedLogin advance(LoginPhase next) {
    final ok = switch ((phase, next)) {
      (AwaitingProvider(), SlackPrechecked()) => lane == ConnectOAuthLane.slack,
      (AwaitingProvider(), Authorized(:final slack)) =>
        lane != ConnectOAuthLane.slack && slack == null,
      (SlackPrechecked() && final checked, Authorized(:final slack)) =>
        identical(slack, checked),
      _ => false,
    };
    if (!ok) {
      throw StateError('login $id cannot move to ${next.runtimeType}');
    }
    return StagedLogin._(
      id: id,
      lane: lane,
      installId: installId,
      workspaceId: workspaceId,
      codeChallenge: codeChallenge,
      confirmCode: confirmCode,
      expiresAt: expiresAt,
      startNetwork: startNetwork,
      oidcNonce: oidcNonce,
      phase: next,
      storedAs: storedAs,
    );
  }

  /// The stored form.
  String encode() => jsonEncode({
    'lane': lane.wire,
    'install_id': installId,
    'workspace_id': workspaceId,
    'code_challenge': codeChallenge,
    'confirm_code': confirmCode,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'start_network': startNetwork,
    'provider_code': ?providerCode,
    if (oidcNonce.isNotEmpty) 'oidc_nonce': oidcNonce,
    'slack_team_id': ?slackPrecheck?.teamId,
    'slack_user_id': ?slackPrecheck?.userId,
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
  bool _hostedRoot = false;

  /// Whether the signed config being served verifies only under a key from
  /// `CONNECT_CONFIG_PUBLIC_KEYS`, not under Control Center's built-in
  /// hosted root keys.
  bool get signedByOperatorKey => _signed != null && !_hostedRoot;

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
      await _serve(await _check(utf8.encode(inline)));
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
    await _serve(await _check(bytes));
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

  /// Serves [signed] from now on.
  Future<void> _serve(SignedConfigFile signed) async {
    _hostedRoot =
        hostedConfigRootKeys.isNotEmpty &&
        await verifyConnectConfigSignature(
          signed.json,
          trustedKeys: hostedConfigRootKeys,
        );
    _signed = signed;
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
        log.event('config.rollback_ignored', {
          'epoch': next.config.epoch,
        }, ConnectLogLevel.warn);
        return;
      }
      if (current == null || current.config.epoch != next.config.epoch) {
        final config = next.config;
        log.event('config.changed', {
          'epoch': config.epoch,
          'lanes': [
            if (config.github != null) 'github',
            if (config.google != null) 'google',
            if (config.linear != null) 'linear',
            if (config.slack != null) 'slack',
            if (config.klipy != null) 'klipy',
          ].join('/'),
          'paused': [
            if (config.github?.acceptsNewAuthorizations == false) 'github',
            if (config.google?.acceptsNewAuthorizations == false) 'google',
            if (config.linear?.acceptsNewAuthorizations == false) 'linear',
            if (config.slack?.acceptsNewAuthorizations == false) 'slack',
          ].join('/'),
        }, ConnectLogLevel.warn);
      }
      await _serve(next);
    } on FileSystemException {
      log.event('config.reload_failed', {
        'reason': 'unreadable',
      }, ConnectLogLevel.error);
    } on ConnectConfigException {
      log.event('config.reload_failed', {
        'reason': 'rejected',
      }, ConnectLogLevel.error);
    } on Object catch (error, stack) {
      log.exception('config.reload_failed', error, stack);
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
       quotas = QuotaGate(state, log, clock),
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

  /// Budgets shared across instances.
  final QuotaGate quotas;

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

  /// The budgets a refresh or a new child spends: the person's share for
  /// this install, their account-wide ceiling, the caller's address and the
  /// whole App's hourly ceiling. [enforce] false only counts (a disconnect is
  /// never refused).
  List<Quota> githubTokenQuotas(
    ConnectCaller caller, {
    required int? accountId,
    bool enforce = true,
  }) {
    final limits = config.rateLimits;
    return [
      if (accountId != null)
        ...githubAccountQuotas(caller.installId, accountId, enforce: enforce),
      Quota(
        'github_address',
        caller.address,
        window: _hour,
        limit: enforce ? limits.githubTokensPerIpPerHour : null,
        logFields: {'ip': caller.network},
      ),
      Quota(
        'github_ceiling',
        '*',
        window: _hour,
        limit: enforce ? limits.githubTokenCeilingPerHour : null,
      ),
    ];
  }

  /// The budgets a code exchange spends before the account is known: the
  /// caller's address and the App-wide sign-in ceiling, which is separate
  /// from the one refreshes and children spend.
  List<Quota> githubExchangeQuotas(ConnectCaller caller) {
    final limits = config.rateLimits;
    return [
      Quota(
        'github_address',
        caller.address,
        window: _hour,
        limit: limits.githubTokensPerIpPerHour,
        logFields: {'ip': caller.network},
      ),
      Quota(
        'github_exchange_ceiling',
        '*',
        window: _hour,
        limit: limits.githubExchangeCeilingPerHour,
      ),
    ];
  }

  /// A GitHub account's token-endpoint budgets: one share per install, so
  /// one server cannot spend what the person's other servers need, and a
  /// ceiling across every install.
  List<Quota> githubAccountQuotas(
    String installId,
    int accountId, {
    bool enforce = true,
  }) {
    final limits = config.rateLimits;
    final fields = {'github_user_id': accountId};
    return [
      Quota(
        'github_account',
        '$accountId/$installId',
        window: _hour,
        limit: enforce ? limits.githubTokensPerAccountPerHour : null,
        logFields: {...fields, 'install': log.tag(installId)},
      ),
      Quota(
        'github_account_ceiling',
        '$accountId',
        window: _hour,
        limit: enforce ? limits.githubTokensAccountCeilingPerHour : null,
        logFields: fields,
      ),
    ];
  }

  /// The budgets an `as: app` installation-token mint spends: the install,
  /// the asking person's GitHub account across installs, and the whole
  /// App's App-JWT ceiling.
  List<Quota> githubAppMintQuotas(ConnectCaller caller, String accountId) {
    final limits = config.rateLimits;
    return [
      Quota(
        'github_app_install',
        caller.installId,
        window: _hour,
        limit: limits.githubAppMintsPerInstallPerHour,
        logFields: {'install': log.tag(caller.installId)},
      ),
      Quota(
        'github_app_account',
        accountId,
        window: _hour,
        limit: limits.githubAppMintsPerAccountPerHour,
        logFields: {'github_user_id': int.tryParse(accountId)},
      ),
      Quota(
        'github_app_ceiling',
        '*',
        window: _hour,
        limit: limits.githubAppCeilingPerHour,
      ),
    ];
  }

  static const _hour = Duration(hours: 1);

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

  /// Stores [login] for the rest of its lifetime: a new login only when its
  /// id is free, an advanced one only while the stored copy is still the
  /// one it was read as (compare-and-set). False when another request got
  /// there first (a replayed callback, a concurrent claim or burn): the
  /// caller treats the login as gone.
  Future<bool> saveLogin(StagedLogin login) async {
    final remaining = login.expiresAt.difference(now());
    if (remaining <= Duration.zero) {
      return false;
    }
    final key = 'login:${login.id}';
    final previous = login.storedAs;
    return previous == null
        ? state.putIfAbsent(key, login.encode(), remaining)
        : state.replace(key, previous, login.encode(), remaining);
  }

  /// Burns a login (and its attempt counter and consent token).
  Future<void> burnLogin(String id) async {
    await state.delete('login:$id');
    await state.delete('attempts:$id');
    await state.delete('consent:$id');
  }
}

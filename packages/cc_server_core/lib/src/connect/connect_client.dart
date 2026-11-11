import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/utils/single_flight.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/bounded_body.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart'
    show errorKindOf;
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/media_proxy_guard.dart'
    show pinnedPermittedConnection;

/// A Connect that did not retire the old install key: its origin and why.
typedef ConnectRetireFailure = ({String origin, ConnectErrorCode error});

/// Thrown by `InstallKeyRotation.rotate` when a Connect could not retire
/// the old install key; the key was not replaced.
final class ConnectRetireFailed implements Exception {
  /// Creates the exception.
  const ConnectRetireFailed(this.failures);

  /// Each Connect that still accepts the old key.
  final List<ConnectRetireFailure> failures;

  /// What the operator reads: origins and error codes, nothing secret.
  String get message =>
      'The install key was not replaced: '
      '${[for (final f in failures) '${f.origin} (${f.error.wire})'].join(', ')} '
      'could not retire the old one. Try again later, or rotate with force '
      'to replace it anyway; those Connects then keep accepting the old key.';

  @override
  String toString() => message;
}

/// The trust state of one Connect target.
final class ConnectConfigState {
  /// Creates the state.
  const ConnectConfigState({
    required this.target,
    this.config,
    this.installId = '',
    this.error = '',
    this.stale = false,
    this.pendingPins,
  });

  /// Which Connect (if any), and whose trust store.
  final ConnectTarget target;

  /// [target] as a choice, for status surfaces.
  ConnectChoice get choice => target.choice;

  /// The verified config, or null when none could be trusted.
  final ConnectConfig? config;

  /// This server's install id towards the Connect (empty when off).
  final String installId;

  /// Why [config] is missing or limited, as a stable code:
  /// `hosted_unprovisioned`, `signature`, `rollback`, `unreachable`,
  /// `install_blocked`, `pins_changed`, `protocol`.
  final String error;

  /// True when [config] is the cached copy because Connect is unreachable.
  final bool stale;

  /// Changed self-hosted identifiers awaiting confirmation in [target]'s
  /// trust store.
  final Map<String, String>? pendingPins;

  /// Whether lanes may route through Connect right now.
  bool get usable => target.enabled && config != null && pendingPins == null;
}

/// Whether a sealed credential can be opened by the Connect its workspace
/// talks to now.
enum SealStanding {
  /// Sealed by this Connect for this server's install identity.
  usable,

  /// The workspace's Connect is off or another one: unusable for now, but
  /// kept, so switching back signs nobody out.
  parked,

  /// Sealed for another install identity at the same Connect (a restored
  /// backup, a rotated key): it can never be opened again, so the honest
  /// state is "sign in again".
  dead,
}

/// The standing of a seal made for [sealInstallId], given this server's
/// install id towards the seal's Connect ([currentInstallId], null or empty
/// when the workspace's Connect is off or another origin). The one rule
/// every sealed lane applies.
SealStanding sealStandingOf({
  required String sealInstallId,
  required String? currentInstallId,
}) {
  if (currentInstallId == null || currentInstallId.isEmpty) {
    return SealStanding.parked;
  }
  return currentInstallId == sealInstallId
      ? SealStanding.usable
      : SealStanding.dead;
}

/// Signs and sends calls to a Connect.
///
/// Every call names its [ConnectTarget]: the server's choice
/// ([serverTarget]) or the one a workspace's choice resolves to
/// ([targetFor]). Everything goes to fixed paths under the target's base
/// URL; nothing a caller passes changes the host. A workspace-chosen URL
/// ([ConnectTarget.guarded]) is resolved, checked against the media-proxy
/// SSRF rules and pinned to that address on every connection. Failures
/// surface as [ConnectException] with the closed vocabulary — a transport
/// failure is always [ConnectErrorCode.providerUnavailable], which callers
/// must never treat as "sign out".
class ConnectClient {
  /// Creates the client. [guardedHttpClient] carries workspace-chosen
  /// targets; by default it connects only through
  /// [pinnedPermittedConnection].
  ConnectClient({
    required this.settings,
    HttpClient? httpClient,
    HttpClient? guardedHttpClient,
    this.timeout = const Duration(seconds: 5),
    this.trustedRootKeys = hostedConfigRootKeys,
    DateTime Function()? now,
  }) : _http = httpClient ?? (HttpClient()..connectionTimeout = timeout),
       _guardedHttp =
           guardedHttpClient ??
           (HttpClient()
             ..connectionTimeout = timeout
             ..findProxy = ((_) => 'DIRECT')
             ..connectionFactory = pinnedPermittedConnection),
       _now = now ?? DateTime.now {
    // A choice or key change, made here or noticed from `cc_server connect`
    // in another process, drops the identities and configs this client
    // cached.
    settings.addListener(invalidate);
    // A workspace's own choice drops what was cached for its trust store.
    settings.addWorkspaceListener(invalidateWorkspace);
  }

  /// Where the choices, seed and trust state live.
  final ConnectSettings settings;

  /// Bound on one call (the long poll uses its own).
  final Duration timeout;

  /// Keys trusted to sign the hosted config.
  final List<String> trustedRootKeys;

  final HttpClient _http;
  final HttpClient _guardedHttp;
  final DateTime Function() _now;

  static const int _maxResponseBytes = 256 * 1024;
  static const Duration _configTtl = Duration(minutes: 10);

  /// Routes where Connect makes several upstream calls in a row (a code
  /// exchange plus identity checks, a refresh plus a mint, a membership
  /// lookup per organization) get longer than one round trip.
  static const Duration _multiCall = Duration(seconds: 30);

  /// Derived identities by base URL; all from [_seedUsed].
  final Map<String, ConnectInstallIdentity> _identities = {};
  List<int>? _seedUsed;

  /// Config states by [ConnectTarget.cacheKey], with when they were read.
  final Map<String, ({ConnectConfigState state, DateTime at})> _states = {};

  /// The last verified `/v1/config` body per target, kept in memory only:
  /// it is the one copy that still holds a key-mode Klipy app key, which
  /// [ConnectSettings.cacheConfig] never persists.
  final Map<String, Map<String, Object?>> _lastGood = {};

  /// One config load per target at a time.
  final SingleFlight<String, ConnectConfigState> _configLoad = SingleFlight();

  /// The server's own choice as a target (`connect.*`, `cc_server connect`,
  /// and every call made for no workspace).
  Future<ConnectTarget> serverTarget() async =>
      ConnectTarget.server(await settings.choice());

  /// Where [workspaceId]'s lanes run; the server's route for null.
  Future<ConnectRoute> routeFor(String? workspaceId) =>
      settings.routeFor(workspaceId);

  /// The Connect [workspaceId]'s lanes route through
  /// ([ConnectTarget.none] when none); the server's for null.
  Future<ConnectTarget> targetFor(String? workspaceId) async =>
      (await settings.routeFor(workspaceId)).target;

  /// This server's identity towards [target], or null when it is off. The
  /// same origin gives the same identity whoever chose it: it is
  /// HKDF-derived per origin from the one master seed.
  Future<ConnectInstallIdentity?> identity(ConnectTarget target) async {
    if (!target.enabled) {
      return null;
    }
    final seed = await settings.installSeed();
    if (!_sameBytes(_seedUsed, seed)) {
      _identities.clear();
      _seedUsed = List.of(seed);
    }
    final cached = _identities[target.baseUrl];
    if (cached != null) {
      return cached;
    }
    final derived = await ConnectInstallIdentity.derive(
      masterSeed: seed,
      connectUrl: target.baseUrl,
    );
    return _identities[target.baseUrl] = derived;
  }

  /// This server's install id towards the Connect at [connectOrigin], as
  /// [workspaceId] sees it (the server's choice for null): null when that
  /// workspace's Connect is off or another origin.
  Future<String?> installIdFor(
    String connectOrigin, {
    String? workspaceId,
  }) async {
    final target = await targetFor(workspaceId);
    if (!target.enabled || target.origin != connectOrigin) {
      return null;
    }
    return (await identity(target))?.installId;
  }

  /// The [SealStanding] of a seal Connect at [connectOrigin] made for
  /// [sealInstallId], held in [workspaceId]'s slot (null: the server-wide
  /// slot, which follows the server's choice).
  Future<SealStanding> sealStanding({
    required String connectOrigin,
    required String sealInstallId,
    String? workspaceId,
  }) async => sealStandingOf(
    sealInstallId: sealInstallId,
    currentInstallId: await installIdFor(
      connectOrigin,
      workspaceId: workspaceId,
    ),
  );

  /// Drops every cached identity and config (after the owner changes the
  /// server's choice or rotates the key).
  void invalidate() {
    _identities.clear();
    _seedUsed = null;
    _states.clear();
    _lastGood.clear();
    // A load started under the old choice or key must not repopulate the
    // cache once it lands.
    _configLoad.invalidateAll();
  }

  /// Drops what was cached for [target] alone.
  void invalidateTarget(ConnectTarget target) {
    _states.remove(target.cacheKey);
    _lastGood.remove(target.cacheKey);
    _configLoad.invalidate(target.cacheKey);
  }

  /// Drops every config cached in [workspaceId]'s own trust store (its
  /// choice changed, or it was deleted). The server's and other
  /// workspaces' entries stay.
  void invalidateWorkspace(String workspaceId) {
    bool theirs(String key) => key.split('\u0000')[1] == workspaceId;
    for (final key in [..._states.keys, ..._lastGood.keys].where(theirs)) {
      _states.remove(key);
      _lastGood.remove(key);
      _configLoad.invalidate(key);
    }
  }

  /// [target]'s config state, refetched at most every ten minutes (or now
  /// with [refresh], which never joins a fetch already in the air), and at
  /// once after the server's choice or install key changed, here or in
  /// another process ([ConnectSettings.noticeExternalChanges]). Concurrent
  /// callers for one target share one fetch.
  Future<ConnectConfigState> configState(
    ConnectTarget target, {
    bool refresh = false,
  }) async {
    await settings.noticeExternalChanges();
    final key = target.cacheKey;
    final cached = _states[key];
    if (!refresh &&
        cached != null &&
        _now().difference(cached.at) < _configTtl) {
      return cached.state;
    }
    if (refresh) {
      _configLoad.invalidate(key);
    }
    return _configLoad.run(
      key,
      () => _loadConfig(target),
      commit: (state) => _states[key] = (state: state, at: _now()),
    );
  }

  /// [target]'s verified config, or null when lanes cannot use it.
  Future<ConnectConfig?> usableConfig(ConnectTarget target) async {
    final state = await configState(target);
    return state.usable ? state.config : null;
  }

  Future<ConnectConfigState> _loadConfig(ConnectTarget target) async {
    if (!target.enabled) {
      return ConnectConfigState(target: target);
    }
    final id = await identity(target);
    final installId = id?.installId ?? '';
    final hosted = target.mode == ConnectMode.hosted;
    if (hosted && trustedRootKeys.isEmpty) {
      return ConnectConfigState(
        target: target,
        installId: installId,
        error: 'hosted_unprovisioned',
      );
    }
    Map<String, Object?> json;
    try {
      json = await _send(target, 'GET', '/v1/config');
    } on ConnectException catch (e) {
      final cached =
          _lastGood[target.cacheKey] ?? await settings.cachedConfig(target);
      final parsed = cached == null ? null : _tryParse(cached);
      final pending = await settings.pendingPins(target);
      return ConnectConfigState(
        target: target,
        installId: installId,
        config: parsed,
        stale: parsed != null,
        error: e.code == ConnectErrorCode.installBlocked
            ? 'install_blocked'
            : 'unreachable',
        pendingPins: pending,
      );
    }
    final ConnectConfig config;
    try {
      config = ConnectConfig.fromJson(json);
    } on FormatException {
      return ConnectConfigState(
        target: target,
        installId: installId,
        error: 'protocol',
      );
    }
    if (hosted) {
      if (!await verifyConnectConfigSignature(
        json,
        trustedKeys: trustedRootKeys,
      )) {
        return ConnectConfigState(
          target: target,
          installId: installId,
          error: 'signature',
        );
      }
      // The epoch high-water mark is global: it only ever rises, so every
      // target that reaches the hosted Connect shares it safely.
      if (config.epoch < await settings.hostedEpoch()) {
        return ConnectConfigState(
          target: target,
          installId: installId,
          error: 'rollback',
        );
      }
      await settings.recordHostedEpoch(config.epoch);
      await _keep(target, json);
      return ConnectConfigState(
        target: target,
        installId: installId,
        config: config,
      );
    }
    // Self-hosted: trust on first use, then hold the identifiers still, in
    // this target's own trust store.
    final identifiers = config.pinnedIdentifiers();
    final pinned = await settings.pins(target);
    if (pinned == null) {
      await settings.setPins(target, identifiers);
    } else if (!_sameMap(pinned, identifiers)) {
      await settings.setPendingPins(target, identifiers);
      return ConnectConfigState(
        target: target,
        installId: installId,
        config: config,
        error: 'pins_changed',
        pendingPins: identifiers,
      );
    }
    await _keep(target, json);
    return ConnectConfigState(
      target: target,
      installId: installId,
      config: config,
    );
  }

  /// Accepts [target]'s changed self-hosted identifiers, in its own trust
  /// store only.
  Future<ConnectConfigState> confirmPendingPins(ConnectTarget target) async {
    final pending = await settings.pendingPins(target);
    if (pending != null) {
      await settings.setPins(target, pending);
    }
    return configState(target, refresh: true);
  }

  Future<void> _keep(ConnectTarget target, Map<String, Object?> json) async {
    _lastGood[target.cacheKey] = json;
    await settings.cacheConfig(target, json);
  }

  static ConnectConfig? _tryParse(Map<String, Object?> json) {
    try {
      return ConnectConfig.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  // --- Typed calls -------------------------------------------------------
  //
  // Each names the target it goes to. A caller holding a seal passes the
  // target its workspace resolves to now; a seal another origin made is
  // parked (`sealStanding`) and never sent elsewhere.

  /// Starts a browser flow at [target] and checks the URL before anyone sees
  /// it.
  Future<OAuthStartResponse> startOAuth(
    ConnectTarget target,
    ConnectOAuthLane lane,
    OAuthStartRequest request, {
    required String expectedClientId,
  }) async {
    final json = await _send(
      target,
      'POST',
      '/v1/oauth/${lane.wire}/start',
      body: request.toJson(),
    );
    final OAuthStartResponse response;
    try {
      response = OAuthStartResponse.fromJson(json);
    } on FormatException {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    try {
      validateAuthorizeUrl(
        lane: lane,
        url: response.authorizeUrl,
        connectBaseUrl: target.baseUrl,
        expectedClientId: expectedClientId,
        codeChallenge: request.codeChallenge,
      );
    } on AuthorizeUrlRejected catch (e) {
      CcHostLog.warning(
        'connect: refused an authorization URL for ${lane.wire} '
        '(${e.reason}) — the Connect at ${target.baseUrl} answered with '
        'something other than its fixed flow.',
      );
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    return response;
  }

  /// Completes a browser flow. The shape of the answer depends on the lane.
  Future<Map<String, Object?>> claim(
    ConnectTarget target,
    ConnectOAuthLane lane,
    OAuthClaimRequest request,
  ) => _send(
    target,
    'POST',
    '/v1/oauth/${lane.wire}/claim',
    body: request.toJson(),
    overrideTimeout: _multiCall,
  );

  /// Refreshes a sealed grant.
  Future<SealedGrant> refresh(
    ConnectTarget target,
    ConnectProvider provider,
    SealRequest request,
  ) async => _parse(
    await _send(
      target,
      'POST',
      '/v1/${provider.name}/refresh',
      body: request.toJson(),
      overrideTimeout: _multiCall,
    ),
    SealedGrant.fromJson,
  );

  /// Mints a one-repository GitHub token.
  Future<GitHubScopedToken> githubScope(
    ConnectTarget target,
    GitHubScopeRequest request,
  ) async => _parse(
    await _send(
      target,
      'POST',
      '/v1/github/scope',
      body: request.toJson(),
      overrideTimeout: _multiCall,
    ),
    GitHubScopedToken.fromJson,
  );

  /// Revokes a GitHub grant or one scoped token.
  Future<void> githubRevoke(
    ConnectTarget target,
    GitHubRevokeRequest request,
  ) async {
    await _send(target, 'POST', '/v1/github/revoke', body: request.toJson());
  }

  /// The installations of the shared app the person can see.
  Future<GitHubInstallationsResponse> githubInstallations(
    ConnectTarget target,
    SealRequest request,
  ) async => _parse(
    await _send(
      target,
      'POST',
      '/v1/github/installations',
      body: request.toJson(),
      overrideTimeout: _multiCall,
    ),
    GitHubInstallationsResponse.fromJson,
  );

  /// Uninstalls the shared Slack bot from this server's team binding.
  Future<void> slackRevoke(ConnectTarget target, SealRequest request) async {
    await _send(target, 'POST', '/v1/slack/revoke', body: request.toJson());
  }

  /// Long-polls [target] for relayed Slack references (up to ~25 s).
  Future<List<Map<String, Object?>>> pollEvents(ConnectTarget target) async {
    final json = await _send(
      target,
      'POST',
      '/v1/events/poll',
      body: const {},
      overrideTimeout: const Duration(seconds: 35),
    );
    final raw = json['events'];
    return [
      if (raw is List)
        for (final item in raw)
          if (item is Map<String, Object?>) item,
    ];
  }

  /// GIF search through [target]'s proxy.
  Future<List<KlipyGif>> klipySearch(
    ConnectTarget target,
    String query,
  ) async => _gifs(
    await _send(target, 'POST', '/v1/klipy/search', body: {'q': query}),
  );

  /// Trending GIFs through [target]'s proxy.
  Future<List<KlipyGif>> klipyTrending(ConnectTarget target) async =>
      _gifs(await _send(target, 'POST', '/v1/klipy/trending', body: const {}));

  static List<KlipyGif> _gifs(Map<String, Object?> json) {
    final raw = json['gifs'];
    return [
      if (raw is List)
        for (final item in raw) ?KlipyGif.tryParse(item),
    ];
  }

  static T _parse<T>(
    Map<String, Object?> json,
    T Function(Map<String, Object?>) parse,
  ) {
    try {
      return parse(json);
    } on FormatException {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
  }

  // --- Transport ---------------------------------------------------------

  Future<Map<String, Object?>> _send(
    ConnectTarget target,
    String method,
    String path, {
    Map<String, Object?>? body,
    Duration? overrideTimeout,
    ConnectInstallIdentity? signer,
  }) async {
    final id = signer ?? await identity(target);
    if (!target.enabled || id == null) {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    final url = Uri.parse('${target.baseUrl}$path');
    final bytes = body == null ? const <int>[] : utf8.encode(jsonEncode(body));
    final headers = await ConnectRequestSigner(
      id,
      now: _now,
    ).sign(method: method, targetUri: url, body: bytes);
    final limit = overrideTimeout ?? timeout;
    String? requestId;
    int? status;
    void failed(String error) =>
        forgeAudit(ForgeAuditEvent.connectCallFailed, {
          'origin': target.origin,
          'method': method,
          'path': path,
          'status': status,
          'error': error,
          // Connect answers every request with one; it finds the call in
          // Connect's own log.
          'connect_request_id': requestId,
        });
    try {
      final http = target.guarded ? _guardedHttp : _http;
      final request = await http.openUrl(method, url).timeout(limit);
      request.followRedirects = false;
      headers.forEach(request.headers.set);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close().timeout(limit);
      requestId = response.headers.value('x-request-id');
      status = response.statusCode;
      final raw = await readBoundedText(
        response,
        maxBytes: _maxResponseBytes,
        timeout: limit,
      );
      Object? decoded;
      try {
        decoded = raw.isEmpty ? const <String, Object?>{} : jsonDecode(raw);
      } on FormatException {
        decoded = null;
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, Object?>) {
          return decoded;
        }
        throw const ConnectException(ConnectErrorCode.providerUnavailable);
      }
      final code = decoded is Map ? decoded['error'] : null;
      throw ConnectException(ConnectErrorCode.fromWire(code));
    } on ConnectException catch (e) {
      failed(e.code.wire);
      rethrow;
    } on Object catch (e) {
      failed('network:${errorKindOf(e)}');
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
  }

  /// Asks [target] to retire the install identity [oldSeed] derives for
  /// it (`POST /v1/install/retire`), signed with that identity and carrying
  /// [seal], one credential seal this Connect made for it. From then on
  /// that Connect refuses the identity and every seal made for it. Throws
  /// [ConnectException]: `install_blocked` means it was retired already.
  Future<void> retireInstall(
    ConnectTarget target,
    SealRequest seal, {
    required List<int> oldSeed,
  }) async {
    final signer = await ConnectInstallIdentity.derive(
      masterSeed: oldSeed,
      connectUrl: target.baseUrl,
    );
    final Map<String, Object?> answer = await _send(
      target,
      'POST',
      connectInstallRetirePath,
      body: seal.toJson(),
      signer: signer,
    );
    try {
      ConnectAck.fromJson(answer);
    } on FormatException {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
  }

  static bool _sameBytes(List<int>? a, List<int> b) {
    if (a == null || a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static bool _sameMap(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}

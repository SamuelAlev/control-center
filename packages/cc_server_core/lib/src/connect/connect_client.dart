import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/utils/single_flight.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/bounded_body.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';

/// The trust state of the Connect this server is configured for.
final class ConnectConfigState {
  /// Creates the state.
  const ConnectConfigState({
    required this.choice,
    this.config,
    this.installId = '',
    this.error = '',
    this.stale = false,
    this.pendingPins,
  });

  /// Which Connect (if any).
  final ConnectChoice choice;

  /// The verified config, or null when none could be trusted.
  final ConnectConfig? config;

  /// This server's install id towards the Connect (empty when off).
  final String installId;

  /// Why [config] is missing or limited, as a stable code:
  /// `hosted_unprovisioned`, `signature`, `rollback`, `unreachable`,
  /// `pins_changed`, `protocol`.
  final String error;

  /// True when [config] is the cached copy because Connect is unreachable.
  final bool stale;

  /// Changed self-hosted identifiers awaiting the owner's confirmation.
  final Map<String, String>? pendingPins;

  /// Whether lanes may route through Connect right now.
  bool get usable => choice.enabled && config != null && pendingPins == null;
}

/// Whether a sealed credential can be opened by the Connect this server
/// talks to now.
enum SealStanding {
  /// Sealed by this Connect for this server's install identity.
  usable,

  /// Connect is off or points at another Connect: unusable for now, but
  /// kept, so switching back signs nobody out.
  parked,

  /// Sealed for another install identity (a restored backup, a rotated key):
  /// it can never be opened again, so the honest state is "sign in again".
  dead,
}

/// The standing of a seal made for [sealInstallId], given this server's
/// install id towards the seal's Connect ([currentInstallId], null or empty
/// when Connect is off or points elsewhere). The one rule every sealed lane
/// applies.
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

/// Signs and sends calls to the configured Connect.
///
/// Everything goes to fixed paths under the configured base URL; nothing a
/// caller passes changes the host. Failures surface as [ConnectException]
/// with the closed vocabulary — a transport failure is always
/// [ConnectErrorCode.providerUnavailable], which callers must never treat as
/// "sign out".
class ConnectClient {
  /// Creates the client.
  ConnectClient({
    required this.settings,
    HttpClient? httpClient,
    this.timeout = const Duration(seconds: 5),
    this.trustedRootKeys = hostedConfigRootKeys,
    DateTime Function()? now,
  }) : _http = httpClient ?? (HttpClient()..connectionTimeout = timeout),
       _now = now ?? DateTime.now {
    // A choice or key change, made here or noticed from `cc_server connect`
    // in another process, drops the identity and config this client cached.
    settings.addListener(invalidate);
  }

  /// Where the choice, seed and trust state live.
  final ConnectSettings settings;

  /// Bound on one call (the long poll uses its own).
  final Duration timeout;

  /// Keys trusted to sign the hosted config.
  final List<String> trustedRootKeys;

  final HttpClient _http;
  final DateTime Function() _now;

  static const int _maxResponseBytes = 256 * 1024;
  static const Duration _configTtl = Duration(minutes: 10);

  /// Routes where Connect makes several upstream calls in a row (a code
  /// exchange plus identity checks, a refresh plus a mint, a membership
  /// lookup per organization) get longer than one round trip.
  static const Duration _multiCall = Duration(seconds: 30);

  ConnectInstallIdentity? _identity;
  String _identityBase = '';
  List<int>? _seedUsed;
  ConnectConfigState? _state;
  DateTime? _stateAt;

  /// The last verified `/v1/config` body and the base it came from, kept in
  /// memory only: it is the one copy that still holds a key-mode Klipy app
  /// key, which [ConnectSettings.cacheConfig] never persists.
  Map<String, Object?>? _lastGood;
  String _lastGoodBase = '';
  final SingleFlight<int, ConnectConfigState> _configLoad = SingleFlight();

  /// The identity for the current Connect, or null when Connect is off.
  Future<ConnectInstallIdentity?> identity() async {
    final choice = await settings.choice();
    if (!choice.enabled) {
      return null;
    }
    final seed = await settings.installSeed();
    final cached = _identity;
    if (cached != null &&
        _identityBase == choice.baseUrl &&
        _sameBytes(_seedUsed, seed)) {
      return cached;
    }
    final derived = await ConnectInstallIdentity.derive(
      masterSeed: seed,
      connectUrl: choice.baseUrl,
    );
    _identity = derived;
    _identityBase = choice.baseUrl;
    _seedUsed = List.of(seed);
    return derived;
  }

  /// This server's install id towards the Connect at [connectOrigin], or
  /// null when Connect is off or configured for another origin.
  Future<String?> installIdFor(String connectOrigin) async {
    final choice = await settings.choice();
    if (!choice.enabled ||
        canonicalConnectBaseUrl(choice.baseUrl) != connectOrigin) {
      return null;
    }
    return (await identity())?.installId;
  }

  /// The [SealStanding] of a seal Connect at [connectOrigin] made for
  /// [sealInstallId].
  Future<SealStanding> sealStanding({
    required String connectOrigin,
    required String sealInstallId,
  }) async => sealStandingOf(
    sealInstallId: sealInstallId,
    currentInstallId: await installIdFor(connectOrigin),
  );

  /// Drops cached identity and config (after the owner changes the choice
  /// or rotates the key).
  void invalidate() {
    _identity = null;
    _identityBase = '';
    _seedUsed = null;
    _state = null;
    _stateAt = null;
    _lastGood = null;
    _lastGoodBase = '';
    // A load started under the old choice or key must not repopulate the
    // cache once it lands.
    _configLoad.invalidateAll();
  }

  /// The current config state, refetched at most every ten minutes (or now
  /// with [refresh], which never joins a fetch already in the air), and at
  /// once after the choice or install key changed, here or in another
  /// process ([ConnectSettings.noticeExternalChanges]). Concurrent callers
  /// share one fetch.
  Future<ConnectConfigState> configState({bool refresh = false}) async {
    await settings.noticeExternalChanges();
    final cached = _state;
    final at = _stateAt;
    if (!refresh &&
        cached != null &&
        at != null &&
        _now().difference(at) < _configTtl) {
      return Future.value(cached);
    }
    if (refresh) {
      _configLoad.invalidate(0);
    }
    return _configLoad.run(0, _loadConfig, commit: _remember);
  }

  /// The verified config, or null when lanes cannot use Connect.
  Future<ConnectConfig?> usableConfig() async {
    final state = await configState();
    return state.usable ? state.config : null;
  }

  Future<ConnectConfigState> _loadConfig() async {
    final choice = await settings.choice();
    if (!choice.enabled) {
      return ConnectConfigState(choice: choice);
    }
    final id = await identity();
    final installId = id?.installId ?? '';
    final hosted = choice.mode == ConnectMode.hosted;
    if (hosted && trustedRootKeys.isEmpty) {
      return ConnectConfigState(
        choice: choice,
        installId: installId,
        error: 'hosted_unprovisioned',
      );
    }
    Map<String, Object?> json;
    try {
      json = await _send('GET', '/v1/config');
    } on ConnectException catch (e) {
      final cached = _lastGoodBase == choice.baseUrl
          ? _lastGood ?? await settings.cachedConfig(choice.baseUrl)
          : await settings.cachedConfig(choice.baseUrl);
      final parsed = cached == null ? null : _tryParse(cached);
      final pending = await settings.pendingPins(choice.baseUrl);
      return ConnectConfigState(
        choice: choice,
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
        choice: choice,
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
          choice: choice,
          installId: installId,
          error: 'signature',
        );
      }
      if (config.epoch < await settings.hostedEpoch()) {
        return ConnectConfigState(
          choice: choice,
          installId: installId,
          error: 'rollback',
        );
      }
      await settings.recordHostedEpoch(config.epoch);
      await _keep(choice.baseUrl, json);
      return ConnectConfigState(
        choice: choice,
        installId: installId,
        config: config,
      );
    }
    // Self-hosted: trust on first use, then hold the identifiers still.
    final identifiers = config.pinnedIdentifiers();
    final pinned = await settings.pins(choice.baseUrl);
    if (pinned == null) {
      await settings.setPins(choice.baseUrl, identifiers);
    } else if (!_sameMap(pinned, identifiers)) {
      await settings.setPendingPins(choice.baseUrl, identifiers);
      return ConnectConfigState(
        choice: choice,
        installId: installId,
        config: config,
        error: 'pins_changed',
        pendingPins: identifiers,
      );
    }
    await _keep(choice.baseUrl, json);
    return ConnectConfigState(
      choice: choice,
      installId: installId,
      config: config,
    );
  }

  /// Accepts the self-hosted Connect's changed identifiers.
  Future<ConnectConfigState> confirmPendingPins() async {
    final choice = await settings.choice();
    final pending = await settings.pendingPins(choice.baseUrl);
    if (pending != null) {
      await settings.setPins(choice.baseUrl, pending);
    }
    return configState(refresh: true);
  }

  Future<void> _keep(String baseUrl, Map<String, Object?> json) async {
    _lastGood = json;
    _lastGoodBase = baseUrl;
    await settings.cacheConfig(baseUrl, json);
  }

  ConnectConfigState _remember(ConnectConfigState state) {
    _state = state;
    _stateAt = _now();
    return state;
  }

  static ConnectConfig? _tryParse(Map<String, Object?> json) {
    try {
      return ConnectConfig.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  // --- Typed calls -------------------------------------------------------

  /// Starts a browser flow and checks the URL before anyone sees it.
  Future<OAuthStartResponse> startOAuth(
    ConnectOAuthLane lane,
    OAuthStartRequest request, {
    required String expectedClientId,
  }) async {
    final json = await _send(
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
    final choice = await settings.choice();
    try {
      validateAuthorizeUrl(
        lane: lane,
        url: response.authorizeUrl,
        connectBaseUrl: choice.baseUrl,
        expectedClientId: expectedClientId,
        codeChallenge: request.codeChallenge,
      );
    } on AuthorizeUrlRejected catch (e) {
      CcHostLog.warning(
        'connect: refused an authorization URL for ${lane.wire} '
        '(${e.reason}) — the Connect at ${choice.baseUrl} answered with '
        'something other than its fixed flow.',
      );
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    return response;
  }

  /// Completes a browser flow. The shape of the answer depends on the lane.
  Future<Map<String, Object?>> claim(
    ConnectOAuthLane lane,
    OAuthClaimRequest request,
  ) => _send(
    'POST',
    '/v1/oauth/${lane.wire}/claim',
    body: request.toJson(),
    overrideTimeout: _multiCall,
  );

  /// Refreshes a sealed grant.
  Future<SealedGrant> refresh(
    ConnectProvider provider,
    SealRequest request,
  ) async => _parse(
    await _send(
      'POST',
      '/v1/${provider.name}/refresh',
      body: request.toJson(),
      overrideTimeout: _multiCall,
    ),
    SealedGrant.fromJson,
  );

  /// Mints a one-repository GitHub token.
  Future<GitHubScopedToken> githubScope(GitHubScopeRequest request) async =>
      _parse(
        await _send(
          'POST',
          '/v1/github/scope',
          body: request.toJson(),
          overrideTimeout: _multiCall,
        ),
        GitHubScopedToken.fromJson,
      );

  /// Revokes a GitHub grant or one scoped token.
  Future<void> githubRevoke(GitHubRevokeRequest request) async {
    await _send('POST', '/v1/github/revoke', body: request.toJson());
  }

  /// An install link that binds the new installation to this server.
  Future<GitHubInstallStartResponse> githubInstallStart(
    SealRequest request,
  ) async => _parse(
    await _send(
      'POST',
      '/v1/github/install/start',
      body: request.toJson(),
      overrideTimeout: _multiCall,
    ),
    GitHubInstallStartResponse.fromJson,
  );

  /// The installations of the shared app the person can see.
  Future<GitHubInstallationsResponse> githubInstallations(
    SealRequest request,
  ) async => _parse(
    await _send(
      'POST',
      '/v1/github/installations',
      body: request.toJson(),
      overrideTimeout: _multiCall,
    ),
    GitHubInstallationsResponse.fromJson,
  );

  /// Authorizes this server on an installation (admin only).
  Future<ConnectAck> githubAuthorizeServer(
    GitHubAuthorizeServerRequest request,
  ) async {
    return _parse(
      await _send(
        'POST',
        '/v1/github/authorize_server',
        body: request.toJson(),
        overrideTimeout: _multiCall,
      ),
      ConnectAck.fromJson,
    );
  }

  /// Uninstalls the shared Slack bot from this server's team binding.
  Future<void> slackRevoke(SealRequest request) async {
    await _send('POST', '/v1/slack/revoke', body: request.toJson());
  }

  /// Long-polls for relayed Slack references (up to ~25 s).
  Future<List<Map<String, Object?>>> pollEvents() async {
    final json = await _send(
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

  /// GIF search through the Connect proxy.
  Future<List<KlipyGif>> klipySearch(String query) async =>
      _gifs(await _send('POST', '/v1/klipy/search', body: {'q': query}));

  /// Trending GIFs through the Connect proxy.
  Future<List<KlipyGif>> klipyTrending() async =>
      _gifs(await _send('POST', '/v1/klipy/trending', body: const {}));

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
    String method,
    String path, {
    Map<String, Object?>? body,
    Duration? overrideTimeout,
  }) async {
    final choice = await settings.choice();
    final id = await identity();
    if (!choice.enabled || id == null) {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    final target = Uri.parse('${choice.baseUrl}$path');
    final bytes = body == null ? const <int>[] : utf8.encode(jsonEncode(body));
    final headers = await ConnectRequestSigner(
      id,
      now: _now,
    ).sign(method: method, targetUri: target, body: bytes);
    final limit = overrideTimeout ?? timeout;
    try {
      final request = await _http.openUrl(method, target).timeout(limit);
      request.followRedirects = false;
      headers.forEach(request.headers.set);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close().timeout(limit);
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
    } on ConnectException {
      rethrow;
    } on Object {
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

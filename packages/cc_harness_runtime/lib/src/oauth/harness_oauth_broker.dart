import 'dart:async';
import 'dart:io';

import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/anthropic_oauth.dart';
import 'package:cc_harness_runtime/src/oauth/kimi_oauth.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/oauth/openai_oauth.dart';
import 'package:cc_harness_runtime/src/oauth/pkce.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// Server-owned OAuth broker for the built-in harness.
///
/// Owns every browser-login flow end to end (the "brain"). Two flow shapes live
/// here because providers implement two:
///
/// - **Redirect** (Anthropic, OpenAI): mint PKCE + state, host a loopback
///   callback on the provider's fixed port, exchange the returned code.
/// - **Device code** (Kimi Code, RFC 8628): request a code, show the user a
///   verification URL and poll the token endpoint server-side until it flips.
///
/// Either way it persists the OAuth [ProviderCredential] and refreshes tokens
/// before expiry. Clients only open the returned URL and poll status (or paste
/// a code, for the redirect flows' web/remote fallback).
class HarnessOAuthBroker implements ProviderCredentialRefresher {
  /// Creates a [HarnessOAuthBroker] persisting into [store].
  ///
  /// [dataDir] is handed to flows that need to persist device identity across
  /// restarts; null is valid and degrades to per-process identity.
  HarnessOAuthBroker({
    required ProviderCredentialStore store,
    List<HarnessOAuthProvider>? providers,
    List<HarnessDeviceOAuthProvider>? deviceProviders,
    String? dataDir,
    ProviderHttp? http,
    Duration minPollInterval = const Duration(seconds: 1),
  }) : _store = store,
       _minPollInterval = minPollInterval,
       _providers = {
         for (final p
             in providers ??
                 [AnthropicOAuth(http: http), OpenAiOAuth(http: http)])
           p.providerId: p,
       },
       _deviceProviders = {
         for (final p
             in deviceProviders ?? [KimiOAuth(dataDir: dataDir, http: http)])
           p.providerId: p,
       };

  final ProviderCredentialStore _store;

  /// Floor on the device-poll interval, so a provider advertising an
  /// implausibly small one cannot turn a login into a hot loop.
  final Duration _minPollInterval;
  final Map<String, HarnessOAuthProvider> _providers;
  final Map<String, HarnessDeviceOAuthProvider> _deviceProviders;
  final Map<String, _OAuthFlow> _flows = {};

  /// How long an unfinished login is kept before it is expired.
  ///
  /// A flow holds a BOUND loopback port on the provider's fixed callback port,
  /// so an abandoned login (the user closed the tab) blocked every retry for
  /// the process lifetime — and the retry then fell silently to the manual
  /// code-paste path, which reads as "the browser login just doesn't work".
  static const Duration _flowTtl = Duration(minutes: 15);

  /// In-flight token refreshes, keyed by provider + account identity.
  final Map<String, Future<ProviderCredential>> _refreshes = {};

  /// Whether [providerId] offers a browser OAuth login, of either shape.
  bool supports(String providerId) =>
      _providers.containsKey(providerId) ||
      _deviceProviders.containsKey(providerId);

  /// Starts a login for [providerId] and returns the URL the client opens plus
  /// the flow id it polls.
  ///
  /// Redirect flows mint PKCE + state and best-effort bind the loopback
  /// callback; device flows request a code and begin polling in the background,
  /// returning the user code for the client to display.
  Future<HarnessOAuthStart> start(String providerId) async {
    final deviceProvider = _deviceProviders[providerId];
    if (deviceProvider != null) {
      return _startDevice(providerId, deviceProvider);
    }
    final provider = _providers[providerId];
    if (provider == null) {
      throw StateError('Provider "$providerId" does not support OAuth.');
    }
    final pkce = Pkce.generate();
    final state = randomOAuthState();
    final flowId = randomOAuthState();
    final flow = _OAuthFlow(provider: provider, pkce: pkce, state: state);
    _expireStaleFlows();
    _flows[flowId] = flow;
    _armFlowExpiry(flowId, flow);
    await _bindLoopback(flowId, flow);
    return HarnessOAuthStart(
      flowId: flowId,
      authUrl: provider.buildAuthUrl(pkce: pkce, state: state),
    );
  }

  Future<HarnessOAuthStart> _startDevice(
    String providerId,
    HarnessDeviceOAuthProvider provider,
  ) async {
    final device = await provider.authorize();
    final flowId = randomOAuthState();
    final flow = _OAuthFlow(deviceProvider: provider)..deviceCode = device;
    _expireStaleFlows();
    _flows[flowId] = flow;
    _armFlowExpiry(flowId, flow);
    // Poll server-side: the client only watches `status`, so a browser tab
    // closing (or a phone finishing the login) cannot strand the flow.
    unawaited(_pollDevice(flowId, flow, provider, device));
    return HarnessOAuthStart(
      flowId: flowId,
      authUrl: device.verificationUri,
      // No code to paste — the user confirms in the browser instead.
      supportsManualPaste: false,
      userCode: device.userCode,
    );
  }

  Future<void> _pollDevice(
    String flowId,
    _OAuthFlow flow,
    HarnessDeviceOAuthProvider provider,
    HarnessDeviceAuthorization device,
  ) async {
    final deadline = DateTime.now().add(device.expiresIn);
    var interval = device.interval < _minPollInterval
        ? _minPollInterval
        : device.interval;
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(interval);
      // Cancelled (or already resolved) while we were waiting.
      if (!identical(_flows[flowId], flow) ||
          flow.status.state != HarnessOAuthState.pending) {
        return;
      }
      try {
        final credential = await provider.poll(device.deviceCode);
        if (credential != null) {
          await _store.save(credential);
          flow.complete(credential.accountLabel);
          return;
        }
      } on HarnessDeviceSlowDown {
        // Widen the interval by 5s, per RFC 8628 section 3.5.
        interval += const Duration(seconds: 5);
      } on HarnessDeviceAuthException catch (e) {
        flow.fail(e.message);
        return;
      } on Object {
        // A transient network blip must not abort a login the user is midway
        // through; back off and keep polling until the device code expires.
        interval *= 2;
      }
    }
    if (flow.status.state == HarnessOAuthState.pending) {
      flow.fail('The Kimi Code sign-in timed out. Start the login again.');
    }
  }

  /// Polls the state of the flow [flowId].
  HarnessOAuthStatus status(String flowId) {
    final flow = _flows[flowId];
    if (flow == null) {
      return const HarnessOAuthStatus(
        state: HarnessOAuthState.error,
        error: 'Unknown or expired login flow.',
      );
    }
    return flow.status;
  }

  /// Completes [flowId] with a manually-pasted [code] (web / remote fallback).
  Future<void> complete(String flowId, String code) => _exchange(flowId, code);

  /// Cancels [flowId] and releases its loopback port.
  Future<void> cancel(String flowId) async {
    final flow = _flows.remove(flowId);
    flow?.expiry?.cancel();
    await flow?.closeServer();
  }

  /// Drops (and unbinds) any flow that has outlived [_flowTtl]. Called on every
  /// `start` so a long-lived process cannot accumulate them.
  void _expireStaleFlows() {
    final now = DateTime.now();
    for (final entry in _flows.entries.toList()) {
      if (now.difference(entry.value.startedAt) < _flowTtl) {
        continue;
      }
      _flows.remove(entry.key);
      entry.value.expiry?.cancel();
      unawaited(entry.value.closeServer());
    }
  }

  /// Expires ONE flow on a timer, so an abandoned login releases its port even
  /// if no further login is ever started.
  void _armFlowExpiry(String flowId, _OAuthFlow flow) {
    flow.expiry = Timer(_flowTtl, () {
      if (!identical(_flows[flowId], flow)) {
        return;
      }
      _flows.remove(flowId);
      flow.fail('Login timed out — start it again.');
      unawaited(flow.closeServer());
    });
  }

  @override
  Future<ProviderCredential> refreshIfNeeded(
    ProviderCredential credential, {
    bool force = false,
  }) async {
    if (credential.method != HarnessAuthMethod.oauth) {
      return credential;
    }
    final refresh =
        _providers[credential.providerId]?.refresh ??
        _deviceProviders[credential.providerId]?.refresh;
    if (refresh == null) {
      return credential;
    }
    final expiresAt = credential.expiresAt;
    if (!force && (expiresAt == null || expiresAt.isAfter(DateTime.now()))) {
      return credential;
    }
    if (credential.refreshToken == null || credential.refreshToken!.isEmpty) {
      return credential;
    }
    // Single-flight per account: one run fans out into parallel subagents that
    // all hit expiry at the same moment and a provider that rotates its
    // refresh token would invalidate every racing exchange but one.
    final key = '${credential.providerId}:${credential.identityKey ?? ''}';
    final inFlight = _refreshes[key];
    if (inFlight != null) {
      return inFlight;
    }
    final pending = _refresh(refresh, credential);
    _refreshes[key] = pending;
    try {
      return await pending;
    } finally {
      unawaited(_refreshes.remove(key));
    }
  }

  /// Performs the token exchange, persisting the result. Never throws — a
  /// failed refresh returns the original credential so the caller still has a
  /// (stale) token to try and the provider's own 401 reports the real cause.
  Future<ProviderCredential> _refresh(
    Future<ProviderCredential> Function(ProviderCredential) refresh,
    ProviderCredential credential,
  ) async {
    try {
      final refreshed = await refresh(credential);
      await _store.save(refreshed);
      return refreshed;
    } on Object {
      return credential;
    }
  }

  Future<void> _bindLoopback(String flowId, _OAuthFlow flow) async {
    try {
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        flow.provider!.callbackPort,
      );
      flow.server = server;
      server.listen((request) async {
        final params = request.uri.queryParameters;
        final code = params['code'];
        final state = params['state'];
        final error = params['error'];
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(_resultPage(error == null && code != null));
        await request.response.close();
        if (error != null) {
          flow.fail(error);
        } else if (code != null && state == flow.state) {
          // The state must MATCH — a callback carrying none used to pass, which
          // is the CSRF check declining to check. Redirect flows always mint
          // one (`randomOAuthState()`), so an absent state means the callback
          // did not come from the authorization we started.
          await _exchange(flowId, code);
        }
        await flow.closeServer();
      });
    } on Object {
      // Port unavailable (busy, or a remote server whose loopback the user's
      // browser can't reach) — the manual code-paste path still completes it.
      flow.server = null;
    }
  }

  Future<void> _exchange(String flowId, String code) async {
    final flow = _flows[flowId];
    final provider = flow?.provider;
    if (flow == null || flow.status.state == HarnessOAuthState.completed) {
      return;
    }
    if (provider == null) {
      // A device-code flow has no code to redeem — it completes by polling.
      flow.fail('This provider completes sign-in in the browser.');
      return;
    }
    try {
      final credential = await provider.exchange(code: code, pkce: flow.pkce);
      await _store.save(credential);
      flow.complete(credential.email);
    } on Object catch (e) {
      flow.fail('$e');
    } finally {
      await flow.closeServer();
    }
  }

  static String _resultPage(bool ok) =>
      '<!doctype html><html><body '
      'style="font-family:system-ui;padding:3rem;text-align:center">'
      '<h2>${ok ? 'Signed in ✓' : 'Sign-in failed'}</h2>'
      '<p>${ok ? 'You can close this tab and return to Control Center.' : 'Please return to Control Center and try again.'}</p>'
      '</body></html>';
}

/// Mutable state for one in-flight OAuth login.
class _OAuthFlow {
  _OAuthFlow({this.provider, this.deviceProvider, Pkce? pkce, this.state = ''})
    : pkce = pkce ?? const Pkce(verifier: '', challenge: '');

  /// Set for redirect flows; null for device-code flows.
  final HarnessOAuthProvider? provider;

  /// Set for device-code flows; null for redirect flows.
  final HarnessDeviceOAuthProvider? deviceProvider;
  final Pkce pkce;
  final String state;

  /// When the flow was started (drives TTL expiry).
  final DateTime startedAt = DateTime.now();

  /// Fires once the flow has outlived its TTL.
  Timer? expiry;
  HarnessDeviceAuthorization? deviceCode;
  HttpServer? server;
  HarnessOAuthStatus status = const HarnessOAuthStatus(
    state: HarnessOAuthState.pending,
  );

  void complete(String? account) {
    status = HarnessOAuthStatus(
      state: HarnessOAuthState.completed,
      account: account,
    );
  }

  void fail(String error) {
    status = HarnessOAuthStatus(state: HarnessOAuthState.error, error: error);
  }

  Future<void> closeServer() async {
    final s = server;
    server = null;
    await s?.close(force: true);
  }
}

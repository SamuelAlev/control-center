import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/src/binding_store.dart';
import 'package:cc_connect/src/connect_log.dart';
import 'package:cc_connect/src/context.dart';
import 'package:cc_connect/src/credential_seal.dart';
import 'package:cc_connect/src/firestore_binding_store.dart';
import 'package:cc_connect/src/gcp_auth.dart';
import 'package:cc_connect/src/grant_routes.dart';
import 'package:cc_connect/src/http_io.dart';
import 'package:cc_connect/src/oauth_routes.dart';
import 'package:cc_connect/src/quota.dart';
import 'package:cc_connect/src/rate_limiter.dart';
import 'package:cc_connect/src/redis_state_store.dart';
import 'package:cc_connect/src/relay_routes.dart';
import 'package:cc_connect/src/seal_cipher.dart';
import 'package:cc_connect/src/sentry_reporter.dart';
import 'package:cc_connect/src/service_config.dart';
import 'package:cc_connect/src/state_store.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

typedef _SignedHandler =
    Future<Object?> Function(ConnectCaller caller, Map<String, Object?> body);

/// Control Center Connect as a `dart:io` request handler.
///
/// Standalone, [serveConnect] binds it to a port. Embedded, a host server
/// (cc_server with `CC_SERVER_CONNECT_HOST=on`) forwards every request whose
/// path [ownsPath] to [handle], outside its own session and CORS middleware;
/// routing is relative to the path of `CONNECT_PUBLIC_URL`.
final class ConnectService {
  ConnectService._(
    this.context, {
    required this._ownsHttp,
    required this._ownsState,
    required this._ownsBindings,
  }) : _grants = GrantRoutes(context),
       _relay = RelayRoutes(context),
       _verifyPool = BoundedPool(concurrency: 16, maxQueued: 512),
       _installLimiter = TokenBucketLimiter(
         capacity: context.config.rateLimits.perInstallPerMinute,
         per: const Duration(minutes: 1),
         clock: context.clock,
       ),
       _ipLimiter = TokenBucketLimiter(
         capacity: context.config.rateLimits.perIpPerMinute,
         per: const Duration(minutes: 1),
         clock: context.clock,
       ),
       _globalLimiter = TokenBucketLimiter(
         capacity: context.config.rateLimits.globalPerSecond,
         per: const Duration(seconds: 1),
         clock: context.clock,
       ),
       _hookIpLimiter = TokenBucketLimiter(
         capacity: context.config.rateLimits.slackHookPerIpPerMinute,
         per: const Duration(minutes: 1),
         clock: context.clock,
       ),
       _hookGlobalLimiter = TokenBucketLimiter(
         capacity: context.config.rateLimits.slackHookGlobalPerSecond,
         per: const Duration(seconds: 1),
         clock: context.clock,
       ) {
    _oauth = OAuthRoutes(context);
  }

  /// Builds a service from [config]. Backends default to what the config
  /// names (memory / Redis state, file / Firestore bindings, local / KMS
  /// seals) over a real [IoUpstreamHttp]; tests inject their own.
  ///
  /// Throws [ConnectConfigException] when the signed config does not match
  /// the credentials, the seal cipher fails a round trip, or the state or
  /// binding backend fails its probe ([StateStore.probe],
  /// [BindingStore.probe]).
  static Future<ConnectService> start(
    ConnectServiceConfig config, {
    UpstreamHttp? upstream,
    StateStore? state,
    BindingStore? bindings,
    SealCipher? cipher,
    ConnectLogSink? logSink,
    DateTime Function()? clock,
    Duration pollTimeout = const Duration(seconds: 25),
  }) async {
    // A refused boot closes what it opened: the binding store holds the data
    // dir's lock file, so a later start in this process (or, on Windows,
    // removing the directory) would fail on it.
    final opened = <FutureOr<void> Function()>[];
    try {
      return await _start(
        config,
        opened: opened,
        upstream: upstream,
        state: state,
        bindings: bindings,
        cipher: cipher,
        logSink: logSink,
        clock: clock,
        pollTimeout: pollTimeout,
      );
    } on Object {
      for (final close in opened.reversed) {
        try {
          await close();
        } on Object {
          // The boot error is the one worth reporting.
        }
      }
      rethrow;
    }
  }

  static Future<ConnectService> _start(
    ConnectServiceConfig config, {
    required List<FutureOr<void> Function()> opened,
    required UpstreamHttp? upstream,
    required StateStore? state,
    required BindingStore? bindings,
    required SealCipher? cipher,
    required ConnectLogSink? logSink,
    required DateTime Function()? clock,
    required Duration pollTimeout,
  }) async {
    final now = clock ?? DateTime.now;
    final hmacKey = config.logHmacKey?.value ?? '';
    final log = ConnectLog(
      sink: logSink,
      hmacKey: hmacKey.isEmpty ? null : utf8.encode(hmacKey),
      clock: now,
    );
    final rawDsn = config.sentryDsn?.value;
    final dsn = rawDsn == null ? null : SentryDsn.tryParse(rawDsn);
    final rawHttp =
        upstream ??
        IoUpstreamHttp(
          allowedHosts: {
            ...connectUpstreamHosts,
            if (dsn != null) dsn.host: 'https',
          },
        );
    if (dsn != null) {
      log.reporter = SentryReporter(
        dsn: dsn,
        http: rawHttp,
        log: log,
        release: config.version,
        environment: config.sentryEnvironment.isNotEmpty
            ? config.sentryEnvironment
            : (config.servesSignedConfig ? 'hosted' : 'self-hosted'),
        clock: now,
      ).report;
    }
    if (upstream == null) {
      opened.add(rawHttp.close);
    }
    final http = ObservedUpstream(rawHttp, log, clock: now);
    final tokens = GcpMetadataTokenSource(http, clock: now);

    final SealCipher sealCipher;
    if (cipher != null) {
      sealCipher = cipher;
    } else if (config.sealBackend == SealBackend.gcpKms) {
      sealCipher = GcpKmsSealCipher(
        keyName: config.kmsKey,
        http: http,
        tokens: tokens,
      );
    } else {
      try {
        sealCipher = LocalAeadSealCipher(
          config.sealKeys!,
          onReloadFailed: () => log.event(
            'seal.keyring_reload_failed',
            const {},
            ConnectLogLevel.error,
          ),
        );
      } on FormatException catch (error) {
        throw ConnectConfigException('CONNECT_SEAL_KEYS: ${error.message}');
      }
    }
    await _probeCipher(sealCipher, config.sealBackend);

    final StateStore stateStore;
    if (state != null) {
      stateStore = state;
    } else if (config.stateBackend == StateBackend.redis) {
      SecurityContext? tls;
      if (config.redisCaFile.isNotEmpty) {
        try {
          tls = SecurityContext()..setTrustedCertificates(config.redisCaFile);
        } on Object {
          throw const ConnectConfigException(
            'CONNECT_REDIS_CA_FILE is not a readable PEM bundle',
          );
        }
      }
      stateStore = RedisStateStore(
        Uri.parse(config.redisUrl!.value),
        tlsContext: tls,
      );
    } else {
      stateStore = MemoryStateStore(
        clock: now,
        onFull: () => log.sampled('state.full', '', const {
          'backend': 'memory',
        }, ConnectLogLevel.error),
      );
    }
    if (state == null) {
      opened.add(stateStore.close);
    }
    try {
      await stateStore.probe();
    } on StateStoreUnavailable catch (error) {
      throw ConnectConfigException(
        'CONNECT_REDIS_URL: Redis failed its boot probe (${error.reason}): '
        'AUTH/SELECT and a SET + GETDEL round trip must succeed, which '
        'needs Redis 6.2 or later',
      );
    }
    if (stateStore is RedisStateStore) {
      // Logins, nonces, quotas and leases must never be evicted to make
      // room: an evicted nonce is a replay, an evicted quota a fresh budget.
      final String? policy;
      try {
        policy = await stateStore.evictionPolicy();
      } on StateStoreUnavailable catch (error) {
        throw ConnectConfigException(
          'CONNECT_REDIS_URL: INFO memory failed (${error.reason})',
        );
      }
      if (policy != 'noeviction') {
        throw ConnectConfigException(
          'CONNECT_REDIS_URL: Redis maxmemory-policy is '
          '${policy ?? 'unknown'}; it must be noeviction',
        );
      }
    }

    final BindingStore bindingStore;
    if (bindings != null) {
      bindingStore = bindings;
    } else if (config.bindingBackend == BindingBackend.firestore) {
      bindingStore = CachedBindingStore(
        FirestoreBindingStore(
          project: config.firestoreProject,
          database: config.firestoreDatabase,
          http: http,
          tokens: tokens,
          clock: now,
        ),
        clock: now,
      );
    } else {
      try {
        bindingStore = await FileBindingStore.open(config.dataDir);
      } on FileSystemException {
        throw const ConnectConfigException('CONNECT_DATA_DIR is not writable');
      } on BindingStoreUnavailable catch (error) {
        throw ConnectConfigException('CONNECT_DATA_DIR: ${error.reason}');
      }
    }
    if (bindings == null) {
      opened.add(bindingStore.close);
    }
    try {
      await bindingStore.probe();
    } on BindingStoreUnavailable catch (error) {
      throw ConnectConfigException(
        'CONNECT_FIRESTORE_PROJECT: Firestore failed its boot probe '
        '(${error.reason}); check the database id and the service '
        "account's datastore.user grant",
      );
    }

    final served = ServedConfig(
      config,
      bootTime: now().toUtc(),
      log: log,
      clock: now,
    );
    await served.load();
    if (config.access.allowAll && served.signedByOperatorKey) {
      // Every install on the internet may use this Connect's apps and
      // secrets, under a config signed by the operator's own key rather
      // than Control Center's hosted root.
      log.event('config.open_to_any_install', const {}, ConnectLogLevel.error);
    }

    final context = ConnectContext(
      config: config,
      state: stateStore,
      bindings: bindingStore,
      sealer: CredentialSealer(
        connectOrigin: config.publicBaseUrl,
        cipher: sealCipher,
        log: log,
      ),
      http: http,
      log: log,
      served: served,
      clock: now,
      pollTimeout: pollTimeout,
    );
    final service = ConnectService._(
      context,
      ownsHttp: upstream == null,
      ownsState: state == null,
      ownsBindings: bindings == null,
    );
    final lanes = (await served.current()).config;
    log.event('connect.started', {
      'version': config.version,
      'epoch': lanes.epoch,
      'backend':
          '${config.sealBackend.name}/${config.stateBackend.name}/'
          '${config.bindingBackend.name}',
      'count': [
        lanes.github,
        lanes.google,
        lanes.linear,
        lanes.slack,
        lanes.klipy,
      ].whereType<Object>().length,
    });
    return service;
  }

  /// Encrypts and decrypts a throwaway value: a KMS key that is missing, has
  /// no IAM grant or is disabled refuses boot instead of failing every seal
  /// afterwards.
  static Future<void> _probeCipher(
    SealCipher cipher,
    SealBackend backend,
  ) async {
    final aad = utf8.encode('cc-connect/boot-probe');
    final probe = randomBytes(16);
    try {
      final opened = await cipher.decrypt(
        await cipher.encrypt(probe, aad),
        aad,
      );
      if (b64url(opened) != b64url(probe)) {
        throw const SealDecryptFailed();
      }
    } on Object catch (error) {
      throw ConnectConfigException(
        'The ${backend.name} seal cipher failed its boot round trip '
        '(${error.runtimeType}); check CONNECT_KMS_KEY and its IAM grant',
      );
    }
  }

  /// The shared context (tests inspect stores through it).
  final ConnectContext context;
  final bool _ownsHttp;
  final bool _ownsState;
  final bool _ownsBindings;
  final GrantRoutes _grants;
  final RelayRoutes _relay;
  late final OAuthRoutes _oauth;
  final BoundedPool _verifyPool;
  final TokenBucketLimiter _installLimiter;
  final TokenBucketLimiter _ipLimiter;
  final TokenBucketLimiter _globalLimiter;
  final TokenBucketLimiter _hookIpLimiter;
  final TokenBucketLimiter _hookGlobalLimiter;
  DateTime? _readyAt;
  bool _ready = false;
  bool _forwardedWarned = false;
  Future<bool>? _readyCheck;

  /// The Redis eviction policy the last readiness check saw (boot refused
  /// any other).
  String _evictionPolicy = 'noeviction';

  ConnectServiceConfig get _config => context.config;

  /// Whether [path] (a request's raw path) belongs to this Connect.
  bool ownsPath(String path) {
    final base = _config.basePath;
    return base.isEmpty || path == base || path.startsWith('$base/');
  }

  String? _relative(String path) {
    final base = _config.basePath;
    if (base.isEmpty) {
      return path;
    }
    if (path.startsWith('$base/')) {
      return path.substring(base.length);
    }
    // A reverse proxy that strips the mount prefix hands over the relative
    // path itself; signatures still cover the full public URL.
    return path.startsWith('/v1/') ||
            path.startsWith('/oauth/') ||
            path == '/healthz' ||
            path == '/readyz'
        ? path
        : null;
  }

  /// The per-IP bucket key: the address for IPv4, and for IPv6 its first
  /// [ipv6Groups] groups (four, a /64, by default: one host usually holds a
  /// whole /64).
  static String ipBucketKey(String ip, {int ipv6Groups = 4}) {
    final address = InternetAddress.tryParse(ip);
    if (address == null || address.type != InternetAddressType.IPv6) {
      return ip;
    }
    final raw = address.rawAddress;
    return [
      for (var i = 0; i < ipv6Groups * 2; i += 2)
        ((raw[i] << 8) | raw[i + 1]).toRadixString(16),
    ].join(':');
  }

  bool _take(
    TokenBucketLimiter limiter,
    String bucket,
    String key, {
    String? ip,
    String? install,
  }) {
    if (limiter.tryTake(key)) {
      return true;
    }
    context.log.sampled('ratelimit.hit', '$bucket/$key', {
      'bucket': bucket,
      'ip': ?ip,
      'install': ?install,
    });
    return false;
  }

  String _clientIp(HttpRequest request) {
    final hops = _config.trustProxyHops;
    if (hops == 0 &&
        !_forwardedWarned &&
        request.headers['x-forwarded-for'] != null) {
      // Behind a proxy, every client shares the proxy's per-address budget.
      _forwardedWarned = true;
      context.log.event('config.trust_proxy_unset', const {
        'reason': 'forwarded_header_ignored',
      }, ConnectLogLevel.warn);
    }
    if (hops > 0) {
      final forwarded = request.headers['x-forwarded-for'];
      if (forwarded != null && forwarded.isNotEmpty) {
        final entries = [
          for (final header in forwarded)
            for (final part in header.split(','))
              if (part.trim().isNotEmpty) part.trim(),
        ];
        if (entries.length >= hops) {
          return entries[entries.length - hops];
        }
      }
    }
    return request.connectionInfo?.remoteAddress.address ?? '';
  }

  /// Handles one request and closes its response.
  Future<void> handle(HttpRequest request) {
    final scope = ConnectRequestScope();
    return scope.run(() => _handle(request, scope));
  }

  Future<void> _handle(HttpRequest request, ConnectRequestScope scope) async {
    final started = DateTime.now();
    final response = request.response;
    try {
      applyBaseHeaders(
        response,
        https: _config.publicBaseUrl.startsWith('https://'),
      );
      response.headers.set('x-request-id', scope.requestId);
      final path = _relative(request.uri.path);
      if (path == null) {
        return await _notFound(response);
      }
      scope.route = _routeLabel(path);
      // Probes spend no token: a flood must not fail the platform's health
      // check.
      if (path == '/healthz') {
        return await (request.method == 'GET'
            ? sendJson(response, 200, {'ok': true})
            : _methodNotAllowed(response));
      }
      if (path == '/readyz') {
        if (request.method != 'GET') {
          return await _methodNotAllowed(response);
        }
        final ready = await _readiness();
        return await sendJson(response, ready ? 200 : 503, {'ok': ready});
      }
      final ip = _clientIp(request);
      final logIp = truncateIp(ip);
      final hook =
          path == '/v1/hooks/slack/events' ||
          path == '/v1/hooks/slack/commands';
      // Per IP first: one address cannot drain the instance-wide bucket.
      if (!_take(
            hook ? _hookIpLimiter : _ipLimiter,
            hook ? 'hook_ip' : 'ip',
            ipBucketKey(ip),
            ip: logIp,
          ) ||
          !_take(
            hook ? _hookGlobalLimiter : _globalLimiter,
            hook ? 'hook_global' : 'global',
            '*',
          )) {
        response.persistentConnection = false;
        return await sendError(response, ConnectErrorCode.rateLimited);
      }
      await _dispatch(request, path, ip, logIp);
    } on Object catch (error, stack) {
      await _fail(response, error, stack);
    } finally {
      context.log.event('http.request', {
        'method': request.method,
        'status': response.statusCode,
        'ms': DateTime.now().difference(started).inMilliseconds,
      });
    }
  }

  /// Whether the state and binding backends answer (and Redis still runs
  /// `noeviction`), cached for 5 s.
  Future<bool> _readiness() {
    final at = _readyAt;
    if (at != null &&
        context.clock().difference(at) < const Duration(seconds: 5)) {
      return Future.value(_ready);
    }
    return _readyCheck ??= _probeBackends().whenComplete(
      () => _readyCheck = null,
    );
  }

  Future<bool> _probeBackends() async {
    var ready = true;
    try {
      await context.state.probe();
      ready = await _evictionPolicyHolds();
      await context.bindings.probe();
    } on StateStoreUnavailable catch (error) {
      ready = false;
      context.log.sampled('readyz.failed', 'state', {
        'backend': 'state',
        'reason': _slug(error.reason),
      });
    } on BindingStoreUnavailable catch (error) {
      ready = false;
      context.log.sampled('readyz.failed', 'bindings', {
        'backend': 'bindings',
        'reason': _slug(error.reason),
      });
    }
    _ready = ready;
    _readyAt = context.clock();
    return ready;
  }

  /// Whether Redis still runs `noeviction`, as boot required: a policy
  /// changed since would let it evict nonces and quotas. Logged once per
  /// change.
  Future<bool> _evictionPolicyHolds() async {
    final state = context.state;
    if (state is! RedisStateStore) {
      return true;
    }
    final policy = await state.evictionPolicy() ?? 'unknown';
    if (policy != _evictionPolicy) {
      _evictionPolicy = policy;
      final holds = policy == 'noeviction';
      context.log.event('readyz.eviction_policy', {
        'backend': 'state',
        'reason': _slug(policy),
      }, holds ? ConnectLogLevel.info : ConnectLogLevel.error);
    }
    return policy == 'noeviction';
  }

  static String _slug(String reason) =>
      reason.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');

  /// Answers [error] and writes one line for it: `http.refused` (warn) for a
  /// refusal or an outage with its fixed reason, `http.error` (error, type
  /// only, reported to Sentry) for anything unexpected.
  Future<void> _fail(
    HttpResponse response,
    Object error,
    StackTrace stack,
  ) async {
    final log = context.log;
    switch (error) {
      case ConnectException(:final code, :final reason):
        log.event('http.refused', {
          'error': code.wire,
          if (reason.isNotEmpty) 'reason': _slug(reason),
        }, ConnectLogLevel.warn);
      case StateStoreUnavailable(:final reason) ||
          BindingStoreUnavailable(:final reason) ||
          UpstreamUnavailable(:final reason):
        log.event('http.refused', {
          'error': ConnectErrorCode.providerUnavailable.wire,
          'backend': switch (error) {
            StateStoreUnavailable() => 'state',
            BindingStoreUnavailable() => 'bindings',
            _ => 'upstream',
          },
          'reason': _slug(reason),
        }, ConnectLogLevel.warn);
      case ConnectClientAborted():
        // The socket is gone: the answer below reaches no one.
        log.event('http.client_aborted', const {}, ConnectLogLevel.warn);
      default:
        log.exception('http.error', error, stack, {
          'error': ConnectErrorCode.providerUnavailable.wire,
        });
    }
    try {
      await sendError(
        response,
        error is ConnectException
            ? error.code
            : ConnectErrorCode.providerUnavailable,
      );
    } on Object {
      // Headers already sent or the socket is gone.
    }
  }

  Future<void> _notFound(HttpResponse response) =>
      sendJson(response, 404, {'error': ConnectErrorCode.invalidRequest.wire});

  Future<void> _methodNotAllowed(HttpResponse response) =>
      sendJson(response, 405, {'error': ConnectErrorCode.invalidRequest.wire});

  static String _routeLabel(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length > 5 || segments.any((s) => s.length > 40)) {
      return 'other';
    }
    final label = '/${segments.join('/')}';
    return RegExp(r'^[a-z0-9_/]+$').hasMatch(label) ? label : 'other';
  }

  Future<void> _dispatch(
    HttpRequest request,
    String path,
    String rawIp,
    String ip,
  ) async {
    final method = request.method;
    final response = request.response;
    final segments = path.split('/').skip(1).toList();

    if (path == '/v1/version') {
      return method == 'GET'
          ? sendJson(response, 200, {
              'protocol': connectProtocolVersion,
              'version': _config.version,
              if (_config.imageDigest.isNotEmpty)
                'image_digest': _config.imageDigest,
            })
          : _methodNotAllowed(response);
    }
    // Slack's own servers, on their own buckets (see [_handle]).
    if (path == '/v1/hooks/slack/events' ||
        path == '/v1/hooks/slack/commands') {
      if (method != 'POST') {
        return _methodNotAllowed(response);
      }
      return path.endsWith('events')
          ? _relay.slackEvents(request, ip: ip)
          : _relay.slackCommands(request, ip: ip);
    }

    // Browser routes.
    if (segments.length == 3 && segments[0] == 'oauth') {
      final segment = segments[1];
      final step = segments[2];
      final doneLane = step == 'done'
          ? ConnectOAuthLane.fromWire(segment)
          : null;
      if (doneLane != null && method == 'POST') {
        return _oauth.doneAction(request, doneLane);
      }
      if (method != 'GET') {
        return _methodNotAllowed(response);
      }
      if (segment == 'github' && step == 'setup') {
        return _oauth.githubSetup(request);
      }
      // The callback routes are exactly the segments the lanes redirect to.
      if (step == 'callback' &&
          ConnectOAuthLane.fromCallbackSegment(segment) != null) {
        return _oauth.callback(request, segment);
      }
      if (doneLane != null) {
        return _oauth.done(request, doneLane, network: ip);
      }
      return _notFound(response);
    }

    final handler = _signedRoute(method, segments);
    if (handler == null) {
      return _notFound(response);
    }
    if (handler.$1 != method) {
      return _methodNotAllowed(response);
    }
    return _signed(request, path, handler.$2, rawIp, ip);
  }

  (String, _SignedHandler)? _signedRoute(String method, List<String> s) {
    if (s.isEmpty || s[0] != 'v1') {
      return null;
    }
    final route = s.skip(1).join('/');
    switch (route) {
      case 'config':
        return ('GET', _configRoute);
      case 'github/refresh':
        return (
          'POST',
          (c, b) => _grants.refresh(c, b, ConnectProvider.github),
        );
      case 'google/refresh':
        return (
          'POST',
          (c, b) => _grants.refresh(c, b, ConnectProvider.google),
        );
      case 'slack/refresh':
        return ('POST', (c, b) => _grants.refresh(c, b, ConnectProvider.slack));
      case 'github/scope':
        return ('POST', _grants.githubScope);
      case 'github/review_comments':
        return ('POST', _grants.githubReviewComments);
      case 'github/installations':
        return ('POST', _grants.githubInstallations);
      case 'github/revoke':
        return ('POST', _grants.githubRevoke);
      case 'slack/revoke':
        return ('POST', _grants.slackRevoke);
      case 'events/poll':
        return ('POST', _relay.poll);
      case 'install/retire':
        return ('POST', _retire);
      case 'klipy/search':
        return ('POST', (c, b) => _relay.klipy(c, b, search: true));
      case 'klipy/trending':
        return ('POST', (c, b) => _relay.klipy(c, b, search: false));
    }
    if (s.length == 4 && s[1] == 'oauth') {
      final lane = ConnectOAuthLane.fromWire(s[2]);
      if (lane == null) {
        return null;
      }
      if (s[3] == 'start') {
        return ('POST', (c, b) => _oauth.start(c, lane, b));
      }
      if (s[3] == 'claim') {
        return ('POST', (c, b) => _oauth.claim(c, lane, b));
      }
      return null;
    }
    return null;
  }

  /// The allow/deny list (on the install the request claims, before the
  /// Ed25519 check), RFC 9421 verification, the allow/deny list and the
  /// retired set on the verified install, the nonce replay cache and the
  /// per-install budget, then [handler]. [rawIp] keys budgets; [ip] is its
  /// truncated form for logs.
  Future<void> _signed(
    HttpRequest request,
    String path,
    _SignedHandler handler,
    String rawIp,
    String ip,
  ) async {
    final response = request.response;
    final log = context.log;
    void refused(String reason, {String? install}) => log.sampled(
      'auth.refused',
      '$reason/$ip',
      {'reason': reason, 'ip': ip, 'install': ?install},
    );

    final maxBytes = path == '/v1/github/review_comments'
        ? connectMaxReviewCommentsRequestBytes
        : connectMaxRequestBytes;
    final body = await readCappedBody(request, maxBytes);
    if (body == null) {
      response.persistentConnection = false;
      return sendError(response, ConnectErrorCode.invalidRequest);
    }
    // A claimed install that may not call is refused before the costly
    // verification: the verified id below is derived from the same keyid,
    // so this never admits anyone.
    final claimed = claimedInstallId(singleHeader(request, 'signature-input'));
    if (claimed != null && !_config.access.permits(claimed)) {
      refused('blocked', install: log.tag(claimed));
      return sendError(response, ConnectErrorCode.installBlocked);
    }
    final query = request.uri.hasQuery ? '?${request.uri.query}' : '';
    final target = Uri.parse('${_config.publicBaseUrl}$path$query');
    final VerifiedConnectRequest? verified;
    try {
      verified = await _verifyPool.run(
        () => verifyConnectRequest(
          method: request.method,
          targetUri: target,
          header: (name) => singleHeader(request, name),
          body: body,
          now: context.clock,
        ),
      );
    } on ConnectSignatureException catch (error) {
      refused(error.failure.name);
      return sendError(
        response,
        error.failure == ConnectSignatureFailure.stale
            ? ConnectErrorCode.staleRequest
            : ConnectErrorCode.accessDenied,
      );
    }
    if (verified == null) {
      log.sampled('ratelimit.hit', 'verify', const {'bucket': 'verify'});
      return sendError(response, ConnectErrorCode.rateLimited);
    }
    final install = log.tag(verified.installId);
    // The allow/deny list again on the verified id, before the nonce write
    // so a blocked install cannot fill the replay cache.
    if (!_config.access.permits(verified.installId)) {
      refused('blocked', install: install);
      return sendError(response, ConnectErrorCode.installBlocked);
    }
    ConnectRequestScope.current?.install = install;
    // Retired by its own key: refused for good, on every route.
    if (await context.bindings.isRetired(verified.installId)) {
      refused('retired', install: install);
      return sendError(response, ConnectErrorCode.installBlocked);
    }
    if (!await context.state.putIfAbsent(
      'nonce:${verified.installId}:${verified.nonce}',
      '1',
      nonceTtl,
    )) {
      refused('replay', install: install);
      return sendError(response, ConnectErrorCode.staleRequest);
    }
    if (!_take(
      _installLimiter,
      'install',
      verified.installId,
      install: install,
    )) {
      return sendError(response, ConnectErrorCode.rateLimited);
    }
    final json = body.isEmpty
        ? const <String, Object?>{}
        : decodeJsonObject(body);
    final caller = ConnectCaller(
      installId: verified.installId,
      address: ipBucketKey(rawIp),
      wideAddress: ipBucketKey(rawIp, ipv6Groups: 3),
      network: ip,
    );
    final result = await handler(caller, json);
    if (result is _Verbatim) {
      response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..contentLength = result.bytes.length
        ..add(result.bytes);
      return response.close();
    }
    return sendJson(response, 200, result);
  }

  /// `POST /v1/install/retire` ([connectInstallRetirePath]): retires the
  /// install that signed it, for good. The body is a [SealRequest] naming
  /// any credential seal of that install: it retires only when the seal
  /// opens under the caller's own binding (any lane, any generation the
  /// keyring still opens), so only an install that holds something to
  /// contain reaches the retired set. Nothing is asked upstream. Reachable
  /// only through [_signed], on a budget of its own per client address (an
  /// IPv6 /48), and refused (logged at error) once the retired set is full.
  /// The install's Slack team bindings are released.
  Future<Object?> _retire(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final SealRequest request;
    try {
      request = SealRequest.fromJson(body);
    } on FormatException {
      throw const ConnectException(ConnectErrorCode.invalidRequest);
    }
    final install = context.log.tag(caller.installId);
    await context.quotas.admit([
      Quota(
        'retire_ip',
        caller.wideAddress,
        window: const Duration(hours: 1),
        limit: _config.rateLimits.retiresPerIpPerHour,
        logFields: {'ip': caller.network},
      ),
    ]);
    final header = context.sealer.header(request.seal);
    // Throws access_denied for a seal of another install or workspace.
    await context.sealer.open(
      request.seal,
      provider: header.provider,
      binding: caller.binding(request.workspaceId),
    );
    if (!await context.bindings.retireInstall(caller.installId)) {
      context.log.event('install.retire_refused', {
        'reason': 'retired_set_full',
        'install': install,
      }, ConnectLogLevel.error);
      throw const ConnectException(
        ConnectErrorCode.providerUnavailable,
        reason: 'retired_set_full',
      );
    }
    context.log.event('install.retired', {'install': install});
    // The install cannot sign a retry from here on, so a failure is logged
    // rather than answered.
    try {
      for (final team in await context.bindings.slackTeamsOf(
        caller.installId,
      )) {
        if (await context.bindings.releaseSlack(
          team,
          installId: caller.installId,
        )) {
          context.log.event('slack.released', {
            'team': context.log.tag(team),
            'install': install,
            'reason': 'retired',
          });
        }
      }
    } on Exception {
      // BindingStoreUnavailable, or the transport under it.
      context.log.event('slack.release_failed', {
        'install': install,
        'reason': 'retired',
      }, ConnectLogLevel.error);
    }
    return const ConnectAck().toJson();
  }

  /// `GET /v1/config`.
  Future<Object?> _configRoute(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final current = await context.served.current();
    final verbatim = current.verbatim;
    if (verbatim != null) {
      return _Verbatim(verbatim);
    }
    return current.config.toJson();
  }

  /// Releases backends this service created.
  Future<void> close() async {
    if (_ownsState) {
      await context.state.close();
    }
    if (_ownsBindings) {
      await context.bindings.close();
    }
    if (_ownsHttp) {
      context.http.close();
    }
  }
}

final class _Verbatim {
  const _Verbatim(this.bytes);

  final List<int> bytes;
}

/// A running standalone Connect.
final class ConnectServerHandle {
  ConnectServerHandle._(this._server, this.service);

  final HttpServer _server;

  /// The service.
  final ConnectService service;

  /// The bound port.
  int get port => _server.port;

  /// Stops accepting, then releases the service.
  Future<void> close() async {
    await _server.close(force: true);
    await service.close();
  }
}

/// Binds [service] to [host]:[port].
Future<ConnectServerHandle> serveConnect(
  ConnectService service, {
  required String host,
  required int port,
}) async {
  final server = await HttpServer.bind(host, port, shared: false);
  server
    ..idleTimeout = const Duration(seconds: 60)
    ..serverHeader = null
    ..autoCompress = false;
  // dart:io's defaults include X-Frame-Options and X-XSS-Protection; Connect
  // sets its own security headers per response.
  server.defaultResponseHeaders.clear();
  server.listen((request) => unawaited(service.handle(request)));
  return ConnectServerHandle._(server, service);
}

/// [UpstreamHttp] that writes `upstream.failed` for every provider call that
/// fails (transport error or a non-2xx other than 404), with GitHub's
/// `x-github-request-id`, and tracks the shared GitHub App's OAuth token
/// budget: GitHub allows 2,000 token requests per App per hour, shared by
/// every server on a hosted App.
final class ObservedUpstream implements UpstreamHttp {
  /// Wraps [_inner].
  ObservedUpstream(this._inner, this._log, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final UpstreamHttp _inner;
  final ConnectLog _log;
  final DateTime Function() _clock;
  final Queue<DateTime> _tokenCalls = Queue();
  DateTime? _budgetLoggedAt;

  /// Token requests in the last hour above which `github.token_budget` is
  /// written at warn (and at error above [budgetError]).
  static const int budgetWarn = 1000;

  /// See [budgetWarn].
  static const int budgetError = 1800;

  static const Map<String, String> _names = {
    'github.com': 'github',
    'api.github.com': 'github_api',
    'oauth2.googleapis.com': 'google',
    'slack.com': 'slack',
    'api.klipy.com': 'klipy',
    'cloudkms.googleapis.com': 'kms',
    'firestore.googleapis.com': 'firestore',
    'metadata.google.internal': 'metadata',
  };

  static final RegExp _githubRequestId = RegExp(r'^[A-Fa-f0-9:]{1,64}$');

  /// The `x-github-request-id` of [response] when it is shaped like one.
  static String? githubRequestId(UpstreamResponse response) {
    final id = response.headers['x-github-request-id'];
    return id != null && _githubRequestId.hasMatch(id) ? id : null;
  }

  static bool _isTokenCall(UpstreamRequest request) {
    final url = request.url;
    return request.method == 'POST' &&
        (url.host == 'github.com' && url.path == '/login/oauth/access_token' ||
            url.host == 'api.github.com' &&
                url.path.startsWith('/applications/') &&
                url.path.endsWith('/token/scoped'));
  }

  void _countTokenCall() {
    final now = _clock();
    _tokenCalls.add(now);
    final hourAgo = now.subtract(const Duration(hours: 1));
    while (_tokenCalls.isNotEmpty && !_tokenCalls.first.isAfter(hourAgo)) {
      _tokenCalls.removeFirst();
    }
    final count = _tokenCalls.length;
    final last = _budgetLoggedAt;
    if (count > budgetWarn &&
        (last == null || now.difference(last) >= const Duration(minutes: 10))) {
      _budgetLoggedAt = now;
      _log.event('github.token_budget', {
        'count': count,
      }, count > budgetError ? ConnectLogLevel.error : ConnectLogLevel.warn);
    }
  }

  @override
  Future<UpstreamResponse> send(UpstreamRequest request) async {
    final name = _names[request.url.host];
    if (_isTokenCall(request)) {
      _countTokenCall();
    }
    final UpstreamResponse response;
    try {
      response = await _inner.send(request);
    } on UpstreamUnavailable catch (error) {
      if (name != null) {
        _log.event('upstream.failed', {
          'upstream': name,
          'reason': error.reason.replaceAll(' ', '_'),
        }, ConnectLogLevel.warn);
      }
      rethrow;
    }
    if (name != null && !response.ok && response.status != 404) {
      _log.event('upstream.failed', {
        'upstream': name,
        'upstream_status': response.status,
        'github_request_id': githubRequestId(response),
      }, response.isTransient ? ConnectLogLevel.warn : ConnectLogLevel.info);
    }
    return response;
  }

  @override
  void close() => _inner.close();
}

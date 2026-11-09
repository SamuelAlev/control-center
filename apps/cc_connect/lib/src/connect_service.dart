import 'dart:async';
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
import 'package:cc_connect/src/rate_limiter.dart';
import 'package:cc_connect/src/redis_state_store.dart';
import 'package:cc_connect/src/relay_routes.dart';
import 'package:cc_connect/src/seal_cipher.dart';
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
       ) {
    _oauth = OAuthRoutes(context, _grants);
  }

  /// Builds a service from [config]. Backends default to what the config
  /// names (memory / Redis state, file / Firestore bindings, local / KMS
  /// seals) over a real [IoUpstreamHttp]; tests inject their own.
  ///
  /// Throws [ConnectConfigException] when the signed config does not match
  /// the credentials, or a backend cannot be reached at boot.
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
    final now = clock ?? DateTime.now;
    final http = upstream ?? IoUpstreamHttp();
    final hmacKey = config.logHmacKey?.value ?? '';
    final log = ConnectLog(
      sink: logSink,
      hmacKey: hmacKey.isEmpty ? null : utf8.encode(hmacKey),
      clock: now,
    );
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
        sealCipher = LocalAeadSealCipher(config.sealKeys!);
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
      stateStore = MemoryStateStore(clock: now);
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
        bindingStore = await FileBindingStore.open(config.dataDir, clock: now);
      } on FileSystemException {
        throw const ConnectConfigException('CONNECT_DATA_DIR is not writable');
      } on BindingStoreUnavailable catch (error) {
        throw ConnectConfigException('CONNECT_DATA_DIR: ${error.reason}');
      }
    }

    final served = ServedConfig(
      config,
      bootTime: now().toUtc(),
      log: log,
      clock: now,
    );
    await served.load();

    final context = ConnectContext(
      config: config,
      state: stateStore,
      bindings: bindingStore,
      sealer: CredentialSealer(
        connectOrigin: config.publicBaseUrl,
        cipher: sealCipher,
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
  static Future<void> _probeCipher(SealCipher cipher, SealBackend backend) async {
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
            path == '/healthz'
        ? path
        : null;
  }

  String _clientIp(HttpRequest request) {
    final hops = _config.trustProxyHops;
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
  Future<void> handle(HttpRequest request) async {
    final started = DateTime.now();
    final response = request.response;
    var route = 'unknown';
    try {
      applyBaseHeaders(response);
      final path = _relative(request.uri.path);
      if (path == null) {
        return await _notFound(response);
      }
      route = _routeLabel(path);
      if (!_globalLimiter.tryTake('*')) {
        return await sendError(response, ConnectErrorCode.rateLimited);
      }
      await _dispatch(request, path);
    } on Object catch (error) {
      await _fail(response, error, route);
    } finally {
      context.log.event('http.request', {
        'route': route,
        'method': request.method,
        'status': response.statusCode,
        'ms': DateTime.now().difference(started).inMilliseconds,
      });
    }
  }

  Future<void> _fail(HttpResponse response, Object error, String route) async {
    final code = switch (error) {
      ConnectException(:final code) => code,
      StateStoreUnavailable() ||
      BindingStoreUnavailable() ||
      UpstreamUnavailable() => ConnectErrorCode.providerUnavailable,
      _ => null,
    };
    if (code == null) {
      context.log.event('http.internal_error', {'route': route});
    }
    try {
      await sendError(response, code ?? ConnectErrorCode.providerUnavailable);
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

  Future<void> _dispatch(HttpRequest request, String path) async {
    final method = request.method;
    final response = request.response;
    final segments = path.split('/').skip(1).toList();

    if (path == '/healthz') {
      return method == 'GET'
          ? sendJson(response, 200, {'ok': true})
          : _methodNotAllowed(response);
    }
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
    // Slack's own servers: signed by Slack, exempt from the per-IP budget.
    if (path == '/v1/hooks/slack/events' ||
        path == '/v1/hooks/slack/commands') {
      if (method != 'POST') {
        return _methodNotAllowed(response);
      }
      return path.endsWith('events')
          ? _relay.slackEvents(request)
          : _relay.slackCommands(request);
    }

    if (!_ipLimiter.tryTake(_clientIp(request))) {
      return sendError(response, ConnectErrorCode.rateLimited);
    }

    // Browser routes.
    if (segments.length == 3 && segments[0] == 'oauth') {
      if (method != 'GET') {
        return _methodNotAllowed(response);
      }
      final segment = segments[1];
      final step = segments[2];
      if (segment == 'github' && step == 'setup') {
        return _oauth.githubSetup(request);
      }
      if (step == 'callback' &&
          const {
            'github',
            'google',
            'linear',
            'linear_app',
            'slack_oidc',
            'slack',
          }.contains(segment)) {
        return _oauth.callback(request, segment);
      }
      final lane = ConnectOAuthLane.fromWire(segment);
      if (step == 'done' && lane != null) {
        return _oauth.done(request, lane);
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
    return _signed(request, path, handler.$2);
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
        return ('POST', _grants.refreshGitHub);
      case 'google/refresh':
        return ('POST', _grants.refreshGoogle);
      case 'slack/refresh':
        return ('POST', _grants.refreshSlack);
      case 'github/scope':
        return ('POST', _grants.githubScope);
      case 'github/install/start':
        return ('POST', _grants.githubInstallStart);
      case 'github/installations':
        return ('POST', _grants.githubInstallations);
      case 'github/authorize_server':
        return ('POST', _grants.githubAuthorizeServer);
      case 'github/revoke':
        return ('POST', _grants.githubRevoke);
      case 'slack/revoke':
        return ('POST', _grants.slackRevoke);
      case 'events/poll':
        return ('POST', _relay.poll);
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
    if (s.length == 4 &&
        s[1] == 'chat' &&
        s[3] == 'act' &&
        RegExp(r'^[a-z]{1,32}$').hasMatch(s[2])) {
      return ('POST', _relay.chatAct);
    }
    return null;
  }

  /// RFC 9421 verification, nonce replay cache, allow/deny list and the
  /// per-install budget, then [handler].
  Future<void> _signed(
    HttpRequest request,
    String path,
    _SignedHandler handler,
  ) async {
    final response = request.response;
    final body = await readCappedBody(request, connectMaxRequestBytes);
    if (body == null) {
      response.persistentConnection = false;
      return sendError(response, ConnectErrorCode.invalidRequest);
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
      return sendError(
        response,
        error.failure == ConnectSignatureFailure.stale
            ? ConnectErrorCode.staleRequest
            : ConnectErrorCode.accessDenied,
      );
    }
    if (verified == null) {
      return sendError(response, ConnectErrorCode.rateLimited);
    }
    // The allow/deny list runs before the nonce write so a blocked install
    // cannot fill the replay cache.
    if (!_config.access.permits(verified.installId)) {
      context.log.event('install.blocked', {
        'install': context.log.tag(verified.installId),
      });
      return sendError(response, ConnectErrorCode.installBlocked);
    }
    if (!await context.state.putIfAbsent(
      'nonce:${verified.installId}:${verified.nonce}',
      '1',
      nonceTtl,
    )) {
      return sendError(response, ConnectErrorCode.staleRequest);
    }
    if (!_installLimiter.tryTake(verified.installId)) {
      return sendError(response, ConnectErrorCode.rateLimited);
    }
    final json = body.isEmpty
        ? const <String, Object?>{}
        : decodeJsonObject(body);
    final caller = ConnectCaller(installId: verified.installId);
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

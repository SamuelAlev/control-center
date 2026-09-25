part of 'local_rpc_server.dart';

extension _AuthMethods on LocalRpcServer {
  Future<void> _serveInviteRedeem(HttpRequest request) async {
    final res = request.response;
    final redeem = inviteRedeemer;
    if (redeem == null) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    // CORS, for the same reason `/healthz` has it: the WEB client redeems its
    // invite cross-origin, before any WebSocket exists. A wildcard origin is
    // safe here on the same grounds — no cookies, no ambient credentials, and
    // the invite code in the BODY is the only thing that authorizes anything.
    //
    // Without this the browser's preflight (the client sends
    // `Content-Type: application/json`, which is not a simple request) hit a
    // bare 405 with no CORS headers, so cross-origin pairing by invite could
    // never work at all — a pre-existing bug, not a demo-specific one.
    res.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type')
      ..set('Access-Control-Max-Age', '86400');
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    if (request.method != 'POST') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    // Fields don't promote; take a local for the null check.
    final pairingGate = manualPairingEnabled;
    if (pairingGate != null && !await pairingGate()) {
      // SSO-only posture: an invite code is a manual-pairing admission.
      res
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'error':
                'Manual pairing is disabled on this server — join '
                'through single sign-on instead',
          }),
        );
      await res.close();
      return;
    }
    // Pre-auth: bound both the attempt rate and the body. 20/min per IP is far
    // above a human redeeming an invite and far below brute-force throughput.
    final ip = _clientAddressOf(request);
    if (!_admitInWindow(_inviteRate, ip, 20)) {
      res
        ..statusCode = 429
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'rate limited'}));
      await res.close();
      return;
    }
    try {
      // An invite payload is a few hundred bytes; the unbounded
      // `utf8.decoder.bind(request).join()` this replaces would buffer
      // whatever an unauthenticated caller chose to send.
      const maxBodyBytes = 64 * 1024;
      final chunks = <int>[];
      await for (final chunk in request) {
        chunks.addAll(chunk);
        if (chunks.length > maxBodyBytes) {
          res.statusCode = HttpStatus.requestEntityTooLarge;
          await res.close();
          return;
        }
      }
      final body = utf8.decode(chunks, allowMalformed: true);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('body must be a JSON object');
      }
      final result = await redeem(decoded, remoteIp: ip);
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..headers.set('Cache-Control', 'no-store')
        ..write(jsonEncode(result));
    } on RedeemCapacityException catch (e) {
      // "We are full" is not "your code is wrong". Answering 403 here told a
      // visitor their link was broken and sent them away for good.
      _w('invite redemption refused (capacity): ${e.message}');
      res
        ..statusCode = HttpStatus.serviceUnavailable
        ..headers.contentType = ContentType.json
        ..headers.set('Retry-After', '120')
        ..write(jsonEncode({'error': e.message}));
    } catch (e) {
      _w('invite redemption failed: $e');
      res
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Invite is invalid or expired'}));
    }
    await res.close();
  }

  Future<void> _serveOpenLink(HttpRequest request) async {
    final res = request.response;
    if (request.method != 'GET' && request.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    // ['open', 'workspaces', <ws>, <kind>, <id>]
    final segments = request.uri.pathSegments;
    const kinds = {'spaces', 'tickets'};
    final valid =
        segments.length == 5 &&
        segments[1] == 'workspaces' &&
        kinds.contains(segments[3]) &&
        ChatDeepLinks.isSafeId(segments[2]) &&
        ChatDeepLinks.isSafeId(segments[4]);
    if (!valid) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    final target =
        'control-center://workspaces/${segments[2]}/${segments[3]}/'
        '${segments[4]}';
    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..headers.set('Cache-Control', 'no-store')
      ..headers.set('X-Frame-Options', 'DENY')
      ..headers.set('Referrer-Policy', 'no-referrer')
      ..write(_openLinkPage(target));
    await res.close();
  }

  static String _jsonForScript(Object? value) => jsonEncode(value)
      .replaceAll('<', '\\u003c')
      .replaceAll('>', '\\u003e')
      .replaceAll('&', '\\u0026');

  static String _openLinkPage(String target) => browserHandoffPage(
    title: 'Opening Control Center…',
    body:
        'If nothing happened, Control Center may not be running on this machine.',
    statusLabel: '',
    ctaLabel: 'Open Control Center',
    ctaHref: target,
    extraBody: '<script>location.replace(${_jsonForScript(target)});</script>',
  );

  static String _ssoPopupCompletePage(
    String serverOrigin,
    String deviceId,
    String psk,
    String targetOrigin,
  ) {
    final target = targetOrigin.replaceAll(RegExp('/+\$'), '');
    return browserHandoffPage(
      title: 'Signed in',
      body: 'You can close this tab and return to Control Center.',
      extraBody:
          '''
<script>
(() => {
  const target = ${_jsonForScript(target)};
  try {
    window.opener.postMessage({
      type: 'cc-sso-pair',
      server: ${_jsonForScript(serverOrigin)},
      deviceId: ${_jsonForScript(deviceId)},
      psk: ${_jsonForScript(psk)},
    }, target);
  } catch (_) {
    // The opener is gone (tab closed / navigation raced): the message is
    // one-shot; nothing to clean up.
  }
  setTimeout(() => window.close(), 1000);
})();
</script>
''',
    );
  }

  Future<void> _serveOidcLogin(HttpRequest request) async {
    final res = request.response;
    final sso = oidc;
    if (sso == null || !sso.config.enabled) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    if (request.method != 'GET' && request.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    try {
      final authorizationUrl = await sso.beginLogin(
        redirectUri: _oidcRedirectUri(request),
        relay: request.uri.queryParameters['relay'] ?? '',
        clientOrigin: request.uri.queryParameters['client_origin'],
      );
      res
        ..statusCode = HttpStatus.found
        ..headers.set('Location', authorizationUrl.toString())
        ..headers.set('Cache-Control', 'no-store');
    } catch (e) {
      _w('OIDC login start failed: $e');
      res.statusCode = HttpStatus.badGateway;
    }
    await res.close();
  }

  Future<void> _serveOidcCallback(HttpRequest request) async {
    final res = request.response;
    final sso = oidc;
    if (sso == null || !sso.config.enabled) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    if (request.method != 'GET') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    try {
      final result = await sso.handleCallback(
        requestUri: request.uri,
        redirectUri: _oidcRedirectUri(request),
      );
      final state = request.uri.queryParameters['state'] ?? '';
      await _ssoHandoff(
        request,
        deviceId: result.deviceId,
        psk: result.psk,
        relayState: state.startsWith('p.')
            ? 'web-popup'
            : state.startsWith('d.')
            ? 'desktop'
            : null,
        clientOrigin: result.clientOrigin,
      );
    } catch (e) {
      _w('OIDC callback failed: $e');
      final state = request.uri.queryParameters['state'] ?? '';
      await _writeSignInFailed(
        res,
        retryUrl: _ssoRetryUrl(
          request,
          kind: 'oidc',
          relay: state.startsWith('p.')
              ? 'web-popup'
              : state.startsWith('d.')
              ? 'desktop'
              : null,
        ),
      );
    }
  }

  Uri _oidcRedirectUri(HttpRequest request) =>
      Uri.parse('${_requestOrigin(request)}/oidc/callback');

  Future<void> _serveProviderOAuthCallback(HttpRequest request) async {
    final res = request.response;
    final oauth = providerOAuth;
    final segments = request.uri.pathSegments;
    if (oauth == null ||
        segments.length != 3 ||
        segments.first != 'oauth' ||
        segments.last != 'callback') {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    if (request.method != 'GET') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    try {
      final result = await oauth.handleCallback(
        requestUri: request.uri,
        redirectUri: providerOAuthRedirectUri(
          _requestOrigin(request),
          segments[1],
        ),
      );
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..headers.set('Cache-Control', 'no-store')
        ..write(
          _providerOAuthPage(
            title: 'Signed in',
            body: result.account.isEmpty
                ? 'You can close this tab and return to Control Center.'
                : 'Signed in as ${result.account}. You can close this tab '
                      'and return to Control Center.',
          ),
        );
    } catch (e) {
      _w('Provider sign-in failed: $e');
      res
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.html
        ..headers.set('Cache-Control', 'no-store')
        ..write(
          _providerOAuthPage(
            title: 'Sign-in failed',
            body: e is AuthException ? e.message : 'Something went wrong.',
            ok: false,
          ),
        );
    }
    await res.close();
  }

  static String _providerOAuthPage({
    required String title,
    required String body,
    bool ok = true,
  }) => browserHandoffPage(title: title, body: body, ok: ok);

  /// Sign-in failure page. [retryUrl] is the login start for this same
  /// attempt, so the tab itself has a button instead of only "close and
  /// try again" with nowhere to go.
  Future<void> _writeSignInFailed(
    HttpResponse res, {
    String? retryUrl,
  }) async {
    res
      ..statusCode = HttpStatus.forbidden
      ..headers.contentType = ContentType.html
      ..headers.set('Cache-Control', 'no-store')
      ..write(
        browserHandoffPage(
          title: 'Sign-in failed',
          body: retryUrl == null
              ? 'Close this tab and try again.'
              : 'Sign-in did not finish. You can try again.',
          ok: false,
          ctaLabel: retryUrl == null ? null : 'Try again',
          ctaHref: retryUrl,
        ),
      );
    await res.close();
  }

  /// Login URL that restarts [kind] (`oidc` or `saml`) with the same relay
  /// the failed attempt used. Null when the relay is not one we started.
  String? _ssoRetryUrl(
    HttpRequest request, {
    required String kind,
    required String? relay,
  }) {
    if (relay != 'web-popup' && relay != 'desktop') {
      return null;
    }
    final origin = _requestOrigin(request);
    final path = kind == 'saml' ? '/saml/login' : '/oidc/login';
    final clientOrigin = request.uri.queryParameters['client_origin'];
    final base = '$origin$path?relay=$relay';
    if (clientOrigin == null || clientOrigin.isEmpty) {
      return base;
    }
    return '$base&client_origin=${Uri.encodeComponent(clientOrigin)}';
  }

  Future<void> _serveSamlLogin(HttpRequest request) async {
    final res = request.response;
    final sso = saml;
    if (sso == null || !sso.config.enabled) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    if (request.method != 'GET' && request.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    try {
      final relay = request.uri.queryParameters['relay'];
      final redirect = sso.beginLogin(
        origin: _requestOrigin(request),
        relayState: (relay == null || relay.isEmpty) ? null : relay,
        clientOrigin: request.uri.queryParameters['client_origin'],
      );
      res
        ..statusCode = HttpStatus.found
        ..headers.set('Location', redirect.toString())
        ..headers.set('Cache-Control', 'no-store');
    } catch (e) {
      _w('SAML login start failed: $e');
      res.statusCode = HttpStatus.badGateway;
    }
    await res.close();
  }

  Future<void> _serveSamlAcs(HttpRequest request) async {
    final res = request.response;
    final sso = saml;
    if (sso == null || !sso.config.enabled) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    if (request.method != 'POST') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    String? relay;
    try {
      const maxBodyBytes = 256 * 1024;
      final chunks = <int>[];
      await for (final chunk in request) {
        chunks.addAll(chunk);
        if (chunks.length > maxBodyBytes) {
          res.statusCode = HttpStatus.requestEntityTooLarge;
          await res.close();
          return;
        }
      }
      final fields = Uri.splitQueryString(
        utf8.decode(chunks, allowMalformed: true),
      );
      relay = fields['RelayState'];
      final encoded = fields['SAMLResponse'];
      if (encoded == null || encoded.isEmpty) {
        throw const FormatException('no SAMLResponse field');
      }
      final responseXml = utf8.decode(base64.decode(encoded));
      final result = await sso.handleAcs(
        origin: _requestOrigin(request),
        responseXml: responseXml,
      );
      await _ssoHandoff(
        request,
        deviceId: result.deviceId,
        psk: result.psk,
        relayState: fields['RelayState'],
        clientOrigin: result.clientOrigin,
      );
    } catch (e) {
      _w('SAML ACS failed: $e');
      await _writeSignInFailed(
        res,
        retryUrl: _ssoRetryUrl(request, kind: 'saml', relay: relay),
      );
    }
  }

  Future<void> _serveSamlMetadata(HttpRequest request) async {
    final res = request.response;
    final sso = saml;
    if (sso == null || !sso.config.enabled) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    if (request.method != 'GET' && request.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    try {
      final xml = sso.spMetadataXml(origin: _requestOrigin(request));
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('application', 'xml')
        ..headers.set('Cache-Control', 'no-store')
        ..write(xml);
    } catch (e) {
      _w('SAML metadata emit failed: $e');
      res.statusCode = HttpStatus.badGateway;
    }
    await res.close();
  }

  Future<void> _serveAuthProviders(HttpRequest request) async {
    final res = request.response;
    res.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    if (request.method != 'GET' && request.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    final snapshot = await authProviders?.call();
    if (snapshot == null) {
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..headers.set('Cache-Control', 'no-store')
        ..write(jsonEncode({'providers': const [], 'pairingEnabled': true}));
      await res.close();
      return;
    }
    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.set('Cache-Control', 'no-store')
      ..write(jsonEncode(snapshot));
    await res.close();
  }

  Future<void> _serveScim(HttpRequest request) async {
    final res = request.response;
    final service = scim;
    if (service == null) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    final ip = request.connectionInfo?.remoteAddress.address ?? '?';
    if (!_admitInWindow(_scimRate, ip, 120)) {
      res
        ..statusCode = 429
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'rate limited'}));
      await res.close();
      return;
    }
    if (!await service.authorize(
      request.headers.value(HttpHeaders.authorizationHeader),
    )) {
      res
        ..statusCode = HttpStatus.unauthorized
        ..headers.set('WWW-Authenticate', 'Bearer realm="Control Center SCIM"')
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'schemas': ['urn:ietf:params:scim:api:messages:2.0:Error'],
            'status': '401',
            'detail':
                'A valid SCIM bearer token is required '
                '(generate one via sso.scimRegenerateToken)',
          }),
        );
      await res.close();
      return;
    }
    const maxBodyBytes = 256 * 1024;
    final chunks = <int>[];
    await for (final chunk in request) {
      chunks.addAll(chunk);
      if (chunks.length > maxBodyBytes) {
        res.statusCode = HttpStatus.requestEntityTooLarge;
        await res.close();
        return;
      }
    }
    final result = await service.handle(
      method: request.method,
      segments: request.uri.pathSegments,
      query: request.uri.queryParameters,
      body: chunks.isEmpty ? null : utf8.decode(chunks, allowMalformed: true),
    );
    res
      ..statusCode = result.status
      ..headers.contentType = ContentType.json
      ..headers.set('Cache-Control', 'no-store');
    if (result.status != 204) {
      res.write(jsonEncode(result.body));
    }
    await res.close();
  }

  String _clientAddressOf(HttpRequest request) {
    if (trustProxy) {
      final forwarded = request.headers.value('x-forwarded-for');
      if (forwarded != null && forwarded.trim().isNotEmpty) {
        final hops = forwarded
            .split(',')
            .map((h) => h.trim())
            .where((h) => h.isNotEmpty);
        if (hops.isNotEmpty) {
          return hops.last;
        }
      }
    }
    return request.connectionInfo?.remoteAddress.address ?? '?';
  }

  bool _admitInWindow(
    Map<String, (int, DateTime)> bucket,
    String ip,
    int maxPerMinute,
  ) {
    final now = DateTime.now();
    final entry = bucket[ip];
    if (entry == null ||
        now.difference(entry.$2) > const Duration(minutes: 1)) {
      bucket[ip] = (1, now);
      if (bucket.length > 1024) {
        bucket.removeWhere(
          (_, e) => now.difference(e.$2) > const Duration(minutes: 1),
        );
      }
      return true;
    }
    final count = entry.$1 + 1;
    bucket[ip] = (count, entry.$2);
    return count <= maxPerMinute;
  }

  Future<void> _ssoHandoff(
    HttpRequest request, {
    required String deviceId,
    required String psk,
    String? relayState,
    String? clientOrigin,
  }) async {
    final res = request.response;
    final origin = _requestOrigin(request);
    final fragment = base64Url
        .encode(utf8.encode(jsonEncode({'s': origin, 'i': deviceId, 'k': psk})))
        .replaceAll('=', '');
    if (relayState == 'desktop') {
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..headers.set('Cache-Control', 'no-store')
        ..headers.set('X-Frame-Options', 'DENY')
        ..headers.set('Referrer-Policy', 'no-referrer')
        ..write(_openLinkPage('control-center://pair#$fragment'));
      await res.close();
      return;
    }
    if (relayState == 'web-popup') {
      final pinned = webClientUrl?.trim();
      final target =
          (clientOrigin != null &&
              clientOrigin.isNotEmpty &&
              _originAllowed(clientOrigin))
          ? clientOrigin
          : (pinned == null || pinned.isEmpty)
          ? origin
          : pinned;
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..headers.set('Cache-Control', 'no-store')
        ..headers.set('X-Frame-Options', 'DENY')
        ..headers.set('Referrer-Policy', 'no-referrer')
        ..write(_ssoPopupCompletePage(origin, deviceId, psk, target));
      await res.close();
      return;
    }
    final base = webClientUrl?.trim();
    final target = (base == null || base.isEmpty)
        ? '/#$fragment'
        : '${base.replaceAll(RegExp('/+\$'), '')}/#$fragment';
    res
      ..statusCode = HttpStatus.found
      ..headers.set('Location', target)
      ..headers.set('Cache-Control', 'no-store');
    await res.close();
  }

  String _requestOrigin(HttpRequest request) {
    final scheme = securityContext != null ? 'https' : 'http';
    final host =
        request.headers.value('host') ?? 'localhost:${_server?.port ?? port}';
    return '$scheme://$host';
  }
}

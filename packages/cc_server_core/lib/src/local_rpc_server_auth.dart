part of 'local_rpc_server.dart';

extension _AuthMethods on LocalRpcServer {
  /// Invite codes are high-entropy one-use Noise PSKs. The public hello carries
  /// only a second digest; even a terminating TLS proxy cannot derive the
  /// stored invite hash or read the newly minted paired-device credential.
  Future<void> _serveSecureInvite(WebSocket socket, String remoteIp) async {
    final resolver = invitePskResolver;
    final redeem = inviteRedeemer;
    final serverIdentity = identity;
    final raw = WsRemoteTransport(socket, label: remoteIp)..start();
    if (resolver == null ||
        redeem == null ||
        serverIdentity == null ||
        (manualPairingEnabled != null && !await manualPairingEnabled!()) ||
        !_admitInWindow(_inviteRate, remoteIp, 20)) {
      await raw.close();
      return;
    }
    SecureChannelConnection? session;
    try {
      session = await acceptSecureChannel(
        channel: raw,
        readPsk: (id) async {
          if (!id.startsWith('invite:')) {
            return null;
          }
          return resolver(id.substring('invite:'.length));
        },
        serverPublicKey: serverIdentity.publicKeyB64,
        signIdentity: serverIdentity.signChallenge,
      );
      final routeId = session.deviceId.substring('invite:'.length);
      final request = await session.channel.incoming.first.timeout(
        const Duration(seconds: 15),
      );
      final code = request['code'];
      if (request['type'] != 'invite_redeem' ||
          code is! String ||
          InvitePairingProof.routeIdFromHash(
                InvitePairingProof.codeHash(code),
              ) !=
              routeId ||
          await resolver(routeId) == null) {
        throw const FormatException('Invite rejected');
      }
      final result = await redeem({
        'code': code,
        'platform': request['platform'],
        'device_label': request['device_label'],
      }, remoteIp: remoteIp);
      await session.channel.send({'type': 'invite_redeemed', 'result': result});
    } catch (_) {
      // Never reveal whether a route, code, expiry, or concurrency check failed.
      try {
        await session?.channel.send(const {'type': 'invite_denied'});
      } catch (_) {}
    } finally {
      await (session?.channel ?? raw).close();
    }
  }

  Future<void> _serveInviteRedeem(HttpRequest request) async {
    final res = request.response;
    final redeem = inviteRedeemer;
    if (redeem == null) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    // Real workspace invites must authenticate the secure channel with the
    // out-of-band code. The old JSON POST cannot issue device credentials.
    if (!isDemo) {
      res.statusCode = HttpStatus.upgradeRequired;
      await res.close();
      return;
    }
    // The public demo's invite is a low-entropy admission label, not a Noise
    // PSK. The first-party web origin is its trust root. A client-held
    // recipient keeps minted credentials out of readable HTTP responses.
    // CORS is intentionally open: there are no ambient user credentials.
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
      final recipient = decoded['handoff_key'];
      if (recipient is! String || !CredentialSeal.isValidPublicKey(recipient)) {
        throw const FormatException('Missing credential recipient');
      }
      final result = await redeem(decoded, remoteIp: ip);
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..headers.set('Cache-Control', 'no-store')
        ..write(
          jsonEncode({
            'box': await CredentialSeal.seal(
              recipientPublicKey: recipient,
              credential: result,
              context: 'cc-public-demo-v1',
            ),
          }),
        );
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
    Map<String, String> envelope,
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
      envelope: ${_jsonForScript(envelope)},
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
      final recipientKey = request.uri.queryParameters['handoff_key'];
      if (!CredentialSeal.isValidPublicKey(recipientKey)) {
        throw const FormatException('Invalid credential recipient');
      }
      final authorizationUrl = await sso.beginLogin(
        redirectUri: _oidcRedirectUri(request),
        relay: request.uri.queryParameters['relay'] ?? '',
        clientOrigin: request.uri.queryParameters['client_origin'],
        recipientPublicKey: recipientKey,
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
        recipientPublicKey: result.recipientPublicKey,
        relayState: state.startsWith('p.')
            ? 'web-popup'
            : state.startsWith('d.')
            ? 'desktop'
            : null,
        clientOrigin: result.clientOrigin,
      );
    } catch (e) {
      _w('OIDC callback failed: $e');
      await _writeSignInFailed(res);
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

  /// A retry must begin in the app with a fresh client-held encryption key.
  Future<void> _writeSignInFailed(HttpResponse res) async {
    res
      ..statusCode = HttpStatus.forbidden
      ..headers.contentType = ContentType.html
      ..headers.set('Cache-Control', 'no-store')
      ..write(
        browserHandoffPage(
          title: 'Sign-in failed',
          body: 'Close this tab and try again from Control Center.',
          ok: false,
        ),
      );
    await res.close();
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
      final recipientKey = request.uri.queryParameters['handoff_key'];
      if (!CredentialSeal.isValidPublicKey(recipientKey)) {
        throw const FormatException('Invalid credential recipient');
      }
      final relay = request.uri.queryParameters['relay'];
      final redirect = sso.beginLogin(
        origin: _requestOrigin(request),
        relayState: (relay == null || relay.isEmpty) ? null : relay,
        clientOrigin: request.uri.queryParameters['client_origin'],
        recipientPublicKey: recipientKey,
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
    if (!_admitInWindow(_samlAcsRate, _clientAddressOf(request), 30)) {
      res.statusCode = HttpStatus.tooManyRequests;
      await res.close();
      return;
    }
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
      final encoded = fields['SAMLResponse'];
      if (encoded == null || encoded.isEmpty) {
        throw const FormatException('no SAMLResponse field');
      }
      final responseXml = utf8.decode(base64.decode(encoded));
      final outcome = await sso.handleBrowserAcs(
        origin: _requestOrigin(request),
        responseXml: responseXml,
      );
      if (outcome.login case final result?) {
        await _ssoHandoff(
          request,
          deviceId: result.deviceId,
          psk: result.psk,
          recipientPublicKey: result.recipientPublicKey,
          relayState: fields['RelayState'],
          clientOrigin: result.clientOrigin,
        );
      } else {
        final origin = _requestOrigin(request);
        res.cookies.add(
          Cookie('cc_saml_grant', outcome.cookie!)
            ..httpOnly = true
            ..sameSite = SameSite.strict
            ..secure = Uri.parse(origin).scheme == 'https'
            ..path = '/saml/claim'
            ..maxAge = 300,
        );
        res
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..headers.set('Cache-Control', 'no-store')
          ..headers.set('X-Frame-Options', 'DENY')
          ..headers.set('Referrer-Policy', 'no-referrer')
          ..headers.set(
            'Content-Security-Policy',
            "default-src 'none'; script-src 'unsafe-inline'; "
                "style-src 'unsafe-inline'; connect-src 'self'; "
                "base-uri 'none'; form-action 'none'",
          )
          ..write(_samlGrantPage(origin, outcome.handle!));
        await res.close();
      }
    } catch (e) {
      _w('SAML ACS failed: $e');
      await _writeSignInFailed(res);
    }
  }

  static final _samlAcsRate = <String, (int, DateTime)>{};

  static final _samlGrantRate = <String, (int, DateTime)>{};

  Future<void> _serveSamlGrantClaim(HttpRequest request) async {
    final res = request.response;
    final service = saml;
    if (service == null || !service.config.enabled) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    final origin = _requestOrigin(request);
    if (request.method != 'POST' ||
        request.headers.value('origin') != origin ||
        !_admitInWindow(_samlGrantRate, _clientAddressOf(request), 30)) {
      res.statusCode = HttpStatus.forbidden;
      await res.close();
      return;
    }
    var cookie = '';
    for (final entry in request.cookies) {
      if (entry.name == 'cc_saml_grant') {
        cookie = entry.value;
        break;
      }
    }
    try {
      final bytes = <int>[];
      await for (final chunk in request) {
        bytes.addAll(chunk);
        if (bytes.length > 4096) {
          throw const FormatException('Grant claim too large');
        }
      }
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, dynamic> ||
          value['handle'] is! String ||
          value['handoff_key'] is! String ||
          cookie.isEmpty) {
        throw const FormatException('Invalid grant claim');
      }
      final credential = await service.redeemBrowserGrant(
        handle: value['handle'] as String,
        cookie: cookie,
        recipientPublicKey: value['handoff_key'] as String,
      );
      final envelope = await CredentialSeal.seal(
        recipientPublicKey: value['handoff_key'] as String,
        credential: {
          's': origin,
          'i': credential.deviceId,
          'k': credential.psk,
        },
        context: origin,
      );
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..headers.set('Cache-Control', 'no-store')
        ..headers.set('X-Content-Type-Options', 'nosniff')
        ..write(jsonEncode({'box': envelope}));
    } catch (e) {
      _w('SAML grant claim denied: $e');
      res.statusCode = HttpStatus.forbidden;
    } finally {
      res.cookies.add(
        Cookie('cc_saml_grant', '')
          ..httpOnly = true
          ..sameSite = SameSite.strict
          ..secure = Uri.parse(origin).scheme == 'https'
          ..path = '/saml/claim'
          ..maxAge = 0,
      );
      await res.close();
    }
  }

  String _samlGrantPage(String origin, String handle) {
    final web = (webClientUrl?.trim().isNotEmpty ?? false)
        ? webClientUrl!.trim().replaceAll(RegExp('/+\$'), '')
        : origin;
    return browserHandoffPage(
      title: 'Sign-in verified',
      body:
          'Choose where to open Control Center. This sign-in expires in five minutes.',
      statusLabel: '',
      extraBody:
          '''
<p><button type="button" id="cc-web">Open web client</button>
<button type="button" id="cc-desktop">Open desktop app</button></p>
<p id="cc-error" role="alert"></p>
<script>
(() => {
  const origin = ${_jsonForScript(origin)};
  const handle = ${_jsonForScript(handle)};
  const web = ${_jsonForScript(web)};
  const buttons = [document.getElementById('cc-web'),
                   document.getElementById('cc-desktop')];
  const encode = bytes =>
    btoa(String.fromCharCode(...bytes)).replace(/=/g, '').replace(/\\+/g, '-').replace(/\\//g, '_');
  async function open(destination) {
    buttons.forEach(button => button.disabled = true);
    try {
      // WebCrypto generates this private key in the browser; it never crosses
      // the HTTP boundary. Only the public half is sent to the claim endpoint.
      const pair = await crypto.subtle.generateKey({name: 'X25519'}, true, ['deriveBits']);
      const publicKey = new Uint8Array(await crypto.subtle.exportKey('raw', pair.publicKey));
      const pkcs8 = new Uint8Array(await crypto.subtle.exportKey('pkcs8', pair.privateKey));
      const prefix = [0x30,0x2e,0x02,0x01,0x00,0x30,0x05,0x06,
                      0x03,0x2b,0x65,0x6e,0x04,0x22,0x04,0x20];
      if (pkcs8.length !== 48 || !prefix.every((byte, index) => pkcs8[index] === byte)) {
        throw Error('Unsupported browser key format');
      }
      const response = await fetch(origin + '/saml/claim', {
        method: 'POST',
        credentials: 'same-origin',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({handle, handoff_key: encode(publicKey)}),
      });
      if (!response.ok) throw Error('This sign-in expired. Please return to your identity provider.');
      const result = await response.json();
      if (!result.box) throw Error('Incomplete sign-in response');
      const fragment = encode(new TextEncoder().encode(JSON.stringify({
        s: origin, box: result.box,
        recipientPrivateKey: encode(pkcs8.slice(16)),
        idpInitiated: true,
      })));
      if (destination === 'desktop') {
        // Keep a working fallback if this browser has no native URL handler.
        const fallback = document.createElement('a');
        fallback.href = web + '/#' + fragment;
        fallback.textContent = 'Open web client instead';
        document.getElementById('cc-error').replaceChildren(fallback);
        location.href = 'control-center://pair#' + fragment;
      } else {
        location.replace(web + '/#' + fragment);
      }
    } catch (error) {
      document.getElementById('cc-error').textContent =
        error instanceof Error ? error.message : 'Sign-in failed.';
      buttons.forEach(button => button.disabled = false);
    }
  }
  buttons[0].onclick = () => open('web');
  buttons[1].onclick = () => open('desktop');
})();
</script>''',
    );
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
    required String? recipientPublicKey,
    String? relayState,
    String? clientOrigin,
  }) async {
    final res = request.response;
    if (!CredentialSeal.isValidPublicKey(recipientPublicKey)) {
      throw StateError('Missing credential recipient');
    }
    final origin = _requestOrigin(request);
    final envelope = await CredentialSeal.seal(
      recipientPublicKey: recipientPublicKey!,
      credential: {'s': origin, 'i': deviceId, 'k': psk},
      context: origin,
    );
    final fragment = base64Url
        .encode(utf8.encode(jsonEncode({'s': origin, 'box': envelope})))
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
        ..write(_ssoPopupCompletePage(origin, envelope, target));
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
    final forwardedScheme = trustProxy
        ? request.headers.value('x-forwarded-proto')?.split(',').last.trim()
        : null;
    final scheme = securityContext != null || forwardedScheme == 'https'
        ? 'https'
        : 'http';
    final host =
        request.headers.value('host') ?? 'localhost:${_server?.port ?? port}';
    return '$scheme://$host';
  }
}

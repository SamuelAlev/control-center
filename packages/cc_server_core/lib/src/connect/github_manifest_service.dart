import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_connect_core/cc_connect_core.dart' show constantTimeEquals;
import 'package:cc_domain/cc_domain.dart'
    show AuthException, ValidationException;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart'
    show gitHubRestApiVersion;
import 'package:cc_server_core/src/connect/bounded_body.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';

/// One "Create my GitHub App" attempt.
final class _ManifestTicket {
  _ManifestTicket({
    required this.ticket,
    required this.state,
    required this.nonce,
    required this.origin,
    required this.organization,
    required this.ownerAccountId,
    required this.expiresAt,
  });

  final String ticket;
  final String state;
  final String nonce;
  final String origin;
  final String organization;
  final int? ownerAccountId;
  final DateTime expiresAt;

  /// Set when the page is served: the browser that loaded it must be the
  /// one GitHub sends back.
  String? browserKey;
}

/// The outcome of a finished manifest flow.
typedef GitHubManifestResult = ({String slug, Uri installUrl});

/// The start page and the cookie that binds the attempt to the browser it
/// was served to.
typedef GitHubManifestPage = ({String html, String browserKey, bool secure});

/// Registers this server's own GitHub App in one click, straight with GitHub
/// (the conversion code never touches Connect).
///
/// 1. The server owner asks for a ticket ([begin]); the app gets a one-time
///    URL on this server.
/// 2. That page ([startPage]) auto-posts the manifest to GitHub. It can be
///    served once, and sets a cookie binding the attempt to that browser;
///    the ticket and its random state expire in ten minutes.
/// 3. GitHub redirects back with a code ([complete]) to the same browser;
///    the server converts it (`POST /app-manifests/{code}/conversions`),
///    checks the app's name carries this attempt's nonce and its owner is the
///    account asked for — the owner's own GitHub account by id when they are
///    signed in — and stores the app id, private key, client id and client
///    secret.
///
/// The origin in every URL is the server's configured public URL (or
/// loopback), never a `Host` header.
class GitHubManifestService {
  /// Creates the service.
  GitHubManifestService({
    required this.apps,
    HttpClient? httpClient,
    DateTime Function()? now,
    Random? random,
    Uri? apiBase,
  }) : _api = apiBase ?? Uri.https('api.github.com'),
       _http = httpClient ?? (HttpClient()..connectionTimeout = _timeout),
       _now = now ?? (() => DateTime.now().toUtc()),
       _random = random ?? Random.secure();

  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _ttl = Duration(minutes: 10);
  static const int _maxBody = 64 * 1024;
  static const int _maxPending = 16;

  /// The cookie [startPage]'s browser carries back to [callbackPath].
  static const String browserCookie = 'cc_gh_manifest';

  /// Where the new app's credentials go.
  final ProviderAppSettings apps;

  final Uri _api;
  final HttpClient _http;
  final DateTime Function() _now;
  final Random _random;
  final Map<String, _ManifestTicket> _byTicket = {};

  /// The path of the auto-post page.
  static const String startPath = '/oauth/github/manifest/start';

  /// The path GitHub redirects back to.
  static const String callbackPath = '/oauth/github/manifest/callback';

  /// Permissions the app asks for: exactly what the scoped-token table needs
  /// (`read`, `review`, `bot`, `write`) plus organization members for team
  /// review requests.
  static const Map<String, String> permissions = {
    'metadata': 'read',
    'contents': 'write',
    'pull_requests': 'write',
    'issues': 'write',
    'checks': 'read',
    'actions': 'read',
    'statuses': 'read',
    'members': 'read',
  };

  static String _appName(String nonce) => 'Control Center $nonce';

  static const List<String> _levels = ['read', 'write', 'admin'];

  /// Whether the created app holds a permission the manifest did not ask
  /// for, or a higher level of one: those are not what this server posted.
  /// An app holding less is accepted (it just does less); an answer that
  /// does not say what it holds is refused.
  static bool _exceedsRequested(Object? granted) {
    if (granted is! Map) {
      return true;
    }
    for (final MapEntry(:key, :value) in granted.entries) {
      final asked = permissions[key];
      if (asked == null) {
        return true;
      }
      final level = _levels.indexOf('$value');
      if (level < 0 || level > _levels.indexOf(asked)) {
        return true;
      }
    }
    return false;
  }

  String _token(int bytes) => base64Url
      .encode(List<int>.generate(bytes, (_) => _random.nextInt(256)))
      .replaceAll('=', '');

  void _sweep() {
    final now = _now();
    _byTicket.removeWhere((_, t) => !t.expiresAt.isAfter(now));
  }

  /// Starts an attempt and returns the one-time page to open in a browser.
  ///
  /// [origin] is this server's HTTP origin; an empty one means the server
  /// has no URL a browser could come back to. [organization] creates the
  /// app under that organization instead of the signed-in GitHub user.
  /// [ownerAccountId] is the requesting owner's GitHub account id when they
  /// are signed in: a personal app created under any other account is
  /// refused.
  Uri begin({
    required String origin,
    String organization = '',
    int? ownerAccountId,
  }) {
    if (origin.isEmpty) {
      throw const ValidationException(
        'This server has no address a browser can return to. Set its public '
        'URL first.',
      );
    }
    final org = organization.trim();
    if (org.isNotEmpty && !RegExp(r'^[A-Za-z0-9-]{1,39}$').hasMatch(org)) {
      throw const ValidationException('That is not a GitHub organization.');
    }
    _sweep();
    while (_byTicket.length >= _maxPending) {
      _byTicket.remove(_byTicket.keys.first);
    }
    final ticket = _ManifestTicket(
      ticket: _token(24),
      state: _token(24),
      // 64 bits, and still under GitHub's 34-character app name limit.
      nonce: List<String>.generate(
        16,
        (_) => _random.nextInt(16).toRadixString(16),
      ).join(),
      origin: origin,
      organization: org,
      ownerAccountId: ownerAccountId,
      expiresAt: _now().add(_ttl),
    );
    _byTicket[ticket.ticket] = ticket;
    return Uri.parse(
      '$origin$startPath',
    ).replace(queryParameters: {'ticket': ticket.ticket});
  }

  /// The auto-post page for [ticket] and the [browserCookie] value to set
  /// with it, or null when it is unknown, expired or already served.
  GitHubManifestPage? startPage(String ticket) {
    _sweep();
    final t = _byTicket[ticket];
    if (t == null || t.browserKey != null) {
      return null;
    }
    final browserKey = _token(32);
    t.browserKey = browserKey;
    final manifest = jsonEncode({
      'name': _appName(t.nonce),
      'url': t.origin,
      'redirect_url': '${t.origin}$callbackPath',
      'callback_urls': ['${t.origin}/oauth/github/callback'],
      'public': false,
      'request_oauth_on_install': false,
      'hook_attributes': {'url': '${t.origin}/', 'active': false},
      'default_permissions': permissions,
      'default_events': const <String>[],
    });
    final target = t.organization.isEmpty
        ? 'https://github.com/settings/apps/new'
        : 'https://github.com/organizations/${t.organization}/settings/apps/new';
    final action = Uri.parse(
      target,
    ).replace(queryParameters: {'state': t.state});
    const escape = HtmlEscape();
    final html =
        '<!doctype html><html lang="en"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        '<title>Create your GitHub App</title></head>'
        '<body style="font-family: system-ui, sans-serif; margin: 3rem;">'
        '<form id="m" method="post" action="${escape.convert(action.toString())}">'
        '<input type="hidden" name="manifest" '
        'value="${escape.convert(manifest)}">'
        '<p>Sending you to GitHub to create this server&#39;s app…</p>'
        '<noscript><button type="submit">Continue to GitHub</button>'
        '</noscript></form>'
        '<script>document.getElementById("m").submit();</script>'
        '</body></html>';
    return (
      html: html,
      browserKey: browserKey,
      secure: Uri.parse(t.origin).scheme == 'https',
    );
  }

  /// Finishes the flow GitHub redirected back with. [browserKey] is the
  /// [browserCookie] the redirected browser sent.
  Future<GitHubManifestResult> complete(
    Uri callback, {
    required String? browserKey,
  }) async {
    _sweep();
    final code = callback.queryParameters['code'] ?? '';
    final state = callback.queryParameters['state'] ?? '';
    _ManifestTicket? match;
    for (final t in _byTicket.values) {
      if (t.state == state && state.isNotEmpty) {
        match = t;
        break;
      }
    }
    final expected = match?.browserKey;
    if (match == null || expected == null) {
      throw _refused(
        'expired',
        'This GitHub App link expired. Start again from Settings.',
      );
    }
    if (browserKey == null || !constantTimeEquals(browserKey, expected)) {
      // Single use either way: a state carried to another browser is spent.
      _byTicket.remove(match.ticket);
      throw _refused(
        'other_browser',
        'Finish creating the app in the browser that started it. Start '
        'again from Settings.',
      );
    }
    // Single use, whatever happens next.
    _byTicket.remove(match.ticket);
    if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(code)) {
      throw _refused(
        'bad_code',
        'GitHub did not send a usable code.',
      );
    }
    final request = await _http.postUrl(
      _api.replace(path: '/app-manifests/$code/conversions'),
    );
    request.followRedirects = false;
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'control-center')
      ..set('X-GitHub-Api-Version', gitHubRestApiVersion);
    final response = await request.close().timeout(_timeout);
    final Object? json;
    try {
      final body = await readBoundedText(
        response,
        maxBytes: _maxBody,
        timeout: _timeout,
      );
      if (response.statusCode != 201) {
        throw _refused(
          'not_created',
          'GitHub did not create the app.',
        );
      }
      json = jsonDecode(body);
    } on HttpException {
      throw _refused(
        'unexpected_answer',
        'GitHub sent an unexpected answer.',
      );
    } on FormatException {
      throw _refused(
        'unexpected_answer',
        'GitHub sent an unexpected answer.',
      );
    }
    if (json is! Map) {
      throw _refused(
        'unexpected_answer',
        'GitHub sent an unexpected answer.',
      );
    }
    final id = json['id'];
    final slug = json['slug'];
    final name = json['name'];
    final clientId = json['client_id'];
    final clientSecret = json['client_secret'];
    final pem = json['pem'];
    final owner = json['owner'];
    if (id is! int ||
        slug is! String ||
        name is! String ||
        clientId is! String ||
        clientSecret is! String ||
        pem is! String ||
        owner is! Map) {
      throw _refused(
        'incomplete_app',
        'GitHub sent an incomplete app.',
      );
    }
    // The exact name this attempt's manifest posted: the nonce is in no
    // other attempt's manifest and is spent with this one.
    if (name != _appName(match.nonce) ||
        _exceedsRequested(json['permissions'])) {
      throw _refused(
        'not_this_manifest',
        'That app was not created from this server. Start again.',
      );
    }
    final ownerLogin = owner['login'];
    final ownerType = owner['type'];
    final wantOrg = match.organization.isNotEmpty;
    final ownerId = match.ownerAccountId;
    if (wantOrg
        ? ownerType != 'Organization' ||
              ownerLogin is! String ||
              ownerLogin.toLowerCase() != match.organization.toLowerCase()
        : ownerType != 'User' || (ownerId != null && owner['id'] != ownerId)) {
      throw _refused(
        'wrong_owner',
        'GitHub created the app under a different account than requested.',
      );
    }
    forgeAudit(ForgeAuditEvent.githubAppManifestCreated, {
      'app_id': id,
      'owner': ownerLogin is String ? ownerLogin : '',
      'owner_type': ownerType is String ? ownerType : '',
    });
    await apps.save(
      ProviderApp.github,
      appId: '$id',
      clientId: clientId,
      clientSecret: clientSecret,
      privateKeyPem: pem,
    );
    return (
      slug: slug,
      installUrl: Uri.https('github.com', '/apps/$slug/installations/new'),
    );
  }

  static AuthException _refused(String reason, String message) {
    forgeAudit(ForgeAuditEvent.githubAppManifestRefused, {'reason': reason});
    return AuthException(message);
  }
}

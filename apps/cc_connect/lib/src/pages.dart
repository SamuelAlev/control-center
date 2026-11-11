import 'dart:convert';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:crypto/crypto.dart' as crypto;

/// The one stylesheet every browser page uses, inline and pinned by hash in
/// the CSP so nothing else can style (or script) the page.
const String _style =
    'body{margin:0;min-height:100vh;display:flex;align-items:center;'
    'justify-content:center;font:16px/1.5 system-ui,-apple-system,"Segoe UI",'
    'sans-serif;background:#f6f4ef;color:#1f1d1a}'
    'main{max-width:30rem;padding:2rem 1.5rem;text-align:center}'
    'h1{font-size:1.4rem;margin:0 0 .75rem}'
    'p{margin:.5rem 0;color:#4a4640}'
    '.code{display:block;margin:1.5rem 0;font:600 2.2rem/1.2 ui-monospace,'
    'SFMono-Regular,Menlo,monospace;letter-spacing:.18em;color:#1f1d1a}'
    'a.button{display:inline-block;margin:1rem 0;padding:.7rem 1.4rem;'
    'border-radius:.5rem;background:#1f1d1a;color:#f6f4ef;text-decoration:none;'
    'font-weight:600}'
    'form{display:flex;gap:.75rem;justify-content:center;margin:1.5rem 0 0}'
    'button{font:inherit;font-weight:600;padding:.7rem 1.4rem;'
    'border-radius:.5rem;border:1px solid #1f1d1a;cursor:pointer;'
    'background:transparent;color:#1f1d1a}'
    'button.primary{background:#1f1d1a;color:#f6f4ef}'
    '.warn{font-weight:600;color:#1f1d1a}'
    '.fine{font-size:.85rem;color:#6b665e}'
    '@media (prefers-color-scheme:dark){body{background:#1a1916;color:#efece6}'
    'p{color:#c9c4ba}.code,.warn{color:#efece6}a.button{background:#efece6;'
    'color:#1a1916}button{border-color:#efece6;color:#efece6}'
    'button.primary{background:#efece6;color:#1a1916}.fine{color:#9c968b}}';

/// The CSP `style-src` source for [_style].
final String pageStyleHash =
    "'sha256-${base64.encode(crypto.sha256.convert(utf8.encode(_style)).bytes)}'";

/// The Content-Security-Policy every page carries.
final String pageContentSecurityPolicy =
    "default-src 'none'; style-src $pageStyleHash; frame-ancestors 'none'; "
    "base-uri 'none'; form-action 'none'";

/// The policy of the one page with a form (the consent page): the same, but
/// the form may post to Connect itself.
final String formPageContentSecurityPolicy =
    "default-src 'none'; style-src $pageStyleHash; frame-ancestors 'none'; "
    "base-uri 'none'; form-action 'self'";

/// A fixed message page. No query, provider or user string is ever
/// interpolated into one.
enum StaticPage {
  /// The state was unknown, expired or already used.
  expired(
    400,
    'This link has expired',
    'Start again from Control Center. Sign-in links work once and expire '
        'after ten minutes.',
  ),

  /// The provider reported an error or the person declined.
  declined(
    400,
    'Sign-in was not completed',
    'The provider did not approve the request. You can close this tab and '
        'try again from Control Center.',
  ),

  /// The Slack workspace is bound to another server.
  teamBoundElsewhere(
    409,
    'This Slack workspace is connected to another server',
    'Each Slack workspace connects to one Control Center server. Disconnect '
        'it from that server first, or ask a Slack admin to uninstall the app '
        'from the workspace.',
  ),

  /// The person cancelled at the consent page.
  cancelled(
    200,
    'Sign-in cancelled',
    'Connect threw this sign-in away. The provider\'s one-time code will never '
        'be exchanged, so the server that started it receives no token. You '
        'can close this tab.',
  ),

  /// The flow failed on Connect's side or the provider's.
  failed(
    503,
    'Something went wrong',
    'The provider could not be reached. You can close this tab and try again '
        'in a moment.',
  ),

  /// The GitHub App was installed.
  githubInstalled(
    200,
    'GitHub App installed',
    'Installing it consents for every Control Center server a member of this '
        'account signs in on: each such server can act as that member on the '
        'repositories the app is installed on. You can close this tab.',
  ),

  /// An organization install is waiting for an owner's approval.
  githubRequested(
    200,
    'Installation requested',
    'An organization owner has to approve the installation on GitHub. Once '
        'they do, members can use it from Control Center.',
  ),

  /// An existing installation's settings changed.
  githubUpdated(200, 'Installation updated', 'You can close this tab.');

  const StaticPage(this.status, this.title, this.body);

  /// The HTTP status.
  final int status;

  /// The heading.
  final String title;

  /// The explanation.
  final String body;
}

String _escape(String value) => const HtmlEscape().convert(value);

String _document(String title, String main) =>
    '<!doctype html><html lang="en"><head><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width,initial-scale=1">'
    '<meta name="referrer" content="no-referrer">'
    '<meta name="robots" content="noindex">'
    '<title>${_escape(title)} · Control Center Connect</title>'
    '<style>$_style</style></head><body><main>$main</main></body></html>';

/// Renders [page].
String renderStaticPage(StaticPage page) => _document(
  page.title,
  '<h1>${_escape(page.title)}</h1><p>${_escape(page.body)}</p>',
);

/// What the server that started a sign-in on [lane] can do with it, in
/// plain words, for the consent page.
String consentScopeFor(ConnectOAuthLane lane) => switch (lane) {
  ConnectOAuthLane.github =>
    'The server that started this sign-in will be able to act as you on '
        'GitHub: on every repository the Control Center app is installed on '
        'that you can reach, in every organization, until you disconnect.',
  ConnectOAuthLane.slack =>
    'The server that started this sign-in will install the Control Center '
        'bot in your Slack workspace and hold its token. The bot reads '
        'messages in the channels it is added to and in its direct messages, '
        'reads the member list with email addresses, and posts messages, '
        'until the app is uninstalled from the workspace.',
  ConnectOAuthLane.google =>
    'The server that started this sign-in will be able to see your list of '
        'Google calendars and read and change their events, until you '
        'disconnect.',
  ConnectOAuthLane.linear =>
    'The server that started this sign-in will be able to act as you in '
        'Linear: read and change everything you can see there and create '
        'issues, until you disconnect.',
  ConnectOAuthLane.linearApp =>
    'The server that started this sign-in will be able to act as the Control '
        'Center app in your Linear workspace: read and change everything the '
        'app can see there and create issues, until the app is removed.',
};

/// The `GET /done` consent page: what the server will be able to do, the
/// warning, and continue/cancel posting back to [action] with the page's
/// form [token] (base64url, generated by Connect). It shows no code and no
/// deep link. [otherNetwork] adds the proximity hint.
String renderConsentPage({
  required ConnectOAuthLane lane,
  required bool otherNetwork,
  required Uri action,
  required String token,
}) {
  const hint =
      '<p class="warn">This sign-in was started from another network than '
      'this browser\'s. That is normal for a hosted server or another device, '
      'and it is also what phishing looks like.</p>';
  const attribute = HtmlEscape(HtmlEscapeMode.attribute);
  final target = attribute.convert(action.toString());
  return _document(
    'Allow this server?',
    '<h1>Allow this server?</h1>'
        '<p>${_escape(consentScopeFor(lane))}</p>'
        '<p class="warn">Connect cannot tell who runs that server. Continue '
        'only if you started this sign-in yourself, in your own Control Center '
        'app or on a server you trust. If someone sent you this link, close '
        'this page.</p>'
        '${otherNetwork ? hint : ''}'
        '<form method="post" action="$target">'
        '<input type="hidden" name="token" '
        'value="${attribute.convert(token)}">'
        '<button type="submit" name="action" value="cancel">Cancel</button>'
        '<button class="primary" type="submit" name="action" '
        'value="continue">Continue</button></form>',
  );
}

/// The `POST /done` page after continue: the confirm code and the local deep
/// link. [code] is an 8-character Crockford code and [deepLink] is built by
/// Connect from its own login id, so neither is a reflected string.
String renderDonePage({required String code, required Uri deepLink}) {
  final shown = code.length == 8
      ? '${code.substring(0, 4)}-${code.substring(4)}'
      : code;
  return _document(
    'Your sign-in code',
    '<h1>Your sign-in code</h1>'
        '<span class="code">${_escape(shown)}</span>'
        '<p class="warn">Type it only where you started this sign-in. Anyone '
        'who gets it gets the access you just approved. Nobody will ever ask '
        'you for it.</p>'
        '<a class="button" href="${_escape(deepLink.toString())}">'
        'Open Control Center</a>'
        '<p class="fine">The button opens Control Center on this device, if '
        'you started the sign-in here.</p>',
  );
}

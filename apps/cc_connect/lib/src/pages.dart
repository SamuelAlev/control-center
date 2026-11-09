import 'dart:convert';

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
    '.fine{font-size:.85rem;color:#6b665e}'
    '@media (prefers-color-scheme:dark){body{background:#1a1916;color:#efece6}'
    'p{color:#c9c4ba}.code{color:#efece6}a.button{background:#efece6;'
    'color:#1a1916}.fine{color:#9c968b}}';

/// The CSP `style-src` source for [_style].
final String pageStyleHash =
    "'sha256-${base64.encode(crypto.sha256.convert(utf8.encode(_style)).bytes)}'";

/// The Content-Security-Policy every page carries.
final String pageContentSecurityPolicy =
    "default-src 'none'; style-src $pageStyleHash; frame-ancestors 'none'; "
    "base-uri 'none'; form-action 'none'";

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

  /// Another sign-in is connecting the same Slack workspace right now.
  slackInProgress(
    409,
    'This Slack workspace is already being connected',
    'Someone started connecting it a moment ago. Wait a few minutes, then try '
        'again from Control Center.',
  ),

  /// The flow failed on Connect's side or the provider's.
  failed(
    503,
    'Something went wrong',
    'The provider could not be reached. You can close this tab and try again '
        'in a moment.',
  ),

  /// The GitHub App was installed and this server authorized.
  githubInstalled(
    200,
    'GitHub App installed',
    'This Control Center server can now use the installation. You can close '
        'this tab.',
  ),

  /// An organization install is waiting for an owner's approval.
  githubRequested(
    200,
    'Installation requested',
    'An organization owner has to approve the installation on GitHub. Run '
        '"Authorize this server" in Control Center once it is approved.',
  ),

  /// The installer may not authorize this server on the installation.
  githubNotAdmin(
    403,
    'You cannot authorize this server here',
    'Only an organization admin can authorize a Control Center server on an '
        "organization's installation. Ask an admin to run \"Authorize this "
        'server" in Control Center.',
  ),

  /// The installation was not found for this app.
  githubNotInstalled(
    404,
    'Installation not found',
    'GitHub did not report this installation for the Control Center app. You '
        'can close this tab and try again from Control Center.',
  ),

  /// The server the link was made for is not allowed on this Connect.
  installBlocked(
    403,
    'This server cannot use Control Center Connect',
    'The operator of this Connect has blocked the Control Center server that '
        'made this link. Nothing was installed for it.',
  ),

  /// Nothing to do (an installation was updated without a ticket).
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

/// The `/done` page: the confirm code and the local deep link. [code] is an
/// 8-character Crockford code and [deepLink] is built by Connect from its own
/// login id, so neither is a reflected string.
String renderDonePage({required String code, required Uri deepLink}) {
  final shown = code.length == 8
      ? '${code.substring(0, 4)}-${code.substring(4)}'
      : code;
  return _document(
    'Finish signing in',
    '<h1>Finish signing in</h1>'
        '<p>Open Control Center on this device, or type this code where '
        'Control Center asks for it.</p>'
        '<span class="code">${_escape(shown)}</span>'
        '<a class="button" href="${_escape(deepLink.toString())}">'
        'Open Control Center</a>'
        '<p class="fine">Only enter this code in a Control Center you started '
        'this sign-in from. Nobody from Control Center will ever ask you for '
        'it.</p>',
  );
}

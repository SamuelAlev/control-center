import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/browser_pane.dart'
    show BrowserPane;
// Web iframe surface. The conditional import keeps `dart:ui_web` / `package:web`
// out of the desktop VM build (which gets the stub and never constructs it).
import 'package:control_center/features/messaging/presentation/ide/editor/browser_webview_stub.dart'
    if (dart.library.js_interop) 'package:control_center/features/messaging/presentation/ide/editor/browser_webview_web.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Embedded code-server (VS Code in the browser) editor tab: the full VS Code
/// UI on the conversation's isolated CoW worktree, reached through the
/// authenticated `/proxy/vscode/<sid>/` reverse proxy on the connected server.
///
/// Same three-backend structure as [BrowserPane] but WITHOUT the navigation
/// toolbar — code-server owns its own chrome:
///   * **macOS / Windows** (`flutter_inappwebview` has a native backend) load
///     the proxied URL in a real [InAppWebView]. Cookies persist for the
///     session so code-server's auth cookie survives tab flicker.
///   * **Web** embeds the same-origin proxied URL directly in an `<iframe>`.
///   * **Linux** (no native webview) degrades to an "open editor in browser"
///     card → the loopback direct URL via [openExternalUrl].
///
/// The session is resolved via [codeServerSessionProvider]; a spinner shows
/// while installing and a guidance card shows when code-server is unavailable
/// on the connected server.
class CodeServerPane extends ConsumerStatefulWidget {
  /// Creates a [CodeServerPane].
  const CodeServerPane({
    super.key,
    required this.channelId,
    this.repoId,
    this.path,
    this.line,
  });

  /// The conversation whose isolated worktree code-server should open.
  final String channelId;

  /// The repo whose worktree to open (null lets the server pick the first).
  final String? repoId;

  /// Optional file to deep-link open first inside code-server.
  final String? path;

  /// Optional 1-based line to reveal in the deep-linked file (best-effort).
  final int? line;

  @override
  ConsumerState<CodeServerPane> createState() => _CodeServerPaneState();
}

class _CodeServerPaneState extends ConsumerState<CodeServerPane> {
  // The webview mounts only after the first frame (mirrors [BrowserPane] +
  // the newsfeed's AdBlockerWebView `ready` gate): mounting the platform view in
  // the very first build can race the platform-view system on macOS so
  // `onWebViewCreated` never fires; deferring one frame lets it initialise.
  bool _ready = false;
  // code-server owns its own reload chrome, so the pane never bumps this — the
  // iframe just needs a stable token.
  final int _reloadToken = 0;

  // `flutter_inappwebview` ships a NATIVE webview on these platforms only. Web
  // is handled separately via the proxied iframe (see [_buildContent]); Linux
  // has no Flutter webview → external-browser fallback.
  bool get _nativeWebviewSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  /// Resolves [url] to an absolute `http(s)` URL against the server [base].
  /// Returns [url] unchanged when it is already absolute, or null when it is
  /// relative and no base is available (the caller then falls back to the direct
  /// loopback URL). A relative proxy path must NOT be embedded as-is: it would
  /// resolve against the client's own origin (Flutter web bundle / dev server)
  /// and never reach the server proxy.
  String? _absolutize(String url, Uri? base) {
    if (url.isEmpty) {
      return null;
    }
    Uri? resolved;
    final parsed = Uri.tryParse(url);
    if (parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https')) {
      resolved = parsed;
    } else if (base != null) {
      resolved = base.resolveUri(Uri.parse(url));
    }
    if (resolved == null) {
      return null;
    }
    // cc_server binds IPv4 loopback (127.0.0.1) only. A browser resolving
    // `localhost` may try IPv6 (::1) first and get "connection refused" for an
    // iframe navigation (unlike the WS/media fetch, which falls back). Pin the
    // loopback host to 127.0.0.1 so the embed always reaches the server; remote
    // hosts are left untouched.
    if (resolved.host == 'localhost') {
      resolved = resolved.replace(host: '127.0.0.1');
    }
    return resolved.toString();
  }

  CodeServerSessionRequest get _request => CodeServerSessionRequest(
    channelId: widget.channelId,
    repoId: widget.repoId,
    path: widget.path,
    line: widget.line,
  );

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(codeServerSessionProvider(_request));
    return ColoredBox(
      color: (context.designSystem ?? DesignSystemTokens.light()).bgPrimary,
      child: session.when(
        loading: () => _Installing(
          label: AppLocalizations.of(context).ideCodeServerInstalling,
        ),
        error: (e, _) => _errorCard(context, e),
        data: (result) => _buildContent(context, result),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CodeServerSessionResult result) {
    final l10n = AppLocalizations.of(context);
    if (result.status == CodeServerStatus.unavailable || result.url.isEmpty) {
      return _UnavailableCard(
        title: l10n.ideCodeServerUnavailable,
        hint: l10n.ideCodeServerUnavailableHint,
        directUrl: result.directUrl,
      );
    }
    if (result.status == CodeServerStatus.installing) {
      return _Installing(label: l10n.ideCodeServerInstalling);
    }

    // The server returns an app-relative proxy path (`/proxy/vscode/<sid>/`).
    // Make it ABSOLUTE against the connected server's http base — a relative
    // path would resolve against the client's own origin (the Flutter web
    // bundle / dev server), hit the SPA fallback and throw a go_router
    // "no routes for location" instead of reaching the server proxy. Works for
    // a loopback desktop server and a remote server alike; the capability is in
    // the path, so no cookie is required.
    final base = MediaProxyScope.httpBaseOf(context);
    final embedUrl = _absolutize(result.url, base) ?? result.directUrl;

    const web = kIsWeb;
    if (web) {
      // Proxied URL embeds inline in the web bundle's <iframe>.
      return BrowserWebView(src: embedUrl, reloadToken: _reloadToken);
    }
    if (!_nativeWebviewSupported) {
      // Linux desktop: no Flutter webview → open code-server in the system
      // browser against the (absolute) proxied URL.
      return _BrowserFallbackCard(
        url: embedUrl,
        ctaLabel: l10n.ideCodeServerOpenInBrowser,
      );
    }
    // macOS / Windows / mobile: real InAppWebView on the proxied URL. Cookies
    // persist for the session (NOT incognito, unlike the browser pane) so
    // code-server's session cookie survives the tab's lifetime.
    return _ready
        ? ClipRect(
            child: InAppWebView(
              key: ValueKey(result.sessionId),
              initialUrlRequest: URLRequest(url: WebUri(embedUrl)),
              initialSettings: InAppWebViewSettings(
                isInspectable: kDebugMode,
                allowsInlineMediaPlayback: true,
              ),
            ),
          )
        : const Center(child: CcSpinner());
  }

  Widget _errorCard(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // opUnknown = the connected server doesn't host code-server ops → treat it
    // as "unavailable" guidance, not a hard error.
    final isUnavailable =
        error is RemoteRpcException && error.code == RpcErrorCodes.opUnknown;
    if (isUnavailable) {
      return _UnavailableCard(
        title: l10n.ideCodeServerUnavailable,
        hint: l10n.ideCodeServerUnavailableHint,
        directUrl: '',
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.alertTriangle, size: 40, color: t.fgQuaternary),
            const SizedBox(height: 12),
            Text(
              l10n.ideCodeServerError,
              style: TextStyle(fontSize: 13, color: t.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 11, color: t.textQuaternary),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Spinner shown while code-server installs / the session resolves.
class _Installing extends StatelessWidget {
  const _Installing({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CcSpinner(),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 13, color: t.textTertiary)),
        ],
      ),
    );
  }
}

/// Guidance card shown when code-server is not installed on the server.
class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({
    required this.title,
    required this.hint,
    required this.directUrl,
  });

  final String title;
  final String hint;
  final String directUrl;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.code, size: 40, color: t.fgQuaternary),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(fontSize: 12, color: t.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown where `flutter_inappwebview` has no native backend (Linux). Hands the
/// loopback code-server URL to the system browser.
class _BrowserFallbackCard extends StatelessWidget {
  const _BrowserFallbackCard({required this.url, required this.ctaLabel});

  final String url;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final hasUrl = url.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.code, size: 40, color: t.fgQuaternary),
            const SizedBox(height: 12),
            if (hasUrl)
              CcButton(
                icon: AppIcons.externalLink,
                onPressed: () => openExternalUrl(url),
                child: Text(ctaLabel),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
// Web iframe surface. The conditional import keeps `dart:ui_web` / `package:web`
// out of the desktop VM build (which gets the stub and never constructs it).
import 'package:control_center/features/messaging/presentation/ide/editor/browser_webview_stub.dart'
    if (dart.library.js_interop) 'package:control_center/features/messaging/presentation/ide/editor/browser_webview_web.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_webview.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves a code-server route only through the local resource capability.
/// Never embed an absolute server URL or fall back to an unencrypted origin.
///
/// Also points the `openFile` payload at the window's own remote authority.
/// code-server's workbench takes its remote authority from the page's
/// `location.host`, but the server can't know which host the client reaches it
/// on and writes a placeholder `remote`. A boot file opened under the
/// placeholder is a different resource from the same file opened later by
/// path, so switching a shared window back to it would open a second editor
/// with its own buffer.
@visibleForTesting
String? codeServerEmbedUrl(String url, Uri? base) {
  if (url.isEmpty) {
    return null;
  }
  final parsed = Uri.tryParse(url);
  if (base == null ||
      parsed == null ||
      parsed.hasScheme ||
      parsed.hasAuthority ||
      !parsed.path.startsWith('/proxy/vscode/') ||
      parsed.hasFragment) {
    return null;
  }
  final prefix = base.path.endsWith('/')
      ? base.path.substring(0, base.path.length - 1)
      : base.path;
  var resolved = base.replace(
    path: '$prefix${parsed.path}',
    query: parsed.query,
  );
  // Native facades bind IPv4 loopback only; `localhost` can resolve to ::1.
  if (resolved.host == 'localhost') {
    resolved = resolved.replace(host: '127.0.0.1');
  }
  final payload = resolved.queryParameters['payload'];
  if (payload != null) {
    final host = resolved.host.contains(':')
        ? '[${resolved.host}]'
        : resolved.host;
    final authority = resolved.hasPort ? '$host:${resolved.port}' : host;
    resolved = resolved.replace(
      queryParameters: {
        ...resolved.queryParameters,
        'payload': payload.replaceAll(
          'vscode-remote://remote/',
          'vscode-remote://$authority/',
        ),
      },
    );
  }
  return resolved.toString();
}

/// One embedded code-server (VS Code in the browser) window: the full VS Code
/// UI on the conversation's isolated CoW worktree, reached through the
/// authenticated `/proxy/vscode/<sid>/` reverse proxy on the connected server.
/// macOS / Windows / mobile load it in a native webview; web embeds the
/// same-origin proxied URL in an `<iframe>`; Linux hands it to the browser.
///
/// [onBooting] fires once per fresh view (a moved view keeps its state and
/// does not boot again); [onBridgeWindow] reports the bridge's window id.
class CodeServerWindowView extends ConsumerStatefulWidget {
  /// Creates a [CodeServerWindowView].
  const CodeServerWindowView({
    super.key,
    required this.request,
    this.onBooting,
    this.onBridgeWindow,
  });

  /// The session (worktree + boot file) the window opens.
  final CodeServerSessionRequest request;

  /// Called when this view starts a fresh boot.
  final VoidCallback? onBooting;

  /// Called with the bridge extension's window id once it logs it.
  final ValueChanged<String>? onBridgeWindow;

  @override
  ConsumerState<CodeServerWindowView> createState() =>
      _CodeServerWindowViewState();
}

class _CodeServerWindowViewState extends ConsumerState<CodeServerWindowView> {
  // The webview mounts only after the first frame (mirrors [BrowserPane] +
  // the newsfeed's AdBlockerWebView `ready` gate): mounting the platform view in
  // the very first build can race the platform-view system on macOS so
  // `onWebViewCreated` never fires; deferring one frame lets it initialise.
  bool _ready = false;
  // code-server owns its own reload chrome, so the view never bumps this — the
  // iframe just needs a stable token.
  final int _reloadToken = 0;
  bool _editorResourceFailed = false;

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
    widget.onBooting?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(codeServerSessionProvider(widget.request));
    return ColoredBox(
      color: (context.designSystem ?? DesignSystemTokens.light()).bgPrimary,
      child: session.when(
        loading: () => const CodeServerPreparing(),
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
      );
    }
    if (result.status == CodeServerStatus.installing) {
      return const CodeServerPreparing();
    }

    if (_editorResourceFailed) {
      return _UnavailableCard(
        title: l10n.ideCodeServerUnavailable,
        hint: l10n.ideCodeServerUnavailableHint,
      );
    }
    // The host returns a path; only a live encrypted local resource facade
    // may turn it into an iframe/WebView URL.
    final base = MediaProxyScope.httpBaseOf(context);
    final embedUrl = codeServerEmbedUrl(result.url, base);
    if (embedUrl == null) {
      return _UnavailableCard(
        title: l10n.ideCodeServerUnavailable,
        hint: l10n.ideCodeServerUnavailableHint,
      );
    }

    const web = kIsWeb;
    if (web) {
      // Trusted editor scripts share the app origin; all server I/O stays
      // inside this connection's encrypted resource capability.
      return BrowserWebView(
        src: embedUrl,
        reloadToken: _reloadToken,
        codeServerResource: true,
        onError: () {
          if (mounted) setState(() => _editorResourceFailed = true);
        },
      );
    }
    if (!_nativeWebviewSupported) {
      // Linux desktop: no Flutter webview → open code-server in the system
      // browser against the (absolute) proxied URL.
      return _BrowserFallbackCard(
        url: embedUrl,
        ctaLabel: l10n.ideCodeServerOpenInBrowser,
      );
    }
    // macOS / Windows / mobile: real InAppWebView on the proxied URL, kept
    // under the same "preparing" state until the editor is clean (see
    // [CodeServerWebView]).
    const preparing = CodeServerPreparing();
    return _ready
        ? CodeServerWebView(
            key: ValueKey(result.sessionId),
            url: embedUrl,
            cover: preparing,
            onBridgeWindow: widget.onBridgeWindow,
          )
        : preparing;
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

/// Spinner shown while code-server installs / a window resolves or boots.
class CodeServerPreparing extends StatelessWidget {
  /// Creates a [CodeServerPreparing].
  const CodeServerPreparing({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CcSpinner(),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).ideCodeServerInstalling,
            style: TextStyle(fontSize: 13, color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Guidance card shown when code-server is not installed on the server.
class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.title, required this.hint});

  final String title;
  final String hint;

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

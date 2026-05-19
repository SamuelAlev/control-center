import 'package:cc_ui/cc_ui.dart';
// Web iframe surface. The conditional import keeps `dart:ui_web` / `package:web`
// out of the desktop VM build (which gets the stub and never constructs it).
import 'package:control_center/features/messaging/presentation/ide/editor/browser_webview_stub.dart'
    if (dart.library.js_interop) 'package:control_center/features/messaging/presentation/ide/editor/browser_webview_web.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// In-app browser editor tab: a navigable webview with a full toolbar
/// (back / forward / reload / address bar / open-external).
///
/// Two backends sit behind one toolbar:
///   * **Desktop / mobile** (`flutter_inappwebview` has a native backend) use a
///     real [InAppWebView], which loads any URL directly.
///   * **Web** has no native webview, so it embeds pages in an `<iframe>` routed
///     through the connected cc_server's `/proxy/page` endpoint, which strips the
///     frame-blocking headers (`X-Frame-Options` / CSP `frame-ancestors`) that
///     would otherwise stop the page rendering. Sites that allow framing load
///     inline; the rest still expose the address bar + "open in browser".
///   * **Linux** (no backend, no connection) degrades to an "open in browser"
///     card via [openExternalUrl].
class BrowserPane extends StatefulWidget {
  /// Creates a [BrowserPane].
  const BrowserPane({super.key, this.initialUrl});

  /// URL to load first. `null` / `about:blank` starts on a focused blank page.
  final String? initialUrl;

  @override
  State<BrowserPane> createState() => _BrowserPaneState();
}

class _BrowserPaneState extends State<BrowserPane> {
  InAppWebViewController? _controller;
  late final TextEditingController _address;
  final FocusNode _addressFocus = FocusNode();

  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _loading = false;
  int _progress = 0;
  // The webview mounts only after the first frame (mirrors the newsfeed's
  // AdBlockerWebView `ready` gate). Mounting the platform view in the very
  // first build can race the platform-view system on macOS so
  // `onWebViewCreated` never fires; deferring one frame lets it initialise.
  bool _ready = false;

  // Web-only state. `_webUrl` is the raw URL the user navigated to (the iframe
  // src is derived from it via the proxy); `_reloadToken` bumps to force a
  // same-URL reload.
  String _webUrl = '';
  int _reloadToken = 0;

  // `flutter_inappwebview` ships a NATIVE webview on these platforms only. Web
  // is handled separately via the proxied iframe (see [_buildContent]).
  bool get _nativeWebviewSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  String get _initialUrl => widget.initialUrl?.isNotEmpty == true
      ? widget.initialUrl!
      : 'about:blank';

  @override
  void initState() {
    super.initState();
    final initial = _initialUrl;
    final initialText = initial == 'about:blank' ? '' : initial;
    _address = TextEditingController(text: initialText);
    _webUrl = initialText;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _refreshNavState() async {
    final c = _controller;
    if (c == null) {
      return;
    }
    final back = await c.canGoBack();
    final fwd = await c.canGoForward();
    if (!mounted) {
      return;
    }
    setState(() {
      _canGoBack = back;
      _canGoForward = fwd;
    });
  }

  /// Normalises raw address-bar input into a loadable `http(s)` URL, or null
  /// when blank.
  String? _normalizeAddress(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(raw);
    final hasScheme = uri != null && uri.hasScheme;
    return hasScheme ? raw : 'https://$raw';
  }

  /// Navigates to the address-bar value on whichever backend is active.
  void _submitAddress(String value) {
    final url = _normalizeAddress(value);
    if (url == null) {
      return;
    }
    _address.text = url;
    _addressFocus.unfocus();
    if (kIsWeb) {
      setState(() => _webUrl = url);
    } else {
      _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
  }

  void _reload() {
    if (kIsWeb) {
      setState(() => _reloadToken++);
    } else {
      _controller?.reload();
    }
  }

  void _openExternal() {
    final url = (kIsWeb ? _webUrl : _address.text).trim();
    if (url.isEmpty || url == 'about:blank') {
      return;
    }
    openExternalUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    const web = kIsWeb;

    return Column(
      children: [
        _buildToolbar(context, l10n, t, web: web),
        // Native webviews report load progress; the cross-origin iframe can't.
        if (!web && _loading)
          LinearProgressIndicator(
            value: _progress > 0 ? _progress / 100 : null,
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: t.accent,
          ),
        Expanded(child: _buildContent(context, l10n, t, web: web)),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    AppLocalizations l10n,
    DesignSystemTokens t, {
    required bool web,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        border: Border(bottom: BorderSide(color: t.lineStrong)),
      ),
      child: Row(
        children: [
          CcIconButton(
            icon: AppIcons.arrowLeft,
            size: CcButtonSize.sm,
            // History nav isn't reachable on the cross-origin web iframe.
            onPressed:
                !web && _canGoBack ? () => _controller?.goBack() : null,
            tooltip: l10n.backLabel,
          ),
          CcIconButton(
            icon: AppIcons.arrowRight,
            size: CcButtonSize.sm,
            onPressed:
                !web && _canGoForward ? () => _controller?.goForward() : null,
            tooltip: l10n.forward,
          ),
          CcIconButton(
            icon: AppIcons.refreshCw,
            size: CcButtonSize.sm,
            onPressed: _reload,
            tooltip: l10n.reload,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CcTextField(
              controller: _address,
              focusNode: _addressFocus,
              size: CcTextFieldSize.sm,
              hintText: l10n.ideBrowserAddressHint,
              prefix: Icon(AppIcons.globe, size: 14, color: t.textTertiary),
              onSubmitted: _submitAddress,
              autofocus: _initialUrl == 'about:blank',
            ),
          ),
          const SizedBox(width: 4),
          CcIconButton(
            icon: AppIcons.externalLink,
            size: CcButtonSize.sm,
            onPressed: _openExternal,
            tooltip: l10n.openInBrowser,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    DesignSystemTokens t, {
    required bool web,
  }) {
    if (web) {
      // Simple browser: embed the URL directly in an iframe. Empty/blank shows
      // a hint; a real URL is handed straight to the iframe (pages that refuse
      // framing simply won't render — the inherent limit of a web iframe).
      if (!_isHttpUrl(_webUrl)) {
        return _WebBrowserNotice(message: l10n.ideBrowserEnterUrl);
      }
      return BrowserWebView(src: _webUrl, reloadToken: _reloadToken);
    }

    if (!_nativeWebviewSupported) {
      return _BrowserFallbackCard(
        url: _address.text.isEmpty ? _initialUrl : _address.text,
      );
    }

    return _ready
        ? ClipRect(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_initialUrl)),
              initialSettings: InAppWebViewSettings(
                incognito: true,
                isInspectable: kDebugMode,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (controller, url) async {
                setState(() => _loading = true);
                await _refreshNavState();
              },
              onLoadStop: (controller, url) async {
                final current = await controller.getUrl();
                if (!mounted) {
                  return;
                }
                final shown = current?.toString() ?? '';
                setState(() {
                  _loading = false;
                  _progress = 100;
                  _address.text = shown == 'about:blank' ? '' : shown;
                });
                await _refreshNavState();
              },
              onUpdateVisitedHistory: (controller, url, isReload) async {
                if (!mounted) {
                  return;
                }
                final shown = url?.toString() ?? '';
                if (shown != 'about:blank') {
                  _address.text = shown;
                }
                await _refreshNavState();
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress);
              },
            ),
          )
        : const Center(child: CcSpinner());
  }

  bool _isHttpUrl(String s) {
    final u = Uri.tryParse(s);
    return u != null && (u.scheme == 'http' || u.scheme == 'https');
  }
}

/// Web placeholder shown in the content area when there is nothing to embed yet
/// (blank address bar).
class _WebBrowserNotice extends StatelessWidget {
  const _WebBrowserNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.globe, size: 40, color: t.fgQuaternary),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: t.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown where `flutter_inappwebview` has no native backend (Linux). Hands the
/// current URL to the system browser.
class _BrowserFallbackCard extends StatelessWidget {
  const _BrowserFallbackCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final hasUrl = url.isNotEmpty && url != 'about:blank';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.globe, size: 40, color: t.fgQuaternary),
            const SizedBox(height: 12),
            Text(
              hasUrl ? url : 'about:blank',
              style: TextStyle(fontSize: 13, color: t.textTertiary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (hasUrl)
              CcButton(
                icon: AppIcons.externalLink,
                onPressed: () => openExternalUrl(url),
                child: Text(l10n.openInBrowser),
              )
            else
              Text(
                l10n.ideBrowserAddressHint,
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Native code-server webview that boots under an opaque [cover].
///
/// The bundled bridge extension closes code-server's side bars and panel, but
/// only once the extension host activates, seconds after the workbench first
/// paints with them open. The webview loads and runs underneath the cover (an
/// offstage platform view can stall the boot) and is uncovered when the bridge
/// logs [codeServerChromeHiddenMarker] to this window's console, so the editor
/// first appears with that chrome already gone.
///
/// Key it by session: a new session is a new webview that starts covered again.
class CodeServerWebView extends StatefulWidget {
  /// Creates a [CodeServerWebView].
  const CodeServerWebView({super.key, required this.url, required this.cover});

  /// Absolute URL of the code-server workbench to load.
  final String url;

  /// Shown above the booting webview, on an opaque background.
  final Widget cover;

  @override
  State<CodeServerWebView> createState() => _CodeServerWebViewState();
}

class _CodeServerWebViewState extends State<CodeServerWebView> {
  /// Uncovers anyway when the marker never arrives (a server running an older
  /// bridge, a failed bridge install), so a missing signal costs a brief chrome
  /// flash rather than a stuck spinner. A warm boot logs it in ~5s.
  static const Duration _coverTimeout = Duration(seconds: 10);

  bool _covered = true;
  Timer? _coverFallback;

  @override
  void initState() {
    super.initState();
    _coverFallback = Timer(_coverTimeout, _uncover);
  }

  @override
  void dispose() {
    _coverFallback?.cancel();
    super.dispose();
  }

  void _uncover() {
    _coverFallback?.cancel();
    if (mounted && _covered) {
      setState(() => _covered = false);
    }
  }

  /// A failed main-frame load shows its error page right away instead of
  /// waiting out the cover for a marker that will never come.
  void _uncoverOnMainFrameFailure(WebResourceRequest request) {
    if (request.isForMainFrame ?? false) {
      _uncover();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          // Cookies persist for the session (NOT incognito, unlike the browser
          // pane) so code-server's session cookie survives the tab's lifetime.
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              isInspectable: kDebugMode,
              allowsInlineMediaPlayback: true,
            ),
            onConsoleMessage: (_, message) {
              if (_covered &&
                  message.message.contains(codeServerChromeHiddenMarker)) {
                _uncover();
              }
            },
            onReceivedError: (_, request, _) =>
                _uncoverOnMainFrameFailure(request),
            onReceivedHttpError: (_, request, _) =>
                _uncoverOnMainFrameFailure(request),
          ),
        ),
        if (_covered) ColoredBox(color: t.bgPrimary, child: widget.cover),
      ],
    );
  }
}

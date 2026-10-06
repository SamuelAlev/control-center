import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Console line [codeServerEditorReadyScript] logs once the workbench shows
/// a painted editor with no side bar, panel or secondary side bar.
const String codeServerEditorReadyMarker = 'cc-ide-page:editor-ready';

/// Page script that watches the workbench's own layout classes and logs
/// [codeServerEditorReadyMarker] once the editor is painted with the chrome
/// already hidden (two consecutive polls, so a transient layout can't pass).
///
/// Once a worktree's layout state is saved (VS Code flushes it ~5s after a
/// window settles), later windows paint with the chrome hidden. This fires at
/// first paint then, about a second ahead of the bridge extension's marker,
/// which has to wait for a fresh extension host. On a worktree's first window
/// it fires as soon as the bridge has closed the side bar.
const String codeServerEditorReadyScript =
    '''
(function () {
  var stable = 0;
  var started = Date.now();
  var poll = setInterval(function () {
    if (Date.now() - started > 30000) { clearInterval(poll); return; }
    var wb = document.querySelector('.monaco-workbench');
    var c = wb && wb.classList;
    var ready = !!c && c.contains('nosidebar') && c.contains('nopanel') &&
      c.contains('noauxiliarybar') &&
      !!wb.querySelector('.part.editor .monaco-editor .view-line');
    stable = ready ? stable + 1 : 0;
    if (stable >= 2) {
      clearInterval(poll);
      console.log('$codeServerEditorReadyMarker');
    }
  }, 50);
})();
''';

final RegExp _bridgeWindowId = RegExp(
  '${RegExp.escape(codeServerBridgeWindowMarker)}([A-Za-z0-9-]+)',
);

/// Native code-server webview that boots under an opaque [cover].
///
/// code-server's side bars and panel can paint open before the bundled bridge
/// extension closes them, so the webview loads and runs underneath the cover
/// (an offstage platform view can stall the boot). It is uncovered by whichever
/// arrives first: [codeServerEditorReadyMarker] from the injected page script
/// (the workbench itself reports a clean, painted editor) or the bridge's
/// [codeServerChromeHiddenMarker] (a non-text editor the page script can't
/// see, such as an image).
///
/// Key it by session: a new session is a new webview that starts covered again.
class CodeServerWebView extends StatefulWidget {
  /// Creates a [CodeServerWebView].
  const CodeServerWebView({
    super.key,
    required this.url,
    required this.cover,
    this.onBridgeWindow,
  });

  /// Absolute URL of the code-server workbench to load.
  final String url;

  /// Shown above the booting webview, on an opaque background.
  final Widget cover;

  /// Called with the window id the bridge extension logs on activation
  /// ([codeServerBridgeWindowMarker]); again if its extension host restarts.
  final ValueChanged<String>? onBridgeWindow;

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
            initialUserScripts: UnmodifiableListView([
              UserScript(
                source: codeServerEditorReadyScript,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
              ),
            ]),
            onConsoleMessage: (_, message) {
              final windowId = _bridgeWindowId
                  .firstMatch(message.message)
                  ?.group(1);
              if (windowId != null) {
                widget.onBridgeWindow?.call(windowId);
              }
              if (_covered &&
                  (message.message.contains(codeServerEditorReadyMarker) ||
                      message.message.contains(codeServerChromeHiddenMarker))) {
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

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Per-instance controller for `AdBlockerWebView` (mirrors the API shape
/// of `flutter_adblocker_webview`'s `AdBlockerWebviewController`, but
/// without the singleton — each widget owns its own controller).
///
/// The widget wires the underlying [InAppWebViewController] via
/// [attach] on creation. Until then, navigation methods are no-ops.
class AdBlockerWebViewController {
  /// Creates a new [AdBlockerWebViewController].
  AdBlockerWebViewController();

  InAppWebViewController? _inner;

  /// Notifies listeners whenever the page-load state flips. `true` while
  /// a page is loading, `false` otherwise.
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  /// Notifies listeners whenever the current URL changes.
  final ValueNotifier<String> currentUrl = ValueNotifier<String>('');

  /// Notifies listeners whenever the back/forward navigation state
  /// changes. Field order: (canGoBack, canGoForward).
  final ValueNotifier<({bool canGoBack, bool canGoForward})> navState =
      ValueNotifier<({bool canGoBack, bool canGoForward})>((
        canGoBack: false,
        canGoForward: false,
      ));

  /// Attaches the underlying [InAppWebViewController]. Called by the
  /// widget from `onWebViewCreated`.
  void attach(InAppWebViewController inner) {
    _inner = inner;
  }

  /// Detaches and disposes any value notifiers. Called by the widget on
  /// dispose.
  void dispose() {
    _inner = null;
    isLoading.dispose();
    currentUrl.dispose();
    navState.dispose();
  }

  /// Reloads the current page.
  Future<void> reload() async {
    await _inner?.reload();
  }

  /// Navigates back if possible.
  Future<void> goBack() async {
    await _inner?.goBack();
  }

  /// Navigates forward if possible.
  Future<void> goForward() async {
    await _inner?.goForward();
  }

  /// Loads [url], replacing the current page.
  Future<void> loadUrl(Uri url) async {
    await _inner?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(url)));
  }

  /// Evaluates [script] in the page's main frame.
  Future<dynamic> runScript(String script) async {
    return _inner?.evaluateJavascript(source: script);
  }
}

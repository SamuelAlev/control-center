import 'dart:async';
import 'dart:js_interop';

import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

@JS('ccResourceBridge.attachEditor')
external JSPromise<JSString> _attachEditor(
  web.HTMLIFrameElement iframe,
  JSString source,
);

@JS('ccResourceBridge.detachEditor')
external void _detachEditor(web.HTMLIFrameElement iframe);

/// Plain browser panes embed their URL directly. Trusted code-server panes
/// attach through the app-origin resource facade, which owns their lifetime
/// and carries HTTP/WebSocket traffic over the authenticated encrypted session.
class BrowserWebView extends StatefulWidget {
  /// Creates a [BrowserWebView].
  const BrowserWebView({
    super.key,
    required this.src,
    required this.reloadToken,
    this.codeServerResource = false,
    this.onError,
  });

  /// The absolute URL to load directly in the iframe.
  final String src;

  /// Monotonic reload trigger; changing it reloads [src].
  final int reloadToken;

  /// Whether this iframe uses the authenticated code-server resource facade.
  final bool codeServerResource;

  /// Called when the authenticated editor facade fails to load.
  final VoidCallback? onError;

  @override
  State<BrowserWebView> createState() => _BrowserWebViewState();
}

class _BrowserWebViewState extends State<BrowserWebView> {
  // Each instance registers its own view factory + iframe so split panes /
  // multiple browser tabs don't share one DOM element.
  static int _seq = 0;
  late final String _viewType;
  late final web.HTMLIFrameElement _iframe;
  String? _appliedSrc;
  int _appliedToken = 0;

  @override
  void initState() {
    super.initState();
    _viewType = 'cc-browser-iframe-${_seq++}';
    _iframe = web.document.createElement('iframe') as web.HTMLIFrameElement
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('allow', 'clipboard-read; clipboard-write; fullscreen');
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _iframe,
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant BrowserWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final url = widget.src.isEmpty ? 'about:blank' : widget.src;
    final urlChanged = url != _appliedSrc;
    final reloadRequested = widget.reloadToken != _appliedToken;
    if (!urlChanged && !reloadRequested) {
      return;
    }
    _appliedSrc = url;
    _appliedToken = widget.reloadToken;
    if (widget.codeServerResource) {
      _iframe.removeAttribute('credentialless');
    } else {
      _iframe.setAttribute('credentialless', '');
    }
    if (widget.codeServerResource) {
      _iframe.src = 'about:blank';
      unawaited(
        _attachEditor(_iframe, url.toJS).toDart.then((_) {}).catchError((
          Object _,
        ) {
          if (mounted) {
            widget.onError?.call();
          }
        }),
      );
      return;
    }
    if (urlChanged) {
      _iframe.src = url;
      return;
    }
    // Same URL, explicit reload: bounce through about:blank so navigation runs.
    _iframe.src = 'about:blank';
    Future.microtask(() {
      if (mounted && _appliedSrc == url) {
        _iframe.src = url;
      }
    });
  }

  @override
  void dispose() {
    if (widget.codeServerResource) {
      _detachEditor(_iframe);
    }
    _iframe.src = 'about:blank';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}

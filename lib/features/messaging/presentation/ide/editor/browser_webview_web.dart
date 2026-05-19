import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web "simple web browser" surface: embeds [src] directly in an `<iframe>`.
///
/// There is no proxy — the iframe loads the URL as-is, so it renders pages that
/// permit framing (localhost dev servers and many sites). Pages that send
/// `X-Frame-Options` / CSP `frame-ancestors` (Google, YouTube, GitHub, …) refuse
/// to render; that is the inherent limit of a plain web iframe and is expected
/// here. The full in-app browser lives on desktop (native webview).
///
/// Bumping [reloadToken] reloads the current page.
///
/// This file is web-only: it is reached through a `dart.library.js_interop`
/// conditional import (the io build gets the stub), so the `dart:ui_web` /
/// `package:web` imports never reach the desktop VM build.
class BrowserWebView extends StatefulWidget {
  /// Creates a [BrowserWebView].
  const BrowserWebView({
    super.key,
    required this.src,
    required this.reloadToken,
  });

  /// The absolute URL to load directly in the iframe.
  final String src;

  /// Monotonic reload trigger; changing it reloads [src].
  final int reloadToken;

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
    ui_web.platformViewRegistry
        .registerViewFactory(_viewType, (int _) => _iframe);
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
    if (urlChanged) {
      _iframe.src = url;
      return;
    }
    // Same URL, explicit reload: bounce through about:blank so the navigation
    // actually re-runs (re-assigning the identical src can be a no-op).
    _iframe.src = 'about:blank';
    Future.microtask(() {
      if (mounted && _appliedSrc == url) {
        _iframe.src = url;
      }
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}

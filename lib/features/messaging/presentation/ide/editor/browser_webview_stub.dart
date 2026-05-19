import 'package:flutter/widgets.dart';

/// Non-web stub for [BrowserWebView]. The web iframe surface is only ever
/// constructed on web (the caller gates on `kIsWeb`); this exists so the
/// `dart.library.js_interop` conditional import resolves on the desktop VM
/// build, where `dart:ui_web` / `package:web` are unavailable.
class BrowserWebView extends StatelessWidget {
  /// Creates a [BrowserWebView] stub.
  const BrowserWebView({
    super.key,
    required this.src,
    required this.reloadToken,
  });

  /// Unused on non-web.
  final String src;

  /// Unused on non-web.
  final int reloadToken;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

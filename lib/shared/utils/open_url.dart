import 'package:control_center/shared/utils/open_url_io.dart'
    if (dart.library.js_interop) 'package:control_center/shared/utils/open_url_web.dart';

/// Hands [url] to the operating system's default external handler (browser for
/// http/https, mail client for mailto, etc.) and returns whether the system
/// accepted it.
///
/// Routes through a conditional-import seam so the desktop build uses nativeapi's
/// `UrlOpener` (synchronous, system handler) while the web build opens a new
/// browser tab — keeping the `dart:ffi`-laden nativeapi off the web graph.
bool openExternalUrl(String url) => openUrlImpl(url);

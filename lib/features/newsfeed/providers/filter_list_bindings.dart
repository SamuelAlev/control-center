/// Platform seam for the filter-list update operations behind
/// `filterListUpdateProvider`.
///
/// On the VM these delegate to the real `FilterListService` (downloading +
/// caching ad/cookie rule lists for the desktop ad-blocking webview); on web
/// they are honest no-ops returning an empty (no-rules) state, since the web
/// client has no local cache or webview.
library;

export 'filter_list_bindings_io.dart'
    if (dart.library.js_interop) 'filter_list_bindings_web.dart';

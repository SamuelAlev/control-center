// Puts bytes fetched out of a guest onto the HOST's filesystem, so the OS can
// carry them: a `file://` URI is the only thing Finder, Explorer and a GTK
// file manager will accept from a clipboard or a drag, and none of them will
// take raw bytes.
//
// Split io/web because the web build has no filesystem to stage into, and the
// honest consequence is that carrying FILES out of a machine is a desktop
// capability. Text and images still cross on web, where the clipboard carries
// values rather than paths.
library;

export 'host_file_staging_io.dart'
    if (dart.library.js_interop) 'host_file_staging_web.dart';

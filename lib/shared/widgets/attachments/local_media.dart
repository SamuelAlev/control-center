// Reading and playing a file the user just dropped, on the platforms that have
// one.
//
// Split io/web because the web build has no filesystem: a drop there carries
// bytes and nothing else, so there is no path to read and no `file://` URL to
// hand a player. The consequence is stated rather than smoothed — a preview
// that cannot open says so, instead of showing an empty frame.
//
// This is presentation, not business logic: it reads the bytes of a file the
// person just handed the composer so the app can draw it. Nothing here touches
// a database, an API, or a process — all of which stay in `cc_server`.
library;

export 'local_media_io.dart'
    if (dart.library.js_interop) 'local_media_web.dart';

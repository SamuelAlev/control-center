/// Service-worker probe + page-reload seam (web-only behaviour behind a
/// conditional export so shared update code compiles on every platform).
library;

export 'service_worker_probe_io.dart'
    if (dart.library.js_interop) 'service_worker_probe_web.dart';

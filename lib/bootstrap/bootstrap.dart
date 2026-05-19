/// Selects the platform's app bootstrap.
///
/// On the VM (desktop) this exports the full native multi-window startup
/// (`bootstrap_io.dart`); on web it exports the thin-client connect-then-render
/// startup (`bootstrap_web.dart`). Both expose `Future<void> bootstrapAndRun()`,
/// so `lib/main.dart` is a single shim that calls it without knowing the target.
library;

export 'bootstrap_io.dart'
    if (dart.library.js_interop) 'bootstrap_web.dart';

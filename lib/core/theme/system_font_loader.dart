/// Platform seam for loading a user-selected *system* font from a local file.
///
/// The desktop reads the chosen `.ttf`/`.otf` off disk and registers it with
/// Flutter's `FontLoader` (`system_font_loader_io.dart`); web has no local font
/// files, so both operations are inert (`system_font_loader_web.dart`). Importing
/// `dart:io` directly in the (web-reachable) theme/font code would break
/// `flutter build web`, so font code calls through this seam.
library;

export 'system_font_loader_io.dart'
    if (dart.library.js_interop) 'system_font_loader_web.dart';

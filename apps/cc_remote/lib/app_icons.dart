import 'package:flutter/widgets.dart';

/// Icons used by cc_remote, referenced directly against the bundled Lucide font.
///
/// We deliberately do NOT import `package:lucide_icons_flutter/lucide_icons.dart`.
/// That package exposes its whole icon set as a single 12 MB / 123k-line
/// `LucideIcons` class of `static const IconData` fields. On Flutter web the dev
/// compiler (DDC) lazily links a library the first time one of its members is
/// accessed; linking that giant library overflows the JS stack and crashes with
/// a `StackOverflowError` before the first screen can render.
///
/// Declaring only the glyphs we use keeps the same Lucide font (the asset is
/// still bundled via the `lucide_icons_flutter` dependency) without ever
/// triggering that initialization. Codepoints mirror `LucideIcons`.
abstract final class AppIcons {
  static const String _family = 'Lucide';
  static const String _package = 'lucide_icons_flutter';

  static const IconData scanLine =
      IconData(57944, fontFamily: _family, fontPackage: _package);
  static const IconData triangleAlert =
      IconData(57747, fontFamily: _family, fontPackage: _package);
  static const IconData messageCircle =
      IconData(57622, fontFamily: _family, fontPackage: _package);
  static const IconData user =
      IconData(57759, fontFamily: _family, fontPackage: _package);
  static const IconData hash =
      IconData(57583, fontFamily: _family, fontPackage: _package);
  static const IconData send =
      IconData(57682, fontFamily: _family, fontPackage: _package);
  static const IconData arrowLeft =
      IconData(57416, fontFamily: _family, fontPackage: _package);
  static const IconData newspaper =
      IconData(58184, fontFamily: _family, fontPackage: _package);
  static const IconData bookmark =
      IconData(57440, fontFamily: _family, fontPackage: _package);
  static const IconData bookmarkCheck =
      IconData(58655, fontFamily: _family, fontPackage: _package);
  static const IconData externalLink =
      IconData(57529, fontFamily: _family, fontPackage: _package);
  static const IconData ticket =
      IconData(57871, fontFamily: _family, fontPackage: _package);
  static const IconData userCheck =
      IconData(57760, fontFamily: _family, fontPackage: _package);
  static const IconData x =
      IconData(57778, fontFamily: _family, fontPackage: _package);
  static const IconData bot =
      IconData(57787, fontFamily: _family, fontPackage: _package);
  static const IconData layers =
      IconData(58665, fontFamily: _family, fontPackage: _package);
  static const IconData chevronDown =
      IconData(57453, fontFamily: _family, fontPackage: _package);
  static const IconData check =
      IconData(57452, fontFamily: _family, fontPackage: _package);
  static const IconData wifiOff =
      IconData(57775, fontFamily: _family, fontPackage: _package);
  static const IconData circleCheck =
      IconData(57894, fontFamily: _family, fontPackage: _package);
  static const IconData loader =
      IconData(57609, fontFamily: _family, fontPackage: _package);
  static const IconData sparkles =
      IconData(58386, fontFamily: _family, fontPackage: _package);
  static const IconData minus =
      IconData(57628, fontFamily: _family, fontPackage: _package);
  static const IconData chevronRight =
      IconData(57455, fontFamily: _family, fontPackage: _package);
  static const IconData settings =
      IconData(57684, fontFamily: _family, fontPackage: _package);
  static const IconData sun =
      IconData(57720, fontFamily: _family, fontPackage: _package);
  static const IconData moon =
      IconData(57630, fontFamily: _family, fontPackage: _package);
  static const IconData monitor =
      IconData(57629, fontFamily: _family, fontPackage: _package);
  static const IconData logOut =
      IconData(57614, fontFamily: _family, fontPackage: _package);
  static const IconData globe =
      IconData(57576, fontFamily: _family, fontPackage: _package);
  static const IconData palette =
      IconData(57821, fontFamily: _family, fontPackage: _package);
  static const IconData languages =
      IconData(57598, fontFamily: _family, fontPackage: _package);
  static const IconData refreshCw =
      IconData(57669, fontFamily: _family, fontPackage: _package);
}

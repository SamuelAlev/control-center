import 'package:flutter/widgets.dart';

/// The handful of Lucide glyphs cc_ui's own components need (chevrons, check).
///
/// cc_ui deliberately does NOT import
/// `package:lucide_icons_flutter/lucide_icons.dart`. That package exposes its
/// entire icon set as one ~123k-line `LucideIcons` class; on Flutter web the dev
/// compiler (DDC) links a library the first time any member is touched, and
/// linking that giant class overflows the JS stack — crashing
/// `flutter run -d chrome` before the first frame. Since cc_ui is the shared
/// design system, importing the giant class there would break the web build for
/// every consumer (and forced apps like cc_remote / the web client to avoid the
/// components below). Declaring only the codepoints used keeps the same bundled
/// Lucide font without ever triggering that link.
///
/// Codepoints mirror `LucideIcons` (3.1.14). cc_ui is purist — built on
/// `package:flutter/widgets.dart` only — and this keeps it web-safe too.
abstract final class CcIcons {
  static const String _family = 'Lucide';
  static const String _package = 'lucide_icons_flutter';

  /// A check mark (selected option).
  static const IconData check =
      IconData(57452, fontFamily: _family, fontPackage: _package);

  /// A downward chevron (expand / dropdown affordance).
  static const IconData chevronDown =
      IconData(57453, fontFamily: _family, fontPackage: _package);

  /// A rightward chevron (breadcrumb separator).
  static const IconData chevronRight =
      IconData(57455, fontFamily: _family, fontPackage: _package);

  /// A folder (directory entry).
  static const IconData folder =
      IconData(57559, fontFamily: _family, fontPackage: _package);

  /// A folder marked as a git repository.
  static const IconData folderGit =
      IconData(58377, fontFamily: _family, fontPackage: _package);

  /// A git branch (repository marker).
  static const IconData gitBranch =
      IconData(57570, fontFamily: _family, fontPackage: _package);

  /// An up-and-back corner arrow (navigate to the parent directory).
  static const IconData cornerLeftUp =
      IconData(57508, fontFamily: _family, fontPackage: _package);

  /// A house (a configured browse root).
  static const IconData house =
      IconData(57589, fontFamily: _family, fontPackage: _package);
}

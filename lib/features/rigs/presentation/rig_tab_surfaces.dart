// Which machine a rig tab shows, in the wire vocabulary a tab's args carry.
library;

import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:control_center/features/rigs/presentation/rig_labels.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show IconData;

/// Which machine a rig tab shows. The wire strings the server uses.
// ignore: avoid_classes_with_only_static_members
abstract final class RigTabSurfaces {
  /// A Linux desktop.
  static const String computer = 'computer';

  /// A headless Chromium.
  static const String browser = 'browser';

  /// An Android device.
  static const String mobile = 'mobile';

  /// Every surface a tab can show, in menu order.
  static const List<String> all = [computer, browser, mobile];

  /// The tab-strip icon for [surface].
  ///
  /// Delegates to the shared vocabulary in `rig_labels.dart` rather than
  /// re-deriving it: this switch and three others drifted apart the first
  /// time a phase was added.
  static IconData iconFor(String surface) =>
      rigSurfaceIcon(RigSurface.fromWire(surface));

  /// The localized tab label for [surface].
  static String labelFor(AppLocalizations l10n, String surface) =>
      rigSurfaceLabel(l10n, RigSurface.fromWire(surface));
}

// The ONE place the rig state machine is turned into words and colour.
//
// It used to be five: `rigs_screen`, `rig_panel`, `rig_tab_pane`, `pr_rig_tab`
// and the settings screen each hand-compared `'ready'` / `'parked'` / … and
// each drifted its own way. `rig_panel` mapped an unknown phase to the
// "Failed" LABEL beside a NEUTRAL dot — two different claims about the same
// machine, from two switches four lines apart.
library;

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_ui/cc_ui.dart' show CcStatusTone;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart' show IconData;

/// The tab-strip / header icon for [surface].
///
/// An unknown surface gets the desktop glyph: it is the neutral one, and a
/// missing icon is a hole in a row of them.
IconData rigSurfaceIcon(RigSurface? surface) => switch (surface) {
  RigSurface.browser => AppIcons.globe,
  RigSurface.mobile => AppIcons.smartphone,
  RigSurface.computer || null => AppIcons.monitor,
};

/// The localized name of [surface].
String rigSurfaceLabel(AppLocalizations l10n, RigSurface? surface) =>
    switch (surface) {
      RigSurface.browser => l10n.rigSurfaceBrowser,
      RigSurface.mobile => l10n.rigSurfaceMobile,
      RigSurface.computer || null => l10n.rigSurfaceComputer,
    };

/// The status-tag colour for [phase].
///
/// Null (a phase this client does not know) is NEUTRAL, and
/// [rigPhaseLabel] says "unknown" beside it. The two must agree: a machine
/// cannot be described as failed and drawn as fine.
CcStatusTone rigPhaseTone(RigPhase? phase) => switch (phase) {
  RigPhase.ready => CcStatusTone.positive,
  RigPhase.parked => CcStatusTone.neutral,
  RigPhase.provisioning => CcStatusTone.caution,
  RigPhase.closing => CcStatusTone.caution,
  RigPhase.closed => CcStatusTone.neutral,
  RigPhase.failed => CcStatusTone.negative,
  null => CcStatusTone.neutral,
};

/// The localized status label for [rig].
///
/// `ready` reads as "You have control" when this human holds it — the state
/// that changes what the next click does is the one worth naming.
String rigPhaseLabel(AppLocalizations l10n, RigView rig) =>
    switch (rig.phaseKind) {
      RigPhase.ready =>
        rig.isHumanControlled ? l10n.rigYouHaveControl : l10n.rigPhaseReady,
      RigPhase.parked => l10n.rigPhaseParked,
      RigPhase.provisioning => l10n.rigPhaseStarting,
      RigPhase.closing => l10n.rigPhaseClosing,
      RigPhase.closed => l10n.rigPhaseClosed,
      RigPhase.failed => l10n.rigPhaseFailed,
      // Honest, not pessimistic. An older/newer server, or a truncated
      // payload, is not a failed machine.
      null => l10n.rigPhaseUnknown,
    };

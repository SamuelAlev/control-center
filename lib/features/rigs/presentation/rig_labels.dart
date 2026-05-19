// The ONE place the rig state machine is turned into words and colour.
//
// It used to be five: `rigs_screen`, `rig_panel`, `rig_tab_pane`, `pr_rig_tab`
// and the settings screen each hand-compared `'ready'` / `'parked'` / … and
// each drifted its own way. `rig_panel` mapped an unknown phase to the
// "Failed" LABEL beside a NEUTRAL dot — two different claims about the same
// machine, from two switches four lines apart.
library;

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
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

/// The localized name of [surface], naming [engine] when the surface is a
/// browser and the engine is known.
///
/// A browser rig is worth naming by its ENGINE everywhere it appears: three
/// of them can be open in one conversation, and "Browser" on all three tells
/// a person nothing about which page they are looking at. The engine names
/// themselves are products and are never translated — only the frame around
/// them is.
String rigSurfaceLabel(
  AppLocalizations l10n,
  RigSurface? surface, {
  RigBrowserEngine? engine,
}) => switch (surface) {
  RigSurface.browser =>
    engine == null
        ? l10n.rigSurfaceBrowser
        : l10n.rigSurfaceBrowserEngine(engine.label),
  RigSurface.mobile => l10n.rigSurfaceMobile,
  RigSurface.computer || null => l10n.rigSurfaceComputer,
};

/// [rigSurfaceLabel] for [surface], numbered when [slotId] names one of the
/// conversation's EXTRA machines of that kind.
///
/// A conversation can hold more than one machine of the same surface and
/// engine — two WebKit rigs to compare two builds — and every one of them is
/// otherwise described by the same words. The number is the only thing telling
/// a person which tab, which sidebar row and which machine they are looking at,
/// so it is derived from the slot id rather than from a position in a list:
/// positions renumber when a machine closes, and a tab silently renaming
/// itself to another machine's name is worse than no number at all.
String rigMachineLabel(
  AppLocalizations l10n,
  RigSurface? surface, {
  RigBrowserEngine? engine,
  String? slotId,
}) {
  final base = rigSurfaceLabel(l10n, surface, engine: engine);
  final suffix = rigSlotSuffix(slotId);
  return suffix == null ? base : l10n.rigLabelNumbered(base, suffix);
}

/// What to append to a machine's name for [slotId], or null for the
/// conversation's default machine (which is simply "WebKit", not "WebKit 1").
///
/// Slots this app minted are `s<n>` and read as the number. Anything else —
/// a slot from some other client — is shown VERBATIM rather than dropped: two
/// machines sharing one name is the single thing this suffix exists to
/// prevent, and an unrecognised id still tells them apart.
String? rigSlotSuffix(String? slotId) {
  if (slotId == null || slotId.isEmpty) {
    return null;
  }
  final ordinal = slotId.startsWith('s')
      ? int.tryParse(slotId.substring(1))
      : null;
  return ordinal == null ? slotId : '$ordinal';
}

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

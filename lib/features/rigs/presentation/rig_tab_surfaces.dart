// Which machine a rig tab shows, in the wire vocabulary a tab's args carry.
library;

import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:control_center/features/rigs/presentation/rig_labels.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show IconData;

/// One machine a tab can open: a surface, plus which browser when the surface
/// is one.
///
/// A pair rather than two loose strings because the two travel together
/// everywhere — the menu entry, the tab args, the dedup key, the provider
/// key — and every place that dropped one of them addressed the wrong
/// machine.
class RigTabTarget {
  /// Creates a [RigTabTarget].
  const RigTabTarget(this.surface, {this.engine, this.slotId});

  /// The surface's wire string.
  final String surface;

  /// Which browser, on the browser surface. Null on the others, which have
  /// no engine to choose.
  final RigBrowserEngine? engine;

  /// WHICH machine of this surface + engine, within the conversation.
  ///
  /// Null is the conversation's DEFAULT machine: the one an agent's `*_use`
  /// calls drive and the one every tab addressed before a conversation could
  /// hold more than one of a kind. A non-null slot is a second machine opened
  /// deliberately to compare two things — a real VM of its own, not a second
  /// view of the first.
  final String? slotId;

  /// The tab args a rig tab carries. `engine` is omitted rather than
  /// defaulted on the non-browser surfaces so a persisted layout does not
  /// claim a Chromium desktop; `slot` is omitted on the default machine for
  /// the same reason, and so a layout written before slots keeps meaning what
  /// it meant.
  Map<String, String> get args => {
    'surface': surface,
    if (engine != null) 'engine': engine!.wire,
    'slot': ?slotId,
  };

  /// The dedup key that makes one tab per machine.
  ///
  /// The engine is IN the key: a second "Firefox (VM)" of the same machine
  /// would show it twice, but a "Firefox (VM)" next to a "Chromium (VM)" is
  /// two machines and the whole reason both entries exist. The slot is in the
  /// key for exactly the same reason one level down — two slots are two VMs.
  String get dedupKey =>
      'rig:$surface'
      '${engine == null ? '' : ':${engine!.wire}'}'
      '${slotId == null ? '' : ':#$slotId'}';

  @override
  bool operator ==(Object other) =>
      other is RigTabTarget &&
      other.surface == surface &&
      other.engine == engine &&
      other.slotId == slotId;

  @override
  int get hashCode => Object.hash(surface, engine, slotId);
}

/// Which machine a rig tab shows. The wire strings the server uses.
// ignore: avoid_classes_with_only_static_members
abstract final class RigTabSurfaces {
  /// A Linux desktop.
  static const String computer = 'computer';

  /// A headless browser.
  static const String browser = 'browser';

  /// An Android device.
  static const String mobile = 'mobile';

  /// Every surface a tab can show, in menu order.
  static const List<String> all = [browser, mobile, computer];

  /// The machines to offer, given the browsers the connected server can boot.
  ///
  /// One entry per ENGINE rather than a single "Browser (VM)": choosing the
  /// browser after the machine exists is not possible (a rig is one engine
  /// for its whole life), and the reason to open a second browser rig is
  /// almost always to compare it against the first.
  ///
  /// An engine the server did not report is not offered. A server that names
  /// none at all still gets Chromium — that is an older server, which had
  /// exactly one browser and no way to say so.
  static List<RigTabTarget> targets(Set<RigBrowserEngine> engines) {
    final available = engines.isEmpty
        ? const {RigBrowserEngine.chromium}
        : engines;
    return [
      for (final engine in RigBrowserEngine.values)
        if (available.contains(engine)) RigTabTarget(browser, engine: engine),
      const RigTabTarget(mobile),
      // The desktop is last: it is the heavyweight machine a conversation
      // needs least often, so it sits below the phone rather than above the
      // browsers.
      const RigTabTarget(computer),
    ];
  }

  /// The slots [openTabArgs] already hold for machines of the same kind as
  /// [kind] — same surface, and same engine on the browser surface.
  ///
  /// Both halves of that match are load-bearing. Without the surface a phone
  /// tab would number the desktops; without the engine a Firefox press would
  /// count the Chromium tabs and skip to #2 for its first machine.
  ///
  /// Takes raw tab args rather than tabs so the rule stays testable, and so
  /// this file keeps knowing nothing about the editor engine.
  static Set<String?> takenSlots(
    Iterable<Map<String, Object?>> openTabArgs,
    RigTabTarget kind,
  ) => {
    for (final args in openTabArgs)
      if (args['surface'] == kind.surface &&
          browserEngineOf(args) == browserEngineOf(kind.args))
        slotFromArgs(args),
  };

  /// The machine a `[+]` press on [kind] should address, given the args of
  /// every rig tab currently open ([openRigTabArgs]).
  ///
  /// The lowest-numbered machine of that kind with no tab — see [allocateSlot]
  /// for why that is the rule — except on the phone, which always addresses the
  /// conversation's one device: the mobile surface drives the HOST's attached
  /// phone, so there is no second one to open and `RigSpec` refuses a slot
  /// there. Allocating one anyway would fail at Start with a validation error
  /// instead of showing the machine.
  static RigTabTarget nextTarget(
    RigTabTarget kind,
    Iterable<Map<String, Object?>> openRigTabArgs,
  ) => kind.surface == mobile
      ? kind
      : RigTabTarget(
          kind.surface,
          engine: kind.engine,
          slotId: allocateSlot(takenSlots(openRigTabArgs, kind)),
        );

  /// The slot a `[+]` press should address, given the slots already [taken] by
  /// that kind's open tabs.
  ///
  /// Null — the conversation's default machine — when nothing holds it yet, so
  /// the first press lands on the machine an agent's `*_use` calls drive. That
  /// is the property the whole feature has to keep: a person and an agent
  /// talking about "the browser" must mean one machine until the person
  /// deliberately opens another.
  ///
  /// Then `s2`, `s3`, … taking the lowest free number rather than a counter,
  /// so closing #2 and opening another gives #2 back instead of drifting to
  /// #7. The scan terminates: the lowest free ordinal is at most one past the
  /// number of taken slots.
  static String? allocateSlot(Set<String?> taken) {
    if (!taken.contains(null)) {
      return null;
    }
    for (var n = 2; ; n++) {
      final slot = 's$n';
      if (!taken.contains(slot)) {
        return slot;
      }
    }
  }

  /// Reads a tab's `engine` arg, or null when it carries none.
  static RigBrowserEngine? engineFromArgs(Map<String, Object?> args) =>
      RigBrowserEngine.fromWire(args['engine'] as String?);

  /// Reads a tab's `slot` arg: WHICH machine of its kind it addresses.
  ///
  /// Null — the conversation's default machine — for every tab that names no
  /// slot, which includes every tab in a layout written before slots existed.
  /// That is what keeps a restored layout pointing at the machine it opened.
  static String? slotFromArgs(Map<String, Object?> args) {
    final slot = args['slot'];
    return slot is String && slot.isNotEmpty ? slot : null;
  }

  /// The engine a BROWSER tab addresses, resolving an absent one.
  ///
  /// A browser tab always names an engine, even when its args do not: a
  /// layout written before engines existed is a Chromium tab, because
  /// Chromium is the only browser those rigs ever ran. Leaving it null would
  /// make such a tab match ANY browser rig in the conversation — which is how
  /// closing an old tab could shut down the Firefox machine next to it.
  ///
  /// Null for the surfaces that have no engine at all.
  static RigBrowserEngine? browserEngineOf(Map<String, Object?> args) {
    if (args['surface'] != browser) {
      return null;
    }
    return engineFromArgs(args) ?? RigBrowserEngine.chromium;
  }

  /// The tab-strip icon for [surface].
  ///
  /// Delegates to the shared vocabulary in `rig_labels.dart` rather than
  /// re-deriving it: this switch and three others drifted apart the first
  /// time a phase was added.
  static IconData iconFor(String surface) =>
      rigSurfaceIcon(RigSurface.fromWire(surface));

  /// The localized tab label for [surface], naming [engine] when there is one
  /// and numbering the conversation's extra machines by [slotId].
  static String labelFor(
    AppLocalizations l10n,
    String surface, {
    RigBrowserEngine? engine,
    String? slotId,
  }) => rigMachineLabel(
    l10n,
    RigSurface.fromWire(surface),
    engine: engine,
    slotId: slotId,
  );

  /// The label a `[+]` menu row uses for [target] — the same names as
  /// [labelFor] with the "(VM)" suffix dropped.
  ///
  /// The suffix is not redundant chrome; it is what keeps a browser RIG from
  /// reading like the in-app webview next to it. In the menu the VIRTUAL
  /// MACHINE heading carries that job instead, and carries it better: the
  /// distinguishing word arrives before the group rather than at the end of
  /// every row, and it is said once rather than five times. A TAB has no
  /// heading above it, so [labelFor] keeps the suffix and this stays
  /// menu-only.
  ///
  /// Deliberately NOT numbered either, even though a press may open the
  /// conversation's second machine of that kind: the menu names a KIND of
  /// machine, and a standing entry that reads "Chromium 2" is a menu whose
  /// items rename themselves as you work. The number belongs on the things
  /// that identify ONE machine — its tab and its row in the sidebar's
  /// BROWSERS list.
  static String menuLabelFor(AppLocalizations l10n, RigTabTarget target) =>
      switch (target.surface) {
        // Named by ENGINE when there is one — "Browser" three times over would
        // be three rows a person cannot tell apart.
        browser =>
          target.engine == null ? l10n.rigMenuBrowser : target.engine!.label,
        mobile => l10n.rigMenuMobile,
        _ => l10n.rigMenuComputer,
      };

  /// Words a searchable `[+]` menu matches an enclosed-machine row on, so the
  /// term [menuLabelFor] dropped still finds it: typing "vm" must still reach
  /// "Chromium". The heading's own text is included because that IS the word
  /// the labels shed; "vm" rides along untranslated, as the abbreviation every
  /// locale's developers actually type.
  static String menuSearchKeywords(AppLocalizations l10n) =>
      '${l10n.ideMenuSectionVirtualMachine} vm';
}

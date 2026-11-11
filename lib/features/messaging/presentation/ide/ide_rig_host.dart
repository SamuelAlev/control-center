import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/rigs/presentation/browser_engine_logo.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_audio_controls.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the connected server's rig backends can host right now, read from
/// [rigCapabilitiesProvider]. Empty (and VM terminals off) while the probe has
/// not answered.
class IdeRigCapabilities {
  /// Creates a capability view.
  const IdeRigCapabilities({
    this.browserEngines = const {},
    this.surfaces = const {},
    this.hostsVmTerminals = false,
  });

  /// Reads the current capability probe.
  factory IdeRigCapabilities.read(WidgetRef ref) => ref
      .read(rigCapabilitiesProvider)
      .maybeWhen(
        data: (backends) => IdeRigCapabilities(
          browserEngines: {
            for (final b in backends)
              if (b.hostsBrowser) ...b.browserEngines,
          },
          surfaces: {for (final backend in backends) ...backend.surfaces},
          hostsVmTerminals: backends.any((b) => b.available && b.terminals),
        ),
        orElse: () => const IdeRigCapabilities(),
      );

  /// The browsers the server can boot. Empty until the probe has answered,
  /// which [RigTabSurfaces.targets] reads as "offer no browser yet".
  final Set<RigBrowserEngine> browserEngines;

  /// The rig surfaces the server advertises.
  final Set<String> surfaces;

  /// Whether the server can host a terminal inside an enclosed VM (QEMU
  /// present + the exec image downloaded).
  final bool hostsVmTerminals;
}

/// The messaging IDE's rig (machine) tabs: building them, finding the tab of
/// a machine and the `[+]` entries that open the next one.
///
/// A rig tab is a VIEWER, not the machine: closing it leaves the guest
/// running, and the sidebar's BROWSERS/COMPUTERS rows ([focusOrOpen]) are the
/// way back to it.
class IdeRigHost {
  /// Creates the host over the IDE's current `layout`.
  IdeRigHost({required this._layout});

  final EditorLayoutController Function() _layout;

  /// The rig tab for [target] — the one construction shared by the `[+]` menu
  /// and the General panel's rows, so a tab and its row can never disagree
  /// about args or identity.
  static EditorTab tabFor(AppLocalizations l10n, RigTabTarget target) =>
      EditorTab(
        kind: MessagingTabKinds.rig,
        label: RigTabSurfaces.labelFor(
          l10n,
          target.surface,
          engine: target.engine,
          slotId: target.slotId,
        ),
        icon: RigTabSurfaces.iconFor(target.surface),
        args: target.args,
        // One tab per MACHINE per conversation: a second tab on the same
        // machine would show it twice, while a "Firefox (VM)" beside a
        // "Chromium (VM)" — or a second WebKit machine beside the first — is
        // two machines on purpose, and the slot in the key says which.
        dedupKey: '${MessagingTabKinds.rig}:${target.dedupKey}',
      );

  /// The `[+]` target for [kind]: the lowest-numbered machine of that surface
  /// and engine that has no tab yet. `[+]` means "one I do not have open".
  RigTabTarget nextTarget(RigTabTarget kind) =>
      RigTabSurfaces.nextTarget(kind, [
        for (final tab in _layout().allTabs())
          if (tab.kind == MessagingTabKinds.rig) tab.args,
      ]);

  /// Shows [target]'s machine: its tab if one is open anywhere in the tree,
  /// otherwise a new tab on it in the active leaf.
  ///
  /// The match is surface + engine + SLOT, so a row never opens the tab beside
  /// its own. De-duped across the WHOLE tree: a machine already visible in a
  /// side pane is brought forward there, not mirrored into a second tab whose
  /// × the user would read as closing it.
  void focusOrOpen(AppLocalizations l10n, RigTabTarget target) {
    final layout = _layout();
    bool showsTarget(EditorTab t) =>
        t.kind == MessagingTabKinds.rig &&
        t.args['surface'] == target.surface &&
        RigTabSurfaces.browserEngineOf(t.args) ==
            RigTabSurfaces.browserEngineOf(target.args) &&
        RigTabSurfaces.slotFromArgs(t.args) == target.slotId;
    if (layout.focusTab(showsTarget)) {
      return;
    }
    layout.openInActiveLeaf(tabFor(l10n, target));
  }

  /// One `[+]` entry for a kind of machine — a surface, and one per browser
  /// engine, because a rig runs exactly one engine for its whole life.
  ///
  /// WHICH machine it opens is resolved on press ([nextTarget]): the tab set
  /// can change underneath an open menu, and a slot fixed while the menu was
  /// built would hand a second press the first press's machine. [mounted]
  /// guards the deferred open.
  CcMenuItem menuItem(
    AppLocalizations l10n,
    String leafId,
    RigTabTarget kind, {
    required bool enabled,
    required bool Function() mounted,
  }) => CcMenuItem(
    label: RigTabSurfaces.menuLabelFor(l10n, kind),
    icon: RigTabSurfaces.iconFor(kind.surface),
    searchText: RigTabSurfaces.menuSearchKeywords(l10n),
    // A browser entry leads with its engine's logo — the whole reason to open
    // a second browser rig is to tell the engines apart.
    leading: kind.engine == null
        ? null
        : (color) =>
              BrowserEngineLogo(engine: kind.engine!, size: 16, color: color),
    enabled: enabled,
    onSelected: () => WidgetsBinding.instance.addPostFrameCallback((_) {
      // Deferred a frame: the menu is still tearing its overlay down, and
      // mounting a rig's platform view inside that pointer phase trips the
      // mouse tracker.
      if (!mounted()) {
        return;
      }
      _layout().setActiveLeaf(leafId);
      // Focus-or-open rather than open: on the phone surface every press
      // names the one device, so a second press must show that tab instead of
      // stacking a duplicate view of it.
      focusOrOpen(l10n, nextTarget(kind));
    }),
  );

  /// A browser-rig tab leads with its engine's monochrome logo, so "Firefox
  /// (VM)" and "Chromium (VM)" are told apart at a glance. Null for any other
  /// tab.
  static Widget Function(Color color)? leadingFor(EditorTab tab) =>
      tab.kind == MessagingTabKinds.rig &&
          tab.args['surface'] == RigTabSurfaces.browser
      ? (color) => BrowserEngineLogo(
          engine:
              RigTabSurfaces.browserEngineOf(tab.args) ??
              RigBrowserEngine.fallback,
          color: color,
        )
      : null;

  /// A rig tab's trailing audio indicators. Null for any other tab.
  static Widget Function(Color color)? trailingFor(EditorTab tab) {
    if (tab.kind != MessagingTabKinds.rig) {
      return null;
    }
    final surface = _surfaceOf(tab);
    return (color) => RigTabAudioIndicators(
      tabKey: tab,
      color: color,
      supportsOutput: RigTabSurfaces.supportsAudioOutput(surface),
      supportsMicrophone: RigTabSurfaces.supportsMicrophone(surface),
    );
  }

  /// A rig tab's context-menu audio controls.
  static List<CcMenuItem> contextMenuItems({
    required BuildContext context,
    required WidgetRef ref,
    required EditorTab tab,
  }) {
    final surface = _surfaceOf(tab);
    return rigTabAudioMenuItems(
      context: context,
      ref: ref,
      tabKey: tab,
      supportsOutput: RigTabSurfaces.supportsAudioOutput(surface),
      supportsMicrophone: RigTabSurfaces.supportsMicrophone(surface),
    );
  }

  static String _surfaceOf(EditorTab tab) =>
      tab.args['surface'] as String? ?? RigTabSurfaces.computer;
}

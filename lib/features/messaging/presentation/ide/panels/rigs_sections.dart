import 'dart:async';

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/space_browser_tabs_provider.dart';
import 'package:control_center/features/rigs/presentation/browser_engine_logo.dart';
import 'package:control_center/features/rigs/presentation/rig_labels.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The BROWSERS section of the messaging IDE's General panel: one row per
/// HOST web-browser tab attached to this conversation (the in-app webview,
/// closed with the hover ×) above one row per browser machine (leading with
/// the engine's monochrome logo — with three engines a globe on every row is
/// three rows a person cannot tell apart). Tapping a row focuses (or opens)
/// its tab.
class BrowsersSection extends ConsumerWidget {
  /// Creates a [BrowsersSection].
  const BrowsersSection({
    super.key,
    required this.spaceId,
    required this.workspaceId,
    required this.onFocusRig,
    required this.onFocusBrowserTab,
    required this.onCloseBrowserTab,
  });

  /// The active conversation.
  final String spaceId;

  /// The active workspace.
  final String workspaceId;

  /// Focuses (or opens) the rig tab for the tapped machine.
  final ValueChanged<RigTabTarget> onFocusRig;

  /// Focuses the host web-browser tab its row was tapped for.
  final ValueChanged<String> onFocusBrowserTab;

  /// Closes the host web-browser tab its hover × was pressed on.
  final ValueChanged<String> onCloseBrowserTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final watched = ref.watch(rigSessionsProvider(workspaceId)).asData?.value;
    final rigs = [
      for (final r in watched ?? const <RigView>[])
        if (r.conversationId == spaceId &&
            r.surface == RigTabSurfaces.browser &&
            r.phaseKind != RigPhase.closed)
          r,
    ];
    // Stable engine order, not boot order: a rebooting machine must not
    // reshuffle the list. Within one engine, by slot for the same reason —
    // a conversation can hold several machines of one engine and their order
    // must not depend on which finished booting first.
    rigs.sort((a, b) {
      final byEngine = (a.browserEngine ?? RigBrowserEngine.fallback).index
          .compareTo((b.browserEngine ?? RigBrowserEngine.fallback).index);
      return byEngine != 0
          ? byEngine
          : (a.slotId ?? '').compareTo(b.slotId ?? '');
    });
    final hostBrowsers = ref.watch(spaceBrowserTabsProvider(spaceId));
    return CollapsibleSidebarSection(
      icon: AppIcons.browser,
      label: l10n.generalSectionBrowsers,
      count: rigs.isEmpty && hostBrowsers.isEmpty
          ? null
          : '${rigs.length + hostBrowsers.length}',
      child: rigs.isEmpty && hostBrowsers.isEmpty
          ? SidebarEmptyRow(message: l10n.generalBrowsersEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The host's in-app webviews sit above the VMs: they are the
                // light browsers, and the row order mirrors the `[+]` menu,
                // where "Web browser" precedes the engine entries.
                for (final browser in hostBrowsers)
                  _HostBrowserRow(
                    mirror: browser,
                    onTap: () => onFocusBrowserTab(browser.tabId),
                    onClose: () => onCloseBrowserTab(browser.tabId),
                  ),
                for (final rig in rigs)
                  _RigRow(
                    workspaceId: workspaceId,
                    rig: rig,
                    name: rigMachineLabel(
                      l10n,
                      rig.surfaceKind,
                      engine: rig.browserEngine ?? RigBrowserEngine.fallback,
                      slotId: rig.slotId,
                    ),
                    logo: BrowserEngineLogo(
                      engine: rig.browserEngine ?? RigBrowserEngine.fallback,
                      color: t.textSecondary,
                    ),
                    onTap: () => onFocusRig(
                      RigTabTarget(
                        RigTabSurfaces.browser,
                        engine: rig.browserEngine ?? RigBrowserEngine.fallback,
                        // The row's own machine, not "a browser of that
                        // engine": with two WebKit machines open, a row that
                        // dropped its slot would focus whichever tab came
                        // first and leave the other one unreachable.
                        slotId: rig.slotId,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The COMPUTERS section of the messaging IDE's General panel: one row per
/// desktop machine attached to this conversation. Exec rigs are excluded on
/// purpose — they are the terminals' machines and already surface in the
/// TERMINALS section.
class ComputersSection extends ConsumerWidget {
  /// Creates a [ComputersSection].
  const ComputersSection({
    super.key,
    required this.spaceId,
    required this.workspaceId,
    required this.onFocusRig,
  });

  /// The active conversation.
  final String spaceId;

  /// The active workspace.
  final String workspaceId;

  /// Focuses (or opens) the rig tab for the tapped machine.
  final ValueChanged<RigTabTarget> onFocusRig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final watched = ref.watch(rigSessionsProvider(workspaceId)).asData?.value;
    final rigs = [
      for (final r in watched ?? const <RigView>[])
        if (r.conversationId == spaceId &&
            r.surface == RigTabSurfaces.computer &&
            !r.isExec &&
            r.phaseKind != RigPhase.closed)
          r,
    ];
    // By slot, not by boot time: the number in a row's name comes from its
    // slot, so ordering by anything else puts "Computer 3" above "Computer 2".
    rigs.sort((a, b) => (a.slotId ?? '').compareTo(b.slotId ?? ''));
    return CollapsibleSidebarSection(
      icon: AppIcons.monitor,
      label: l10n.generalSectionComputers,
      count: rigs.isEmpty ? null : '${rigs.length}',
      child: rigs.isEmpty
          ? SidebarEmptyRow(message: l10n.generalComputersEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final rig in rigs)
                  _RigRow(
                    workspaceId: workspaceId,
                    rig: rig,
                    name: rigMachineLabel(
                      l10n,
                      rig.surfaceKind,
                      slotId: rig.slotId,
                    ),
                    logo: Icon(
                      AppIcons.monitor,
                      size: 14,
                      color: t.textSecondary,
                    ),
                    onTap: () => onFocusRig(
                      RigTabTarget(RigTabSurfaces.computer, slotId: rig.slotId),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The PHONES section of the messaging IDE's General panel: the Android device
/// this conversation is driving, when it has one.
///
/// At most one row, and never numbered: the mobile surface drives the HOST's
/// attached device, so a conversation has exactly one phone (`RigSpec` refuses
/// a slot there). It exists for the same reason as the others — closing a rig
/// tab leaves its machine running, so without a row here a phone kept in the
/// background would have no way back to it.
class PhonesSection extends ConsumerWidget {
  /// Creates a [PhonesSection].
  const PhonesSection({
    super.key,
    required this.spaceId,
    required this.workspaceId,
    required this.onFocusRig,
  });

  /// The active conversation.
  final String spaceId;

  /// The active workspace.
  final String workspaceId;

  /// Focuses (or opens) the rig tab for the tapped machine.
  final ValueChanged<RigTabTarget> onFocusRig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final watched = ref.watch(rigSessionsProvider(workspaceId)).asData?.value;
    final rigs = [
      for (final r in watched ?? const <RigView>[])
        if (r.conversationId == spaceId &&
            r.surface == RigTabSurfaces.mobile &&
            r.phaseKind != RigPhase.closed)
          r,
    ];
    return CollapsibleSidebarSection(
      icon: AppIcons.smartphone,
      label: l10n.generalSectionPhones,
      count: rigs.isEmpty ? null : '${rigs.length}',
      child: rigs.isEmpty
          ? SidebarEmptyRow(message: l10n.generalPhonesEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final rig in rigs)
                  _RigRow(
                    workspaceId: workspaceId,
                    rig: rig,
                    name: rigMachineLabel(l10n, rig.surfaceKind),
                    logo: Icon(
                      AppIcons.smartphone,
                      size: 14,
                      color: t.textSecondary,
                    ),
                    onTap: () =>
                        onFocusRig(const RigTabTarget(RigTabSurfaces.mobile)),
                  ),
              ],
            ),
    );
  }
}

/// One machine row: a phase-tinted status dot, the surface's logo, its name
/// and — while the machine is anywhere but ready — the phase as text, so the
/// state never rides on the dot's color alone. A machine that exists to stop
/// also carries the power button, so it can be shut down from the list
/// instead of only from its tab.
class _RigRow extends ConsumerWidget {
  const _RigRow({
    required this.workspaceId,
    required this.rig,
    required this.name,
    required this.logo,
    required this.onTap,
  });

  /// The workspace the rig belongs to — what scopes its destroy call.
  final String workspaceId;

  final RigView rig;
  final String name;
  final Widget logo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final ready = rig.phaseKind == RigPhase.ready;
    // A closing machine is already going down and a failed one is gone;
    // neither has anything left for a stop button to stop.
    final stoppable = rig.isLive || rig.isStarting;
    return CcTappable(
      onPressed: onTap,
      semanticLabel: l10n.focusMachine,
      // A flat hover wash instead of an ink ripple — the design system reports
      // state through color, not motion.
      builder: (context, states) => ColoredBox(
        color: states.contains(WidgetState.hovered)
            ? t.bgSecondaryHover
            : const Color(0x00000000),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 5,
          ),
          child: Row(
            children: [
              CcStatusDot(tone: rigPhaseTone(rig.phaseKind)),
              const SizedBox(width: AppSpacing.sm),
              logo,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
              ),
              if (!ready)
                Text(
                  rigPhaseLabel(l10n, rig),
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, color: t.textQuaternary),
                ),
              if (stoppable) ...[
                if (!ready) const SizedBox(width: AppSpacing.xs),
                _RigStopButton(workspaceId: workspaceId, rig: rig),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One HOST web-browser row: the conversation's in-app webview — a browser on
/// the host, not a machine. A live dot and the globe (the same positive-dot
/// vocabulary as the TERMINALS rows: there is no boot phase to report), the
/// tab's name, and an × that appears on hover to close the tab — the row
/// counterpart of the rig rows' power glyph, which does the same for a
/// machine.
class _HostBrowserRow extends StatelessWidget {
  const _HostBrowserRow({
    required this.mirror,
    required this.onTap,
    required this.onClose,
  });

  final BrowserTabMirror mirror;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      onPressed: onTap,
      semanticLabel: l10n.focusBrowser,
      // A flat hover wash instead of an ink ripple — the design system reports
      // state through color, not motion.
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return ColoredBox(
          color: hovered ? t.bgSecondaryHover : const Color(0x00000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 5,
            ),
            child: Row(
              children: [
                const CcStatusDot(tone: CcStatusTone.positive),
                const SizedBox(width: AppSpacing.sm),
                Icon(AppIcons.globe, size: 14, color: t.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    mirror.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textSecondary),
                  ),
                ),
                // Hover only: the row reads clean at rest, and closing the tab
                // is the one action a host browser row carries.
                if (hovered) _HostBrowserCloseButton(onClose: onClose),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The host browser row's close control: the × glyph alone, named by its
/// tooltip. Sized like [_RigStopButton] — see its comment for why this is not
/// CcIconButton.
class _HostBrowserCloseButton extends StatelessWidget {
  const _HostBrowserCloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.close,
      child: CcTooltip(
        message: l10n.close,
        child: CcTappable(
          onPressed: onClose,
          borderRadius: AppRadii.brSm,
          builder: (context, states) => Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              AppIcons.x,
              size: 14,
              color: states.contains(WidgetState.hovered)
                  ? t.textPrimary
                  : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// The row's shutdown control: the power glyph alone, named by its tooltip.
///
/// Deliberately NOT CcIconButton — its 32px box would tower over these dense
/// rows; this sidebar's idiom for an in-row action is the 14px glyph (the
/// agent rows' pause control and the goal rows' run controls do the same).
class _RigStopButton extends ConsumerWidget {
  const _RigStopButton({required this.workspaceId, required this.rig});

  final String workspaceId;
  final RigView rig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.rigStopMachine,
      child: CcTooltip(
        message: l10n.rigStopMachine,
        child: CcTappable(
          onPressed: () => unawaited(_stop(ref)),
          borderRadius: AppRadii.brSm,
          builder: (context, states) => Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              AppIcons.power,
              size: 14,
              color: states.contains(WidgetState.hovered)
                  ? t.textPrimary
                  : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _stop(WidgetRef ref) async {
    final toastContext = ref.context;
    try {
      await ref.read(rigRepositoryProvider).destroy(workspaceId, rig.id);
    } on Object catch (e) {
      if (toastContext.mounted) {
        CcToastScope.maybeOf(
          toastContext,
        )?.show('$e', variant: CcToastVariant.danger);
      }
    }
  }
}

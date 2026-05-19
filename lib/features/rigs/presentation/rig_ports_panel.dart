// The forwarded-ports control for a Terminal (VM), VS Code / Cursor style.
//
// A plug-icon trigger with a badge, opening a popover that lists every port
// listening inside the machine and every address it answers on: the host
// `localhost:<port>`, an optional LAN share, and a dev domain reachable in the
// conversation's Browser (VM). All the plumbing is server-side — this widget
// only reads the pushed snapshot and calls the mutation ops.
library;

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_port_rows.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The plug-icon trigger + count badge that opens the ports popover.
///
/// Renders nothing until the conversation has a live exec (terminal) rig —
/// there is no machine to have ports before then, and an empty affordance on
/// a host shell would be a promise the host cannot keep.
class RigPortsButton extends ConsumerWidget {
  /// Creates a [RigPortsButton] for [conversationId] in [workspaceId].
  const RigPortsButton({
    super.key,
    required this.workspaceId,
    required this.conversationId,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The conversation whose Terminal (VM) this reports on.
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (workspaceId.isEmpty || conversationId.isEmpty) {
      return const SizedBox.shrink();
    }
    final rig = ref.watch(
      conversationExecRigProvider((
        workspaceId: workspaceId,
        conversationId: conversationId,
      )),
    );
    if (rig == null) {
      return const SizedBox.shrink();
    }
    return _PortsTrigger(workspaceId: workspaceId, rig: rig);
  }
}

class _PortsTrigger extends ConsumerWidget {
  const _PortsTrigger({required this.workspaceId, required this.rig});

  final String workspaceId;
  final RigView rig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final ports = ref.watch(
      rigPortsProvider((workspaceId: workspaceId, rigId: rig.id)),
    );
    final count = ports.maybeWhen(
      data: (view) => view.ports.length,
      orElse: () => 0,
    );
    return CcPopover(
      semanticLabel: l10n.rigPortsTooltip,
      targetAnchor: Alignment.topRight,
      followerAnchor: Alignment.bottomRight,
      offset: const Offset(0, -6),
      // Inert target (see the CcPopover gotcha): a button here would swallow
      // the toggle tap, so it is a plain icon the popover drives.
      target: CcTooltip(
        message: l10n.rigPortsTooltip,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(AppIcons.plug, size: 16, color: t.fgSecondary),
              if (count > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.bgPrimary, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      overlayBuilder: (context, controller) =>
          _PortsPopover(workspaceId: workspaceId, rig: rig),
    );
  }
}

class _PortsPopover extends ConsumerWidget {
  const _PortsPopover({required this.workspaceId, required this.rig});

  final String workspaceId;
  final RigView rig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(
      rigPortsProvider((workspaceId: workspaceId, rigId: rig.id)),
    );
    final view = async.maybeWhen(data: (v) => v, orElse: () => null);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              l10n.rigPortsTitle.toUpperCase(),
              style: CcTypography.caption.copyWith(
                color: t.textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Flexible(
            child: view == null
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CcSpinner()),
                  )
                : view.ports.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Text(
                      l10n.rigPortsEmpty,
                      style: CcTypography.caption.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      for (final port in view.ports)
                        PortRow(
                          workspaceId: workspaceId,
                          rigId: rig.id,
                          port: port,
                          domainTls: view.tlsEnabled,
                        ),
                    ],
                  ),
          ),
          const CcDivider(),
          AddPortRow(workspaceId: workspaceId, rigId: rig.id),
          AutoForwardRow(
            workspaceId: workspaceId,
            rigId: rig.id,
            enabled: view?.autoForward ?? true,
          ),
        ],
      ),
    );
  }
}

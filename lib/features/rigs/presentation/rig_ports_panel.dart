// The forwarded-ports control for a Terminal (VM) or host-shell, VS Code /
// Cursor style.
//
// A plug-icon trigger with a badge, opening a popover that lists every port
// listening in this space's terminal and every address it answers on: the
// host `localhost:<port>`, an optional LAN share, and whether the
// conversation's Browser (VM) / Android can reach it. All the plumbing is
// server-side — this widget only reads the pushed snapshot and calls the
// mutation ops.
library;

import 'package:cc_data/cc_data.dart' show RigPortsView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_port_rows.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The plug-icon trigger + count badge that opens the ports popover.
///
/// Pass [sessionId] for a host-shell PTY. Omit it for a Terminal (VM), which
/// still resolves the conversation's live exec rig. Renders nothing until
/// there is a source to watch.
class RigPortsButton extends ConsumerWidget {
  /// Creates a [RigPortsButton] for [conversationId] in [workspaceId].
  const RigPortsButton({
    super.key,
    required this.workspaceId,
    required this.conversationId,
    this.sessionId,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The conversation (space) whose ports this reports on.
  final String conversationId;

  /// The server PTY session id, when this is a host-shell terminal.
  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (workspaceId.isEmpty || conversationId.isEmpty) {
      return const SizedBox.shrink();
    }
    final sessionId = this.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      return _PortsTrigger(
        target: PortsTarget.session(
          workspaceId: workspaceId,
          sessionId: sessionId,
          spaceId: conversationId,
        ),
      );
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
    return _PortsTrigger(
      target: PortsTarget.rig(workspaceId: workspaceId, rigId: rig.id),
    );
  }
}

class _PortsTrigger extends ConsumerWidget {
  const _PortsTrigger({required this.target});

  final PortsTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tooltip = target.isSession
        ? l10n.rigPortsTooltipHost
        : l10n.rigPortsTooltip;
    final async = _watchPorts(ref, target);
    final count = async.maybeWhen(
      data: (view) => view.ports.length,
      orElse: () => 0,
    );
    return CcPopover(
      semanticLabel: tooltip,
      targetAnchor: AlignmentDirectional.topEnd,
      followerAnchor: AlignmentDirectional.bottomEnd,
      offset: const Offset(0, -6),
      // Inert target (see the CcPopover gotcha): a button here would swallow
      // the toggle tap, so it is a plain icon the popover drives.
      target: CcTooltip(
        message: tooltip,
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
                PositionedDirectional(
                  end: -5,
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
          _PortsPopover(target: target),
    );
  }
}

AsyncValue<RigPortsView> _watchPorts(WidgetRef ref, PortsTarget target) {
  if (target.isSession) {
    return ref.watch(
      terminalPortsProvider((
        workspaceId: target.workspaceId,
        sessionId: target.sessionId!,
        spaceId: target.spaceId,
      )),
    );
  }
  return ref.watch(
    rigPortsProvider((workspaceId: target.workspaceId, rigId: target.rigId!)),
  );
}

class _PortsPopover extends ConsumerWidget {
  const _PortsPopover({required this.target});

  final PortsTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = _watchPorts(ref, target);
    final view = async.maybeWhen(data: (v) => v, orElse: () => null);
    final empty = target.isSession ? l10n.rigPortsEmptyHost : l10n.rigPortsEmpty;
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
                      empty,
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
                          target: target,
                          port: port,
                          domainTls: view.tlsEnabled,
                          browserReachable: view.browserReachable,
                          androidReachable: view.androidReachable,
                        ),
                    ],
                  ),
          ),
          const CcDivider(),
          AddPortRow(target: target),
          AutoForwardRow(
            target: target,
            enabled: view?.autoForward ?? true,
          ),
        ],
      ),
    );
  }
}

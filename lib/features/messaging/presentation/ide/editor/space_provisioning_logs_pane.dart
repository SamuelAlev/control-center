import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_provisioning_log_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/live_log_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A preparation log tab's body from its [args], or nothing when they name
/// another workspace or are incomplete.
Widget spaceProvisioningLogsTabBody(
  Map<String, Object?> args,
  String? workspaceId,
) {
  final tabWorkspaceId = args['workspaceId'] as String?;
  final spaceId = args['spaceId'] as String?;
  if (tabWorkspaceId == null ||
      tabWorkspaceId != workspaceId ||
      spaceId == null) {
    return const SizedBox.shrink();
  }
  return SpaceProvisioningLogsPane(
    workspaceId: tabWorkspaceId,
    spaceId: spaceId,
  );
}

/// What a space's workspace preparation printed: the copy, the fetch, the
/// checkout and any `provision` tasks, live while it runs.
///
/// Read-only. Closing it leaves the preparation running; stopping that is the
/// banner's job.
class SpaceProvisioningLogsPane extends ConsumerWidget {
  /// Creates a [SpaceProvisioningLogsPane].
  const SpaceProvisioningLogsPane({
    super.key,
    required this.workspaceId,
    required this.spaceId,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The space being prepared.
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final logs = ref.watch(
      spaceProvisioningLogLinesProvider((
        workspaceId: workspaceId,
        spaceId: spaceId,
      )),
    );
    final lines = logs.value ?? const <String>[];
    if (logs.hasError && lines.isEmpty) {
      return CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: l10n.failedToLoadLogs('${logs.error}'),
      );
    }
    final status = ref.watch(spaceProvisioningStatusProvider(spaceId));
    return LiveLogView(
      title: _StatusTitle(spaceId: spaceId, status: status),
      lines: lines,
      // Logs live in the server's memory, so a space prepared before its last
      // restart has none, and nothing more is coming.
      emptyMessage: status == SpaceProvisioningStatus.provisioning
          ? l10n.environmentLogsWaiting
          : l10n.noExecutionLogsYet,
      onCopy: (text) => copyEnvironmentText(context, text),
    );
  }
}

/// The preparation's current state, in the banner's words.
class _StatusTitle extends ConsumerWidget {
  const _StatusTitle({required this.spaceId, required this.status});

  final String spaceId;
  final SpaceProvisioningStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final preparing = status == SpaceProvisioningStatus.provisioning;
    final label = switch (status) {
      SpaceProvisioningStatus.provisioning => provisioningStepLabel(
        l10n,
        ref.watch(spaceProvisioningStepProvider(spaceId)),
      ),
      SpaceProvisioningStatus.failed => l10n.workspacePrepFailed,
      SpaceProvisioningStatus.cancelled => l10n.workspacePrepStopped,
      SpaceProvisioningStatus.ready => l10n.spaceSetupLogs,
    };
    return Row(
      children: [
        if (preparing) ...[
          const CcSpinner(size: 12),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        ),
      ],
    );
  }
}

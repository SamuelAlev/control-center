import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_run_viewer_dialog.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One run in an agent's log list: its status and times, the viewer for its
/// recorded events, and Stop while it is live.
class AgentRunRow extends ConsumerWidget {
  /// Creates the row for [log].
  const AgentRunRow({super.key, required this.log, required this.workspaceId});

  /// The run.
  final AgentRunLog log;

  /// The workspace the run belongs to — scopes the host-side log read (a run
  /// row's own `workspaceId` is nullable, so it cannot be the only source).
  final String workspaceId;

  CcBadgeVariant get _variant => switch (log.status) {
    RunStatus.completed => CcBadgeVariant.success,
    RunStatus.error => CcBadgeVariant.danger,
    _ => CcBadgeVariant.neutral,
  };

  IconData get _icon => switch (log.status) {
    RunStatus.completed => AppIcons.checkCircle,
    RunStatus.error => AppIcons.xCircle,
    _ => AppIcons.loader,
  };

  String _durationText() {
    if (log.completedAt == null) {
      return 'Running…';
    }
    final dur = log.completedAt!.difference(log.startedAt);
    if (dur.inSeconds < 60) {
      return '${dur.inSeconds}s';
    }
    if (dur.inMinutes < 60) {
      return '${dur.inMinutes}m ${dur.inSeconds % 60}s';
    }
    return '${dur.inHours}h ${dur.inMinutes % 60}m';
  }

  String _formatDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  /// Asks the host to stop the run. A not-found answer means the run is gone
  /// (it already ended, or it is in a space this viewer may no longer read):
  /// the list refreshes and nothing is reported as a failure.
  Future<void> _stop(WidgetRef ref) async {
    try {
      await ref
          .read(remoteAgentRunLogOpsProvider)
          .stop(log.workspaceId ?? workspaceId, log.id);
    } on RemoteRpcException catch (e) {
      if (e.code != RpcErrorCodes.notFound) {
        rethrow;
      }
      ref.invalidate(agentRunLogsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.isRunning)
            CcSpinner(size: 18, color: tokens.textPrimary)
          else
            Icon(
              _icon,
              size: 18,
              color: log.status == RunStatus.completed
                  ? tokens.success
                  : log.status == RunStatus.error
                  ? tokens.danger
                  : tokens.textTertiary,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CcBadge(
                      variant: _variant,
                      label: log.status.name.toUpperCase(),
                    ),
                    const Spacer(),
                    Text(
                      _durationText(),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AppTimestamp(
                  dateTime: log.startedAt,
                  child: Text(
                    'Started: ${_formatDate(log.startedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
                if (log.completedAt != null)
                  AppTimestamp(
                    dateTime: log.completedAt!,
                    child: Text(
                      'Completed: ${_formatDate(log.completedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ),
                if (log.pid != null)
                  Text(
                    'PID: ${log.pid}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      fontFamily: 'monospace',
                      color: tokens.textTertiary,
                    ),
                  ),
                if (log.adapter != null)
                  Text(
                    'Adapter: ${log.adapter}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: tokens.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (log.logPath != null)
                CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  onPressed: () => showCcDialog<void>(
                    context: context,
                    builder: (_) => AgentRunViewerDialog(
                      runId: log.id,
                      logPath: log.logPath!,
                      workspaceId: log.workspaceId ?? workspaceId,
                    ),
                  ),
                  icon: AppIcons.scrollText,
                  child: Text(l10n.viewLabel),
                ),
              if (log.isRunning && log.pid != null)
                CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  // The host stops the process and settles the run as
                  // stopped by a person; the client writes no run log.
                  onPressed: () => _stop(ref),
                  icon: AppIcons.square,
                  child: Text(l10n.stop),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

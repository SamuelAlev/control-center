import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// The agent registry's "Logs" tab: one agent's run history, the kill control
/// for anything still running, and the per-run NDJSON viewer.
///
/// Split out of `agent_registry_screen.dart`, which was over a thousand lines
/// against a 250-line convention. Nothing here is shared with the roster or the
/// config form, so it is a file rather than a region.
class AgentLogsTab extends ConsumerWidget {
  /// Creates an [AgentLogsTab] for [agent].
  const AgentLogsTab({super.key, required this.agent});

  /// The agent whose runs to list.
  final Agent agent;

  /// Asks the HOST to stop every process belonging to this agent.
  ///
  /// The agent's processes live in the SERVER's process table, so this is one
  /// RPC op, not a local `Process.killPid` loop: killing pids client-side only
  /// ever worked when the server happened to be co-located, and against a
  /// remote server it silently killed nothing (or an unrelated recycled pid on
  /// the operator's own machine).
  Future<void> _killAgentProcesses(WidgetRef ref) async {
    await ref
        .read(remoteAgentOpsProvider)
        .killProcesses(agent.workspaceId, agent.id);
    ref.invalidate(
      agentRunLogsProvider((workspaceId: agent.workspaceId, agentId: agent.id)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(
      agentRunLogsProvider((workspaceId: agent.workspaceId, agentId: agent.id)),
    );
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return logsAsync.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(child: Text(l10n.failedToLoadLogs('$e'))),
      data: (logs) {
        final runningCount = logs.where((l) => l.isRunning).length;
        final hasRunning = runningCount > 0;

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.scrollText, size: 40, color: tokens.textTertiary),
                const SizedBox(height: 8),
                Text(
                  l10n.noExecutionLogsYet,
                  style: TextStyle(fontSize: 14, color: tokens.textTertiary),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${l10n.runsLabel}${hasRunning ? ' ($runningCount ${l10n.runningLabel})' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textTertiary,
                    ),
                  ),
                  if (hasRunning) ...[
                    const Spacer(),
                    CcButton(
                      variant: CcButtonVariant.destructive,
                      size: CcButtonSize.sm,
                      onPressed: () => unawaited(_killAgentProcesses(ref)),
                      icon: AppIcons.skull,
                      child: Text(l10n.killRunning),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: logs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _RunRow(log: logs[i], workspaceId: agent.workspaceId),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shows one run's recorded NDJSON events.
///
/// The log file lives in the SERVER's data directory, so its contents are
/// fetched with an RPC op. This dialog used to `File(...).readAsLines()` the
/// path directly, which rendered an empty list with no error whenever the
/// server was not the local machine.
class _RunViewerDialog extends ConsumerStatefulWidget {
  const _RunViewerDialog({
    required this.runId,
    required this.logPath,
    required this.workspaceId,
  });

  /// The run whose log to read (the server resolves the file from this).
  final String runId;

  /// The server-side path — displayed as the dialog title only, never opened.
  final String logPath;

  /// The workspace the run belongs to (scopes the read).
  final String workspaceId;

  @override
  ConsumerState<_RunViewerDialog> createState() => _RunViewerDialogState();
}

class _RunViewerDialogState extends ConsumerState<_RunViewerDialog> {
  late Future<List<Map<String, dynamic>>> _events;

  @override
  void initState() {
    super.initState();
    _events = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final read = await ref
        .read(remoteAgentRunLogOpsProvider)
        .readEvents(widget.workspaceId, widget.runId);
    return [
      if (read.truncated)
        {'type': 'raw', 'content': '… (older lines trimmed by the server)'},
      ...read.events,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: tokens.borderPrimary),
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.scrollText,
                      size: 16,
                      color: tokens.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.basename(widget.logPath),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    CcIconButton(
                      icon: AppIcons.x,
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const CcDivider(),
              Flexible(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _events,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CcSpinner());
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to read log: ${snap.error}',
                          style: TextStyle(color: tokens.textErrorPrimary),
                        ),
                      );
                    }
                    final events = snap.data ?? const [];
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: events.length,
                      itemBuilder: (_, i) {
                        final e = events[i];
                        final type = (e['type'] as String?) ?? 'raw';
                        final ts = e['ts'] as String?;
                        final content =
                            (e['content'] as String?) ??
                            e['eventType']?.toString() ??
                            '';
                        Color color = tokens.textPrimary;
                        if (type == 'start') {
                          color = tokens.textPrimary;
                        }
                        if (type == 'end') {
                          color = tokens.success;
                        }
                        if (type == 'event' && e['eventType'] == 'error') {
                          color = tokens.textErrorPrimary;
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: tokens.textPrimary,
                              ),
                              children: [
                                if (ts != null)
                                  TextSpan(
                                    text: '${ts.substring(11, 19)}  ',
                                    style: TextStyle(
                                      color: tokens.textTertiary,
                                    ),
                                  ),
                                TextSpan(
                                  text: '$type ',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (type == 'event')
                                  TextSpan(
                                    text: '${e['eventType']} ',
                                    style: TextStyle(
                                      color: tokens.textTertiary,
                                    ),
                                  ),
                                TextSpan(text: content),
                                if (e['exitCode'] != null)
                                  TextSpan(
                                    text: ' exit=${e['exitCode']}',
                                    style: TextStyle(color: color),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunRow extends ConsumerWidget {
  const _RunRow({required this.log, required this.workspaceId});
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
                    builder: (_) => _RunViewerDialog(
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
                  onPressed: () async {
                    await ref.read(processControlPortProvider).kill(log.pid!);
                    await ref
                        .read(agentRunLogRepositoryProvider)
                        .upsert(
                          log.copyWith(
                            status: RunStatus.error,
                            completedAt: DateTime.now(),
                            summary: 'Killed by user',
                          ),
                        );
                  },
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

import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/domain/usecases/create_agent.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/memory/presentation/widgets/agent_working_memory_panel.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_form_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/settings_shortcuts.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

final _skillNamesProvider = FutureProvider.family<List<String>, String>((
  ref,
  workspaceId,
) async {
  final fs = ref.read(workspaceFilesystemPortProvider);
  return fs.listSkillSlugs(workspaceId);
});

/// Settings screen for managing agent registry and agent details.
class AgentsSettings extends ConsumerStatefulWidget {
  /// Creates a new [AgentsSettings].
  const AgentsSettings({super.key});

  @override
  ConsumerState<AgentsSettings> createState() => _AgentsSettingsState();
}

class _AgentsSettingsState extends ConsumerState<AgentsSettings> {
  String? _selectedAgentId;
  final _filterCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filterCtl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _filterCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agentsAsync = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId))
        : ref.watch(agentsProvider);
    final selectedAgentForDelete = agentsAsync.value
        ?.where((a) => a.id == _selectedAgentId)
        .firstOrNull;

    return SettingsShortcuts(
      extraBindings: {
        'settings.agents-new': _createUnnamedAgent,
        if (selectedAgentForDelete != null)
          'settings.agents-delete': () => _deleteAgent(selectedAgentForDelete),
      },
      child: PageWrapper(
      title: l10n.agentRegistry,
      subtitle: l10n.configureAgentIdentities,
      actions: [
        FButton(
          onPress: _createUnnamedAgent,
          mainAxisSize: MainAxisSize.min,
          prefix: const Icon(LucideIcons.plus, size: 14),
          child: Text(l10n.addAgent),
        ),
      ],
      child: agentsAsync.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(child: Text(l10n.failedToLoadAgents('$e'))),
        data: (agents) {
          if (_selectedAgentId != null &&
              !agents.any((a) => a.id == _selectedAgentId)) {
            _selectedAgentId = agents.isNotEmpty ? agents.first.id : null;
          }
          if (_selectedAgentId == null && agents.isNotEmpty) {
            _selectedAgentId = agents.first.id;
          }
          final selectedAgent = agents
              .where((a) => a.id == _selectedAgentId)
              .firstOrNull;
          final filter = _filterCtl.text.toLowerCase();
          final filteredAgents = agents
              .where(
                (a) =>
                    a.name.toLowerCase().contains(filter) ||
                    a.title.toLowerCase().contains(filter),
              )
              .toList();

          final workspaceId = ref.read(activeWorkspaceIdProvider);
          final availableSkills = workspaceId != null
              ? (ref.watch(_skillNamesProvider(workspaceId)).value ??
                    const <String>[])
              : const <String>[];

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 260,
                  child: _AgentListPane(
                    agents: filteredAgents,
                    selectedAgentId: selectedAgent?.id,
                    filterController: _filterCtl,
                    onAgentSelected: (id) =>
                        setState(() => _selectedAgentId = id),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: selectedAgent != null
                      ? _AgentDetailPane(
                          key: ValueKey(selectedAgent.id),
                          agent: selectedAgent,
                          availableSkills: availableSkills,
                          onOpenFolder: () => _openAgentFolder(selectedAgent),
                          onDelete: () => _deleteAgent(selectedAgent),
                        )
                      : _EmptyState(onCreate: _createUnnamedAgent),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Future<void> _createUnnamedAgent() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(agentRepositoryProvider);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final fsService = ref.read(workspaceFilesystemPortProvider);
    try {
      final agent = await CreateAgentUseCase(
        repository: repo,
        filesystemService: fsService,
      ).execute(
        CreateAgentCommand(
          name: l10n.unnamedAgent,
          title: l10n.unnamedAgent,
          skills: const <String>[],
          workspaceId: workspaceId,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() => _selectedAgentId = agent.id);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorCreatingAgent('$e'))));
    }
  }

  Future<void> _openAgentFolder(Agent agent) async {
    final dirPath = p.dirname(agent.agentMdPath);
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [dirPath]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [dirPath]);
      } else {
        await Process.run('xdg-open', [dirPath]);
      }
    } on Object catch (_) {}
  }

  Future<void> _deleteAgent(Agent agent) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(AppLocalizations.of(context).deleteAgent),
        body: Text(l10n.deleteAgentConfirm(agent.name)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.pop(ctx, false),
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.pop(ctx, true),
                  variant: FButtonVariant.destructive,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(AppLocalizations.of(context).delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final repo = ref.read(agentRepositoryProvider);
    try {
      await repo.delete(agent.id);
      if (!mounted) {
        return;
      }
      setState(() {
        if (_selectedAgentId == agent.id) {
          _selectedAgentId = null;
        }
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorDeletingAgent('$e'))));
    }
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = FTheme.of(context).colors;
    return SectionCard(
      label: l10n.agents,
      child: SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.bot, size: 48, color: colors.mutedForeground),
              const SizedBox(height: 12),
              Text(
                l10n.noAgents,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your first agent to get started.',
                style: TextStyle(fontSize: 13, color: colors.mutedForeground),
              ),
              const SizedBox(height: 16),
              FButton(
                onPress: onCreate,
                prefix: const Icon(LucideIcons.plus, size: 14),
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.addAgent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Left list pane ────────────────────────────────────────────────────────

class _AgentListPane extends StatelessWidget {
  const _AgentListPane({
    required this.agents,
    required this.selectedAgentId,
    required this.filterController,
    required this.onAgentSelected,
  });

  final List<Agent> agents;
  final String? selectedAgentId;
  final TextEditingController filterController;
  final void Function(String agentId) onAgentSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = FTheme.of(context).colors;
    return SectionCard(
      label: l10n.agentsCount(agents.length, agents.length),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      expands: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: FTextField(
              control: FTextFieldControl.managed(controller: filterController),
              hint: l10n.filterAgentsPlaceholder,
              size: FTextFieldSizeVariant.sm,
            ),
          ),
          const FDivider(),
          Expanded(
            child: agents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No matches.',
                        style: TextStyle(color: colors.mutedForeground),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: agents.length,
                    separatorBuilder: (_, _) => const FDivider(),
                    itemBuilder: (context, index) {
                      final agent = agents[index];
                      return _AgentListTile(
                        agent: agent,
                        selected: agent.id == selectedAgentId,
                        onTap: () => onAgentSelected(agent.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AgentListTile extends ConsumerWidget {
  const _AgentListTile({
    required this.agent,
    required this.selected,
    required this.onTap,
  });

  final Agent agent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = FTheme.of(context).colors;
    final l10n = AppLocalizations.of(context);
    final isRunning = ref.watch(agentIsRunningProvider(agent.id));
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.10) : null,
          border: Border(
            left: BorderSide(
              color: selected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: colors.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agent.title,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.mutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isRunning) ...[
              const SizedBox(width: 8),
              FBadge(
                variant: FBadgeVariant.primary,
                child: Text(l10n.runningLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Right detail pane ─────────────────────────────────────────────────────

class _AgentDetailPane extends ConsumerWidget {
  const _AgentDetailPane({
    super.key,
    required this.agent,
    required this.availableSkills,
    required this.onOpenFolder,
    required this.onDelete,
  });

  final Agent agent;
  final List<String> availableSkills;
  final VoidCallback onOpenFolder;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = agent.workspaceId;
    return SectionCard(
      expands: true,
      label: agent.name,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
      title: Text(agent.title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: onOpenFolder,
            mainAxisSize: MainAxisSize.min,
            prefix: const Icon(LucideIcons.folderOpen, size: 14),
            child: Text(l10n.openFolder),
          ),
          const SizedBox(width: 8),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: onDelete,
            mainAxisSize: MainAxisSize.min,
            prefix: const Icon(LucideIcons.trash2, size: 14),
            child: Text(l10n.delete),
          ),
        ],
      ),
      child: FTabs(
        expands: true,
        children: [
          FTabEntry(
            label: Text(l10n.settingsLabel),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: AgentSettingsForm(
                agent: agent,
                availableSkills: availableSkills,
              ),
            ),
          ),
          FTabEntry(
            label: Text(l10n.logs),
            child: _AgentLogsTab(agent: agent),
          ),
          FTabEntry(
            label: Text(l10n.memoryLabel),
            child: AgentWorkingMemoryPanel(
              workspaceId: workspaceId,
              agentId: agent.id,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logs tab ──────────────────────────────────────────────────────────────

class _AgentLogsTab extends ConsumerWidget {
  const _AgentLogsTab({required this.agent});
  final Agent agent;

  void _killAgentProcesses(WidgetRef ref) {
    final logs = ref.read(agentRunLogsProvider(agent.id)).value ?? [];
    final runLogRepo = ref.read(agentRunLogRepositoryProvider);
    final runningPids = <int>{};
    for (final log in logs) {
      if (log.isRunning && log.pid != null) {
        try {
          Process.killPid(log.pid!);
        } catch (_) {}
        runningPids.add(log.pid!);
        runLogRepo.upsert(
          log.copyWith(
            status: RunStatus.error,
            completedAt: DateTime.now(),
            summary: 'Killed by user',
          ),
        );
      }
    }

    ref.read(processDetectionServiceProvider).detect().then((processes) {
      for (final proc in processes) {
        if (!runningPids.contains(proc.pid) &&
            proc.command.contains(agent.name)) {
          try {
            Process.killPid(proc.pid);
          } catch (_) {}
        }
      }
    });

    ref.invalidate(agentRunLogsProvider(agent.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(agentRunLogsProvider(agent.id));
    final colors = FTheme.of(context).colors;
    final l10n = AppLocalizations.of(context);

    return logsAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(child: Text(l10n.failedToLoadLogs('$e'))),
      data: (logs) {
        final runningCount = logs.where((l) => l.isRunning).length;
        final hasRunning = runningCount > 0;

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.scrollText,
                  size: 40,
                  color: colors.mutedForeground,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noExecutionLogsYet,
                  style: TextStyle(fontSize: 14, color: colors.mutedForeground),
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
                      color: colors.mutedForeground,
                    ),
                  ),
                  if (hasRunning) ...[
                    const Spacer(),
                    FButton(
                      variant: FButtonVariant.destructive,
                      size: FButtonSizeVariant.xs,
                      mainAxisSize: MainAxisSize.min,
                      onPress: () => _killAgentProcesses(ref),
                      prefix: const Icon(LucideIcons.skull, size: 12),
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
                itemBuilder: (_, i) => _RunRow(log: logs[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RunViewerDialog extends StatefulWidget {
  const _RunViewerDialog({required this.logPath});
  final String logPath;

  @override
  State<_RunViewerDialog> createState() => _RunViewerDialogState();
}

class _RunViewerDialogState extends State<_RunViewerDialog> {
  late Future<List<Map<String, dynamic>>> _events;

  @override
  void initState() {
    super.initState();
    _events = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final lines = await File(widget.logPath).readAsLines();
    final out = <Map<String, dynamic>>[];
    for (final l in lines) {
      if (l.isEmpty) {
        continue;
      }
      try {
        final j = jsonDecode(l);
        if (j is Map<String, dynamic>) {
          out.add(j);
        }
      } catch (_) {
        out.add({'type': 'raw', 'content': l});
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    final tokens = context.designSystem;
    return FDialog.raw(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
      builder: (context, style) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Icon(LucideIcons.scrollText,
                    size: 16, color: colors.foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.basename(widget.logPath),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: colors.foreground,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _events,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: FCircularProgress());
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to read log: ${snap.error}',
                      style: TextStyle(color: colors.destructive),
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
                    final content = (e['content'] as String?) ??
                        e['eventType']?.toString() ??
                        '';
                    Color color = colors.foreground;
                    if (type == 'start') {
                      color = colors.primary;
                    }
                    if (type == 'end') {
                      color = tokens?.success ?? Colors.green;
                    }
                    if (type == 'event' && e['eventType'] == 'error') {
                      color = colors.destructive;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: colors.foreground,
                          ),
                          children: [
                            if (ts != null)
                              TextSpan(
                                text: '${ts.substring(11, 19)}  ',
                                style: TextStyle(
                                  color: colors.mutedForeground,
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
                                  color: colors.mutedForeground,
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
    );
  }
}

class _RunRow extends ConsumerWidget {
  const _RunRow({required this.log});
  final AgentRunLog log;

  FBadgeVariant get _variant => switch (log.status) {
    RunStatus.completed => FBadgeVariant.primary,
    RunStatus.error => FBadgeVariant.destructive,
    _ => FBadgeVariant.secondary,
  };

  IconData get _icon => switch (log.status) {
    RunStatus.completed => LucideIcons.checkCircle,
    RunStatus.error => LucideIcons.xCircle,
    _ => LucideIcons.loader,
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
    final colors = FTheme.of(context).colors;
    final tokens = context.designSystem;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.isRunning)
            FCircularProgress(
              style: FCircularProgressStyleDelta.delta(
                iconStyle: IconThemeDataDelta.delta(
                  size: 18,
                  color: colors.primary,
                ),
              ),
            )
          else
            Icon(
              _icon,
              size: 18,
              color: log.status == RunStatus.completed
                  ? (tokens?.success ?? Colors.green)
                  : log.status == RunStatus.error
                      ? (tokens?.danger ?? Colors.red)
                      : colors.mutedForeground,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FBadge(
                      variant: _variant,
                      child: Text(log.status.name.toUpperCase()),
                    ),
                    const Spacer(),
                    Text(
                      _durationText(),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Started: ${_formatDate(log.startedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: colors.mutedForeground,
                  ),
                ),
                if (log.completedAt != null)
                  Text(
                    'Completed: ${_formatDate(log.completedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: colors.mutedForeground,
                    ),
                  ),
                if (log.pid != null)
                  Text(
                    'PID: ${log.pid}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      fontFamily: 'monospace',
                      color: colors.mutedForeground,
                    ),
                  ),
                if (log.adapter != null)
                  Text(
                    'Adapter: ${log.adapter}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: colors.mutedForeground,
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
                FButton(
                  variant: FButtonVariant.ghost,
                  size: FButtonSizeVariant.sm,
                  mainAxisSize: MainAxisSize.min,
                  onPress: () => showDialog<void>(
                    context: context,
                    builder: (_) => _RunViewerDialog(logPath: log.logPath!),
                  ),
                  prefix: const Icon(LucideIcons.scrollText, size: 14),
                  child: Text(l10n.viewLabel),
                ),
              if (log.isRunning && log.pid != null)
                FButton(
                  variant: FButtonVariant.ghost,
                  size: FButtonSizeVariant.sm,
                  mainAxisSize: MainAxisSize.min,
                  onPress: () async {
                    await ref.read(processControlPortProvider).kill(log.pid!);
                    await ref.read(agentRunLogRepositoryProvider).upsert(
                      log.copyWith(
                        status: RunStatus.error,
                        completedAt: DateTime.now(),
                        summary: 'Killed by user',
                      ),
                    );
                  },
                  prefix: const Icon(LucideIcons.square, size: 14),
                  child: Text(l10n.stop),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


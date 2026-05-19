import 'dart:convert';
import 'dart:io';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
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
        CcButton(
          onPressed: _createUnnamedAgent,
          icon: LucideIcons.plus,
          child: Text(l10n.addAgent),
        ),
      ],
      child: agentsAsync.when(
        loading: () => const Center(child: CcSpinner()),
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
      CcToastScope.of(
        context,
      ).show(l10n.errorCreatingAgent('$e'), variant: CcToastVariant.danger);
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
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: AppLocalizations.of(context).deleteAgent,
        content: Text(l10n.deleteAgentConfirm(agent.name)),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(AppLocalizations.of(context).delete),
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
      CcToastScope.of(
        context,
      ).show(l10n.errorDeletingAgent('$e'), variant: CcToastVariant.danger);
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return SectionCard(
      label: l10n.agents,
      child: SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.bot, size: 48, color: tokens.textTertiary),
              const SizedBox(height: 12),
              Text(
                l10n.noAgents,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your first agent to get started.',
                style: TextStyle(fontSize: 13, color: tokens.textTertiary),
              ),
              const SizedBox(height: 16),
              CcButton(
                onPressed: onCreate,
                icon: LucideIcons.plus,
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
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
            child: CcTextField(
              controller: filterController,
              hintText: l10n.filterAgentsPlaceholder,
            ),
          ),
          const CcDivider(),
          Expanded(
            child: agents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No matches.',
                        style: TextStyle(color: tokens.textTertiary),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: agents.length,
                    separatorBuilder: (_, _) => const CcDivider(),
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final isRunning = ref.watch(
      agentIsRunningProvider((
        workspaceId: agent.workspaceId,
        agentId: agent.id,
      )),
    );
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? tokens.textPrimary.withValues(alpha: 0.10) : null,
          border: Border(
            left: BorderSide(
              color: selected ? tokens.textPrimary : Colors.transparent,
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
                      color: tokens.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agent.title,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: tokens.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isRunning) ...[
              const SizedBox(width: 8),
              CcBadge(
                variant: CcBadgeVariant.brand,
                label: l10n.runningLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Right detail pane ─────────────────────────────────────────────────────

class _AgentDetailPane extends ConsumerStatefulWidget {
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
  ConsumerState<_AgentDetailPane> createState() => _AgentDetailPaneState();
}

class _AgentDetailPaneState extends ConsumerState<_AgentDetailPane> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final availableSkills = widget.availableSkills;
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
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: widget.onOpenFolder,
            icon: LucideIcons.folderOpen,
            child: Text(l10n.openFolder),
          ),
          const SizedBox(width: 8),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: widget.onDelete,
            icon: LucideIcons.trash2,
            child: Text(l10n.delete),
          ),
        ],
      ),
      child: CcTabView(
        expand: true,
        selectedIndex: _selectedTab,
        onChanged: (i) => setState(() => _selectedTab = i),
        tabs: [
          CcTabViewEntry(
            label: Text(l10n.settingsLabel),
            content: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: AgentSettingsForm(
                agent: agent,
                availableSkills: availableSkills,
              ),
            ),
          ),
          CcTabViewEntry(
            label: Text(l10n.logs),
            content: _AgentLogsTab(agent: agent),
          ),
          CcTabViewEntry(
            label: Text(l10n.memoryLabel),
            content: AgentWorkingMemoryPanel(
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
    final logs = ref.read(agentRunLogsProvider((workspaceId: agent.workspaceId, agentId: agent.id))).value ?? [];
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

    ref.invalidate(agentRunLogsProvider((workspaceId: agent.workspaceId, agentId: agent.id)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(agentRunLogsProvider((workspaceId: agent.workspaceId, agentId: agent.id)));
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
                Icon(
                  LucideIcons.scrollText,
                  size: 40,
                  color: tokens.textTertiary,
                ),
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
                      onPressed: () => _killAgentProcesses(ref),
                      icon: LucideIcons.skull,
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
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
                    Icon(LucideIcons.scrollText,
                        size: 16, color: tokens.textPrimary),
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
                      icon: LucideIcons.x,
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
                        final content = (e['content'] as String?) ??
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
  const _RunRow({required this.log});
  final AgentRunLog log;

  CcBadgeVariant get _variant => switch (log.status) {
    RunStatus.completed => CcBadgeVariant.success,
    RunStatus.error => CcBadgeVariant.danger,
    _ => CcBadgeVariant.neutral,
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
                Text(
                  'Started: ${_formatDate(log.startedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: tokens.textTertiary,
                  ),
                ),
                if (log.completedAt != null)
                  Text(
                    'Completed: ${_formatDate(log.completedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: tokens.textTertiary,
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
                    builder: (_) => _RunViewerDialog(logPath: log.logPath!),
                  ),
                  icon: LucideIcons.scrollText,
                  child: Text(l10n.viewLabel),
                ),
              if (log.isRunning && log.pid != null)
                CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  onPressed: () async {
                    await ref.read(processControlPortProvider).kill(log.pid!);
                    await ref.read(agentRunLogRepositoryProvider).upsert(
                      log.copyWith(
                        status: RunStatus.error,
                        completedAt: DateTime.now(),
                        summary: 'Killed by user',
                      ),
                    );
                  },
                  icon: LucideIcons.square,
                  child: Text(l10n.stop),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/di/settings_registry.dart';
import 'package:control_center/features/agents/domain/usecases/create_agent.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_form_dialog.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_logs_tab.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_profile_header.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_roster.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/pr_review/providers/ide_providers.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/features/settings/settings_shortcuts.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final _skillNamesProvider = FutureProvider.family<List<String>, String>((
  ref,
  workspaceId,
) async {
  final fs = ref.read(workspaceFilesystemPortProvider);
  return fs.listSkillSlugs(workspaceId);
});

/// The agent registry — the roster, the per-agent configuration, and whatever
/// other features contribute alongside them.
///
/// This is the `agents` feature's own screen. It used to live under
/// `settings/presentation/widgets/agents_settings.dart` and reach out to five
/// other features by name, which left `agents` a bag of widgets with no screen
/// of its own and made settings the app's integration point. Settings now owns
/// the route and the nav entry; the composition is here, and the pieces other
/// features add come through [SettingsRegistry] rather than an import.
///
/// Shares the fleet-roster design with the rest of the app — presence dots,
/// avatars, skill chips and a profile header with live status — while keeping
/// the full configuration surface: the editable agent form (adapter, model,
/// reasoning, capabilities, …), the execution logs, and the contributed tabs.
class AgentRegistryScreen extends ConsumerStatefulWidget {
  /// Creates a new [AgentRegistryScreen].
  const AgentRegistryScreen({super.key});

  @override
  ConsumerState<AgentRegistryScreen> createState() =>
      _AgentRegistryScreenState();
}

class _AgentRegistryScreenState extends ConsumerState<AgentRegistryScreen> {
  static const _wideBreakpoint = 720.0;
  static const _rosterWidth = 340.0;

  String? _selectedAgentId;

  /// The [AgentRegistryView.id] currently showing, or null for the roster.
  ///
  /// A registered id rather than a local enum: the views are contributed, so
  /// the screen cannot enumerate them at compile time. An id that stops being
  /// contributed simply resolves to null and the roster comes back, which is
  /// the right failure mode for a toggle whose feature was removed.
  String? _activeViewId;

  final _filterCtl = TextEditingController();
  String _query = '';
  AgentRosterSort _sort = AgentRosterSort.status;

  @override
  void initState() {
    super.initState();
    _filterCtl.addListener(() {
      if (_filterCtl.text != _query) {
        setState(() => _query = _filterCtl.text);
      }
    });
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
    final registry = ref.watch(settingsRegistryProvider);
    final agentsAsync = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId))
        : ref.watch(agentsProvider);
    final selectedAgentForDelete = agentsAsync.value
        ?.where((a) => a.id == _selectedAgentId)
        .firstOrNull;

    final views = registry.sortedAgentRegistryViews;
    final activeView = views
        .where((v) => v.id == _activeViewId)
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
          for (final view in views)
            CcButton(
              onPressed: () => setState(
                () => _activeViewId = _activeViewId == view.id ? null : view.id,
              ),
              variant: _activeViewId == view.id
                  ? CcButtonVariant.accent
                  : CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: view.icon,
              child: Text(view.label(l10n)),
            ),
          CcButton(
            onPressed: _createUnnamedAgent,
            size: CcButtonSize.sm,
            icon: AppIcons.plus,
            child: Text(l10n.addAgent),
          ),
        ],
        child: (activeView != null && activeView.replacesRoster)
            ? (workspaceId != null
                  ? ColoredBox(
                      color:
                          (context.designSystem ??
                              DesignSystemTokens.light()).bgPrimary,
                      child: activeView.builder(context, workspaceId),
                    )
                  : const SizedBox.shrink())
            : agentsAsync.when(
                loading: () => const Center(child: CcSpinner()),
                error: (e, _) =>
                    Center(child: Text(l10n.failedToLoadAgents('$e'))),
                data: (agents) {
                  if (agents.isEmpty) {
                    return _EmptyState(onCreate: _createUnnamedAgent);
                  }
                  if (_selectedAgentId == null ||
                      !agents.any((a) => a.id == _selectedAgentId)) {
                    _selectedAgentId = agents.first.id;
                  }
                  final selectedAgent = agents
                      .where((a) => a.id == _selectedAgentId)
                      .firstOrNull;

                  final availableSkills = workspaceId != null
                      ? (ref.watch(_skillNamesProvider(workspaceId)).value ??
                            const <String>[])
                      : const <String>[];

                  return _buildMasterDetail(
                    agents: agents,
                    selectedAgent: selectedAgent,
                    availableSkills: availableSkills,
                    workspaceId: workspaceId,
                    activeView: activeView,
                    agentTabs: registry.sortedAgentTabs,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMasterDetail({
    required List<Agent> agents,
    required Agent? selectedAgent,
    required List<String> availableSkills,
    required String? workspaceId,
    required AgentRegistryView? activeView,
    required List<AgentSettingsTab> agentTabs,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tokens = context.designSystem ?? DesignSystemTokens.light();
        final wide = constraints.maxWidth >= _wideBreakpoint;

        final roster = AgentRosterList(
          agents: agents,
          query: _query,
          sort: _sort,
          selectedId: _selectedAgentId,
          filterController: _filterCtl,
          onSelect: (id) => setState(() {
            _selectedAgentId = id;
            // Selecting an agent leaves whichever overview was showing.
            _activeViewId = null;
          }),
          onSortChanged: (s) => setState(() => _sort = s),
        );

        Widget? detail() {
          if (activeView != null && workspaceId != null) {
            return _ContributedViewPane(
              view: activeView,
              workspaceId: workspaceId,
              onClose: wide ? null : () => setState(() => _activeViewId = null),
            );
          }
          return selectedAgent == null
              ? null
              : _AgentDetailPane(
                  key: ValueKey(selectedAgent.id),
                  agent: selectedAgent,
                  availableSkills: availableSkills,
                  extraTabs: agentTabs,
                  onOpenFolder: () => _openAgentFolder(selectedAgent),
                  onDelete: () => _deleteAgent(selectedAgent),
                  onClose: wide
                      ? null
                      : () => setState(() => _selectedAgentId = null),
                );
        }

        if (!wide) {
          final pane = detail();
          return pane ?? roster;
        }

        final pane = detail();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _rosterWidth, child: roster),
            CcDivider(axis: Axis.vertical, color: tokens.borderSecondary),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: tokens.borderSecondary),
                  ),
                ),
                child: pane ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createUnnamedAgent() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(agentRepositoryProvider);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final fsService = ref.read(workspaceFilesystemPortProvider);
    try {
      final agent =
          await CreateAgentUseCase(
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
      await ref.read(revealInFileManagerProvider).reveal(dirPath);
    } on Object catch (_) {
      // Best-effort: opening the OS file manager is non-critical.
    }
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

    // The agent's own workspace: an agent belongs to exactly one and it is what
    // picks the database the delete lands in. Sourced from the entity rather than
    // the route so a delete cannot depend on where the operator happens to be.
    final repo = ref.read(agentRepositoryProvider);
    try {
      await repo.delete(agent.workspaceId, agent.id);
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

// ─── Contributed view pane ──────────────────────────────────────────────────

/// Chrome for an [AgentRegistryView] shown in the detail area — a titled header
/// with the view's own icon and label, plus a back button on narrow layouts.
///
/// The chrome is the HOST's, not the contribution's: a feature that had to draw
/// its own header would have to know the pane's padding, its title style and
/// whether a back button is needed at this width, which is three chances for
/// two views to look subtly different. The contribution supplies content.
class _ContributedViewPane extends StatelessWidget {
  const _ContributedViewPane({
    required this.view,
    required this.workspaceId,
    this.onClose,
  });

  final AgentRegistryView view;
  final String workspaceId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: tokens.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                if (onClose != null) ...[
                  CcIconButton(
                    icon: AppIcons.arrowLeft,
                    tooltip: l10n.backLabel,
                    onPressed: onClose,
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(view.icon, size: 18, color: tokens.fgBrandPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    view.label(l10n),
                    style: CcTypography.title.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: view.builder(context, workspaceId)),
        ],
      ),
    );
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
              Icon(AppIcons.bot, size: 48, color: tokens.textTertiary),
              const SizedBox(height: 12),
              Text(
                l10n.noAgents,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your first agent to get started.',
                style: TextStyle(fontSize: 13, color: tokens.textTertiary),
              ),
              const SizedBox(height: 16),
              CcButton(
                onPressed: onCreate,
                icon: AppIcons.plus,
                child: Text(l10n.addAgent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Right detail pane ─────────────────────────────────────────────────────

/// The detail surface: a compact fleet-style profile header (avatar, live
/// status, last-active) over the configuration tabs — the settings form and the
/// execution logs, which are the agent's own, followed by whatever other
/// features contributed ([extraTabs], e.g. `memory`'s working-memory panel).
class _AgentDetailPane extends ConsumerStatefulWidget {
  const _AgentDetailPane({
    super.key,
    required this.agent,
    required this.availableSkills,
    required this.extraTabs,
    required this.onOpenFolder,
    required this.onDelete,
    this.onClose,
  });

  final Agent agent;
  final List<String> availableSkills;

  /// Tabs contributed by other features, appended after the built-in two.
  final List<AgentSettingsTab> extraTabs;

  final VoidCallback onOpenFolder;
  final VoidCallback onDelete;
  final VoidCallback? onClose;

  @override
  ConsumerState<_AgentDetailPane> createState() => _AgentDetailPaneState();
}

class _AgentDetailPaneState extends ConsumerState<_AgentDetailPane> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return Container(
      color: tokens.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AgentProfileHeader(
                  agent: agent,
                  compact: true,
                  leading: widget.onClose != null
                      ? CcIconButton(
                          icon: AppIcons.arrowLeft,
                          tooltip: l10n.backLabel,
                          onPressed: widget.onClose,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CcButton(
                      variant: CcButtonVariant.secondary,
                      onPressed: widget.onOpenFolder,
                      icon: AppIcons.folderOpen,
                      child: Text(l10n.openFolder),
                    ),
                    const SizedBox(width: 8),
                    CcButton(
                      variant: CcButtonVariant.destructive,
                      onPressed: widget.onDelete,
                      icon: AppIcons.trash2,
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: CcTabView(
              expand: true,
              // Clamped because the tab count is no longer a compile-time
              // constant: a contribution that stops being registered would
              // otherwise leave a stale index pointing past the last tab.
              selectedIndex: _selectedTab.clamp(
                0,
                widget.extraTabs.length + 1,
              ),
              onChanged: (i) => setState(() => _selectedTab = i),
              tabs: [
                CcTabViewEntry(
                  label: Text(l10n.settingsLabel),
                  content: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: AgentSettingsForm(
                      agent: agent,
                      availableSkills: widget.availableSkills,
                    ),
                  ),
                ),
                CcTabViewEntry(
                  label: Text(l10n.logs),
                  content: AgentLogsTab(agent: agent),
                ),
                for (final tab in widget.extraTabs)
                  CcTabViewEntry(
                    label: Text(tab.label(l10n)),
                    content: tab.builder(context, agent),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

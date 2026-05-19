import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/di/settings_registry.dart';
import 'package:control_center/features/agents/domain/usecases/create_agent.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_form_dialog.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_logs_tab.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_roster.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/features/settings/settings_shortcuts.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final views = registry.sortedAgentRegistryViews;
    final activeView = views.where((v) => v.id == _activeViewId).firstOrNull;

    return SettingsShortcuts(
      extraBindings: {'settings.agents-new': _createUnnamedAgent},
      child: PageWrapper(
        title: l10n.agents,
        subtitle: l10n.configureAgentIdentities,
        // Only the view toggles. "New agent" sits on the roster card instead,
        // in the same slot as Skills' "New skill": it acts on that list, not on
        // the page, and up here it was also on offer while the org chart or the
        // teams manager had replaced the roster entirely — offering to add a
        // row to a table that is not on screen. The `settings.agents-new`
        // keybinding below still reaches it from anywhere.
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
        ],
        // A body-replacing view wears its own card on the page background, the
        // same as the roster branch below. It used to be wrapped in a
        // `bgPrimary` ColoredBox, which painted the whole page the card's own
        // colour — so Teams and the org chart lost the frame every other
        // settings page has and read as a bare white sheet.
        child: (activeView != null && activeView.replacesRoster)
            ? (workspaceId != null
                  ? activeView.builder(context, workspaceId)
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

  /// The roster + detail surface, wrapped in the same card the rest of the
  /// dense settings surfaces use.
  ///
  /// The registry used to float its roster straight on the page background,
  /// which is what made it read as a different product from Skills, Model
  /// providers and Detected runners. It is now the same card over a hairline
  /// and a [SettingsMasterDetail], exactly like those pages — with the roster
  /// size carried as a badge on the heading rather than a stat strip, since
  /// every per-agent state the strip summarised is already a dot on its row.
  Widget _buildMasterDetail({
    required List<Agent> agents,
    required Agent? selectedAgent,
    required List<String> availableSkills,
    required String? workspaceId,
    required AgentRegistryView? activeView,
    required List<AgentSettingsTab> agentTabs,
  }) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SectionCard(
        label: l10n.agents,
        count: agents.length,
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
        headerPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        expands: true,
        // Beside the roster it fills, at the same weight and in the same slot
        // as Skills' "New skill" — the two are the same gesture on two lists,
        // so they are the same control in the same place.
        trailing: CcButton(
          onPressed: _createUnnamedAgent,
          size: CcButtonSize.sm,
          icon: AppIcons.plus,
          child: Text(l10n.newAgent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CcDivider(),
            Expanded(
              child: _buildRosterAndDetail(
                agents: agents,
                selectedAgent: selectedAgent,
                availableSkills: availableSkills,
                workspaceId: workspaceId,
                activeView: activeView,
                agentTabs: agentTabs,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterAndDetail({
    required List<Agent> agents,
    required Agent? selectedAgent,
    required List<String> availableSkills,
    required String? workspaceId,
    required AgentRegistryView? activeView,
    required List<AgentSettingsTab> agentTabs,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;

        final roster = Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AgentRosterList(
            agents: agents,
            query: _query,
            selectedId: _selectedAgentId,
            filterController: _filterCtl,
            onSelect: (id) => setState(() {
              _selectedAgentId = id;
              // Selecting an agent leaves whichever overview was showing.
              _activeViewId = null;
            }),
          ),
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
        return SettingsMasterDetail(
          railWidth: _rosterWidth,
          stretch: true,
          railPadding: EdgeInsets.zero,
          rail: roster,
          detail: pane ?? const SizedBox.shrink(),
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
            // The same insets as the agent detail pane's header, so switching
            // between them with the toolbar toggle does not shift the title.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                if (onClose != null) ...[
                  CcIconButton(
                    icon: AppIcons.arrowLeft,
                    tooltip: l10n.backLabel,
                    onPressed: onClose,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Icon(view.icon, size: 18, color: tokens.fgBrandPrimary),
                const SizedBox(width: AppSpacing.sm),
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
    // Same page insets as the populated card, so the page does not jump when
    // the first agent is created.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SectionCard(
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
                  style: CcTypography.title.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create your first agent to get started.',
                  style: CcTypography.bodySm.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                CcButton(
                  onPressed: onCreate,
                  icon: AppIcons.plus,
                  child: Text(l10n.newAgent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Right detail pane ─────────────────────────────────────────────────────

/// The detail surface: the configuration tabs — the settings form and the
/// execution logs, which are the agent's own, followed by whatever other
/// features contributed ([extraTabs], e.g. `memory`'s working-memory panel).
///
/// There is deliberately no profile card above the tabs. It restated the name
/// and title of the row you had just clicked, immediately above the Name and
/// Title fields that let you change them, and its live-status line duplicated
/// the roster row's own status dot — a bordered box spending the top of the
/// pane on facts already on screen twice. Deleting an agent moved with it,
/// into a danger zone at the end of the form where a destructive action
/// belongs: at the top it was the first thing the eye landed on, on a pane
/// whose job is configuration.
///
/// The narrow layout keeps a slim header, because there the roster is not
/// beside the pane and nothing else would say which agent this is.
class _AgentDetailPane extends ConsumerStatefulWidget {
  const _AgentDetailPane({
    super.key,
    required this.agent,
    required this.availableSkills,
    required this.extraTabs,
    required this.onDelete,
    this.onClose,
  });

  final Agent agent;
  final List<String> availableSkills;

  /// Tabs contributed by other features, appended after the built-in two.
  final List<AgentSettingsTab> extraTabs;

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
          if (widget.onClose != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  CcIconButton(
                    icon: AppIcons.arrowLeft,
                    tooltip: l10n.backLabel,
                    onPressed: widget.onClose,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      agent.name,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.title.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
              selectedIndex: _selectedTab.clamp(0, widget.extraTabs.length + 1),
              onChanged: (i) => setState(() => _selectedTab = i),
              tabs: [
                CcTabViewEntry(
                  label: Text(l10n.settingsLabel),
                  // The form owns its own scroll and its own save bar; the tab
                  // used to wrap it in a SECOND SingleChildScrollView, which
                  // stacked the two paddings and left the inner one unable to
                  // scroll at all.
                  content: AgentSettingsForm(
                    agent: agent,
                    availableSkills: widget.availableSkills,
                    onDelete: widget.onDelete,
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

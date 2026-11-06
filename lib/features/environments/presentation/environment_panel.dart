import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/environments/presentation/environment_panel_sections.dart';
import 'package:control_center/features/environments/presentation/environment_setup_prompt.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_endpoint_rows.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_live_panel.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_section.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_start.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How wide the panel's content may grow in an editor tab. A sidebar is
/// narrower than this and is filled edge to edge.
const double _maxContentWidth = 760;

/// Everything about a space's environment in one place: whether it runs and
/// how to start or stop it, where it answers, each service and process, the
/// scripts that can be run, what ran and what it printed, and the definition
/// behind it.
///
/// A space with nothing it could start offers to set an environment up rather
/// than showing an empty panel.
class EnvironmentPanel extends ConsumerWidget {
  /// Creates an [EnvironmentPanel].
  const EnvironmentPanel({
    super.key,
    required this.workspaceId,
    required this.spaceId,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The space whose environment this shows.
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isDemoServerProvider)) {
      return const Center(
        child: DemoUnavailable(capability: DemoCapability.environments),
      );
    }
    final key = (workspaceId: workspaceId, spaceId: spaceId);
    final eligibleAsync = ref.watch(eligibleDefinitionsProvider(key));
    final environments = ref.watch(spaceEnvironmentsProvider(key));
    if (eligibleAsync.error is EnvironmentsUnsupported ||
        environments.error is EnvironmentsUnsupported) {
      return const EnvironmentPanelFrame(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: EnvironmentsUnsupportedNote(),
          ),
        ],
      );
    }
    if (!environments.hasValue && !eligibleAsync.hasValue) {
      return const Center(child: CcSpinner());
    }
    final environment = ref.watch(spaceEnvironmentProvider(key));
    final runs =
        ref.watch(spaceEnvironmentRunsProvider(key)).value ??
        const <EnvironmentRun>[];
    return EnvironmentPanelFrame(
      children: [
        if (environment != null)
          ..._live(context, ref, key, environment, runs)
        else
          _notRunning(context, ref, key, eligibleAsync.value ?? const []),
        if (runs.isNotEmpty) EnvironmentActivitySection(runs: runs),
      ],
    );
  }

  List<Widget> _live(
    BuildContext context,
    WidgetRef ref,
    EnvironmentSpaceKey key,
    SpaceEnvironment environment,
    List<EnvironmentRun> runs,
  ) {
    final l10n = AppLocalizations.of(context);
    final record = environmentRecordFor(ref, key, environment);
    final definition = record == null ? null : environmentDefinitionOf(record);
    final scripts = [
      for (final component in environment.components)
        if (component.kind == 'task') component,
    ];
    final parts = [
      for (final component in environment.components)
        if (component.kind != 'task') component,
    ];
    return [
      Padding(
        // The same left edge as the sections below it.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: EnvironmentSummary(
          spaceKey: key,
          environment: environment,
          runs: runs,
          menu: true,
        ),
      ),
      // Nothing to reach while nothing runs, whatever the last start reported.
      if (environment.endpoints.isNotEmpty && _reachable(environment))
        CollapsibleSidebarSection(
          icon: AppIcons.globe,
          label: l10n.environmentUrls,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: EnvironmentEndpointRows(
              spaceKey: key,
              endpoints: environment.endpoints,
            ),
          ),
        ),
      if (parts.isNotEmpty)
        EnvironmentComponentsSection(
          icon: AppIcons.layers,
          label: l10n.environmentsSectionComponents,
          spaceKey: key,
          environment: environment,
          components: parts,
          definition: definition,
          runs: runs,
        ),
      if (scripts.isNotEmpty)
        EnvironmentComponentsSection(
          icon: AppIcons.scrollText,
          label: l10n.environmentScripts,
          spaceKey: key,
          environment: environment,
          components: scripts,
          definition: definition,
          runs: runs,
        ),
    ];
  }

  bool _reachable(SpaceEnvironment environment) =>
      environment.status.isRunning ||
      environment.components.any(
        (part) => const {'running', 'ready', 'starting'}.contains(part.state),
      );

  Widget _notRunning(
    BuildContext context,
    WidgetRef ref,
    EnvironmentSpaceKey key,
    List<EnvironmentDefinitionRecord> eligible,
  ) {
    if (eligible.isEmpty) {
      final worktrees = ref
          .watch(
            spaceWorktreesProvider((
              workspaceId: workspaceId,
              spaceId: spaceId,
            )),
          )
          .value;
      return EnvironmentSetupPrompt(
        workspaceId: workspaceId,
        repoId: worktrees == null || worktrees.isEmpty
            ? null
            : worktrees.first.repoId,
        message: AppLocalizations.of(context).environmentNoneForSpace,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: EnvironmentStartPanel(
        definitions: eligible,
        onStart: (context, definitionId, options) => forwardEnsure(
          context,
          ref,
          key,
          definitionId: definitionId,
          options: options,
        ),
        workspaceId: workspaceId,
        busy: ref.watch(environmentActionsProvider(key)).contains('start'),
      ),
    );
  }
}

/// The scrolling column every environment panel body sits in, kept to a
/// readable width when an editor tab gives it more.
class EnvironmentPanelFrame extends StatelessWidget {
  /// Creates an [EnvironmentPanelFrame].
  const EnvironmentPanelFrame({super.key, required this.children});

  /// The sections, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxContentWidth),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: children,
      ),
    ),
  );
}

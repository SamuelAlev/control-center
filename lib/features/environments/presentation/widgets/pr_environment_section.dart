import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host_setup.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_section.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_start.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_pr_providers.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The environment of a pull request.
///
/// Merely viewing a PR must not provision a worktree, so this looks the space
/// up rather than ensuring it. Without one it offers Start from the workspace's
/// definitions, and Start is what creates the space.
class PrEnvironmentSection extends ConsumerStatefulWidget {
  /// Creates a [PrEnvironmentSection].
  const PrEnvironmentSection({
    super.key,
    required this.workspaceId,
    required this.pr,
    this.onOpenPanel,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The pull request.
  final PullRequest pr;

  /// Opens the PR's Environment tab, when the page has one.
  final VoidCallback? onOpenPanel;

  @override
  ConsumerState<PrEnvironmentSection> createState() =>
      _PrEnvironmentSectionState();
}

/// Starts a pull request's environment: ensures the PR's space, waits for its
/// worktree, then ensures the environment in it. Shared by the PR sidebar and
/// the PR's Environment tab, which both offer Start before a space exists.
mixin PrEnvironmentStarting<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Whether a start is in flight.
  bool starting = false;

  /// Starts [definitionId] for [pr] in [workspaceId].
  Future<void> startPrEnvironment(
    BuildContext context, {
    required String workspaceId,
    required PullRequest pr,
    required String definitionId,
    required Map<String, dynamic> options,
  }) async {
    final toasts = CcToastScope.maybeOf(context);
    final followUp = HostSetupFollowUp.of(context, ref);
    setState(() => starting = true);
    try {
      final spaceId = await ref.read(prSpaceProvider(PrSpaceKey.of(pr)).future);
      final key = (workspaceId: workspaceId, spaceId: spaceId);
      await _provisioned(spaceId);
      SpaceEnvironment? started;
      await ref.read(environmentActionsProvider(key).notifier).run('start', (
        repository,
      ) async {
        started = await repository.ensure(
          key.workspaceId,
          key.spaceId,
          definitionId: definitionId,
          options: options,
        );
      });
      if (started != null) {
        await followUp.after(key, started!);
      }
    } on Object catch (error) {
      toasts?.show(
        environmentFailureMessage(error),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => starting = false);
      }
    }
  }

  /// Completes once the space's worktree has left provisioning, or the budget
  /// has gone. The server refuses a Start it can't honour, so giving up here
  /// surfaces its error rather than a spinner that never ends.
  Future<void> _provisioned(String spaceId) async {
    final provider = spaceProvisioningStatusProvider(spaceId);
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    while (mounted &&
        DateTime.now().isBefore(deadline) &&
        ref.read(provider) == SpaceProvisioningStatus.provisioning) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
}

/// The definitions [pr] could start: those anchored on its repo.
List<EnvironmentDefinitionRecord> prStartableDefinitions(
  WidgetRef ref,
  String workspaceId,
  PullRequest pr,
) {
  final repoId = prRepoIdFor(ref, pr);
  final definitions =
      ref.watch(environmentDefinitionsProvider(workspaceId)).value ??
      const <EnvironmentDefinitionRecord>[];
  return [
    for (final record in definitions)
      if (environmentAnchoredOn(record, repoId)) record,
  ];
}

class _PrEnvironmentSectionState extends ConsumerState<PrEnvironmentSection>
    with PrEnvironmentStarting {
  @override
  Widget build(BuildContext context) {
    if (ref.watch(isDemoServerProvider)) {
      return const SizedBox.shrink();
    }
    final spaceId = ref
        .watch(existingPrSpaceIdProvider(PrSpaceKey.of(widget.pr)))
        .value;
    if (spaceId != null) {
      return EnvironmentSection(
        workspaceId: widget.workspaceId,
        spaceId: spaceId,
        onOpenPanel: widget.onOpenPanel,
      );
    }
    final startable = prStartableDefinitions(
      ref,
      widget.workspaceId,
      widget.pr,
    );
    if (startable.isEmpty) {
      return const SizedBox.shrink();
    }
    return EnvironmentSectionShell(
      onOpenPanel: widget.onOpenPanel,
      child: EnvironmentStartPanel(
        workspaceId: widget.workspaceId,
        definitions: startable,
        onStart: (context, definitionId, options) => startPrEnvironment(
          context,
          workspaceId: widget.workspaceId,
          pr: widget.pr,
          definitionId: definitionId,
          options: options,
        ),
        busy: starting,
      ),
    );
  }
}

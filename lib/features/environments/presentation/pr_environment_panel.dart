import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/environments/presentation/environment_panel.dart';
import 'package:control_center/features/environments/presentation/environment_setup_prompt.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_section.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_start.dart';
import 'package:control_center/features/environments/presentation/widgets/pr_environment_section.dart';
import 'package:control_center/features/environments/providers/environment_pr_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A pull request's Environment tab.
///
/// Once the PR has a space this is that space's [EnvironmentPanel]. Before
/// then, viewing it provisions nothing: it offers Start from the definitions
/// anchored on the PR's repo, and Start is what creates the space. A repo with
/// no definition is offered one.
class PrEnvironmentPanel extends ConsumerStatefulWidget {
  /// Creates a [PrEnvironmentPanel].
  const PrEnvironmentPanel({
    super.key,
    required this.workspaceId,
    required this.pr,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The pull request.
  final PullRequest pr;

  @override
  ConsumerState<PrEnvironmentPanel> createState() => _PrEnvironmentPanelState();
}

class _PrEnvironmentPanelState extends ConsumerState<PrEnvironmentPanel>
    with PrEnvironmentStarting {
  @override
  Widget build(BuildContext context) {
    if (ref.watch(isDemoServerProvider)) {
      return const Center(
        child: DemoUnavailable(capability: DemoCapability.environments),
      );
    }
    final spaceAsync = ref.watch(
      existingPrSpaceIdProvider(PrSpaceKey.of(widget.pr)),
    );
    final spaceId = spaceAsync.value;
    if (spaceId != null) {
      return EnvironmentPanel(
        workspaceId: widget.workspaceId,
        spaceId: spaceId,
      );
    }
    if (!spaceAsync.hasValue) {
      return const Center(child: CcSpinner());
    }
    final startable = prStartableDefinitions(
      ref,
      widget.workspaceId,
      widget.pr,
    );
    return EnvironmentPanelFrame(
      children: [
        if (startable.isEmpty)
          EnvironmentSetupPrompt(
            workspaceId: widget.workspaceId,
            repoId: prRepoIdFor(ref, widget.pr),
            message: AppLocalizations.of(context).environmentNoneForPr,
          )
        else
          EnvironmentSectionShell(
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
          ),
      ],
    );
  }
}

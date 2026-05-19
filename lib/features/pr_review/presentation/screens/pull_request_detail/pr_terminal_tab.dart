import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR terminal tab: an interactive shell on the prepared PR worktree.
///
/// On first open it ensures the PR space (which provisions the repo at the
/// PR head, `refs/pull/N/head`), waits for provisioning to be ready, then
/// attaches a PTY at the conversation root — `repos/<name>` holds the PR's
/// checked-out tree. Reuses [TerminalPanel] (thin client over `terminal.*`),
/// so it works on desktop and web alike.
class PrTerminalTab extends ConsumerStatefulWidget {
  /// Creates a [PrTerminalTab].
  const PrTerminalTab({
    super.key,
    required this.pr,
    this.backend,
    this.onTitleChange,
  });

  /// The pull request whose worktree the terminal runs in.
  final PullRequest pr;

  /// The `SandboxBackend` name to request (`microvm` = a shell inside the
  /// PR conversation's enclosed VM), or null for the server default.
  final String? backend;

  /// Forwards the shell's OSC title (see [TerminalPanel.onTitleChange]) so the
  /// host can retitle this tab, wezterm/ghostty/iTerm-style.
  final ValueChanged<String>? onTitleChange;

  @override
  ConsumerState<PrTerminalTab> createState() => _PrTerminalTabState();
}

class _PrTerminalTabState extends ConsumerState<PrTerminalTab> {
  // Stable per-tab id so the panel's server session survives rebuilds/moves.
  final String _sessionId =
      'pr-terminal-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final spaceAsync = ref.watch(prSpaceProvider(widget.pr));
    return spaceAsync.when(
      loading: () => _Preparing(label: l10n.preparingWorkspace, t: t),
      error: (e, _) => Center(
        child: Text(
          l10n.failedWithError('$e'),
          style: TextStyle(
            color: t.fgSecondary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      data: (spaceId) {
        // Gate on provisioning: the worktree must be checked out at the PR head
        // before the shell is useful.
        final status = ref.watch(spaceProvisioningStatusProvider(spaceId));
        if (status == SpaceProvisioningStatus.provisioning) {
          final step = ref.watch(spaceProvisioningStepProvider(spaceId));
          return _Preparing(label: provisioningStepLabel(l10n, step), t: t);
        }
        final workspaceId = ref.watch(activeWorkspaceIdProvider) ?? '';
        return TerminalPanel(
          session: TerminalSession(
            sessionId: _sessionId,
            spaceId: spaceId,
            workspaceId: workspaceId,
            backend: widget.backend,
          ),
          onTitleChange: widget.onTitleChange,
          backgroundColor: t.bgPrimary,
        );
      },
    );
  }
}

class _Preparing extends StatelessWidget {
  const _Preparing({required this.label, required this.t});
  final String label;
  final DesignSystemTokens t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CcSpinner(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.terminal, size: 14, color: t.fgTertiary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: t.fgSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

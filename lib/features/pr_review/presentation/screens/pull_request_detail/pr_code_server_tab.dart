import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_pane.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_channel_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A full VS Code (code-server) IDE on the PR worktree, embedded in a tab.
/// Resolves the PR channel (provisioned at the PR head) then reuses the
/// messaging IDE's [CodeServerPane], which runs code-server server-side over
/// the `/proxy/vscode` reverse proxy against the conversation's worktree.
///
/// Gates on the channel's provisioning status — the isolated PR-head worktree
/// must be checked out before code-server can open on it (otherwise
/// `codeServer.open` fails with "no isolated worktree"). Mirrors the terminal
/// tab's preparing/failed states.
class PrCodeServerTab extends ConsumerWidget {
  /// Creates a [PrCodeServerTab].
  const PrCodeServerTab({
    super.key,
    required this.pr,
    this.path,
    this.repoId,
    this.line,
  });

  /// The pull request whose worktree the editor opens on.
  final PullRequest pr;

  /// Optional file (repo-relative) to deep-link open + edit on load.
  final String? path;

  /// Optional repo whose worktree to open (null lets the server pick).
  final String? repoId;

  /// Optional 1-based line to reveal in [path] (best-effort).
  final int? line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final channelAsync = ref.watch(prChannelProvider(pr));
    return channelAsync.when(
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
      data: (channelId) {
        // The worktree must be checked out at the PR head before code-server
        // can open on it. Wait while provisioning is in flight; surface a
        // failed state rather than letting `codeServer.open` throw.
        final status = ref.watch(channelProvisioningStatusProvider(channelId));
        if (status == ChannelProvisioningStatus.provisioning) {
          final step = ref.watch(channelProvisioningStepProvider(channelId));
          return _Preparing(label: provisioningStepLabel(l10n, step), t: t);
        }
        if (status == ChannelProvisioningStatus.failed) {
          return _Failed(t: t, l10n: l10n);
        }
        return CodeServerPane(
          channelId: channelId,
          repoId: repoId,
          path: path,
          line: line,
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
          Text(
            label,
            style: TextStyle(
              color: t.fgSecondary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.t, required this.l10n});
  final DesignSystemTokens t;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.prWorktreeUnavailable,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.prWorktreeUnavailableHint,
              style: TextStyle(
                fontSize: 12,
                color: t.textTertiary,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

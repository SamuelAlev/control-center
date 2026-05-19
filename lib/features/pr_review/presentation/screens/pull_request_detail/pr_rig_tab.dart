import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_channel_provider.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_pane.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A rig tab on the PR detail page: a desktop, browser or phone scoped to this
/// pull request.
///
/// Resolves the PR's channel first, exactly as the terminal tab does, so the
/// machine belongs to the same conversation the PR's agents work in — open the
/// browser here and `browser_use` from a PR agent drives THIS machine rather
/// than opening a second one nobody is watching.
class PrRigTab extends ConsumerWidget {
  /// Creates a [PrRigTab].
  const PrRigTab({
    super.key,
    required this.pr,
    required this.surface,
    this.isVisible = true,
  });

  /// The pull request this machine belongs to.
  final PullRequest pr;

  /// Which machine to show (`computer` / `browser` / `mobile`).
  final String surface;

  /// Whether this tab is on screen. A hidden tab stops streaming frames.
  final bool isVisible;

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
        // Unlike the terminal, a rig does not need the worktree checked out
        // before it is useful — a browser rig has nothing to do with the
        // repo. But the channel is what scopes the machine, so wait for it to
        // exist before offering to start one.
        final status = ref.watch(channelProvisioningStatusProvider(channelId));
        if (status == ChannelProvisioningStatus.provisioning) {
          final step = ref.watch(channelProvisioningStepProvider(channelId));
          return _Preparing(label: provisioningStepLabel(l10n, step), t: t);
        }
        return RigTabPane(
          surface: surface,
          conversationId: channelId,
          isVisible: isVisible,
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
              Icon(AppIcons.monitor, size: 14, color: t.fgTertiary),
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

import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/conversation_pane.dart'
    show SpaceProvisioningBanner;
import 'package:control_center/features/messaging/presentation/ide/quick_open/quick_open_dialog.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the ⌘P "go to file" picker over [pr]'s worktree and resolves to the
/// operator's pick (null when dismissed).
///
/// The worktree hangs off the PR's space, checked out at the PR head
/// (`refs/pull/<n>/head` on `pr/<n>`), and the first ⌘P on a pull request is
/// usually what creates it. Until that checkout is ready the query field is
/// disabled under the same provisioning strip the composer shows; then it
/// enables and takes focus.
Future<QuickOpenChoice?> showPrQuickOpen(
  BuildContext context, {
  required String workspaceId,
  required PullRequest pr,
}) {
  return showQuickOpenDialog(
    context,
    panel: (_) => PrQuickOpenPanel(workspaceId: workspaceId, pr: pr),
  );
}

/// The PR picker body: [QuickOpenPanel] gated on the PR space's checkout.
/// Public for widget tests.
class PrQuickOpenPanel extends ConsumerWidget {
  /// Creates the picker body for [pr].
  const PrQuickOpenPanel({
    super.key,
    required this.workspaceId,
    required this.pr,
  });

  /// The workspace the pull request was opened in.
  final String workspaceId;

  /// The pull request whose worktree is searched.
  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spaceAsync = ref.watch(prSpaceProvider(pr));
    final spaceId = spaceAsync.value;
    // Read the row itself rather than `spaceProvisioningStatusProvider`, which
    // answers `ready` for a space the stream has not delivered yet. A space
    // `pr.ensureSpace` just created is exactly that, and an enabled field
    // over a worktree that does not exist would only ever find nothing.
    final space = spaceId == null
        ? null
        : ref
              .watch(workspaceSpacesProvider(workspaceId))
              .value
              ?.where((s) => s.id == spaceId)
              .firstOrNull;
    final ready = space?.provisioningStatus == SpaceProvisioningStatus.ready;

    final Widget? status;
    if (ready) {
      status = null;
    } else if (spaceId == null && spaceAsync.hasError) {
      status = _StatusLine(
        icon: AppIcons.triangleAlert,
        label: l10n.failedWithError('${spaceAsync.error}'),
      );
    } else if (spaceId == null || space == null) {
      status = _StatusLine(label: l10n.preparingWorkspace);
    } else {
      // Progress step, stop, and retry after a failure — the composer's strip.
      status = SpaceProvisioningBanner(spaceId: spaceId);
    }

    return QuickOpenPanel(
      workspaceId: workspaceId,
      spaceId: spaceId,
      ready: ready,
      status: status,
    );
  }
}

/// A one-line status in the provisioning strip's shape, for the moments the
/// strip has no space row to report on yet.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, this.icon});

  final String label;

  /// Leading glyph; null shows a spinner.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          if (icon case final icon?)
            Icon(icon, size: 14, color: ds.danger)
          else
            const CcSpinner(size: 14),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ds.fgSecondary,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/channel_takeover_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Slim banner shown in the conversation pane while a take-over of this
/// channel's worktree is active (PRD 16 §8). Shows who holds it; when it's
/// the current user, offers a "Hand back" action. Polls
/// [takeoverStatusProvider] (no server subscription exists for this) and
/// keeps this client's `worktree` soft-claim in sync while mounted.
class TakeoverBanner extends ConsumerWidget {
  /// Creates a [TakeoverBanner] for [channelId].
  const TakeoverBanner({super.key, required this.channelId});

  /// The channel this banner watches.
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the `worktree` soft-claim in sync with whether I hold the
    // take-over — active for as long as this banner is mounted.
    ref.watch(takeoverClaimSyncProvider(channelId));

    final takeover = ref.watch(takeoverStatusProvider(channelId)).value;
    if (takeover == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final myUserId = ref.watch(currentUserIdProvider);
    final isMine = myUserId != null && takeover.userId == myUserId;

    return Container(
      color: t.accentSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(AppIcons.userCheck, size: 14, color: t.accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              isMine
                  ? l10n.takeoverBannerSelf
                  : l10n.takeoverBannerOther(takeover.displayName),
              style: TextStyle(
                color: t.accent,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (isMine)
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: () => _handBack(context, ref),
              child: Text(l10n.handBackButton),
            ),
        ],
      ),
    );
  }

  Future<void> _handBack(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.handBackDialogTitle,
        content: CcTextField(
          controller: controller,
          hintText: l10n.handBackDialogNoteHint,
          autofocus: true,
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.handBackButton),
          ),
        ],
      ),
    );
    final note = controller.text;
    controller.dispose();
    if (confirmed != true) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final toast = CcToastScope.maybeOf(context);
    try {
      await handBackChannelTakeover(
        ref.read(rpcClientProvider),
        channelId,
        note: note,
      );
    } on RemoteRpcException catch (e) {
      toast?.show(
        l10n.handBackFailed(e.message),
        variant: CcToastVariant.danger,
      );
      return;
    }
    ref.invalidate(takeoverStatusProvider(channelId));
  }
}

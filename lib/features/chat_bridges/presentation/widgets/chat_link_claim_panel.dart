import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/providers/chat_link_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chat profile that sent the member's link code, with the Confirm /
/// Decline that finishes or refuses the link.
///
/// Sending the code only claims it. This is the half that links: the member
/// recognizes the profile as theirs, because a code read over somebody's
/// shoulder and sent from another account must not become that account
/// acting as them. Shown in the link dialog and under the "link my account"
/// row, so a claim made after the dialog closed is still answered here.
class ChatLinkClaimPanel extends ConsumerWidget {
  /// Creates a [ChatLinkClaimPanel].
  const ChatLinkClaimPanel({
    super.key,
    required this.provider,
    required this.providerName,
    required this.claim,
  });

  /// The chat provider the code was sent on.
  final ChatProvider provider;

  /// The provider's product name.
  final String providerName;

  /// Who sent the code.
  final ChatLinkClaimView claim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final answer = ref.watch(chatLinkClaimControllerProvider(provider));
    final controller = ref.read(
      chatLinkClaimControllerProvider(provider).notifier,
    );
    final busy = answer.isLoading;
    final caption = CcTypography.caption.copyWith(color: t.textSecondary);
    final claimedAt = claim.claimedAt;
    return CcAlert(
      variant: CcAlertVariant.warning,
      icon: AppIcons.userCheck,
      title: l10n.chatLinkClaimTitle(providerName),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            claim.displayName,
            style: CcTypography.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                claim.externalUserId,
                style: CcFonts.code(textStyle: caption),
              ),
              if (claimedAt != null)
                AppTimestamp.relative(claimedAt, style: caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.chatLinkClaimBody(providerName), style: caption),
          if (answer.hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.failedWithError('${answer.error}'),
              style: CcTypography.caption.copyWith(color: t.bgErrorSolid),
            ),
          ],
        ],
      ),
      action: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          CcButton(
            size: CcButtonSize.sm,
            loading: busy,
            onPressed: busy
                ? null
                : () => unawaited(controller.confirm(claim.externalUserId)),
            child: Text(l10n.confirm),
          ),
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            onPressed: busy ? null : () => unawaited(controller.decline()),
            child: Text(l10n.chatLinkDecline),
          ),
        ],
      ),
    );
  }
}

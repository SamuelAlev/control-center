import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_sign_in_account_list.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A turn that ended because its credential stopped authenticating.
///
/// Not a raw error row: the operator does not need the CLI's sentence as a
/// headline, they need to know the fix is a sign-in, and a way to do it. The
/// upstream sentence stays underneath, verbatim, as the evidence. The failed
/// badge below the turn still carries the retry.
class TurnAuthFailureNotice extends ConsumerWidget {
  /// Creates a [TurnAuthFailureNotice] for [segment].
  const TurnAuthFailureNotice({required this.segment, super.key});

  /// The authentication failure being explained.
  final ErrorSegment segment;

  /// The upstream sentence without the lane prefix the server stamps on it.
  static String detailOf(ErrorSegment segment) =>
      segment.message.replaceFirst(RegExp(r'^\[\w+\]\s*'), '').trim();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final claude = segment.source == ErrorSegment.claudeCodeSource;
    final detail = detailOf(segment);

    return CcAlert(
      variant: CcAlertVariant.warning,
      icon: AppIcons.keyRound,
      title: claude
          ? l10n.transcriptClaudeSignInExpiredTitle
          : l10n.transcriptSignInExpiredTitle,
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            claude
                ? l10n.transcriptClaudeSignInExpiredBody
                : l10n.transcriptSignInExpiredBody,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ],
        ],
      ),
      action: claude
          ? CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.keyRound,
              onPressed: () => showClaudeSignInDialog(context, ref),
              child: Text(l10n.claudeAccountSignIn),
            )
          : null,
    );
  }
}

import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show SignInNeed;
import 'package:control_center/features/forge/presentation/repo_code_refusal.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A code view (a file, a diff, a search) that could not load, in place of
/// its content.
///
/// A refusal that follows the person's own forge account (not signed in,
/// cannot read, could not confirm, the repository replaced) is worded by its
/// code, and a missing sign-in offers it. Anything else shows [fallback],
/// with [onRetry] when given.
class RepoCodeFailureView extends StatelessWidget {
  /// Creates the view for [error].
  const RepoCodeFailureView({
    super.key,
    required this.error,
    required this.fallback,
    this.workspaceId,
    this.onRetry,
    this.describe = repoCodeFailureOf,
  });

  /// What went wrong; null shows [fallback].
  final Object? error;

  /// The view's own failure sentence, for anything that is not a refusal.
  final String fallback;

  /// The workspace a sign-in starts from.
  final String? workspaceId;

  /// Loads again.
  final VoidCallback? onRetry;

  /// Words [error] when it is a refusal (with the sign-in that fixes it), or
  /// null for anything else; a code view's reading unless a surface (a
  /// space) has its own.
  final ({String message, SignInNeed? signIn})? Function(
    AppLocalizations l10n,
    Object error,
  )
  describe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final error = this.error;
    final failure = error == null ? null : describe(l10n, error);
    final need = failure?.signIn;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              need != null
                  ? AppIcons.keyRound
                  : failure != null
                  ? AppIcons.lock
                  : AppIcons.triangleAlert,
              size: 18,
              color: t.textTertiary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              failure?.message ?? fallback,
              textAlign: TextAlign.center,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
            if (need != null || onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.secondary,
                onPressed: need != null
                    ? () => unawaited(
                        showSignInRequiredDialog(
                          context,
                          need: need,
                          workspaceId: workspaceId,
                        ),
                      )
                    : onRetry,
                child: Text(need != null ? l10n.repoCodeSignIn : l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

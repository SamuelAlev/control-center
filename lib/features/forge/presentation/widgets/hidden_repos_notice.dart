import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show LaneSignInNeed, SignInNeed, TokenSignInNeed;
import 'package:control_center/features/forge/presentation/widgets/forge_token_dialog.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a pull request view leaves out for the reader, by forge and reason,
/// so a short list never reads as the whole workspace.
///
/// The server sends counts only, never the names of repositories the reader
/// cannot see. Not being signed in to a forge is the reader's to fix, so it
/// comes with the sign-in (a token dialog for GitLab and Bitbucket). A forge
/// account that cannot see a repository, or no grant on it in this
/// workspace, is explained without an action. A check still running is one
/// quiet line.
///
/// Renders nothing when nothing is hidden and carries its own bottom margin,
/// so callers can drop it into a column unconditionally.
class HiddenReposNotice extends ConsumerWidget {
  /// Creates a [HiddenReposNotice] over [hidden].
  const HiddenReposNotice({required this.hidden, super.key});

  /// What is hidden; empty renders nothing.
  final List<HiddenRepos> hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hidden.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final checking = hidden
        .where((h) => h.reason == HiddenRepoReason.checking)
        .fold(0, (sum, h) => sum + h.count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final h in hidden)
          switch (h.reason) {
            HiddenRepoReason.signInRequired => _alert(
              icon: AppIcons.keyRound,
              variant: CcAlertVariant.warning,
              title: l10n.hiddenReposSignIn(h.count, h.forge.displayName),
              action: _signInButton(context, l10n, h, workspaceId),
            ),
            HiddenRepoReason.noForgeAccess => _alert(
              icon: AppIcons.eyeOff,
              variant: CcAlertVariant.info,
              title: l10n.hiddenReposNoForgeAccess(
                h.count,
                h.forge.displayName,
              ),
            ),
            HiddenRepoReason.noGrant => _alert(
              icon: AppIcons.lock,
              variant: CcAlertVariant.info,
              title: l10n.hiddenReposNoGrant(h.count),
            ),
            HiddenRepoReason.checking => null,
          },
        if (checking > 0)
          _CheckingLine(text: l10n.hiddenReposChecking(checking)),
      ].nonNulls.toList(),
    );
  }

  Widget _alert({
    required IconData icon,
    required CcAlertVariant variant,
    required String title,
    Widget? action,
  }) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
    child: CcAlert(
      variant: variant,
      icon: icon,
      title: title,
      trailing: action,
    ),
  );

  Widget _signInButton(
    BuildContext context,
    AppLocalizations l10n,
    HiddenRepos h,
    String? workspaceId,
  ) {
    final need = SignInNeed.forForge(h.forge);
    return CcButton(
      size: CcButtonSize.sm,
      variant: CcButtonVariant.secondary,
      onPressed: () => unawaited(switch (need) {
        LaneSignInNeed(:final lane) => showProviderSignInDialog(
          context,
          lane: lane,
          workspaceId: workspaceId,
        ),
        TokenSignInNeed(:final forge) => showForgeTokenDialog(
          context,
          forge: forge,
        ),
      }),
      child: Text(switch (need) {
        LaneSignInNeed(:final lane) => signInActionLabel(l10n, lane),
        TokenSignInNeed() => l10n.addToken,
      }),
    );
  }
}

/// Access still being checked: nothing to do, so said quietly.
class _CheckingLine extends StatelessWidget {
  const _CheckingLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(AppIcons.clock, size: 14, color: t.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

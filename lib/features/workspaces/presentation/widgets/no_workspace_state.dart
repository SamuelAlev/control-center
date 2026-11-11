import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/server_switch_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the workspace picker shows when the signed-in person is in no
/// workspace.
///
/// Someone who may create workspaces ([canCreateWorkspacesProvider]) gets the
/// create action ([onAdd]). Anyone else lands on a calm dead end: they are
/// signed in, they are just not in a workspace yet, and a workspace admin has
/// to invite them (or the server owner creates one). It offers a single
/// re-check and sign-out, never a create button or a polling spinner: an
/// invite arrives on the live workspace list by itself.
class NoWorkspaceState extends ConsumerStatefulWidget {
  /// Creates the state; [onAdd] opens the create flow.
  const NoWorkspaceState({super.key, required this.onAdd});

  /// Opens the create flow; used only when the person may create.
  final VoidCallback onAdd;

  @override
  ConsumerState<NoWorkspaceState> createState() => _NoWorkspaceStateState();
}

class _NoWorkspaceStateState extends ConsumerState<NoWorkspaceState> {
  bool _checking = false;
  bool _leaving = false;

  /// Re-reads the create right and the workspace list once. The list is live
  /// anyway; this answers the person who was just told they were invited.
  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    ref
      ..invalidate(workspacesProvider)
      ..invalidate(currentIdentityProvider);
    try {
      await ref.read(currentIdentityProvider.future);
    } on Object {
      // A failed re-read keeps the last answer; the button simply re-enables.
    }
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  Future<void> _signOut(Future<void> Function() returnToSignIn) async {
    setState(() => _leaving = true);
    try {
      await returnToSignIn();
    } finally {
      if (mounted) {
        setState(() => _leaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(canCreateWorkspacesProvider)) {
      return EmptyState(
        message: l10n.noWorkspace,
        primaryAction: widget.onAdd,
        actionLabel: l10n.addWorkspace,
      );
    }
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final user = ref.watch(currentIdentityProvider).value?.user;
    final name = switch (user) {
      final u? when u.displayName.trim().isNotEmpty => u.displayName.trim(),
      final u? when u.handle.trim().isNotEmpty => '@${u.handle.trim()}',
      _ => null,
    };
    final returnToSignIn = ref.watch(returnToServerSignInProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 24,
          vertical: 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.userPlus, size: 28, color: tokens.textTertiary),
              const SizedBox(height: 20),
              Text(
                l10n.noWorkspaceInviteTitle,
                style: CcTypography.title.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noWorkspaceInviteBody,
                style: CcTypography.body.copyWith(
                  color: tokens.textSecondary,
                  height: 1.5,
                ),
              ),
              if (name != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.noWorkspaceSignedInAs(name),
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CcButton(
                    variant: CcButtonVariant.secondary,
                    icon: AppIcons.refreshCw,
                    loading: _checking,
                    autofocus: true,
                    onPressed: _checking || _leaving
                        ? null
                        : () => unawaited(_checkAgain()),
                    child: Text(l10n.noWorkspaceCheckAgain),
                  ),
                  if (returnToSignIn != null)
                    CcButton(
                      variant: CcButtonVariant.ghost,
                      icon: AppIcons.logOut,
                      loading: _leaving,
                      onPressed: _leaving
                          ? null
                          : () => unawaited(_signOut(returnToSignIn)),
                      child: Text(l10n.noWorkspaceSignOut),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

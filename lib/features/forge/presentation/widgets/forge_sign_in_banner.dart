import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Whether [connections] say this workspace has no working forge sign-in.
///
/// Only a real answer counts: a `forgeConnectionsProvider` that could not ask
/// the server has no value (or keeps its last one), and an unreachable server
/// is not evidence that anyone signed out. A real answer lists every
/// supported forge. A connection the server reports as authenticated but
/// whose person grant lapsed ([ForgeConnection.needsSignIn]: revoked, expired
/// or voided by a Connect key rotation) is not a working sign-in either.
bool needsForgeSignIn(List<ForgeConnection>? connections) =>
    connections != null &&
    connections.isNotEmpty &&
    !connections.any((c) => c.authenticated && !c.needsSignIn);

/// Workspaces whose missing-sign-in warning was dismissed this session.
///
/// Session-scoped and per workspace: the warning comes back after a restart
/// while the sign-in is still missing, and dismissing it in one workspace
/// says nothing about another, which may use a different GitHub App.
class DismissedForgeSignInNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Hides the warning for [workspaceId] until the app restarts.
  void dismiss(String workspaceId) => state = {...state, workspaceId};
}

/// Tracks dismissed missing-sign-in warnings.
final dismissedForgeSignInProvider =
    NotifierProvider<DismissedForgeSignInNotifier, Set<String>>(
      DismissedForgeSignInNotifier.new,
    );

/// The workspace shell's warning that no code host answers for this
/// workspace: a sign-in expired or was revoked, or the workspace uses its own
/// GitHub App and this member has not signed in through it yet.
///
/// It replaces a full-screen gate. Everything that does not need the forge
/// keeps working, so the operator stays where they are and is offered the
/// one action that fixes it. Hidden on the settings page that already holds
/// the sign-in card, so the warning never points at the screen it sits on.
class ForgeSignInBanner extends ConsumerWidget {
  /// Creates a [ForgeSignInBanner].
  const ForgeSignInBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isDemoServerProvider)) {
      return const SizedBox.shrink();
    }
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null ||
        !needsForgeSignIn(ref.watch(forgeConnectionsProvider).value) ||
        ref.watch(dismissedForgeSignInProvider).contains(workspaceId)) {
      return const SizedBox.shrink();
    }
    final signInRoute = settingsProfileRoute(workspaceId);
    if (GoRouterState.of(context).matchedLocation == signInRoute) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Part of the shell chrome, like the title bar above it: same fill and a
    // closing hairline, so the panes below start on a clean edge instead of
    // butting against a bare padding strip.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderPrimary)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: CcAlert(
          variant: CcAlertVariant.warning,
          icon: AppIcons.gitBranch,
          title: l10n.forgeSignInBannerTitle,
          description: Text(l10n.forgeSignInBannerBody),
          trailing: CcButton(
            size: CcButtonSize.sm,
            onPressed: () => context.go(signInRoute),
            child: Text(l10n.forgeSignInBannerAction),
          ),
          onClose: () => ref
              .read(dismissedForgeSignInProvider.notifier)
              .dismiss(workspaceId),
        ),
      ),
    );
  }
}

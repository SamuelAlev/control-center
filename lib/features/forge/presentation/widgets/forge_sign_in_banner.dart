import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
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
/// supported forge. Only a [ForgeConnection.isUsable] connection is a working
/// sign-in: a lapsed, paused or unreachable one is not.
bool needsForgeSignIn(List<ForgeConnection>? connections) =>
    connections != null &&
    connections.isNotEmpty &&
    !connections.any((c) => c.isUsable);

/// What the shell banner says when nothing is usable: the most actionable
/// state among [connections] decides.
///
/// A lapsed grant ([ForgeConnectionStatus.needsSignIn]) is the reader's to
/// fix and comes first; a paused one is the workspace's sign-in service
/// having changed; a grant that only failed to renew right now
/// ([ForgeConnectionStatus.unreachable]) needs nothing from anyone, so a list
/// of only those shows no banner. Null when nothing needs saying.
ForgeConnection? forgeSignInBannerSubject(List<ForgeConnection>? connections) {
  if (!needsForgeSignIn(connections)) {
    return null;
  }
  for (final status in const [
    ForgeConnectionStatus.needsSignIn,
    ForgeConnectionStatus.paused,
  ]) {
    for (final c in connections!) {
      if (c.status == status) {
        return c;
      }
    }
  }
  if (connections!.any((c) => c.status == ForgeConnectionStatus.unreachable)) {
    return null;
  }
  return connections.first;
}

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
    final subject = forgeSignInBannerSubject(
      ref.watch(forgeConnectionsProvider).value,
    );
    if (workspaceId == null ||
        subject == null ||
        ref.watch(dismissedForgeSignInProvider).contains(workspaceId)) {
      return const SizedBox.shrink();
    }
    // The page that holds the sign-in needs no warning pointing at itself.
    if (GoRouterState.of(context).matchedLocation ==
        settingsAccountProfileRoute(workspaceId)) {
      return const SizedBox.shrink();
    }
    final signInRoute = settingsAccountsRoute(workspaceId);

    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final forge = subject.forge.displayName;
    final lane = signInLaneForForge(subject.forge);
    final (String title, String body) = switch (subject.status) {
      ForgeConnectionStatus.needsSignIn => (
        unusableConnectionLine(
          l10n,
          subject.status,
          forge,
          account: subject.username,
        )!,
        l10n.forgeSignInBannerBody,
      ),
      ForgeConnectionStatus.paused => (
        l10n.connectionPaused,
        l10n.forgeSignInBannerPausedBody,
      ),
      _ => (l10n.forgeSignInBannerTitle, l10n.forgeSignInBannerBody),
    };
    // A lapsed browser grant is one click from fixed, so the banner signs in
    // right here; everything else goes to the card that explains it.
    final signInHere =
        subject.status == ForgeConnectionStatus.needsSignIn && lane != null;
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
          variant: subject.status == ForgeConnectionStatus.paused
              ? CcAlertVariant.info
              : CcAlertVariant.warning,
          icon: subject.status == ForgeConnectionStatus.paused
              ? AppIcons.pause
              : AppIcons.gitBranch,
          title: title,
          description: Text(body),
          trailing: CcButton(
            size: CcButtonSize.sm,
            onPressed: signInHere
                ? () => unawaited(
                    showProviderSignInDialog(
                      context,
                      lane: lane,
                      workspaceId: workspaceId,
                    ),
                  )
                : () => context.go(signInRoute),
            child: Text(
              signInHere ? l10n.signInAgain : l10n.forgeSignInBannerAction,
            ),
          ),
          onClose: () => ref
              .read(dismissedForgeSignInProvider.notifier)
              .dismiss(workspaceId),
        ),
      ),
    );
  }
}

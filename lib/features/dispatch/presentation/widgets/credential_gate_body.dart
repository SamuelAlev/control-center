import 'package:cc_domain/cc_domain.dart'
    show RunCredentialBlockDto, RunCredentialLane, RunCredentialReason;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/harness_provider_login.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_account_row.dart'
    show claudeShortTime;
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// What a parked run's dialog shows: who is waiting, the server's own reason,
/// the two instants that bound the wait, and the lane-specific fix.
///
/// Split out of `credential_gate_overlay.dart` so the modal's control flow (open
/// when a block arrives, close when it leaves) stays readable next to the fix
/// forms, which are two entirely different surfaces sharing one frame.
class CredentialGateBody extends ConsumerWidget {
  /// Creates a [CredentialGateBody].
  const CredentialGateBody({
    required this.block,
    required this.onConnected,
    super.key,
  });

  /// The parked run being explained.

  final RunCredentialBlockDto block;

  /// Called when the embedded login panel reports a credential landed, so the
  /// server re-probes immediately instead of on its next poll.
  final VoidCallback onConnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final agent = block.agentName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          agent == null || agent.isEmpty
              ? l10n.credentialGateWaitingRun
              : l10n.credentialGateWaitingAgent(agent),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // The server's own sentence, verbatim. It is the same text the turn
        // fails with if nobody answers, so the dialog and the transcript can
        // never describe the block differently.
        Text(
          block.detail,
          style: TextStyle(
            fontSize: 12,
            color: t.textSecondary,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Deadlines(block: block),
        const SizedBox(height: AppSpacing.md),
        if (block.lane == RunCredentialLane.harness)
          _HarnessFix(providerId: block.providerId, onConnected: onConnected)
        else
          _ClaudeFix(block: block),
      ],
    );
  }
}

/// The two instants that matter while a run is parked: when the block clears by
/// itself (a plan window's reset — only [RunCredentialReason.planSpent] has
/// one) and when the gate gives up and the turn fails.
///
/// The second one is shown even though it is not urgent, because a bounded wait
/// nobody is told about is indistinguishable from a hang.
class _Deadlines extends StatelessWidget {
  const _Deadlines({required this.block});

  final RunCredentialBlockDto block;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final style = TextStyle(
      fontSize: 12,
      color: t.textTertiary,
      decoration: TextDecoration.none,
    );
    final availableAt = block.availableAt;
    final expiresAt = block.expiresAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.clock, size: 14, color: t.textTertiary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(l10n.credentialGateWatching, style: style)),
          ],
        ),
        if (availableAt != null) ...[
          const SizedBox(height: 2),
          AppTimestamp(
            dateTime: availableAt,
            child: Text(
              l10n.credentialGateFreesUpAt(claudeShortTime(availableAt)),
              style: style,
            ),
          ),
        ],
        if (expiresAt != null) ...[
          const SizedBox(height: 2),
          AppTimestamp(
            dateTime: expiresAt,
            child: Text(
              l10n.credentialGateGivesUpAt(claudeShortTime(expiresAt)),
              style: style,
            ),
          ),
        ],
      ],
    );
  }
}

/// The harness lane's fix, which is the whole Settings → Providers connect flow
/// rendered inline: API key, browser OAuth, device code, paste code.
///
/// [HarnessProviderLoginPanel] is reused rather than reimplemented — a second
/// copy of a four-branch auth flow would drift, and this one already handles
/// every branch.
class _HarnessFix extends ConsumerWidget {
  const _HarnessFix({required this.providerId, required this.onConnected});

  final String? providerId;
  final VoidCallback onConnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(harnessProvidersProvider).asData?.value;
    final id = providerId;
    if (providers == null || id == null) {
      return const SizedBox.shrink();
    }
    final info = providers.where((p) => p.id == id).firstOrNull;
    if (info == null) {
      // A provider the server named but the client's catalogue does not know
      // (a custom endpoint removed mid-run). The detail line above already
      // says what is missing; inventing a login form for it would not help.
      return const SizedBox.shrink();
    }
    return HarnessProviderLoginPanel(info: info, onConnected: onConnected);
  }
}

/// The Claude Code lane's fix. Control Center never performs this login — the
/// CLI owns it — so the panel names the accounts that were tried and points at
/// the one screen that hands over the login command.
class _ClaudeFix extends ConsumerWidget {
  const _ClaudeFix({required this.block});

  final RunCredentialBlockDto block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final roster = ref.watch(claudeAccountsProvider).asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.accountIds.isNotEmpty) ...[
          Text(
            l10n.credentialGateAccountsTried,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: t.textTertiary,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final id in block.accountIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(AppIcons.keyRound, size: 13, color: t.textTertiary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      // The roster's own label when the client has it, the raw
                      // id when it does not — an account can be named in a
                      // block that the list has not loaded yet.
                      roster
                              ?.where((v) => v.account.id == id)
                              .map((v) => v.account.label)
                              .firstOrNull ??
                          id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSecondary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (block.reason != RunCredentialReason.planSpent) ...[
          Text(
            l10n.credentialGateClaudeSignInHint,
            style: TextStyle(
              fontSize: 12,
              color: t.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: () {
                final workspaceId = context.currentWorkspaceId;
                if (workspaceId == null || workspaceId.isEmpty) {
                  return;
                }
                // The dialog closes: the login happens on that screen, and the
                // gate reopens this if the run is still parked when it is done
                // — it never stopped watching.
                Navigator.of(context).pop();
                context.go(settingsAdaptersRoute(workspaceId));
              },
              child: Text(l10n.credentialGateOpenSettings),
            ),
          ),
        ],
      ],
    );
  }
}

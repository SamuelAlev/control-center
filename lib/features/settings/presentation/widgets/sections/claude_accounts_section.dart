import 'package:cc_data/cc_data.dart' show RpcAccountPoolsRepository;
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/account_pool_editor.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_account_row.dart';
import 'package:control_center/features/settings/providers/account_pool_providers.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Claude Code runner's logins, shown in that runner's detail pane.
///
/// A nested card would rival the Detected runners eyebrow, so this is a
/// [SettingsGroup]: heading, sentence, roster. Each row is one
/// `CLAUDE_CONFIG_DIR` on the server. Control Center creates and deletes those
/// directories but never signs in: the sign-in action hands back the exact
/// `claude auth login` command, scoped with the account's config dir, for the
/// operator to run. That split is deliberate — minting Claude Code tokens from
/// another app is what the harness's Anthropic provider stopped doing, and the
/// CLI's own login is the supported way to reach a subscription.
class ClaudeAccountsSection extends ConsumerWidget {
  /// Creates a [ClaudeAccountsSection].
  const ClaudeAccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final accounts = ref.watch(claudeAccountsProvider);

    // Read through `value` / `hasError` rather than pattern-matching the
    // AsyncValue subtype. Riverpod retries a failed provider on its own (ten
    // times, backing off to 6.4s), and every retry passes back through
    // AsyncLoading — so a `_ => spinner` catch-all turned a failing read into a
    // spinner that never stopped, with the error it was retrying never once on
    // screen. A value that is merely being refreshed keeps its rows, too:
    // flashing the roster away on every invalidate reads as a reload of
    // something that did not change.
    final rows = accounts.value;
    return SettingsGroup(
      title: l10n.accounts,
      description: l10n.claudeAccountsDescription,
      showRule: true,
      separator: SettingsGroupSeparator.none,
      children: [
        if (rows != null)
          rows.isEmpty
              ? CcEmptyState(
                  icon: AppIcons.user,
                  message: l10n.claudeAccountsEmpty,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final view in rows)
                      ClaudeAccountRow(
                        view: view,
                        key: ValueKey(view.account.id),
                      ),
                  ],
                )
        else if (accounts.hasError)
          Text(
            l10n.claudeAccountStatusUnknown('${accounts.error}'),
            style: TextStyle(fontSize: 12, color: t.textErrorPrimary),
          )
        // Centered, not stretched: this Column is
        // `crossAxisAlignment: stretch`, which forces a bare spinner to
        // the pane's full width and draws it as a long thin arc.
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CcSpinner()),
          ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.plus,
            onPressed: () => _addAccount(context, ref),
            child: Text(l10n.claudeAccountAdd),
          ),
        ),
        // Rotation sits below the roster because it is a statement ABOUT
        // that roster — which of those accounts runs get spent on, and in
        // what order. It renders nothing until there are two.
        if ((rows?.length ?? 0) > 1) ...[
          const SizedBox(height: AppSpacing.lg),
          const CcDivider(),
          const SizedBox(height: AppSpacing.md),
          AccountPoolEditor(
            scope: const AccountPoolScope(
              lane: RpcAccountPoolsRepository.claudeLane,
            ),
            candidates: [
              for (final v in rows!)
                AccountPoolCandidate(
                  id: v.account.id,
                  label: v.account.label,
                  detail: _candidateDetail(l10n, v),
                  unavailable: !v.account.loggedIn || v.account.isRateLimited(),
                  // Expired AND signed out, never the timestamp alone: an
                  // access token that lapsed overnight is renewed by the CLI
                  // on the next run, and only the server can tell that from
                  // one nothing can renew.
                  unavailableReason:
                      !v.account.loggedIn && v.account.isCredentialExpired()
                      ? l10n.accountPoolExpired
                      : !v.account.loggedIn
                      ? l10n.accountPoolSignedOut
                      : v.account.isRateLimited()
                      ? l10n.accountPoolCoolingOff(
                          claudeShortTime(v.account.rateLimitedUntil!),
                        )
                      : null,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _addAccount(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(claudeAccountsRepositoryProvider);
    final created = await repo.create();
    ref.invalidate(claudeAccountsProvider);
    if (created == null || !context.mounted) {
      return;
    }
    // Straight into the sign-in instructions: an account directory with no
    // login in it does nothing, so creating one and stopping there would leave
    // a row that looks configured and refuses every run.
    await showClaudeLoginCommand(context, ref, created);
  }
}

/// `max · Weekly: 62% used` — what makes one account the better pick.
String? _candidateDetail(AppLocalizations l10n, ClaudeAccountView view) {
  final window = view.tightestWindow;
  final parts = [
    if (view.account.subtitle.isNotEmpty) view.account.subtitle,
    if (window != null) claudeWindowFact(l10n, window),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

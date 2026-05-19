import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `Session: 62% used` — the window's own name plus its spend.
String claudeWindowFact(AppLocalizations l10n, SubscriptionWindow window) {
  final percent = (window.usedFraction * 100).round();
  return '${window.label}: ${l10n.claudeAccountUsedPercent('$percent')}';
}

/// `14:20` — a cooldown is always within hours, so the date would be noise.
String claudeShortTime(DateTime at) {
  final local = at.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// One account row: identity, status, usage and the per-account actions.
class ClaudeAccountRow extends ConsumerWidget {
  /// Creates a [ClaudeAccountRow].
  const ClaudeAccountRow({required this.view, super.key});

  /// The account and its live usage.
  final ClaudeAccountView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final account = view.account;
    final window = view.tightestWindow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.fgPrimary,
                        ),
                      ),
                    ),
                    if (account.isDefault) ...[
                      const SizedBox(width: 6),
                      CcBadge(
                        label: l10n.claudeAccountDefault,
                        variant: CcBadgeVariant.neutral,
                      ),
                    ],
                    // Status by badge AND word, never colour alone.
                    //
                    // An expired sign-in is called that rather than "signed
                    // out": the two look identical to a run and could not be
                    // less alike to the operator — one account was never
                    // logged into, the other worked this morning and needs the
                    // same login run again.
                    //
                    // Both halves are required. A past `expiresAt` on its own
                    // is the NORMAL state of any account nobody used overnight
                    // — the CLI renews it from the refresh token on the next
                    // run — so the timestamp alone would paint a healthy roster
                    // red every morning. The server is what knows the
                    // difference (only it can see whether anything can renew
                    // the credential) and it says so by reporting the account
                    // signed out.
                    if (!account.loggedIn && account.isCredentialExpired()) ...[
                      const SizedBox(width: 6),
                      CcBadge(
                        label: l10n.claudeAccountExpired,
                        variant: CcBadgeVariant.warning,
                      ),
                    ] else if (!account.loggedIn) ...[
                      const SizedBox(width: 6),
                      CcBadge(
                        label: l10n.claudeAccountSignedOut,
                        variant: CcBadgeVariant.warning,
                      ),
                    ] else if (account.isRateLimited()) ...[
                      // A cooling-off account is signed in and still unusable.
                      // Without saying so, the operator reads a healthy row and
                      // cannot explain why runs are landing elsewhere.
                      const SizedBox(width: 6),
                      CcBadge(
                        label: l10n.accountPoolCoolingOff(
                          claudeShortTime(account.rateLimitedUntil!),
                        ),
                        variant: CcBadgeVariant.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(l10n, window),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: t.fgSecondary),
                ),
              ],
            ),
          ),
          CcMenu(
            semanticLabel: account.label,
            items: [
              CcMenuItem(
                label: account.loggedIn
                    ? l10n.claudeAccountSignInAgain
                    : l10n.claudeAccountSignIn,
                icon: AppIcons.externalLink,
                onSelected: () => showClaudeLoginCommand(context, ref, account),
              ),
              CcMenuItem(
                label: l10n.claudeAccountMakeDefault,
                icon: AppIcons.check,
                enabled: !account.isDefault,
                onSelected: () async {
                  await ref
                      .read(claudeAccountsRepositoryProvider)
                      .setDefault(account.id);
                  ref.invalidate(claudeAccountsProvider);
                },
              ),
              const CcMenuItem.divider(),
              CcMenuItem(
                label: l10n.remove,
                icon: AppIcons.trash2,
                destructive: true,
                onSelected: () => _confirmRemove(context, ref, account),
              ),
            ],
            target: Icon(
              AppIcons.moreHorizontal,
              size: 16,
              color: t.fgSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// The row's second line: the account's identity, plus how much of its
  /// tightest plan window is spent — the fact that decides which login to use.
  String _subtitle(AppLocalizations l10n, SubscriptionWindow? window) {
    final account = view.account;
    // The expiry outranks a quota reading: usage the account can no longer
    // spend is not the fact worth the one line this row has. Same pairing as
    // the badge — a past `expiresAt` only means the account is dead when the
    // server also reports it signed out.
    final expiresAt = account.credentialExpiresAt;
    if (expiresAt != null &&
        !account.loggedIn &&
        account.isCredentialExpired()) {
      return l10n.claudeAccountExpiredDetail(claudeShortTime(expiresAt));
    }
    final error = account.statusError;
    if (error != null) {
      return l10n.claudeAccountStatusUnknown(error);
    }
    final parts = [
      if (account.email != null && account.email!.isNotEmpty) account.email!,
      if (account.subtitle.isNotEmpty) account.subtitle,
      if (window != null) claudeWindowFact(l10n, window),
    ];
    return parts.join(' · ');
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    ClaudeAccount account,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (context) => CcDialog(
        title: l10n.claudeAccountRemoveConfirm(account.label),
        content: Text(l10n.claudeAccountRemoveDetail),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(claudeAccountsRepositoryProvider).remove(account.id);
    ref.invalidate(claudeAccountsProvider);
  }
}

/// Shows the exact `claude auth login` invocation for [account], ready to copy.
///
/// Control Center does not run it: the login opens a browser and binds a
/// loopback callback, neither of which a sandboxed shell can do — and on a
/// remote server the browser belongs to whoever is sitting at it. Handing over
/// the command (with `CLAUDE_CONFIG_DIR` already set to the right directory) is
/// the honest version of that.
Future<void> showClaudeLoginCommand(
  BuildContext context,
  WidgetRef ref,
  ClaudeAccount account,
) async {
  final l10n = AppLocalizations.of(context);
  final cmd = await ref
      .read(claudeAccountsRepositoryProvider)
      .loginCommand(account.id);
  if (cmd == null || !context.mounted) {
    return;
  }
  final line = [
    for (final e in cmd.environment.entries) '${e.key}=${_shellQuote(e.value)}',
    ...cmd.argv.map(_shellQuote),
  ].join(' ');

  await showCcDialog<void>(
    context: context,
    builder: (context) {
      final t = context.designSystem ?? DesignSystemTokens.light();
      return CcDialog(
        title: l10n.claudeAccountSignIn,
        onClose: () => Navigator.of(context).pop(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.claudeAccountSignInHint,
              style: TextStyle(fontSize: 12, color: t.fgSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: t.bgTertiary,
                borderRadius: AppRadii.brLg,
              ),
              // Plain Text, not SelectableText: cc_ui builds on
              // flutter/widgets.dart only and the copy button below is the
              // affordance anyway.
              child: Text(
                line,
                style: CcFonts.code(
                  textStyle: TextStyle(fontSize: 12, color: t.fgPrimary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            icon: AppIcons.copy,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: line));
            },
            child: Text(l10n.copy),
          ),
          CcButton(
            onPressed: () {
              Navigator.of(context).pop();
              // The login happens outside this app, so nothing tells us when
              // it finished — re-read on dismiss, which is the moment the
              // operator believes they are done.
              ref.invalidate(claudeAccountsProvider);
            },
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}

/// POSIX-quotes one argv element so a path with a space survives a paste.
String _shellQuote(String s) {
  if (s.isEmpty) {
    return "''";
  }
  if (RegExp(r'^[A-Za-z0-9_\-./=:@%+,]+$').hasMatch(s)) {
    return s;
  }
  return "'${s.replaceAll("'", r"'\''")}'";
}

import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_login_command_block.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the Claude Code sign-in dialog: every account that needs a human to
/// sign it in again, each with its own `claude auth login` command.
///
/// Opened from a turn that failed on its credential, which does not know which
/// account it ran on. Reading the roster fresh is what finds it: the failing
/// run flagged that account just before the turn ended.
Future<void> showClaudeSignInDialog(BuildContext context, WidgetRef ref) {
  ref.invalidate(claudeAccountsProvider);
  return showCcDialog<void>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final t = context.designSystem ?? DesignSystemTokens.light();
      return CcDialog(
        title: l10n.claudeSignInDialogTitle,
        onClose: () => Navigator.of(context).pop(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.claudeSignInDialogHint,
              style: TextStyle(
                fontSize: 12,
                color: t.fgSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const ClaudeSignInAccountList(),
          ],
        ),
        actions: [
          CcButton(
            onPressed: () {
              Navigator.of(context).pop();
              // The login happens outside this app; dismissing is the moment
              // the operator believes it is done.
              ref.invalidate(claudeAccountsProvider);
            },
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}

/// The accounts a human has to sign in again, each with its login command.
///
/// With [accountIds] (a parked run names the accounts it tried) exactly those
/// are listed, since each of them already failed. Without, every account the
/// roster reports as needing a sign-in. When neither finds one, the run used
/// the CLI's own login, and the plain command is what fixes it.
class ClaudeSignInAccountList extends ConsumerWidget {
  /// Creates a [ClaudeSignInAccountList].
  const ClaudeSignInAccountList({this.accountIds = const [], super.key});

  /// The accounts to list. Empty means "whichever need a sign-in".
  final List<String> accountIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final roster = ref.watch(claudeAccountsProvider);
    final views = roster.asData?.value;
    if (views == null) {
      return roster.hasError
          ? Text(
              l10n.claudeSignInCommandUnavailable,
              style: _style(t.textSecondary),
            )
          : const Center(child: CcSpinner(size: 16));
    }

    final rows = <({String id, ClaudeAccount? account})>[
      if (accountIds.isNotEmpty)
        for (final id in accountIds)
          (
            id: id,
            account: views
                .where((v) => v.account.id == id)
                .map((v) => v.account)
                .firstOrNull,
          )
      else
        for (final v in views)
          if (v.account.needsSignIn()) (id: v.account.id, account: v.account),
    ];

    if (rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.claudeSignInNoAccounts, style: _style(t.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          const ClaudeLoginCommandBlock(line: 'claude auth login'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          _AccountSignInRow(id: rows[i].id, account: rows[i].account),
        ],
      ],
    );
  }
}

/// One account: who it is, why it needs signing in, and the command.
class _AccountSignInRow extends ConsumerWidget {
  const _AccountSignInRow({required this.id, required this.account});

  final String id;

  /// Null when the block names an account the roster has not loaded.
  final ClaudeAccount? account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final a = account;
    final command = ref.watch(claudeLoginCommandProvider(id));
    final status = a == null
        ? null
        : a.isCredentialExpired()
        ? l10n.claudeAccountExpired
        : !a.loggedIn
        ? l10n.claudeAccountSignedOut
        : a.authFailedAt != null
        ? l10n.claudeAccountSignInFailed
        : null;
    final email = a?.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                a?.label ?? id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.fgPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            if (status != null) ...[
              const SizedBox(width: AppSpacing.sm),
              CcBadge(label: status, variant: CcBadgeVariant.warning),
            ],
          ],
        ),
        if (email != null && email.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _style(t.fgSecondary, size: 11),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        switch (command) {
          AsyncData(:final value?) => ClaudeLoginCommandBlock(
            line: claudeShellLine(value),
          ),
          AsyncData() || AsyncError() => Text(
            l10n.claudeSignInCommandUnavailable,
            style: _style(t.textSecondary),
          ),
          _ => const Align(
            alignment: AlignmentDirectional.centerStart,
            child: CcSpinner(size: 16),
          ),
        },
      ],
    );
  }
}

TextStyle _style(Color color, {double size = 12}) =>
    TextStyle(fontSize: size, color: color, decoration: TextDecoration.none);

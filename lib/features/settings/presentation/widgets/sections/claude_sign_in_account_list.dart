import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_login_command_block.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/claude_sign_in_watch.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `claude auth login` argv and environment the host hands out.
typedef _LoginCommand = ({List<String> argv, Map<String, String> environment});

/// The accounts a human has to sign in again, each with its login command.
///
/// With [accountIds] (one account's own dialog, or a parked run naming the
/// accounts it tried) exactly those are listed. Without, every account the
/// roster reports as needing a sign-in. When neither finds one, the run used
/// the CLI's own login, and the plain command is what fixes it.
///
/// The login runs in a terminal, so nothing reports back when it is done.
/// Where a command was handed out, the list watches [claudeSignInsProvider]
/// for it: an account that got signed in reads as signed in and stays listed,
/// and once all of them are, [onAllSignedIn] is called.
class ClaudeSignInAccountList extends ConsumerStatefulWidget {
  /// Creates a [ClaudeSignInAccountList].
  const ClaudeSignInAccountList({
    this.accountIds = const [],
    this.showIdentity = true,
    this.onAllSignedIn,
    super.key,
  });

  /// The accounts to list. Empty means "whichever need a sign-in".
  final List<String> accountIds;

  /// Whether each command is headed by its account's name and state. A surface
  /// about one account it already names leaves that out.
  final bool showIdentity;

  /// Called once, when every listed account is signed in. A surface that
  /// passes it closes itself then, and the list says so under the commands.
  final VoidCallback? onAllSignedIn;

  @override
  ConsumerState<ClaudeSignInAccountList> createState() =>
      _ClaudeSignInAccountListState();
}

class _ClaudeSignInAccountListState
    extends ConsumerState<ClaudeSignInAccountList> {
  /// Accounts a sign-in finished on while this list was up. The roster stops
  /// reporting them as needing one, so this is what keeps them listed.
  final Set<String> _signedIn = {};

  /// Whether [ClaudeSignInAccountList.onAllSignedIn] was called.
  bool _reported = false;

  /// [now] against [before] is what finished since the last reading, so a
  /// list only ever hears of sign-ins that happened while it was up.
  void _onSignIns(Set<String>? before, Set<String> now, List<String> listed) {
    final finished = now.difference(before ?? const {});
    if (finished.isEmpty) {
      return;
    }
    setState(() => _signedIn.addAll(finished));
    if (!_reported && _signedIn.containsAll(listed)) {
      _reported = true;
      widget.onAllSignedIn?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final roster = ref.watch(claudeAccountsProvider);
    // `value`, not the AsyncValue subtype: a roster being re-read after a
    // sign-in keeps its rows.
    final views = roster.value;
    final named = widget.accountIds;
    if (views == null && named.isEmpty) {
      return roster.hasError
          ? Text(
              l10n.claudeSignInCommandUnavailable,
              style: _style(t.textSecondary),
            )
          : const Center(child: CcSpinner(size: 16));
    }

    final rows = <({String id, ClaudeAccount? account})>[
      if (named.isNotEmpty)
        for (final id in named)
          (
            id: id,
            account: views
                ?.where((v) => v.account.id == id)
                .map((v) => v.account)
                .firstOrNull,
          )
      else
        for (final v in views!)
          if (v.account.needsSignIn() || _signedIn.contains(v.account.id))
            (id: v.account.id, account: v.account),
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

    final commands = {
      for (final row in rows)
        row.id: ref.watch(claudeLoginCommandProvider(row.id)),
    };
    // A sign-in can only be waited for where its command was handed out: the
    // host gives both to the same person, and refuses both to anyone else.
    final watching = commands.values.any((command) => command.value != null);
    if (watching) {
      final listed = [for (final row in rows) row.id];
      ref.listen(
        claudeSignInsProvider,
        (before, now) => _onSignIns(before, now, listed),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          _AccountSignInRow(
            id: rows[i].id,
            account: rows[i].account,
            command: commands[rows[i].id]!,
            showIdentity: widget.showIdentity,
            signedIn: _signedIn.contains(rows[i].id),
          ),
        ],
        if (watching && widget.onAllSignedIn != null) ...[
          const SizedBox(height: AppSpacing.md),
          _SignInWatchLine(
            signedIn: rows.every((row) => _signedIn.contains(row.id)),
            several: rows.length > 1,
          ),
        ],
      ],
    );
  }
}

/// One account: who it is, why it needs signing in, and the command.
class _AccountSignInRow extends StatelessWidget {
  const _AccountSignInRow({
    required this.id,
    required this.account,
    required this.command,
    required this.showIdentity,
    required this.signedIn,
  });

  final String id;

  /// Null when the list names an account the roster has not loaded.
  final ClaudeAccount? account;

  final AsyncValue<_LoginCommand?> command;

  final bool showIdentity;

  /// Whether a sign-in finished on this account while the list was up.
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final a = account;
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
        if (showIdentity) ...[
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
              // What the watch saw outranks the roster, which is re-read a
              // moment later and may still describe the old credential.
              if (signedIn) ...[
                const SizedBox(width: AppSpacing.sm),
                CcBadge(
                  label: l10n.claudeAccountSignedIn,
                  variant: CcBadgeVariant.success,
                ),
              ] else if (status != null) ...[
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
        ],
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

/// Under the commands of a surface that closes itself: that it is watching for
/// the sign-in, then that the sign-in happened.
class _SignInWatchLine extends StatelessWidget {
  const _SignInWatchLine({required this.signedIn, required this.several});

  /// Whether every listed account is signed in.
  final bool signedIn;

  /// Whether more than one account is listed.
  final bool several;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Semantics(
      // The change is the news: a screen reader hears the sign-in land.
      liveRegion: true,
      child: Row(
        children: [
          if (signedIn)
            Icon(AppIcons.check, size: 14, color: t.fgSuccessPrimary)
          else
            const CcSpinner(size: 12, strokeWidth: 1.5),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              signedIn
                  ? l10n.signedIn
                  : several
                  ? l10n.claudeSignInClosesItselfAll
                  : l10n.claudeSignInClosesItself,
              style: _style(signedIn ? t.textPrimary : t.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _style(Color color, {double size = 12}) =>
    TextStyle(fontSize: size, color: color, decoration: TextDecoration.none);

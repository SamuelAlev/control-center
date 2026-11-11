import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_login_command_block.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_sign_in_account_list.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the exact `claude auth login` invocation for [account], ready to copy.
///
/// Control Center does not run it: the login opens a browser and binds a
/// loopback callback, neither of which a sandboxed shell can do — and on a
/// remote server the browser belongs to whoever is sitting at it. Handing over
/// the command (with `CLAUDE_CONFIG_DIR` already set to the right directory) is
/// the honest version of that.
Future<void> showClaudeLoginCommand(
  BuildContext context,
  ClaudeAccount account,
) => showCcDialog<void>(
  context: context,
  builder: (context) => _ClaudeSignInDialog(account: account),
);

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
    builder: (context) => const _ClaudeSignInDialog(),
  );
}

/// The dialog both sign-ins share: the commands, and the wait for them.
///
/// The login runs in a terminal, so nothing reports back when it is done. The
/// list inside watches for it. Once every listed account is signed in the
/// dialog closes itself, after the roster behind it was re-read, so the
/// account's row is already right when the dialog is gone. Closed any other
/// way (the close control, Escape, the scrim, the button) it re-reads the
/// roster then: that is the moment the operator believes they are done.
class _ClaudeSignInDialog extends ConsumerStatefulWidget {
  const _ClaudeSignInDialog({this.account});

  /// The one account to sign in. Null lists every account that needs it.
  final ClaudeAccount? account;

  @override
  ConsumerState<_ClaudeSignInDialog> createState() =>
      _ClaudeSignInDialogState();
}

class _ClaudeSignInDialogState extends ConsumerState<_ClaudeSignInDialog> {
  /// How long the dialog waits for the roster before closing anyway.
  static const _rosterWait = Duration(seconds: 10);

  /// Whether the roster was already re-read for the sign-in this dialog
  /// waited on, so that closing does not read it a second time.
  bool _rosterRead = false;

  Future<void> _closeSignedIn() async {
    _rosterRead = true;
    try {
      // The watch invalidated the roster when it saw the sign-in. This is
      // that read, so the row behind the dialog is right before it shows.
      await ref.read(claudeAccountsProvider.future).timeout(_rosterWait);
    } on Object {
      // The roster reports its own failure where it is shown. The sign-in
      // happened either way.
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final account = widget.account;
    final command = account == null
        ? null
        : ref.watch(claudeLoginCommandProvider(account.id)).value;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_rosterRead) {
          ref.invalidate(claudeAccountsProvider);
        }
      },
      child: CcDialog(
        title: account == null
            ? l10n.claudeSignInDialogTitle
            : l10n.claudeAccountSignIn,
        onClose: () => Navigator.of(context).pop(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              account == null
                  ? l10n.claudeSignInDialogHint
                  : l10n.claudeAccountSignInHint,
              style: TextStyle(
                fontSize: 12,
                color: t.fgSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClaudeSignInAccountList(
              accountIds: [if (account != null) account.id],
              // One account, and the row it was opened from already names it.
              showIdentity: account == null,
              onAllSignedIn: _closeSignedIn,
            ),
          ],
        ),
        actions: [
          if (command != null)
            CcButton(
              variant: CcButtonVariant.secondary,
              icon: AppIcons.copy,
              onPressed: () => Clipboard.setData(
                ClipboardData(text: claudeShellLine(command)),
              ),
              child: Text(l10n.copy),
            ),
          CcButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_ui/cc_ui.dart';
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
  final line = _shellLine(cmd);

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
            _CommandBlock(line: line),
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

/// A shell command in a code box. Plain Text, not SelectableText: cc_ui builds
/// on flutter/widgets.dart only and the copy button beside it is the
/// affordance anyway.
class _CommandBlock extends StatelessWidget {
  const _CommandBlock({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t.bgTertiary,
        borderRadius: AppRadii.brLg,
      ),
      child: Text(
        line,
        // RTL carve-out: a shell command reads left to right in every locale.
        textDirection: TextDirection.ltr,
        style: CcFonts.code(
          textStyle: TextStyle(fontSize: 12, color: t.fgPrimary),
        ),
      ),
    );
  }
}

/// `CLAUDE_CONFIG_DIR=… claude …` — one pasteable line.
String _shellLine(({List<String> argv, Map<String, String> environment}) cmd) =>
    [
      for (final e in cmd.environment.entries)
        '${e.key}=${_shellQuote(e.value)}',
      ...cmd.argv.map(_shellQuote),
    ].join(' ');

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

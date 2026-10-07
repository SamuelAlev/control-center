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

/// Walks the operator through giving [account] a long-lived token: the
/// `claude setup-token` command to run, then a field to paste what it prints.
///
/// This is the sign-in that does not expire overnight. The interactive login's
/// refresh token rotates, so its copies sign each other out; a setup token
/// never refreshes. Control Center still mints nothing — the CLI does, in the
/// operator's terminal.
Future<void> showClaudeLongLivedTokenDialog(
  BuildContext context,
  WidgetRef ref,
  ClaudeAccount account,
) async {
  final cmd = await ref
      .read(claudeAccountsRepositoryProvider)
      .setupTokenCommand(account.id);
  if (cmd == null || !context.mounted) {
    return;
  }
  await showCcDialog<void>(
    context: context,
    builder: (context) =>
        _LongLivedTokenDialog(account: account, line: _shellLine(cmd)),
  );
}

class _LongLivedTokenDialog extends ConsumerStatefulWidget {
  const _LongLivedTokenDialog({required this.account, required this.line});

  final ClaudeAccount account;
  final String line;

  @override
  ConsumerState<_LongLivedTokenDialog> createState() =>
      _LongLivedTokenDialogState();
}

class _LongLivedTokenDialogState extends ConsumerState<_LongLivedTokenDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final token = _controller.text.trim();
    // The server checks the same shape; checking here too is what lets the
    // error be localized rather than the server's English sentence.
    if (!token.startsWith('sk-ant-oat01-') || token.contains(RegExp(r'\s'))) {
      setState(() => _invalid = true);
      return;
    }
    setState(() {
      _busy = true;
      _invalid = false;
    });
    try {
      await ref
          .read(claudeAccountsRepositoryProvider)
          .setToken(widget.account.id, token);
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _invalid = true;
        });
      }
      return;
    }
    ref.invalidate(claudeAccountsProvider);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcDialog(
      title: l10n.claudeAccountLongLivedToken,
      onClose: () => Navigator.of(context).pop(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.claudeAccountLongLivedTokenHint,
            style: TextStyle(fontSize: 12, color: t.fgSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _CommandBlock(line: widget.line)),
              const SizedBox(width: AppSpacing.sm),
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                icon: AppIcons.copy,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.line));
                },
                child: Text(l10n.copy),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CcTextField(
            controller: _controller,
            // A literal example, not copy: it is the token's own shape.
            hintText: 'sk-ant-oat01-…',
            obscureText: true,
            autofocus: true,
            errorText: _invalid
                ? l10n.claudeAccountLongLivedTokenInvalid
                : null,
            onSubmitted: (_) => _busy ? null : _save(),
          ),
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(onPressed: _busy ? null : _save, child: Text(l10n.save)),
      ],
    );
  }
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

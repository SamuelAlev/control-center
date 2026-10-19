import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// `CLAUDE_CONFIG_DIR=… claude …` — one pasteable line.
String claudeShellLine(
  ({List<String> argv, Map<String, String> environment}) cmd,
) => [
  for (final e in cmd.environment.entries) '${e.key}=${_shellQuote(e.value)}',
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

/// A shell command in a code box, with its own copy control.
///
/// Plain Text, not SelectableText: cc_ui builds on flutter/widgets.dart only,
/// and the copy button beside the line is the affordance anyway. The line
/// wraps rather than scrolling: an account directory path is long, and a
/// clipped command is one nobody can check before pasting.
class ClaudeLoginCommandBlock extends StatefulWidget {
  /// Creates a [ClaudeLoginCommandBlock] for [line].
  const ClaudeLoginCommandBlock({required this.line, super.key});

  /// The full command, exactly as it is copied.
  final String line;

  @override
  State<ClaudeLoginCommandBlock> createState() =>
      _ClaudeLoginCommandBlockState();
}

class _ClaudeLoginCommandBlockState extends State<ClaudeLoginCommandBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.line));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
        end: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: t.bgTertiary,
        borderRadius: AppRadii.brLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                widget.line,
                // RTL carve-out: a shell command reads left to right in every
                // locale.
                textDirection: TextDirection.ltr,
                style: CcFonts.code(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: t.fgPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          CcIconButton(
            icon: _copied ? AppIcons.check : AppIcons.copy,
            size: CcButtonSize.sm,
            color: t.textTertiary,
            tooltip: _copied ? l10n.copied : l10n.copy,
            onPressed: _copy,
          ),
        ],
      ),
    );
  }
}

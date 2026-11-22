import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The quiet line on an approval or a question that a script the agent is
/// running raised, not the agent directly. The phone shows the space the
/// request came from (the inbox card's "open space"); the line says what in
/// it asked.
class ScriptOriginLine extends StatelessWidget {
  const ScriptOriginLine({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        Icon(CcIcons.code, size: 12, color: t.textTertiary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            AppLocalizations.of(context).scriptOriginLine,
            style: TextStyle(fontSize: 12, color: t.textTertiary),
          ),
        ),
      ],
    );
  }
}

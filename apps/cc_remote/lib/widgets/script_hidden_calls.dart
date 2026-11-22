import 'package:cc_domain/core/domain/services/tool_display_name.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_text.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// How many tools a hidden-calls control names before it trails off.
const int phoneScriptHiddenToolsShown = 4;

/// The hidden calls of a fold by tool, as the phone names a tool, the
/// rarest first: `Bash 1 · Read 4,994`, and `…` after
/// [phoneScriptHiddenToolsShown] tools. Tools that read the same are counted
/// together; each name is drawn as [scriptToolLabel] gives it, so none can
/// push the next off the line.
String phoneScriptHiddenTools(
  AppLocalizations l10n,
  List<({String? tool, int count})> byTool,
) {
  final counts = <String, int>{};
  for (final (:tool, :count) in byTool) {
    final name = tool == null
        ? l10n.scriptToolComputed
        : resolveToolDisplayName(
            tool,
            todos: l10n.transcriptToolTodos,
            searchMemory: l10n.transcriptToolSearchMemory,
            renderMedia: l10n.transcriptToolRenderMedia,
          );
    counts[name] = (counts[name] ?? 0) + count;
  }
  final first = {for (final (i, name) in counts.keys.indexed) name: i};
  // Tools hidden as often keep the order they were first hidden in.
  final ordered = counts.entries.toList()
    ..sort(
      (a, b) => a.value != b.value
          ? a.value.compareTo(b.value)
          : first[a.key]!.compareTo(first[b.key]!),
    );
  final number = NumberFormat.decimalPattern(l10n.localeName);
  return [
    for (final entry in ordered.take(phoneScriptHiddenToolsShown))
      '${scriptToolLabel(entry.key)} ${number.format(entry.value)}',
    if (ordered.length > phoneScriptHiddenToolsShown) '…',
  ].join(' · ');
}

/// Opens the calls folded out of a long group, and says what they are; a
/// full phone touch target.
class PhoneScriptHiddenCalls extends StatelessWidget {
  /// Creates the control for [count] hidden calls.
  const PhoneScriptHiddenCalls({
    super.key,
    required this.count,
    required this.tools,
    required this.onPressed,
  });

  /// How many calls are hidden.
  final int count;

  /// The hidden calls by tool ([phoneScriptHiddenTools]); empty for none.
  final String tools;

  /// Opens them.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onPressed,
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(AppIcons.moreHorizontal, size: 13, color: t.fgTertiary),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).scriptCallsHidden(count),
                    style: TextStyle(fontSize: 12, color: t.textSecondary),
                  ),
                  if (tools.isNotEmpty)
                    Text(
                      tools,
                      // A phone line holds about 35 characters: two lines
                      // keep the second tool in sight after a long first.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: t.textTertiary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

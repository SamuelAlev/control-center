import 'package:cc_domain/features/code_mode/domain/services/script_run_view_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// How many tools a hidden-calls control names before it trails off.
const int scriptHiddenToolsShown = 4;

/// What a hidden-calls control adds to its count: the hidden calls by tool,
/// as the rows name them ([label]), the rarest first, `Bash 1 · Edit 3 ·
/// Read 4,991`, and `…` after [scriptHiddenToolsShown] tools. Tools whose
/// rows read the same are counted together; a computed tool name reads as
/// [AppLocalizations.scriptToolComputed]. Each name is drawn as
/// [scriptToolLabel] gives it, so none can push the next off the line.
String scriptHiddenTools(
  AppLocalizations l10n,
  List<({String? tool, int count})> byTool,
  String Function(String tool) label,
) {
  final counts = <String, int>{};
  for (final (:tool, :count) in byTool) {
    final name = tool == null ? l10n.scriptToolComputed : label(tool);
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
    for (final entry in ordered.take(scriptHiddenToolsShown))
      '${scriptToolLabel(entry.key)} ${number.format(entry.value)}',
    if (ordered.length > scriptHiddenToolsShown) '…',
  ].join(' · ');
}

/// The control that opens the calls hidden from the middle of a long group,
/// with what they are: `Show 4,995 more calls · Bash 1 · Read 4,994`.
class ScriptHiddenCallsButton extends StatelessWidget {
  /// Creates the control for [count] hidden calls.
  const ScriptHiddenCallsButton({
    super.key,
    required this.count,
    required this.tools,
    required this.onPressed,
  });

  /// How many calls are hidden.
  final int count;

  /// The hidden calls by tool, as `scriptHiddenTools` words them; empty for
  /// none.
  final String tools;

  /// Opens them.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: CcTappable(
        onPressed: onPressed,
        builder: (context, states) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 8, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.ellipsis, size: 12, color: t.textTertiary),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: AppLocalizations.of(context).scriptCallsHidden(count),
                    children: [
                      if (tools.isNotEmpty)
                        TextSpan(
                          text: ' · $tools',
                          style: TextStyle(color: t.textTertiary),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.caption.copyWith(
                    color: states.contains(WidgetState.hovered)
                        ? t.textPrimary
                        : t.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

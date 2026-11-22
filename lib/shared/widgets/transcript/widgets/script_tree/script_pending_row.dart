import 'package:cc_domain/core/domain/services/tool_display_name.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/transcript/tool_presentation.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_tree_rows.dart';
import 'package:flutter/widgets.dart';

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

// Stands in for a property whose value is an expression, so the made row's
// caption rule can be asked which property it would show. Private-use code
// points: no path, pattern or command the rule shortens contains them.
const String _open = '\u{E000}';
const String _close = '\u{E001}';
final RegExp _marker = RegExp('$_open(\\d+)$_close');
final RegExp _stray = RegExp('[$_open$_close]\\d*');

/// What a call the script has not made reads as: the same verb and caption
/// its row will have once made, from the made row's own rule
/// ([resolveToolPresentation]) fed with the call's argument as written.
///
/// A property whose value is a plain literal is passed as that value, so a
/// queued `Read README.md` reads exactly as the made one. One whose value is
/// an expression is passed as a marker, and where the caption shows it, its
/// source text shows instead and `captionIsCode` is set (`Read file`). With
/// no object-literal argument the caption is the argument text.
({IconData? icon, String? verb, String? caption, bool captionIsCode})
scriptPendingPresentation(ScriptCallNode site) {
  final name = site.toolName;
  if (name == null) {
    return (
      icon: null,
      verb: null,
      caption: site.argumentText.isEmpty ? null : site.argumentText,
      captionIsCode: true,
    );
  }
  final properties = site.properties;
  final p = resolveToolPresentation(
    ToolSegment(
      toolName: name,
      toolCallId: '',
      startedAt: _epoch,
      inputs: properties.isEmpty
          ? null
          : {
              for (var i = 0; i < properties.length; i++)
                properties[i].key: properties[i].value ?? '$_open$i$_close',
            },
    ),
  );
  var code = false;
  String? fill(String? text) => text
      ?.replaceAllMapped(_marker, (m) {
        code = true;
        return properties[int.parse(m[1]!)].source;
      })
      // A marker the rule cut in half.
      .replaceAll(_stray, '');
  // A verb made from the name is the script's own text; one that is a
  // `description` stays the made row's wording.
  final verb = p.verb == resolveToolDisplayName(name)
      ? scriptToolLabel(p.verb)
      : fill(p.verb);
  code = false;
  final caption = fill(p.subtitle);
  if (caption == null && properties.isEmpty && site.argumentText.isNotEmpty) {
    return (
      icon: p.icon,
      verb: verb,
      caption: site.argumentText,
      captionIsCode: true,
    );
  }
  return (icon: p.icon, verb: verb, caption: caption, captionIsCode: code);
}

/// A tool's verb as a transcript row shows it (`Read`, `Bash`), from its
/// name alone.
String scriptToolVerb(String tool) => resolveToolPresentation(
  ToolSegment(toolName: tool, toolCallId: '', startedAt: _epoch),
).verb;

/// A call the script has not made: the quiet form of its tool row, worded
/// the way that row will be ([scriptPendingPresentation]), with "Queued" or
/// "Skipped" where the duration would be, or nothing when it cannot be told
/// whether the call was made ([ScriptStepState.unknown]). No spinner:
/// nothing is running.
///
/// Same geometry as a transcript tool row, so when the call is made the row
/// that replaces it sits on the same line and only its state changes.
class ScriptPendingRow extends StatelessWidget {
  /// Creates the row for [site].
  const ScriptPendingRow({
    super.key,
    required this.site,
    required this.state,
    required this.codeFont,
  });

  /// The call node.
  final ScriptCallNode site;

  /// [ScriptStepState.queued], [ScriptStepState.skipped] or
  /// [ScriptStepState.unknown].
  final ScriptStepState state;

  /// Mono font for the tool and its arguments.
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final p = scriptPendingPresentation(site);
    final verb = p.verb ?? l10n.scriptToolComputed;
    final skipped =
        state == ScriptStepState.skipped || state == ScriptStepState.unknown;
    final word = scriptPendingWord(l10n, state);
    final subject = [verb, ?p.caption].join(' ');
    final base = AppFonts.codeDynamic(
      codeFont,
      textStyle: CcTypography.caption.copyWith(color: t.textTertiary),
    );
    return Semantics(
      label: word == null ? subject : l10n.scriptStepSemantics(subject, word),
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: t.borderSecondary, width: 2),
          ),
        ),
        padding: const EdgeInsetsDirectional.only(start: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                p.icon ?? AppIcons.wrench,
                size: 14,
                color: t.textQuaternary,
              ),
              const SizedBox(width: 6),
              Expanded(
                // The made row's summary, quieter: verb, two spaces, caption.
                child: Text.rich(
                  TextSpan(
                    style: base,
                    children: [
                      TextSpan(
                        text: verb,
                        style: base.copyWith(
                          color: skipped ? t.textQuaternary : t.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (p.caption case final caption?) ...[
                        const TextSpan(text: '  '),
                        TextSpan(
                          text: caption,
                          style: p.captionIsCode || skipped
                              ? base.copyWith(color: t.textQuaternary)
                              : null,
                        ),
                      ],
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (word != null) ...[
                const SizedBox(width: 6),
                Text(
                  word,
                  style: CcTypography.caption.copyWith(
                    color: t.textQuaternary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  state == ScriptStepState.skipped
                      ? AppIcons.minusCircle
                      : AppIcons.circleDashed,
                  size: 12,
                  color: t.textQuaternary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cc_domain/core/domain/services/tool_display_name.dart';
import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_text.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The word for a row or arm no call has reached, or null when it cannot be
/// told whether one did ([ScriptStepState.unknown]).
String? phoneScriptPendingWord(AppLocalizations l10n, ScriptStepState state) =>
    switch (state) {
      ScriptStepState.skipped => l10n.scriptStepSkipped,
      ScriptStepState.unknown => null,
      _ => l10n.scriptStepQueued,
    };

/// Where code laid out left to right lines up: at the start of the line,
/// which is its right edge in a right-to-left layout.
TextAlign phoneScriptCodeAlign(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? TextAlign.end
    : TextAlign.start;

/// What a call the script has not made reads as on the phone: the label its
/// row will have once made, by that row's rule (the call's `description`,
/// else the tool's display name). A `description` the script computes shows
/// as its source, and [isCode] is set.
({String label, bool isCode}) phoneScriptPendingLabel(
  AppLocalizations l10n,
  ScriptCallNode site,
) {
  final description = site.property('description');
  if (description?.value case final String text when text.trim().isNotEmpty) {
    return (label: text.trim().split('\n').first, isCode: false);
  }
  if (description != null && !description.isLiteral) {
    return (label: description.source, isCode: true);
  }
  final name = site.toolName;
  return (
    label: name == null
        ? l10n.scriptToolComputed
        // The name is the script's own text.
        : scriptToolLabel(
            resolveToolDisplayName(
              name,
              todos: l10n.transcriptToolTodos,
              searchMemory: l10n.transcriptToolSearchMemory,
              renderMedia: l10n.transcriptToolRenderMedia,
            ),
          ),
    isCode: false,
  );
}

/// A call the script has not made, in the geometry of a phone tool row and
/// worded like it ([phoneScriptPendingLabel]), with "Queued" or "Skipped".
class PhoneScriptPendingRow extends StatelessWidget {
  /// Creates the row for [site].
  const PhoneScriptPendingRow({
    super.key,
    required this.site,
    required this.state,
  });

  /// The call node.
  final ScriptCallNode site;

  /// [ScriptStepState.queued], [ScriptStepState.skipped] or
  /// [ScriptStepState.unknown] (no word: whether it was made cannot be
  /// told).
  final ScriptStepState state;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final (:label, :isCode) = phoneScriptPendingLabel(l10n, site);
    final skipped =
        state == ScriptStepState.skipped || state == ScriptStepState.unknown;
    final word = phoneScriptPendingWord(l10n, state);
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: isCode ? FontWeight.w400 : FontWeight.w600,
      color: skipped || isCode ? t.textQuaternary : t.textTertiary,
    );
    return Semantics(
      label: word == null ? label : l10n.scriptStepSemantics(label, word),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: t.borderSecondary),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(
                  switch (state) {
                    ScriptStepState.skipped => AppIcons.minusCircle,
                    ScriptStepState.unknown => AppIcons.circleDot,
                    _ => AppIcons.circleDashed,
                  },
                  size: 13,
                  color: t.textQuaternary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // Only a computed description is code; a label or a
                    // tool's display name stays in the UI font.
                    style: isCode
                        ? CcFonts.code(textStyle: labelStyle)
                        : labelStyle,
                  ),
                ),
                if (word != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    word,
                    style: TextStyle(fontSize: 11, color: t.textQuaternary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The header of a group of calls (a loop, an each, a parallel group, a
/// function) or of a branch's arm: a glyph, what it is, its code and
/// [trailing], the tally or the arm's state word.
class PhoneScriptGroupHeader extends StatelessWidget {
  /// Creates the header for [node].
  const PhoneScriptGroupHeader({
    super.key,
    required this.node,
    required this.state,
    required this.trailing,
  });

  /// The group or arm.
  final ScriptOutlineNode node;

  /// Where it stands.
  final ScriptStepState state;

  /// The tally, or the arm's state word.
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final node = this.node;
    final quiet =
        state == ScriptStepState.queued ||
        state == ScriptStepState.skipped ||
        state == ScriptStepState.unknown;
    final kind = switch (node) {
      ScriptLoopNode() => l10n.scriptGroupLoop,
      ScriptEachNode() => l10n.scriptGroupEach,
      ScriptParallelNode() => l10n.scriptGroupParallel,
      ScriptFunctionNode() => l10n.scriptGroupFunction,
      _ => null,
    };
    final code = node is ScriptArmNode
        ? scriptArmCode(node)
        : scriptGroupCode(node);
    final icon = switch (node) {
      ScriptLoopNode() => AppIcons.repeat,
      ScriptEachNode() => AppIcons.list,
      ScriptParallelNode() => AppIcons.columns3,
      ScriptFunctionNode() => AppIcons.code,
      ScriptArmNode(kind: ScriptArmKind.catchArm || ScriptArmKind.finallyArm) =>
        AppIcons.cornerDownLeft,
      _ => AppIcons.gitBranch,
    };
    return Semantics(
      header: true,
      label: l10n.scriptStepSemantics([?kind, code].join(' '), trailing),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: quiet ? t.textQuaternary : t.fgTertiary,
            ),
            const SizedBox(width: 7),
            if (kind != null) ...[
              Text(
                kind,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: quiet ? t.textTertiary : t.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // RTL carve-out: the header's code is JavaScript.
                textDirection: TextDirection.ltr,
                textAlign: phoneScriptCodeAlign(context),
                style: CcFonts.code(
                  textStyle: TextStyle(
                    fontSize: 11,
                    color: quiet ? t.textQuaternary : t.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              trailing,
              style: TextStyle(fontSize: 11, color: t.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The arm a call in a repeating group was made in, under its row.
class PhoneScriptArmCaption extends StatelessWidget {
  /// Creates the caption for [code].
  const PhoneScriptArmCaption({super.key, required this.code});

  /// The arm as code: `if f.big`, `else`.
  final String code;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 30, top: 2),
      child: Text(
        code,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // RTL carve-out: the arm's condition is JavaScript as written.
        textDirection: TextDirection.ltr,
        textAlign: phoneScriptCodeAlign(context),
        style: CcFonts.code(
          textStyle: TextStyle(fontSize: 10, color: t.textQuaternary),
        ),
      ),
    );
  }
}

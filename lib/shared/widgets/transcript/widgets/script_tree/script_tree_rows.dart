import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_lines.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// How code laid out left to right lines up in the surrounding layout: at
/// the start of the line, which is its right edge in a right-to-left one.
TextAlign scriptCodeAlign(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? TextAlign.end
    : TextAlign.start;

/// The word for a row or arm no call has reached, or null when it cannot be
/// told whether one did ([ScriptStepState.unknown]).
String? scriptPendingWord(AppLocalizations l10n, ScriptStepState state) =>
    switch (state) {
      ScriptStepState.skipped => l10n.scriptStepSkipped,
      ScriptStepState.unknown => null,
      _ => l10n.scriptStepQueued,
    };

/// The header of a group of calls (a loop, an each, a parallel group, a
/// function) or of a branch's arm: a glyph, what it is, its code and a tally.
class ScriptGroupHeader extends StatelessWidget {
  /// Creates a header.
  const ScriptGroupHeader({
    super.key,
    required this.icon,
    required this.kind,
    required this.code,
    required this.trailing,
    required this.state,
    required this.codeFont,
    this.alarm = false,
  });

  /// The glyph.
  final IconData icon;

  /// What the group is, in words; null for an arm, whose code says it.
  final String? kind;

  /// The group's code: a loop header, `files.map(f)`, `if r.ok`.
  final String code;

  /// The tally, or the arm's state word.
  final String trailing;

  /// Where the group stands.
  final ScriptStepState state;

  /// Whether a call under it failed or was denied.
  final bool alarm;

  /// Mono font for [code].
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final quiet =
        state == ScriptStepState.skipped ||
        state == ScriptStepState.queued ||
        state == ScriptStepState.unknown;
    final glyph = switch (state) {
      ScriptStepState.queued => Icon(
        AppIcons.circleDashed,
        size: 12,
        color: t.textQuaternary,
      ),
      ScriptStepState.skipped => Icon(
        AppIcons.minusCircle,
        size: 12,
        color: t.textQuaternary,
      ),
      ScriptStepState.done when alarm => Icon(
        AppIcons.circleAlert,
        size: 12,
        color: t.fgErrorPrimary,
      ),
      ScriptStepState.done => Icon(
        AppIcons.check,
        size: 12,
        color: t.fgSuccessPrimary,
      ),
      // The running call below already spins; an unknown one has nothing
      // to say.
      ScriptStepState.running ||
      ScriptStepState.unknown => const SizedBox(width: 12, height: 12),
    };
    final subject = [?kind, code].join(' ');
    return Semantics(
      header: true,
      label: l10n.scriptStepSemantics(subject, trailing),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: quiet ? t.textQuaternary : t.textTertiary,
            ),
            const SizedBox(width: 6),
            if (kind != null) ...[
              Text(
                kind!,
                style: CcTypography.caption.copyWith(
                  color: quiet ? t.textTertiary : t.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              // RTL carve-out: the header's code is JavaScript as written.
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                textAlign: scriptCodeAlign(context),
                style: AppFonts.codeDynamic(
                  codeFont,
                  textStyle: CcTypography.caption.copyWith(
                    color: quiet ? t.textQuaternary : t.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              trailing,
              style: CcTypography.caption.copyWith(
                color: t.textTertiary,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            glyph,
          ],
        ),
      ),
    );
  }
}

/// The hairline where a new iteration of a loop starts.
class ScriptIterationRule extends StatelessWidget {
  /// Creates the rule.
  const ScriptIterationRule({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, top: 2, bottom: 2),
      child: SizedBox(height: 1, child: ColoredBox(color: t.borderSecondary)),
    );
  }
}

/// The arm a call in a repeating group was made in, under its row:
/// `else if f.big`, quiet.
class ScriptArmCaption extends StatelessWidget {
  /// Creates the caption.
  const ScriptArmCaption({
    super.key,
    required this.code,
    required this.codeFont,
  });

  /// The arm as code.
  final String code;

  /// Mono font.
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 32, bottom: 2),
      child: Row(
        children: [
          Icon(AppIcons.gitBranch, size: 10, color: t.textQuaternary),
          const SizedBox(width: 4),
          Expanded(
            // RTL carve-out: the arm's condition is JavaScript as written.
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              textAlign: scriptCodeAlign(context),
              style: AppFonts.codeDynamic(
                codeFont,
                textStyle: CcTypography.caption.copyWith(
                  color: t.textQuaternary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tree line [depth] groups deep: one guide hairline per group, under the
/// group header's glyph, mirrored with the text; at most
/// [scriptTreeMaxIndent] of them.
class ScriptTreeIndent extends StatelessWidget {
  /// Indents [child] by [depth].
  const ScriptTreeIndent({super.key, required this.depth, required this.child});

  /// How many groups the line sits inside.
  final int depth;

  /// The line.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (depth == 0) {
      return child;
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    var out = child;
    for (var i = 0; i < depth && i < scriptTreeMaxIndent; i++) {
      out = Container(
        margin: const EdgeInsetsDirectional.only(start: 6),
        padding: const EdgeInsetsDirectional.only(start: 8),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: t.borderSecondary),
          ),
        ),
        child: out,
      );
    }
    return out;
  }
}

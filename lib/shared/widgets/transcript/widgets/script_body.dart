import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_syntax/syntax_languages.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/transcript/tool_body.dart';
import 'package:control_center/shared/widgets/transcript/util/script_status_line.dart';
import 'package:control_center/shared/widgets/transcript/widgets/code_preview.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_record_link.dart';
import 'package:flutter/widgets.dart';

/// The expanded body of a `repl` call: how the script stands, the script
/// itself (collapsed until asked for), the calls it made and its output.
///
/// The result's first line is the server's sentence for the model
/// (`Script completed in 2.4 s · …`); here it becomes a status tag, so the
/// person reads a state rather than parsing prose. The calls and the duration
/// already show in the row, so the sentence adds nothing once read.
class ScriptToolBody extends StatefulWidget {
  /// Creates the body of [seg].
  const ScriptToolBody({
    super.key,
    required this.seg,
    required this.codeFont,
    required this.tokens,
    this.nestedCalls,
  });

  /// The `repl` call.
  final ToolSegment seg;

  /// Mono font for the script and the output.
  final String codeFont;

  /// Design tokens.
  final DesignSystemTokens tokens;

  /// The calls the script made, drawn between the script and its output.
  final Widget? nestedCalls;

  @override
  State<ScriptToolBody> createState() => _ScriptToolBodyState();
}

class _ScriptToolBodyState extends State<ScriptToolBody> {
  bool _showScript = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final l10n = AppLocalizations.of(context);
    final status = readScriptStatus(widget.seg);
    final code = widget.seg.inputs?['code'];
    final source = code is String ? code.trimRight() : '';
    final lines = source.isEmpty ? 0 : '\n'.allMatches(source).length + 1;
    final label = CcTypography.caption.copyWith(
      color: tokens.textQuaternary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    // A finished script links its record. A running one is still being
    // written (the row itself is the live view), and a refused one was never
    // admitted, so the server kept no record of it.
    final recordLink =
        status.state == ScriptRunState.running ||
            status.state == ScriptRunState.refused
        ? null
        : ScriptRecordLinkScope.maybeOf(context)?.call(context, widget.seg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recordLink == null)
          ScriptStatusStrip(status: status)
        else
          Row(
            children: [
              Expanded(child: ScriptStatusStrip(status: status)),
              const SizedBox(width: AppSpacing.sm),
              recordLink,
            ],
          ),
        if (source.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          MergeSemantics(
            child: Semantics(
              expanded: _showScript,
              button: true,
              child: CcTappable(
                onPressed: () => setState(() => _showScript = !_showScript),
                builder: (context, states) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Row(
                    children: [
                      Icon(
                        _showScript
                            ? AppIcons.chevronDown
                            : AppIcons.chevronRight,
                        size: 12,
                        color: tokens.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(l10n.scriptSourceLabel, style: label),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.scriptSourceLines(lines),
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          CcCollapsible(
            expanded: _showScript,
            child: Builder(
              // RTL carve-out: the script is JavaScript source; CodePreview
              // lays its lines and gutter out LTR in every locale.
              builder: (context) => CodePreview(
                code: source,
                codeFont: widget.codeFont,
                tokens: tokens,
                languageId: shikiLangForPath('script.js'),
              ),
            ),
          ),
        ],
        ?widget.nestedCalls,
        if (status.rest.isNotEmpty)
          buildLabeledToolBlock(
            context,
            label: l10n.transcriptOutput,
            body: status.rest,
            codeFont: widget.codeFont,
            tokens: tokens,
          ),
      ],
    );
  }
}

/// How a script stands: a status tag, and the reason when it never ran.
class ScriptStatusStrip extends StatelessWidget {
  /// Creates the strip for [status].
  const ScriptStatusStrip({super.key, required this.status});

  /// The script's state.
  final ScriptStatusLine status;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final detail = status.detail;
    return Row(
      children: [
        CcStatusTag(
          label: scriptStateLabel(l10n, status.state),
          tone: scriptStateTone(status.state),
        ),
        if (detail != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

/// The localized name of [state].
String scriptStateLabel(AppLocalizations l10n, ScriptRunState state) =>
    switch (state) {
      ScriptRunState.running => l10n.scriptStateRunning,
      ScriptRunState.completed => l10n.scriptStateCompleted,
      ScriptRunState.failed => l10n.scriptStateFailed,
      ScriptRunState.timedOut => l10n.scriptStateTimedOut,
      ScriptRunState.cancelled => l10n.scriptStateCancelled,
      ScriptRunState.memoryExceeded => l10n.scriptStateMemoryExceeded,
      ScriptRunState.outputExceeded => l10n.scriptStateOutputExceeded,
      ScriptRunState.sandboxError => l10n.scriptStateSandboxError,
      ScriptRunState.refused => l10n.scriptStateRefused,
    };

/// The tone [state] reads in.
///
/// Running stays neutral: the row's spinner already says it is live, and the
/// accent is kept for the few things on screen that need a decision.
CcStatusTone scriptStateTone(ScriptRunState state) => switch (state) {
  ScriptRunState.running || ScriptRunState.cancelled => CcStatusTone.neutral,
  ScriptRunState.completed => CcStatusTone.positive,
  ScriptRunState.timedOut ||
  ScriptRunState.memoryExceeded ||
  ScriptRunState.outputExceeded ||
  ScriptRunState.refused => CcStatusTone.caution,
  ScriptRunState.failed || ScriptRunState.sandboxError => CcStatusTone.negative,
};

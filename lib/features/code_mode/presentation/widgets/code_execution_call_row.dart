import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_syntax/syntax_languages.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/code_mode/presentation/code_mode_copy.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:control_center/shared/widgets/transcript/widgets/code_preview.dart';
import 'package:flutter/widgets.dart';

/// One tool call a script made, in call order: its name, how it ended, how
/// long it took, what the gate decided and how long it waited for a person.
/// It opens to the arguments it was called with and a summary of its result.
class CodeExecutionCallRow extends StatefulWidget {
  /// Creates the row for [call].
  const CodeExecutionCallRow({
    super.key,
    required this.call,
    required this.codeFont,
  });

  /// The call.
  final CodeExecutionCall call;

  /// Mono font for the tool name and the arguments.
  final String codeFont;

  @override
  State<CodeExecutionCallRow> createState() => _CodeExecutionCallRowState();
}

class _CodeExecutionCallRowState extends State<CodeExecutionCallRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final c = widget.call;
    final mono = CcFonts.code(
      textStyle: CcTypography.numeric.copyWith(
        fontSize: 12,
        color: t.textPrimary,
      ),
      family: widget.codeFont,
    );
    final numeric = CcFonts.numeric(
      textStyle: CcTypography.numeric.copyWith(fontSize: 12),
    );
    final caption = CcTypography.caption.copyWith(color: t.textSecondary);
    final statusColor = nestedCallStatusColor(t, c.status);
    final detail = [
      gateDecisionLabel(l10n, c.gateDecision),
      if (c.approvalWaitMs > 0)
        l10n.codeExecutionCallWaited(
          formatScriptDuration(l10n, c.approvalWaitMs),
        ),
    ].join(' · ');
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Semantics(
              button: true,
              expanded: _open,
              child: CcTappable(
                onPressed: () => setState(() => _open = !_open),
                builder: (context, states) => ColoredBox(
                  color: states.contains(WidgetState.hovered)
                      ? t.bgPrimaryHover
                      : const Color(0x00000000),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _open ? AppIcons.chevronDown : AppIcons.chevronRight,
                          size: 12,
                          color: t.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '#${c.sequence}',
                            style: numeric.copyWith(color: t.textTertiary),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // RTL carve-out: a tool name is an identifier
                              // and reads left to right in every locale.
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  c.toolName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: mono,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(detail, style: caption),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          nestedCallStatusIcon(c.status),
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          nestedCallStatusLabel(l10n, c.status),
                          style: caption.copyWith(color: statusColor),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 72,
                          child: Text(
                            formatScriptDuration(l10n, c.durationMs),
                            textAlign: TextAlign.end,
                            style: numeric.copyWith(color: t.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          CcCollapsible(
            expanded: _open,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xl + AppSpacing.lg,
                end: AppSpacing.sm,
                bottom: AppSpacing.md,
              ),
              child: _CallDetail(call: c, codeFont: widget.codeFont),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallDetail extends StatelessWidget {
  const _CallDetail({required this.call, required this.codeFont});

  final CodeExecutionCall call;
  final String codeFont;

  /// The recorded arguments, indented when they parse. They are bounded on
  /// the server, so a long object may be cut and no longer parse; then it is
  /// shown as kept.
  String get _arguments {
    try {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonDecode(call.argumentsJson));
    } on FormatException {
      return call.argumentsJson;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final label = CcTypography.caption.copyWith(
      color: t.textTertiary,
      fontWeight: FontWeight.w600,
    );
    final error = call.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.codeExecutionCallArguments, style: label),
        const SizedBox(height: AppSpacing.xs),
        // RTL carve-out: JSON arguments are code; CodePreview lays them out
        // left to right in every locale.
        CodePreview(
          code: _arguments,
          codeFont: codeFont,
          tokens: t,
          languageId: shikiLangForPath('arguments.json'),
          maxHeight: 240,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.codeExecutionCallResult, style: label),
        const SizedBox(height: AppSpacing.xs),
        Text(
          error ??
              l10n.codeExecutionCallResultSize(
                call.resultBytes < 1024
                    ? l10n.codeExecutionBytes(call.resultBytes)
                    : humanBytes(call.resultBytes),
              ),
          style: CcTypography.caption.copyWith(
            color: error == null ? t.textSecondary : t.textErrorPrimary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

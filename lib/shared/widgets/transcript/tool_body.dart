import 'dart:convert';

import 'package:cc_domain/core/domain/services/transcript_status.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:control_center/shared/widgets/transcript/util/line_diff.dart';
import 'package:control_center/shared/widgets/transcript/util/read_output_parser.dart';
import 'package:control_center/shared/widgets/transcript/widgets/code_preview.dart';
import 'package:control_center/shared/widgets/transcript/widgets/inline_diff_view.dart';
import 'package:flutter/material.dart';

/// Added/removed line counts for an Edit tool, used for the `+N −N` header
/// badge. Null when the segment isn't an edit with both strings present.
({int adds, int dels})? toolDiffStats(ToolSegment seg) {
  final name = normalizeToolName(seg.toolName);
  if (name != 'edit' && name != 'multiedit') {
    return null;
  }
  final oldStr = seg.inputs?['old_string'];
  final newStr = seg.inputs?['new_string'];
  if (oldStr is! String || newStr is! String) {
    return null;
  }
  final r = computeLineDiff(oldStr, newStr);
  return (adds: r.additions, dels: r.deletions);
}

final _ansi = RegExp(r'\x1B\[[0-9;]*[A-Za-z]');

/// Renders the expanded body of a tool cell, dispatching on the tool kind:
/// Read → syntax-highlighted code; Edit → inline diff; Write → highlighted new
/// file; Bash → terminal; everything else → pretty-printed JSON input/output.
Widget buildToolBody(
  BuildContext context, {
  required ToolSegment seg,
  required String codeFont,
  required DesignSystemTokens tokens,
}) {
  final name = normalizeToolName(seg.toolName);
  final inputs = seg.inputs;
  final filePath = inputs?['file_path'] as String?;
  final language = filePath == null
      ? null
      : resolveHighlightLanguage(filePath.split('.').last);

  switch (name) {
    case 'read':
      final parsed = parseReadOutput(seg.outputs);
      if (parsed.content.isEmpty) {
        return _jsonBody(context, seg, codeFont, tokens);
      }
      return CodePreview(
        code: parsed.content,
        codeFont: codeFont,
        tokens: tokens,
        languageId: language,
        startLine: parsed.startLine,
      );
    case 'edit':
    case 'multiedit':
      final oldStr = inputs?['old_string'];
      final newStr = inputs?['new_string'];
      if (oldStr is String && newStr is String) {
        return InlineDiffView(
          oldText: oldStr,
          newText: newStr,
          codeFont: codeFont,
          tokens: tokens,
          languageId: language,
        );
      }
      return _jsonBody(context, seg, codeFont, tokens);
    case 'write':
      final contents = inputs?['file_contents'] ?? inputs?['content'];
      if (contents is String && contents.isNotEmpty) {
        return CodePreview(
          code: contents,
          codeFont: codeFont,
          tokens: tokens,
          languageId: language,
        );
      }
      return _jsonBody(context, seg, codeFont, tokens);
    case 'bash':
      return _BashBody(seg: seg, codeFont: codeFont, tokens: tokens);
    default:
      return _jsonBody(context, seg, codeFont, tokens);
  }
}

Widget _jsonBody(
  BuildContext context,
  ToolSegment seg,
  String codeFont,
  DesignSystemTokens tokens,
) {
  final theme = Theme.of(context);
  final inputs = seg.inputs;
  final inputBody = (inputs == null || inputs.isEmpty)
      ? null
      : const JsonEncoder.withIndent('  ').convert(inputs);
  final output = seg.outputs.isEmpty ? null : _prettyMaybeJson(seg.outputs);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (inputBody != null)
        _LabeledBlock(label: 'Input', body: inputBody, codeFont: codeFont, tokens: tokens, theme: theme),
      if (output != null)
        _LabeledBlock(label: 'Output', body: output, codeFont: codeFont, tokens: tokens, theme: theme),
    ],
  );
}

String _prettyMaybeJson(String raw) {
  final trimmed = raw.trim();
  if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
      (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(trimmed));
    } catch (_) {}
  }
  return raw;
}

class _LabeledBlock extends StatelessWidget {
  const _LabeledBlock({
    required this.label,
    required this.body,
    required this.codeFont,
    required this.tokens,
    required this.theme,
  });

  final String label;
  final String body;
  final String codeFont;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textQuaternary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tokens.bgPrimary,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tokens.borderSecondary),
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: SelectableText(
                  body,
                  style: AppFonts.codeDynamic(
                    codeFont,
                    textStyle: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textTertiary,
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BashBody extends StatelessWidget {
  const _BashBody({required this.seg, required this.codeFont, required this.tokens});

  final ToolSegment seg;
  final String codeFont;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final command = seg.inputs?['command'];
    final output = seg.outputs.isEmpty ? null : seg.outputs.replaceAll(_ansi, '');
    final mono = AppFonts.codeDynamic(
      codeFont,
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: tokens.textTertiary,
        height: 1.45,
        fontSize: 12,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.borderSecondary),
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(8),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (command is String && command.isNotEmpty)
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '\$ ', style: mono.copyWith(color: tokens.fgBrandPrimary)),
                      TextSpan(text: command, style: mono.copyWith(color: tokens.textPrimary)),
                    ]),
                  ),
                if (output != null) ...[
                  const SizedBox(height: 6),
                  Text(output, style: mono),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

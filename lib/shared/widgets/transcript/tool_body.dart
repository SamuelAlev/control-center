import 'dart:convert';

import 'package:cc_domain/core/domain/services/transcript_status.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:control_center/shared/widgets/transcript/util/clamp_text.dart';
import 'package:control_center/shared/widgets/transcript/util/line_diff.dart';
import 'package:control_center/shared/widgets/transcript/util/read_output_parser.dart';
import 'package:control_center/shared/widgets/transcript/widgets/code_preview.dart';
import 'package:control_center/shared/widgets/transcript/widgets/file_change_body.dart';
import 'package:control_center/shared/widgets/transcript/widgets/grep_result_body.dart';
import 'package:control_center/shared/widgets/transcript/widgets/tool_image_strip.dart';
import 'package:flutter/material.dart';

/// One extracted edit: the target file (when known) and the old/new text pair
/// the diff view needs.
typedef _ExtractedEdit = ({String? path, String oldText, String newText});

const _oldKeys = ['old_string', 'old_str', 'old_text', 'old'];
const _newKeys = ['new_string', 'new_str', 'new_text', 'new'];
const _pathKeys = ['file_path', 'path', 'filename'];

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

/// Like [_firstString] but keeps empty strings — `new_text: ""` is a legal
/// deletion edit.
String? _firstText(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String) {
      return value;
    }
  }
  return null;
}

/// The file an Edit/Write/Read targets, whichever key the adapter used.
String? _filePathOf(Map<String, dynamic>? inputs) =>
    inputs == null ? null : _firstString(inputs, _pathKeys);

/// The shiki language id for [path] (well-known filenames like `Dockerfile`
/// included), or null for plain text.
String? _languageForPath(String? path) =>
    path == null ? null : shikiLangForPath(path);

/// Pulls the old/new text pair(s) out of an Edit/MultiEdit call's args.
///
/// The harness `edit` tool speaks `path`/`old_text`/`new_text` (single, or a
/// batched `edits` list); Claude Code's Edit/MultiEdit speaks `file_path` +
/// `old_string`/`new_string` (MultiEdit batches under `edits`); some other
/// adapters use `old_str`/`new_str`. All of them collapse to one list so the
/// diff body, the `+N −N` header badge and the auto-expand check share a
/// single source of truth.
List<_ExtractedEdit> _extractEdits(Map<String, dynamic>? inputs) {
  if (inputs == null) {
    return const [];
  }
  final topPath = _filePathOf(inputs);
  final batch = inputs['edits'];
  if (batch is List) {
    final out = <_ExtractedEdit>[];
    for (final item in batch) {
      if (item is! Map) {
        continue;
      }
      final m = item.cast<String, dynamic>();
      final oldText = _firstText(m, _oldKeys);
      final newText = _firstText(m, _newKeys);
      // `new_text: ""` deletes the old text; both sides just have to be
      // strings for a diff to make sense.
      if (oldText == null || newText == null) {
        continue;
      }
      out.add((
        path: _filePathOf(m) ?? topPath,
        oldText: oldText,
        newText: newText,
      ));
    }
    if (out.isNotEmpty) {
      return out;
    }
  }
  final oldText = _firstText(inputs, _oldKeys);
  final newText = _firstText(inputs, _newKeys);
  if (oldText != null && newText != null) {
    return [(path: topPath, oldText: oldText, newText: newText)];
  }
  return const [];
}

/// Whether [name] is an edit-shaped tool after normalization.
bool _isEditTool(String name) => switch (name) {
  'edit' || 'multiedit' || 'str_replace' || 'str_replace_editor' => true,
  _ => false,
};

/// Added/removed line counts for an Edit tool, used for the `+N −N` header
/// badge. Null when the segment isn't an edit with both strings present.
({int adds, int dels})? toolDiffStats(ToolSegment seg) {
  if (!_isEditTool(normalizeToolName(seg.toolName))) {
    return null;
  }
  final edits = _extractEdits(seg.inputs);
  if (edits.isEmpty) {
    return null;
  }
  var adds = 0;
  var dels = 0;
  for (final edit in edits) {
    final r = computeLineDiff(edit.oldText, edit.newText);
    adds += r.additions;
    dels += r.deletions;
  }
  return (adds: adds, dels: dels);
}

/// Whether [seg]'s body is a file change or search result worth showing
/// without a click, so the transcript row opens expanded (see
/// `TranscriptSegmentRow`).
///
/// Edits, writes and grep hits are the segments whose *body is the point* —
/// "Edit foo.dart" / "Grep bar" tells you nothing on its own, the diff / the
/// matches are the information. Every other tool (reads, bash, MCP calls)
/// stays collapsed: its header already carries the summary and its body is
/// bulk. Requires the inputs the body needs to be present, so a
/// still-streaming call doesn't open onto nothing.
bool toolBodyOpensByDefault(ToolSegment seg) {
  // A screenshot IS the point, by the same rule as a diff or a match list:
  // "Browser: screenshot" tells you nothing, the picture is the information.
  // Checked before the tool-kind switch because the producer is a tool the
  // switch does not know (`browser_use`, `computer_use`, `mobile_use`), which
  // would otherwise fall to the default and stay collapsed.
  if (seg.images.isNotEmpty) {
    return true;
  }
  final name = normalizeToolName(seg.toolName);
  if (_isEditTool(name)) {
    return _extractEdits(seg.inputs).isNotEmpty;
  }
  switch (name) {
    case 'write':
    case 'create_file':
      final inputs = seg.inputs;
      final contents = inputs?['file_contents'] ?? inputs?['content'];
      return contents is String && contents.isNotEmpty;
    case 'grep':
    case 'search':
    case 'ripgrep':
      // Like an edit's diff, the matches ARE the information.
      return seg.outputs.trim().isNotEmpty;
    default:
      return false;
  }
}

final _ansi = RegExp(r'\x1B\[[0-9;]*[A-Za-z]');

/// Renders the expanded body of a tool cell, dispatching on the tool kind:
/// Read → syntax-highlighted code; Edit → inline diff; Write → highlighted new
/// file; Grep/Search → match list grouped by file; Bash → terminal; everything
/// else → pretty-printed JSON input/output.
Widget buildToolBody(
  BuildContext context, {
  required ToolSegment seg,
  required String codeFont,
  required DesignSystemTokens tokens,
  String? workspaceId,
}) {
  final body = _buildToolBodyContent(
    context,
    seg: seg,
    codeFont: codeFont,
    tokens: tokens,
  );
  // Images are ORTHOGONAL to the tool kind: `browser_use` returns a screenshot
  // alongside its text, and so could any future tool. Compose them after the
  // kind-specific body rather than adding an image branch to the switch, so a
  // screenshot shows up no matter which renderer claimed the call.
  if (seg.images.isEmpty) {
    return body;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      body,
      ToolImageStrip(
        images: seg.images,
        tokens: tokens,
        workspaceId: workspaceId,
      ),
    ],
  );
}

Widget _buildToolBodyContent(
  BuildContext context, {
  required ToolSegment seg,
  required String codeFont,
  required DesignSystemTokens tokens,
}) {
  final name = normalizeToolName(seg.toolName);
  final inputs = seg.inputs;
  final filePath = _filePathOf(inputs);
  final language = _languageForPath(filePath);

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
    case 'str_replace':
    case 'str_replace_editor':
      final edits = _extractEdits(inputs);
      if (edits.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < edits.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              FileEditDiffBody(
                oldText: edits[i].oldText,
                newText: edits[i].newText,
                codeFont: codeFont,
                tokens: tokens,
                languageId: _languageForPath(edits[i].path) ?? language,
                filePath: edits[i].path ?? filePath,
              ),
            ],
          ],
        );
      }
      return _jsonBody(context, seg, codeFont, tokens);
    case 'write':
    case 'create_file':
      final contents = inputs?['file_contents'] ?? inputs?['content'];
      if (contents is String && contents.isNotEmpty) {
        return FileWriteBody(
          contents: contents,
          codeFont: codeFont,
          tokens: tokens,
          outputs: seg.outputs,
          languageId: language,
        );
      }
      return _jsonBody(context, seg, codeFont, tokens);
    case 'grep':
    case 'search':
    case 'ripgrep':
      final pattern = inputs?['pattern'];
      return GrepResultBody(
        outputs: seg.outputs,
        codeFont: codeFont,
        tokens: tokens,
        pattern: pattern is String ? pattern : null,
      );
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
  final l10n = AppLocalizations.of(context);
  final inputs = seg.inputs;
  final inputBody = (inputs == null || inputs.isEmpty)
      ? null
      : const JsonEncoder.withIndent('  ').convert(inputs);
  final output = seg.outputs.isEmpty ? null : _prettyMaybeJson(seg.outputs);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (inputBody != null)
        _LabeledBlock(
          label: l10n.transcriptInput,
          body: inputBody,
          codeFont: codeFont,
          tokens: tokens,
          theme: theme,
        ),
      if (output != null)
        _LabeledBlock(
          label: l10n.transcriptOutput,
          body: output,
          codeFont: codeFont,
          tokens: tokens,
          theme: theme,
        ),
    ],
  );
}

String _prettyMaybeJson(String raw) {
  // Giant-content guard: decoding + re-encoding hundreds of KB of JSON just to
  // indent it stalls the build; render the raw (clamped downstream) text.
  if (raw.length > kToolOutputMaxJsonChars) {
    return raw;
  }
  final trimmed = raw.trim();
  if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
      (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(trimmed));
    } catch (_) {
      // Not valid JSON after all — fall through to the raw string.
    }
  }
  return raw;
}

/// The quiet "Show full output (+N KB)" affordance under a clamped block.
class _ShowFullOutputButton extends StatelessWidget {
  const _ShowFullOutputButton({
    required this.hiddenChars,
    required this.onPressed,
    required this.tokens,
    required this.theme,
  });

  final int hiddenChars;
  final VoidCallback onPressed;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final kb = (hiddenChars + 1023) ~/ 1024;
    return Align(
      alignment: Alignment.centerLeft,
      child: CcButton(
        onPressed: onPressed,
        variant: CcButtonVariant.ghost,
        size: CcButtonSize.sm,
        child: Text(
          AppLocalizations.of(context).transcriptShowFullOutput(kb),
          style: CcTypography.caption.copyWith(color: tokens.accent),
        ),
      ),
    );
  }
}

class _LabeledBlock extends StatefulWidget {
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
  State<_LabeledBlock> createState() => _LabeledBlockState();
}

class _LabeledBlockState extends State<_LabeledBlock> {
  bool _showFull = false;

  @override
  void didUpdateWidget(covariant _LabeledBlock old) {
    super.didUpdateWidget(old);
    if (old.body != widget.body) {
      _showFull = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final theme = widget.theme;
    // Clamp BEFORE text layout — a multi-megabyte body must never reach the
    // paragraph builder. The expander renders everything on demand.
    final clamped = _showFull
        ? (text: widget.body, hiddenChars: 0)
        : clampText(widget.body);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            style: CcTypography.caption.copyWith(
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
            // No explicit scrollbar: the app-wide [CcScrollBehavior] injects
            // the design-system one, wired to this scrollable's controller.
            child: SingleChildScrollView(
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      clamped.text,
                      style: AppFonts.codeDynamic(
                        widget.codeFont,
                        textStyle: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                          height: 1.4,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (clamped.hiddenChars > 0)
                      _ShowFullOutputButton(
                        hiddenChars: clamped.hiddenChars,
                        onPressed: () => setState(() => _showFull = true),
                        tokens: tokens,
                        theme: theme,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BashBody extends StatefulWidget {
  const _BashBody({
    required this.seg,
    required this.codeFont,
    required this.tokens,
  });

  final ToolSegment seg;
  final String codeFont;
  final DesignSystemTokens tokens;

  @override
  State<_BashBody> createState() => _BashBodyState();
}

class _BashBodyState extends State<_BashBody> {
  bool _showFull = false;

  @override
  void didUpdateWidget(covariant _BashBody old) {
    super.didUpdateWidget(old);
    if (old.seg.outputs != widget.seg.outputs) {
      _showFull = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = widget.tokens;
    final l10n = AppLocalizations.of(context);
    final command = widget.seg.inputs?['command'];
    // Clamp FIRST, strip ANSI on the clamped text only — running the regex
    // over a multi-megabyte transcript on every build is the expensive part.
    final raw = widget.seg.outputs;
    String? output;
    var hiddenChars = 0;
    if (raw.isNotEmpty) {
      final clamped = _showFull ? (text: raw, hiddenChars: 0) : clampText(raw);
      hiddenChars = clamped.hiddenChars;
      output = clamped.text.replaceAll(_ansi, '');
    }
    final mono = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: CcTypography.caption.copyWith(
        color: tokens.textTertiary,
        height: 1.45,
        fontSize: 12,
      ),
    );
    final sectionLabel = CcTypography.caption.copyWith(
      color: tokens.textQuaternary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.borderSecondary),
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(8),
      // No explicit scrollbar: the app-wide [CcScrollBehavior] injects the
      // design-system one, wired to this scrollable's controller.
      child: SingleChildScrollView(
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (command is String && command.isNotEmpty) ...[
                Text(l10n.shellCommand, style: sectionLabel),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '\$ ',
                        style: mono.copyWith(color: tokens.fgBrandPrimary),
                      ),
                      TextSpan(
                        text: command,
                        style: mono.copyWith(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
              if (output != null) ...[
                const SizedBox(height: 8),
                Text(l10n.shellOutput, style: sectionLabel),
                const SizedBox(height: 2),
                Text(output, style: mono),
                if (hiddenChars > 0)
                  _ShowFullOutputButton(
                    hiddenChars: hiddenChars,
                    onPressed: () => setState(() => _showFull = true),
                    tokens: tokens,
                    theme: theme,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/observability/presentation/tool_render/tool_render_parts.dart';
import 'package:control_center/features/observability/presentation/tool_render/tool_renderers.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `repl` — a code mode script: its description, then the chat transcript's
/// own script body (status, the script collapsed, the calls it made, its
/// output), so run activity and the conversation read the same.
class ScriptRenderer extends ToolRenderer {
  /// Creates a [ScriptRenderer].
  const ScriptRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final description = s.inputs?['description'];
    final code = s.inputs?['code'];
    final described = description is String && description.trim().isNotEmpty;
    final text = described
        ? description.trim().split('\n').first
        : code is String
        ? code.trim().split('\n').first
        : '';
    final style = CcTypography.numeric.copyWith(
      fontSize: 12,
      color: s.isError ? t.textErrorPrimary : t.textSecondary,
    );
    return Text(
      text.isEmpty ? '—' : ellipsize(text, 88),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      // The description is words; the script's first line is code.
      style: described || text.isEmpty ? style : CcFonts.code(textStyle: style),
    );
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) => _body(s, null);

  @override
  Widget bodyWithCalls(BuildContext context, ToolSegment s, Widget calls) =>
      _body(s, calls);

  Widget _body(ToolSegment s, Widget? calls) => Consumer(
    builder: (context, ref, _) => ScriptToolBody(
      seg: s,
      codeFont: ref.watch(codeFontFamilyProvider),
      tokens: context.designSystem ?? DesignSystemTokens.light(),
      nestedCalls: calls,
    ),
  );
}

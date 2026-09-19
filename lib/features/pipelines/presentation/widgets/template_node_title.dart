import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/graph_node_card.dart';
import 'package:flutter/widgets.dart';

const TemplateRenderer _renderer = TemplateRenderer();

/// A pipeline node title that draws each `{{placeholder}}` as a variable
/// badge instead of as braces.
///
/// A run interpolates those placeholders into values; the editor is the
/// place the braces still mean something, and printing them raw (`#{{pr_number}}`)
/// reads as a broken template. The badge is a square identifier chip (code
/// font, surface fill) so the name stays a name and the variable reads as a
/// variable.
class TemplateNodeTitle extends StatelessWidget {
  /// Creates a [TemplateNodeTitle].
  const TemplateNodeTitle(this.label, {super.key, this.style});

  /// The authored label, which may contain `{{placeholders}}`.
  final String label;

  /// Title style; defaults to [GraphNodeCard.titleStyle].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final textStyle =
        style ?? GraphNodeCard.titleStyle(color: tokens.textPrimary);
    final parts = _renderer.parts(label);
    if (parts.isEmpty || parts.every((p) => p is TemplateText)) {
      return Text(
        label,
        style: textStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Semantics(
      label: _semanticLabel(parts),
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(style: textStyle, children: _spans(parts)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static String _semanticLabel(List<TemplatePart> parts) {
    final buffer = StringBuffer();
    for (final part in parts) {
      switch (part) {
        case TemplateText(:final value):
          buffer.write(value);
        case TemplatePlaceholder(:final ref):
          buffer.write(ref);
      }
    }
    return buffer.toString();
  }

  /// Builds inline spans, folding a `#` glued to a placeholder (`#{{pr_number}}`)
  /// into the badge so the hash is not left as a dangling character.
  static List<InlineSpan> _spans(List<TemplatePart> parts) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      switch (part) {
        case TemplateText(:final value):
          final next = i + 1 < parts.length ? parts[i + 1] : null;
          final gluedHash = next is TemplatePlaceholder && value.endsWith('#');
          final text = gluedHash ? value.substring(0, value.length - 1) : value;
          if (text.isNotEmpty) {
            spans.add(TextSpan(text: text));
          }
        case TemplatePlaceholder(:final ref):
          final prev = i > 0 ? parts[i - 1] : null;
          final gluedHash = prev is TemplateText && prev.value.endsWith('#');
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: TemplateVarBadge(name: gluedHash ? '#$ref' : ref),
              ),
            ),
          );
      }
    }
    return spans;
  }
}

/// Compact identifier chip for one template variable (`pr_number`).
///
/// Not a [CcBadge]: those are status pills (`Flexible` + pill radius + the
/// label ramp) and cannot sit inside a [WidgetSpan]. This chip is square,
/// code-font, and intrinsically sized so it flows with the title.
class TemplateVarBadge extends StatelessWidget {
  /// Creates a [TemplateVarBadge].
  const TemplateVarBadge({super.key, required this.name});

  /// Placeholder reference, without braces.
  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CcFonts.code(
              textStyle: TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

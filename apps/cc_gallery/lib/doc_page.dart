import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Layout primitives for the gallery's **Docs** pages.
///
/// Rendered entirely from cc_ui tokens and typography (no markdown dependency),
/// so the documentation pages themselves dogfood the design system. Following
/// [CcTypography], hierarchy comes from size and color, never weight.

/// A scrollable, centered documentation page: an optional [eyebrow] label, a
/// [title], an optional [lede] paragraph, then a stack of [children] sections.
class DocPage extends StatelessWidget {
  /// Creates a documentation page.
  const DocPage({
    required this.title,
    this.eyebrow,
    this.lede,
    this.children = const [],
    super.key,
  });

  /// Small uppercase label above the title (e.g. the section name).
  final String? eyebrow;

  /// The page title.
  final String title;

  /// An optional lead paragraph rendered below the title.
  final String? lede;

  /// The page body — typically a list of [DocSection]s.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: CcFonts.code(textStyle: CcTypography.label)
                      .copyWith(color: t.accent),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(title, style: CcTypography.display.copyWith(color: t.fg)),
              if (lede != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(lede!, style: CcTypography.title.copyWith(color: t.muted)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled documentation section.
class DocSection extends StatelessWidget {
  /// Creates a documentation section.
  const DocSection({required this.title, required this.children, super.key});

  /// The section heading.
  final String title;

  /// The section body.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CcTypography.title.copyWith(color: t.fg)),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

/// A body paragraph.
class DocText extends StatelessWidget {
  /// Creates a body paragraph.
  const DocText(this.text, {super.key});

  /// The paragraph text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: CcTypography.body.copyWith(color: t.textSecondary),
      ),
    );
  }
}

/// A bulleted list with accent-dot markers. Each item is a `(lead, body)` pair;
/// [lead] is rendered in primary ink and [body] in secondary, so a term can be
/// emphasised by size/color without using weight.
class DocBullets extends StatelessWidget {
  /// Creates a bulleted list.
  const DocBullets(this.items, {super.key});

  /// The `(lead, body)` pairs. Pass an empty [lead] for a plain bullet.
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (lead, body) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 9,
                      right: AppSpacing.md,
                    ),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: t.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (lead.isNotEmpty)
                            TextSpan(
                              text: lead.endsWith(' ') ? lead : '$lead — ',
                              style: CcTypography.body.copyWith(color: t.fg),
                            ),
                          TextSpan(
                            text: body,
                            style: CcTypography.body
                                .copyWith(color: t.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A fenced code block in the cc_ui monospace family.
class DocCode extends StatelessWidget {
  /// Creates a code block.
  const DocCode(this.code, {super.key});

  /// The code to render verbatim.
  final String code;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: t.borderSoft),
      ),
      child: Text(
        code,
        style: CcFonts.code(textStyle: CcTypography.bodySm).copyWith(color: t.fg),
      ),
    );
  }
}

/// A horizontal strip of labelled token swatches read live from
/// `context.designSystem`, so toggling the Light/Dark addon repaints them.
class DocSwatches extends StatelessWidget {
  /// Creates a swatch strip for the given `(token name, color)` pairs.
  const DocSwatches(this.swatches, {super.key});

  /// Ordered `(token name, color)` pairs to render.
  final List<(String, Color)> swatches;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final (name, color) in swatches)
            SizedBox(
              width: 104,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: AppRadii.brSm,
                      border: Border.all(color: t.borderPrimary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    name,
                    style: CcFonts.code(textStyle: CcTypography.caption)
                        .copyWith(color: t.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

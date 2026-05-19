import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Foundation use-cases for the **type scale** (`CcTypography`).
///
/// The system's defining rule: hierarchy comes from **size and color, never
/// weight**. Every UI style is a single 400 weight; the `label` eyebrow
/// (uppercase, tracked, 500) is the one deliberate exception. The mono family
/// (Fira Code) is reserved for code, keys, and tabular numerics.

const _path = '[Foundations]/Tokens';

@widgetbook.UseCase(name: 'Type scale', type: TypeScale, path: _path)
Widget typeScaleUseCase(BuildContext context) => const TypeScale();

/// Specimen: every [CcTypography] style with its name, size, and a sample line.
class TypeScale extends StatelessWidget {
  /// Creates a [TypeScale] specimen.
  const TypeScale({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;

    Widget row(String name, String px, TextStyle style, String sample, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name, style: CcTypography.caption.copyWith(color: t.textTertiary)),
                AppSpacing.hGapSm,
                Text(px, style: CcTypography.monoNum.copyWith(color: t.textTertiary, fontSize: 11)),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(sample, style: style.copyWith(color: color ?? t.textPrimary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('displayHero', '40 · w400', CcTypography.displayHero, 'Orchestrate your agents'),
          row('display', '28 · w400', CcTypography.display, 'Pull requests'),
          row('title', '18 · w400', CcTypography.title, 'Open the review session'),
          row('body', '14 · w400', CcTypography.body,
              'The architect agent finished its run and opened a draft PR.'),
          row('bodySm', '13 · w400', CcTypography.bodySm,
              'Small body and control text — buttons, inputs, list rows.'),
          row('caption', '12 · w400', CcTypography.caption,
              'Caption and metadata · 2 minutes ago', color: t.textTertiary),
          row(
            'label',
            '12 · w500 · tracked',
            CcFonts.code(textStyle: CcTypography.label, family: context.ccTheme?.monoFontFamily),
            'DIRECT MESSAGES',
            color: t.textTertiary,
          ),
          row(
            'monoNum',
            '13 · tabular',
            CcFonts.code(textStyle: CcTypography.monoNum, family: context.ccTheme?.monoFontFamily),
            r'$0.42  ·  1,248 tokens  ·  12 files',
            color: t.textSecondary,
          ),
        ],
      ),
    );
  }
}

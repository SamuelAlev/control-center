import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcButton] — the design system's primary action control.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Buttons → CcButton` (from [CcButton] as the
/// `type` and the bracketed `path` segments). The builders return the component
/// directly — the gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Buttons';

void _noop() {}

/// Every visual variant side by side, plus the disabled treatment.
@widgetbook.UseCase(name: 'Variants', type: CcButton, path: _path)
Widget ccButtonVariantsUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CcButton(
          variant: CcButtonVariant.primary,
          onPressed: _noop,
          child: Text('Primary'),
        ),
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: _noop,
          child: Text('Secondary'),
        ),
        CcButton(
          variant: CcButtonVariant.accent,
          onPressed: _noop,
          child: Text('Accent'),
        ),
        CcButton(
          variant: CcButtonVariant.line,
          onPressed: _noop,
          child: Text('Line'),
        ),
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _noop,
          child: Text('Ghost'),
        ),
        CcButton(
          variant: CcButtonVariant.destructive,
          onPressed: _noop,
          child: Text('Delete'),
        ),
        CcButton(onPressed: null, child: Text('Disabled')),
      ],
    ),
  );
}

/// The size scale, with and without a leading icon.
@widgetbook.UseCase(name: 'Sizes', type: CcButton, path: _path)
Widget ccButtonSizesUseCase(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in CcButtonSize.values)
          CcButton(
            size: size,
            icon: LucideIcons.rocket,
            onPressed: _noop,
            child: Text(size.name),
          ),
      ],
    ),
  );
}

/// The loading state — the label is replaced by an inline spinner while the
/// button stays the same width, so layout never jumps.
@widgetbook.UseCase(name: 'Loading', type: CcButton, path: _path)
Widget ccButtonLoadingUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 12,
      children: [
        CcButton(loading: true, onPressed: _noop, child: Text('Deploying')),
        CcButton(
          variant: CcButtonVariant.secondary,
          loading: true,
          onPressed: _noop,
          child: Text('Saving'),
        ),
      ],
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcButton, path: _path)
Widget ccButtonPlaygroundUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: 'Variant',
    options: CcButtonVariant.values,
    labelBuilder: (v) => v.name,
  );
  final size = context.knobs.object.dropdown(
    label: 'Size',
    options: CcButtonSize.values,
    labelBuilder: (v) => v.name,
  );
  final loading = context.knobs.boolean(label: 'Loading');
  final withIcon = context.knobs.boolean(label: 'Leading icon', initialValue: true);
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final label = context.knobs.string(label: 'Label', initialValue: 'Deploy agent');
  return Center(
    child: CcButton(
      variant: variant,
      size: size,
      loading: loading,
      icon: withIcon ? LucideIcons.rocket : null,
      onPressed: enabled ? () {} : null,
      child: Text(label),
    ),
  );
}

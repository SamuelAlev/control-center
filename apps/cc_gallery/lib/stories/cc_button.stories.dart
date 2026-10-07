import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_button.stories.g.dart';

/// Stories for [CcButton] — the design system's primary action control.
///
/// The stories below are listed under `Components → Buttons → CcButton` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Buttons';

const component = ComponentMeta(name: 'CcButton', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcButtonPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    variant: EnumArg<CcButtonVariant>(
      CcButtonVariant.values.first,
      name: 'Variant',
      values: CcButtonVariant.values,
    ),
    size: EnumArg<CcButtonSize>(
      CcButtonSize.values.first,
      name: 'Size',
      values: CcButtonSize.values,
    ),
    loading: BoolArg(false, name: 'Loading'),
    withIcon: BoolArg(true, name: 'Leading icon'),
    enabled: BoolArg(true, name: 'Enabled'),
    label: StringArg('Deploy agent', name: 'Label'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccButtonPlaygroundStory(context, args)),
);

final $Loading = _Story(args: _Args.fixed(preview: ccButtonLoadingStory));

final $Sizes = _Story(args: _Args.fixed(preview: ccButtonSizesStory));

final $Variants = _Story(args: _Args.fixed(preview: ccButtonVariantsStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcButtonPlayground {
  CcButtonPlayground({
    required this.variant,
    required this.size,
    required this.loading,
    required this.withIcon,
    required this.enabled,
    required this.label,
  });

  final CcButtonVariant variant;
  final CcButtonSize size;
  final bool loading;
  final bool withIcon;
  final bool enabled;
  final String label;
}

void _noop() {}

/// Every visual variant side by side, plus the disabled treatment.
Widget ccButtonVariantsStory(BuildContext context) {
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
          variant: CcButtonVariant.success,
          onPressed: _noop,
          child: Text('Approve'),
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
Widget ccButtonSizesStory(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in CcButtonSize.values)
          CcButton(
            size: size,
            icon: CcIcons.rocket,
            onPressed: _noop,
            child: Text(size.name),
          ),
      ],
    ),
  );
}

/// The loading state — the label is replaced by an inline spinner while the
/// button stays the same width, so layout never jumps.
Widget ccButtonLoadingStory(BuildContext context) {
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

/// Interactive playground — drive every arg to see the full state space.
Widget ccButtonPlaygroundStory(
  BuildContext context,
  CcButtonPlaygroundArgs args,
) {
  final variant = args.variant;
  final size = args.size;
  final loading = args.loading;
  final withIcon = args.withIcon;
  final enabled = args.enabled;
  final label = args.label;
  return Center(
    child: CcButton(
      variant: variant,
      size: size,
      loading: loading,
      icon: withIcon ? CcIcons.rocket : null,
      onPressed: enabled ? () {} : null,
      child: Text(label),
    ),
  );
}

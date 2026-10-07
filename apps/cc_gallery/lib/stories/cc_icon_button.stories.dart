import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_icon_button.stories.g.dart';

/// Stories for [CcIconButton] — the square, icon-only sibling of [CcButton].
///
/// Overflow glyphs paint through [CcIcon], which draws Phosphor Regular's
/// `dots-three` SVG (the same viewBox 256 paths as phosphoricons.com) at
/// 16 px — the same size as every other [CcIconButton] glyph.
///
/// The stories below are listed under `Components → Buttons → CcIconButton`
/// (the `ComponentMeta` name and bracketed `path` segments). The builders
/// return the component directly — the gallery's theme addon supplies the
/// [CcTheme] + canvas.

const _path = '[Components]/Buttons';

const component = ComponentMeta(name: 'CcIconButton', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcIconButtonPlayground.new,
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
    enabled: BoolArg(true, name: 'Enabled'),
    loading: BoolArg(false, name: 'Loading'),
    withTooltip: BoolArg(true, name: 'Tooltip'),
    tooltip: StringArg('Restart agent', name: 'Tooltip text'),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccIconButtonPlaygroundStory(context, args),
  ),
);

final $ActiveColor = _Story(
  name: 'Active color',
  args: _Args.fixed(preview: ccIconButtonActiveColorStory),
);

final $Loading = _Story(args: _Args.fixed(preview: ccIconButtonLoadingStory));

final $Sizes = _Story(args: _Args.fixed(preview: ccIconButtonSizesStory));

final $Variants = _Story(args: _Args.fixed(preview: ccIconButtonVariantsStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcIconButtonPlayground {
  CcIconButtonPlayground({
    required this.variant,
    required this.size,
    required this.enabled,
    required this.loading,
    required this.withTooltip,
    required this.tooltip,
  });

  final CcButtonVariant variant;
  final CcButtonSize size;
  final bool enabled;
  final bool loading;
  final bool withTooltip;
  final String tooltip;
}

void _noop() {}

/// Phosphor Regular `dots-three` — same SVG the website serves.
const _dotsThree = IconData(
  0xe1fe,
  fontFamily: 'PhosphorRegular',
  fontPackage: 'cc_ui',
);
const _dotsThreeVertical = IconData(
  0xe208,
  fontFamily: 'PhosphorRegular',
  fontPackage: 'cc_ui',
);

/// Every color variant side by side, plus the disabled treatment.
Widget ccIconButtonVariantsStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CcIconButton(
          icon: CcIcons.rocket,
          variant: CcButtonVariant.primary,
          onPressed: _noop,
          tooltip: 'Deploy agent',
        ),
        CcIconButton(
          icon: CcIcons.gitPullRequest,
          variant: CcButtonVariant.secondary,
          onPressed: _noop,
          tooltip: 'Open pull request',
        ),
        CcIconButton(
          icon: CcIcons.sparkles,
          variant: CcButtonVariant.accent,
          onPressed: _noop,
          tooltip: 'Ask Claude',
        ),
        CcIconButton(
          icon: CcIcons.folderGit2,
          variant: CcButtonVariant.line,
          onPressed: _noop,
          tooltip: 'Browse repo',
        ),
        CcIconButton(
          icon: CcIcons.settings,
          onPressed: _noop,
          tooltip: 'Workspace settings',
        ),
        CcIconButton(icon: CcIcons.lock, onPressed: null, tooltip: 'Locked'),
        CcIconButton(
          icon: _dotsThree,
          onPressed: _noop,
          tooltip: 'More actions',
        ),
        CcIconButton(
          icon: _dotsThreeVertical,
          onPressed: _noop,
          tooltip: 'More actions',
        ),
      ],
    ),
  );
}

/// The loading state — the glyph spins in place (keeping the action
/// identifiable) and the button stops responding until the work completes.
Widget ccIconButtonLoadingStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CcIconButton(
          icon: CcIcons.refreshCw,
          loading: true,
          onPressed: _noop,
          tooltip: 'Refreshing',
        ),
        CcIconButton(
          icon: CcIcons.refreshCw,
          variant: CcButtonVariant.secondary,
          loading: true,
          onPressed: _noop,
          tooltip: 'Refreshing',
        ),
      ],
    ),
  );
}

/// The size scale — md is a 36px box, sm a 32px box.
Widget ccIconButtonSizesStory(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in CcButtonSize.values)
          CcIconButton(
            icon: CcIcons.play,
            size: size,
            variant: CcButtonVariant.primary,
            onPressed: _noop,
            tooltip: 'Run pipeline (${size.name})',
          ),
      ],
    ),
  );
}

/// A custom [CcIconButton.color] override signals an active toolbar
/// affordance without changing the variant background.
Widget ccIconButtonActiveColorStory(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CcIconButton(
          icon: CcIcons.star,
          color: t.accent,
          onPressed: _noop,
          tooltip: 'Starred',
        ),
        CcIconButton(
          icon: CcIcons.bell,
          color: t.textSecondary,
          onPressed: _noop,
          tooltip: 'Mute notifications',
        ),
        const CcIconButton(
          icon: CcIcons.bookmark,
          onPressed: _noop,
          tooltip: 'Bookmark thread',
        ),
      ],
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccIconButtonPlaygroundStory(
  BuildContext context,
  CcIconButtonPlaygroundArgs args,
) {
  final variant = args.variant;
  final size = args.size;
  final enabled = args.enabled;
  final loading = args.loading;
  final withTooltip = args.withTooltip;
  final tooltip = args.tooltip;
  return Center(
    child: CcIconButton(
      icon: CcIcons.refreshCw,
      variant: variant,
      size: size,
      loading: loading,
      onPressed: enabled ? () {} : null,
      tooltip: withTooltip ? tooltip : null,
    ),
  );
}

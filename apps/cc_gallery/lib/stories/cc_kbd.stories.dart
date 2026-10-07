import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_kbd.stories.g.dart';

/// Stories for [CcKbd] — the design system's keyboard key-cap chip.
///
/// The stories below are listed under `Components → Containers → CcKbd` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Containers';

const component = ComponentMeta(name: 'CcKbd', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(Showcase.playground, argsType: CcKbdPlayground.new);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    label: StringArg('⌘K', name: 'Key label'),
    fontSize: DoubleArg(
      11,
      name: 'Font size',
      style: const SliderDoubleArgStyle(min: 8, max: 24, divisions: 16),
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccKbdPlaygroundStory(context, args)),
);

final $Default = _Story(args: _Args.fixed(preview: ccKbdDefaultStory));

final $GroupShortcutHint = _Story(
  name: 'Group & shortcut hint',
  args: _Args.fixed(preview: ccKbdGroupStory),
);

final $ShortcutVocabulary = _Story(
  name: 'Shortcut vocabulary',
  args: _Args.fixed(preview: ccKbdVocabularyStory),
);

final $Sizes = _Story(args: _Args.fixed(preview: ccKbdSizesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcKbdPlayground {
  CcKbdPlayground({required this.label, required this.fontSize});

  final String label;
  final double fontSize;
}

/// A single key-cap and a multi-key shortcut rendered side by side, the way
/// callers stitch them together for command-palette hints.
Widget ccKbdDefaultStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcKbd(keyLabel: '⌘'),
        CcKbd(keyLabel: 'K'),
        SizedBox(width: 16),
        CcKbd(keyLabel: 'Esc'),
        CcKbd(keyLabel: 'Ctrl+S'),
      ],
    ),
  );
}

/// The shortcut vocabulary across Control Center surfaces — open the command
/// palette, dispatch an agent, review the next pull request, dismiss a dialog.
Widget ccKbdVocabularyStory(BuildContext context) {
  const labels = ['⌘K', '⌘↵', '⇧⌘P', '⌥W', 'Esc', 'Tab', '⌘.', '⌘/'];
  return Center(
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [for (final label in labels) CcKbd(keyLabel: label)],
    ),
  );
}

/// The font-size ramp — the same key-cap rendered from compact inline hints up
/// to a prominent onboarding callout.
Widget ccKbdSizesStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcKbd(keyLabel: '⌘K', fontSize: 9),
        CcKbd(keyLabel: '⌘K'),
        CcKbd(keyLabel: '⌘K', fontSize: 14),
        CcKbd(keyLabel: '⌘K', fontSize: 18),
      ],
    ),
  );
}

/// [CcKbdGroup] stitches a chord from individual caps and [CcShortcutHint]
/// pairs a chord with the action it triggers — the way UAC and menus surface
/// shortcuts at the point of use (e.g. `⌘↵ Allow`).
Widget ccKbdGroupStory(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcKbdGroup(keys: ['⌘', '↵']),
        SizedBox(height: 16),
        CcShortcutHint(keys: ['⌘', '↵'], label: 'Allow'),
        SizedBox(height: 8),
        CcShortcutHint(keys: ['↵'], label: 'Deny'),
        SizedBox(height: 8),
        CcShortcutHint(keys: ['G', 'P'], label: 'Go to pull requests'),
      ],
    ),
  );
}

/// Interactive playground — drive the label and size args to preview any
/// key-cap.
Widget ccKbdPlaygroundStory(BuildContext context, CcKbdPlaygroundArgs args) {
  final label = args.label;
  final fontSize = args.fontSize;
  return Center(
    child: CcKbd(keyLabel: label, fontSize: fontSize),
  );
}

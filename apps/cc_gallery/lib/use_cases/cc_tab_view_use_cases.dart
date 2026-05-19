import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTabView] — the design system's tabbed container that pairs
/// an underline strip with the selected content panel.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Navigation & Overlays → CcTabView`. Selection
/// is controlled, so each use-case returns a small file-private StatefulWidget
/// that owns `selectedIndex` and feeds `onChanged` — mirroring the known-correct
/// `_TabViewDemo` in `component_stories.dart`.

const _path = '[Components]/Navigation & Overlays';

/// A panel body styled from the design system tokens (no hardcoded colors).
Widget _panel(BuildContext context, String text) {
  final t = context.designSystem!;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(text, style: CcTypography.body.copyWith(color: t.textSecondary)),
  );
}

/// Plain text-label tabs — the common case (a pull request detail view).
@widgetbook.UseCase(name: 'Text labels', type: CcTabView, path: _path)
Widget ccTabViewTextLabelsUseCase(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(24),
    child: SizedBox(width: 440, child: _TextLabelsDemo()),
  );
}

/// Labels that combine a Lucide icon with text; the strip inherits the
/// selected/unselected color through the ambient IconTheme + DefaultTextStyle.
@widgetbook.UseCase(name: 'Icon labels', type: CcTabView, path: _path)
Widget ccTabViewIconLabelsUseCase(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(24),
    child: SizedBox(width: 480, child: _IconLabelsDemo()),
  );
}

/// A scrollable strip — many tabs overflow horizontally and scroll instead of
/// wrapping (a workspace with one panel per linked repo).
@widgetbook.UseCase(name: 'Scrollable strip', type: CcTabView, path: _path)
Widget ccTabViewScrollableUseCase(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(24),
    child: SizedBox(width: 360, child: _ScrollableDemo()),
  );
}

/// Interactive playground — toggle the structural props and pick a tab.
@widgetbook.UseCase(name: 'Playground', type: CcTabView, path: _path)
Widget ccTabViewPlaygroundUseCase(BuildContext context) {
  final scrollable = context.knobs.boolean(label: 'Scrollable');
  final expand = context.knobs.boolean(label: 'Expand panel to fill height');
  final tabCount = context.knobs.double
      .slider(label: 'Tab count', initialValue: 3, min: 2, max: 6, divisions: 4)
      .round();
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      width: 420,
      height: expand ? 320 : null,
      child: _PlaygroundDemo(
        scrollable: scrollable,
        expand: expand,
        tabCount: tabCount,
      ),
    ),
  );
}

class _TextLabelsDemo extends StatefulWidget {
  const _TextLabelsDemo();
  @override
  State<_TextLabelsDemo> createState() => _TextLabelsDemoState();
}

class _TextLabelsDemoState extends State<_TextLabelsDemo> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return CcTabView(
      selectedIndex: _index,
      onChanged: (i) => setState(() => _index = i),
      tabs: [
        CcTabViewEntry(
          label: const Text('Overview'),
          content: _panel(context, 'Summary of the pull request.'),
        ),
        CcTabViewEntry(
          label: const Text('Checks'),
          content: _panel(context, 'CI status and merge gates.'),
        ),
        CcTabViewEntry(
          label: const Text('Files'),
          content: _panel(context, 'Changed files and diffs.'),
        ),
      ],
    );
  }
}

class _IconLabelsDemo extends StatefulWidget {
  const _IconLabelsDemo();
  @override
  State<_IconLabelsDemo> createState() => _IconLabelsDemoState();
}

class _IconLabelsDemoState extends State<_IconLabelsDemo> {
  int _index = 0;

  Widget _iconLabel(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 6),
          Text(text),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return CcTabView(
      selectedIndex: _index,
      onChanged: (i) => setState(() => _index = i),
      tabs: [
        CcTabViewEntry(
          label: _iconLabel(LucideIcons.bot, 'Agents'),
          content: _panel(context, 'Agents running in this workspace.'),
        ),
        CcTabViewEntry(
          label: _iconLabel(LucideIcons.gitPullRequest, 'Pull requests'),
          content: _panel(context, 'Open pull requests awaiting review.'),
        ),
        CcTabViewEntry(
          label: _iconLabel(LucideIcons.workflow, 'Pipelines'),
          content: _panel(context, 'Pipeline runs and their step status.'),
        ),
      ],
    );
  }
}

class _ScrollableDemo extends StatefulWidget {
  const _ScrollableDemo();
  @override
  State<_ScrollableDemo> createState() => _ScrollableDemoState();
}

class _ScrollableDemoState extends State<_ScrollableDemo> {
  int _index = 0;
  static const _repos = [
    'control-center',
    'cc_ui',
    'cc_gallery',
    'rift',
    'claude-relay',
    'pipelines',
  ];
  @override
  Widget build(BuildContext context) {
    return CcTabView(
      scrollable: true,
      selectedIndex: _index,
      onChanged: (i) => setState(() => _index = i),
      tabs: [
        for (final repo in _repos)
          CcTabViewEntry(
            label: Text(repo),
            content: _panel(context, 'Worktree status for $repo.'),
          ),
      ],
    );
  }
}

class _PlaygroundDemo extends StatefulWidget {
  const _PlaygroundDemo({
    required this.scrollable,
    required this.expand,
    required this.tabCount,
  });

  final bool scrollable;
  final bool expand;
  final int tabCount;

  @override
  State<_PlaygroundDemo> createState() => _PlaygroundDemoState();
}

class _PlaygroundDemoState extends State<_PlaygroundDemo> {
  int _index = 0;
  static const _labels = [
    'Overview',
    'Checks',
    'Files',
    'Commits',
    'Timeline',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final count = widget.tabCount.clamp(1, _labels.length);
    if (_index >= count) _index = count - 1;
    return CcTabView(
      scrollable: widget.scrollable,
      expand: widget.expand,
      selectedIndex: _index,
      onChanged: (i) => setState(() => _index = i),
      tabs: [
        for (var i = 0; i < count; i++)
          CcTabViewEntry(
            label: Text(_labels[i]),
            content: _panel(context, 'Panel for the ${_labels[i]} tab.'),
          ),
      ],
    );
  }
}

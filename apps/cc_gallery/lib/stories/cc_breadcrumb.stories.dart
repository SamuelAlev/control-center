import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_breadcrumb.stories.g.dart';

/// Stories for [CcBreadcrumb] — the design system's navigation trail.
///
/// A breadcrumb draws its [CcBreadcrumbItem] children separated by a chevron.
/// Link segments (with an `onPress`) render in `textTertiary` and hover; the
/// `current` segment renders emphasized in `textPrimary` and is inert. The
/// builders return the component directly — the gallery's theme addon supplies
/// the [CcTheme] + canvas.

const _path = '[Components]/Navigation & Overlays';

const component = ComponentMeta(name: 'CcBreadcrumb', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcBreadcrumbPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    segments: StringArg(
      'Repos, control-center, PR #42',
      name: 'Segments (comma separated)',
    ),
    linksTappable: BoolArg(true, name: 'Links tappable'),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccBreadcrumbPlaygroundStory(context, args),
  ),
);

final $Default = _Story(args: _Args.fixed(preview: ccBreadcrumbDefaultStory));

final $Depths = _Story(args: _Args.fixed(preview: ccBreadcrumbDepthsStory));

final $WithIcons = _Story(
  name: 'With icons',
  args: _Args.fixed(preview: ccBreadcrumbWithIconsStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcBreadcrumbPlayground {
  CcBreadcrumbPlayground({required this.segments, required this.linksTappable});

  final String segments;
  final bool linksTappable;
}

void _noop() {}

/// A typical trail: tappable links leading to the active, emphasized segment.
Widget ccBreadcrumbDefaultStory(BuildContext context) {
  return const Center(
    child: CcBreadcrumb(
      children: [
        CcBreadcrumbItem(onPress: _noop, child: Text('Repos')),
        CcBreadcrumbItem(onPress: _noop, child: Text('control-center')),
        CcBreadcrumbItem(child: Text('PR #42'), current: true),
      ],
    ),
  );
}

/// Segments can carry leading icons, which adopt the segment's text color.
Widget ccBreadcrumbWithIconsStory(BuildContext context) {
  return const Center(
    child: CcBreadcrumb(
      children: [
        CcBreadcrumbItem(
          onPress: _noop,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CcIcons.folderGit2),
              SizedBox(width: 6),
              Text('Workspaces'),
            ],
          ),
        ),
        CcBreadcrumbItem(
          onPress: _noop,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CcIcons.bot),
              SizedBox(width: 6),
              Text('Architect'),
            ],
          ),
        ),
        CcBreadcrumbItem(
          current: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CcIcons.gitPullRequest),
              SizedBox(width: 6),
              Text('Review session'),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Trail lengths side by side — from a single current root to a deep path.
Widget ccBreadcrumbDepthsStory(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcBreadcrumb(
          children: [CcBreadcrumbItem(child: Text('Dashboard'), current: true)],
        ),
        SizedBox(height: 16),
        CcBreadcrumb(
          children: [
            CcBreadcrumbItem(child: Text('Pipelines')),
            CcBreadcrumbItem(child: Text('Nightly review'), current: true),
          ],
        ),
        SizedBox(height: 16),
        CcBreadcrumb(
          children: [
            CcBreadcrumbItem(child: Text('Repos')),
            CcBreadcrumbItem(child: Text('control-center')),
            CcBreadcrumbItem(child: Text('Pull requests')),
            CcBreadcrumbItem(child: Text('PR #128'), current: true),
          ],
        ),
      ],
    ),
  );
}

/// Interactive playground — tune the trail and the active segment.
Widget ccBreadcrumbPlaygroundStory(
  BuildContext context,
  CcBreadcrumbPlaygroundArgs args,
) {
  final segments = args.segments;
  final linksTappable = args.linksTappable;
  final labels = segments
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return Center(
    child: CcBreadcrumb(
      children: [
        for (var i = 0; i < labels.length; i++)
          CcBreadcrumbItem(
            current: i == labels.length - 1,
            onPress: (i == labels.length - 1 || !linksTappable) ? null : _noop,
            child: Text(labels[i]),
          ),
      ],
    ),
  );
}

import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcBreadcrumb] — the design system's navigation trail.
///
/// A breadcrumb draws its [CcBreadcrumbItem] children separated by a chevron.
/// Link segments (with an `onPress`) render in `textTertiary` and hover; the
/// `current` segment renders emphasized in `textPrimary` and is inert. The
/// builders return the component directly — the gallery's theme addon supplies
/// the [CcTheme] + canvas.

const _path = '[Components]/Navigation & Overlays';

void _noop() {}

/// A typical trail: tappable links leading to the active, emphasized segment.
@widgetbook.UseCase(name: 'Default', type: CcBreadcrumb, path: _path)
Widget ccBreadcrumbDefaultUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'With icons', type: CcBreadcrumb, path: _path)
Widget ccBreadcrumbWithIconsUseCase(BuildContext context) {
  return const Center(
    child: CcBreadcrumb(
      children: [
        CcBreadcrumbItem(
          onPress: _noop,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.folderGit2),
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
              Icon(LucideIcons.bot),
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
              Icon(LucideIcons.gitPullRequest),
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
@widgetbook.UseCase(name: 'Depths', type: CcBreadcrumb, path: _path)
Widget ccBreadcrumbDepthsUseCase(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcBreadcrumb(
          children: [
            CcBreadcrumbItem(child: Text('Dashboard'), current: true),
          ],
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
@widgetbook.UseCase(name: 'Playground', type: CcBreadcrumb, path: _path)
Widget ccBreadcrumbPlaygroundUseCase(BuildContext context) {
  final segments = context.knobs.string(
    label: 'Segments (comma separated)',
    initialValue: 'Repos, control-center, PR #42',
  );
  final linksTappable = context.knobs.boolean(
    label: 'Links tappable',
    initialValue: true,
  );
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

import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_color_tag.stories.g.dart';

/// Stories for [CcColorTag] — a read-only forge-colored label chip.
const _path = '[Components]/Containers';

const component = ComponentMeta(name: 'CcColorTag', path: _path);

const meta = Meta(Showcase.new);

final $Compact = _Story(args: _Args.fixed(preview: ccColorTagCompactStory));

final $Fallback = _Story(args: _Args.fixed(preview: ccColorTagFallbackStory));

final $GitHubColors = _Story(
  name: 'GitHub colors',
  args: _Args.fixed(preview: ccColorTagGitHubColorsStory),
);

/// GitHub-style labels across light, mid and dark fills so ink contrast is
/// visible (yellow/cyan get dark type; red/blue get white).
Widget ccColorTagGitHubColorsStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CcColorTag(label: 'bug', color: 'd73a4a'),
        CcColorTag(label: 'enhancement', color: 'a2eeef'),
        CcColorTag(
          label: 'dependencies',
          color: '0366d6',
          tooltip: 'Pull requests that update a dependency file',
        ),
        CcColorTag(label: 'documentation', color: '0075ca'),
        CcColorTag(label: 'good first issue', color: '7057ff'),
        CcColorTag(label: 'performance', color: '0e8a16'),
      ],
    ),
  );
}

/// Dense chips for inbox rows and activity-feed sentences.
Widget ccColorTagCompactStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        CcColorTag(label: 'bug', color: 'd73a4a', compact: true),
        CcColorTag(label: 'dependencies', color: '0366d6', compact: true),
        CcColorTag(label: 'wip', compact: true),
      ],
    ),
  );
}

/// An empty or unparseable color still renders a named chip on the muted
/// secondary fill — GitLab's names-only list payload has no hex.
Widget ccColorTagFallbackStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CcColorTag(label: 'needs-review'),
        CcColorTag(label: 'not-a-color', color: 'zzzzzz'),
      ],
    ),
  );
}

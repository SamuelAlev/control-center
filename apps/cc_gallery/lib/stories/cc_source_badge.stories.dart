import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_source_badge.stories.g.dart';

/// Stories for [CcSourceBadge] — the provenance tag that makes layered config
/// legible: "this rule is project-scoped" vs "globally inherited".
/// [CcConfigRow] carries one per row.

const _path = '[Components]/Data';

const component = ComponentMeta(name: 'CcSourceBadge', path: _path);

const meta = Meta(Showcase.new);

final $SourceBadges = _Story(
  name: 'Source badges',
  args: _Args.fixed(preview: ccSourceBadgeStory),
);

/// The provenance badges across the layering spectrum. Project / local-override
/// take the accent tint; everything else stays quiet neutral.
Widget ccSourceBadgeStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CcSourceBadge(source: CcConfigSource.defaultValue),
        CcSourceBadge(source: CcConfigSource.global),
        CcSourceBadge(source: CcConfigSource.inherited),
        CcSourceBadge(source: CcConfigSource.project),
        CcSourceBadge(source: CcConfigSource.localOverride),
      ],
    ),
  );
}

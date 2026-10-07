import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_sidebar_item.stories.g.dart';

/// Stories for [CcSidebarItem] — one destination row of a [CcSidebar].
///
/// The stories below are listed under `Components → Navigation & Overlays →
/// CcSidebarItem` (the `ComponentMeta` name and bracketed `path` segments).
/// Builders return the component inside a sized sidebar — the gallery's theme
/// addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Navigation & Overlays';

const component = ComponentMeta(name: 'CcSidebarItem', path: _path);

const meta = Meta(Showcase.new);

final $BadgeBesideLabel = _Story(
  name: 'Badge beside label',
  args: _Args.fixed(preview: ccSidebarBadgeBesideLabelStory),
);

/// A state-reporting dot badge beside its label — the badge hugs the text
/// with a small gap instead of pinning to the trailing gutter, which is how
/// a status signal (not a count on the row) reads.
Widget ccSidebarBadgeBesideLabelStory(BuildContext context) {
  final t = context.designSystem;
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      height: 220,
      child: CcSidebar(
        children: [
          CcSidebarGroup(
            label: 'Footer',
            children: [
              CcSidebarItem(
                icon: CcIcons.activity,
                label: 'Service status',
                badge: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t?.success,
                    shape: BoxShape.circle,
                  ),
                ),
                badgeBesideLabel: true,
              ),
              const CcSidebarItem(icon: CcIcons.house, label: 'Newsfeed'),
            ],
          ),
        ],
      ),
    ),
  );
}

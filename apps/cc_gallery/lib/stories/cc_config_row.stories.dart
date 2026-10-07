import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_config_row.stories.g.dart';

/// Stories for [CcConfigRow] / [CcSourceBadge] — making layered config
/// provenance legible: "this rule is project-scoped" vs "globally inherited".

const _path = '[Components]/Data';

const component = ComponentMeta(name: 'CcConfigRow', path: _path);

const meta = Meta(Showcase.new);

final $PolicyList = _Story(
  name: 'Policy list',
  args: _Args.fixed(preview: ccConfigRowListStory),
);

/// A stack of config rows as they'd appear in a policy list — overrides grow a
/// left accent stripe so they're scannable in a long layered list.
Widget ccConfigRowListStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcConfigRow(
            title: Text('git status'),
            subtitle: Text('Auto-approved'),
            source: CcConfigSource.defaultValue,
          ),
          CcConfigRow(
            title: Text('npm install'),
            subtitle: Text('Ask before running'),
            source: CcConfigSource.global,
          ),
          CcConfigRow(
            title: Text('git push'),
            subtitle: Text('Allowed in this workspace'),
            source: CcConfigSource.project,
            status: CcStatusTag(label: 'Allowed', tone: CcStatusTone.positive),
          ),
          CcConfigRow(
            title: Text('rm -rf'),
            subtitle: Text('Always denied here'),
            source: CcConfigSource.localOverride,
            status: CcStatusTag(label: 'Denied', tone: CcStatusTone.negative),
          ),
        ],
      ),
    ),
  );
}

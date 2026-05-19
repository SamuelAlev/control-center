import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcConfigRow] / [CcSourceBadge] — making layered config
/// provenance legible: "this rule is project-scoped" vs "globally inherited".

const _path = '[Components]/Data';

/// The provenance badges across the layering spectrum. Project / local-override
/// take the accent tint; everything else stays quiet neutral.
@widgetbook.UseCase(name: 'Source badges', type: CcSourceBadge, path: _path)
Widget ccSourceBadgeUseCase(BuildContext context) {
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

/// A stack of config rows as they'd appear in a policy list — overrides grow a
/// left accent stripe so they're scannable in a long layered list.
@widgetbook.UseCase(name: 'Policy list', type: CcConfigRow, path: _path)
Widget ccConfigRowListUseCase(BuildContext context) {
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

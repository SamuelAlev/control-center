import 'dart:convert';

import 'package:cc_mcp/src/tools/pin_skill_tool.dart';
import 'package:test/test.dart';

import 'skill_bundle_port_fake.dart';

void main() {
  late FakeSkillBundles bundles;
  late PinSkillTool tool;

  setUp(() {
    bundles = FakeSkillBundles();
    tool = PinSkillTool(bundles: bundles);
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'slug': 'demo'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('pins an existing workspace skill', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'slug': 'demo',
    });
    expect(result.isError, isFalse);
    expect(bundles.lastPinned?.slug, 'demo');
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['status'], 'pinned');
    expect(body['slug'], 'demo');
  });
}

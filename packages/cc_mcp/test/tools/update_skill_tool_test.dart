import 'dart:convert';

import 'package:cc_mcp/src/tools/update_skill_tool.dart';
import 'package:test/test.dart';

import 'skill_bundle_port_fake.dart';

void main() {
  late FakeSkillBundles bundles;
  late UpdateSkillTool tool;

  setUp(() {
    bundles = FakeSkillBundles();
    tool = UpdateSkillTool(bundles: bundles);
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'slug': 'demo', 'ref': 'def456'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('applies an update at the new ref', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'slug': 'demo',
      'ref': 'def456',
    });
    expect(result.isError, isFalse);
    expect(bundles.lastUpdated?.slug, 'demo');
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['slug'], 'demo');
  });
}

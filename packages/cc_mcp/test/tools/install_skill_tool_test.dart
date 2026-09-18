import 'dart:convert';

import 'package:cc_mcp/src/tools/install_skill_tool.dart';
import 'package:test/test.dart';

import 'skill_bundle_port_fake.dart';

void main() {
  late FakeSkillBundles bundles;
  late InstallSkillTool tool;

  setUp(() {
    bundles = FakeSkillBundles();
    tool = InstallSkillTool(bundles: bundles);
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'slug': 'demo',
      'owner': 'acme',
      'repo': 'skills',
      'path': 'skills/demo/SKILL.md',
      'ref': 'abc123',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('installs from GitHub at the pinned ref', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'slug': 'demo',
      'owner': 'acme',
      'repo': 'skills',
      'path': 'skills/demo/SKILL.md',
      'ref': 'abc123',
    });
    expect(result.isError, isFalse);
    expect(bundles.lastInstalled?.slug, 'demo');
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['slug'], 'demo');
  });
}

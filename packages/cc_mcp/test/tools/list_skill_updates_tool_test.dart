import 'dart:convert';

import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_mcp/src/tools/list_skill_updates_tool.dart';
import 'package:test/test.dart';

import 'skill_bundle_port_fake.dart';

void main() {
  late FakeSkillBundles bundles;
  late ListSkillUpdatesTool tool;

  setUp(() {
    bundles = FakeSkillBundles();
    tool = ListSkillUpdatesTool(bundles: bundles);
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run(const {});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('returns upstream updates', () async {
    bundles.updates = const [
      SkillUpdateCandidate(slug: 'demo', currentRef: 'aaa', latestRef: 'bbb'),
    ];
    final result = await tool.run({'workspace_id': 'ws-1'});
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    final update = (body['updates'] as List).single as Map;
    expect(update['slug'], 'demo');
    expect(update['latest_ref'], 'bbb');
  });
}

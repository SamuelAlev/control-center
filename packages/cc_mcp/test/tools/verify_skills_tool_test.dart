import 'dart:convert';

import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_mcp/src/tools/verify_skills_tool.dart';
import 'package:test/test.dart';

import 'skill_bundle_port_fake.dart';

void main() {
  late FakeSkillBundles bundles;
  late VerifySkillsTool tool;

  setUp(() {
    bundles = FakeSkillBundles();
    tool = VerifySkillsTool(bundles: bundles);
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run(const {});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('reports lock verification', () async {
    bundles.verifyResult = const SkillVerifyResult(
      matched: ['demo'],
      drifted: ['old'],
    );
    final result = await tool.run({'workspace_id': 'ws-1'});
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['is_clean'], isFalse);
    expect(body['matched'], ['demo']);
    expect(body['drifted'], ['old']);
  });
}

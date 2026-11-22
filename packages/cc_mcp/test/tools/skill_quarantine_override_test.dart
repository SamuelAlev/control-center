import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_mcp/src/tools/create_skill_tool.dart';
import 'package:cc_mcp/src/tools/install_skill_tool.dart';
import 'package:cc_mcp/src/tools/update_skill_tool.dart';
import 'package:test/test.dart';

import 'skill_bundle_port_fake.dart';

/// A quarantine verdict blocks a model: no skill tool takes
/// `allow_quarantine_override`. Overriding it is a person's decision, made
/// through their own ops (`skills.saveLocal`, `skills.sourceInstall`,
/// `skills.updateSkill`) after they confirm the findings.
void main() {
  test('create_skill does not declare the override and ignores it', () async {
    final files = _Files();
    final tool = CreateSkillTool(filesystem: files, scanner: _Quarantines());

    expect(
      (tool.inputSchema['properties'] as Map).keys,
      isNot(contains('allow_quarantine_override')),
    );
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'slug': 'demo',
      'content': '# Demo',
      'allow_quarantine_override': true,
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('quarantined'));
    expect(files.written, isEmpty);
  });

  test('install_skill does not declare the override and never asks for '
      'one', () async {
    final bundles = _RecordingBundles();
    final tool = InstallSkillTool(bundles: bundles);

    expect(
      (tool.inputSchema['properties'] as Map).keys,
      isNot(contains('allow_quarantine_override')),
    );
    await tool.run({
      'workspace_id': 'ws-1',
      'slug': 'demo',
      'owner': 'owner',
      'repo': 'repo',
      'path': 'skills/demo/SKILL.md',
      'ref': 'abc123',
      'allow_quarantine_override': true,
    });
    expect(bundles.overrides, [false]);
  });

  test('update_skill does not declare the override and never asks for '
      'one', () async {
    final bundles = _RecordingBundles();
    final tool = UpdateSkillTool(bundles: bundles);

    expect(
      (tool.inputSchema['properties'] as Map).keys,
      isNot(contains('allow_quarantine_override')),
    );
    await tool.run({
      'workspace_id': 'ws-1',
      'slug': 'demo',
      'ref': 'abc123',
      'allow_quarantine_override': true,
    });
    expect(bundles.overrides, [false]);
  });
}

class _RecordingBundles extends FakeSkillBundles {
  final List<bool> overrides = [];

  @override
  Future<SkillLockEntry> installFromGitHub({
    required String workspaceId,
    required String slug,
    required String owner,
    required String repo,
    required String path,
    String? ref,
    bool allowQuarantineOverride = false,
    String? spaceId,
    String? agentId,
    String? actingUserId,
  }) {
    overrides.add(allowQuarantineOverride);
    return super.installFromGitHub(
      workspaceId: workspaceId,
      slug: slug,
      owner: owner,
      repo: repo,
      path: path,
      ref: ref,
    );
  }

  @override
  Future<SkillLockEntry> applyUpdate({
    required String workspaceId,
    required String slug,
    String? ref,
    bool allowQuarantineOverride = false,
    String? spaceId,
    String? agentId,
    String? actingUserId,
  }) {
    overrides.add(allowQuarantineOverride);
    return super.applyUpdate(workspaceId: workspaceId, slug: slug, ref: ref);
  }
}

class _Quarantines implements SkillScanPort {
  @override
  Future<SkillScanResult> scan(
    SkillBundle bundle, {
    required String workspaceId,
    SkillTrustTier trustTier = SkillTrustTier.community,
    bool runLlmReview = true,
  }) async => _Quarantined();
}

class _Quarantined implements SkillScanResult {
  @override
  SkillScanVerdict get verdict => SkillScanVerdict.quarantine;

  @override
  List<SkillScanFinding> get findings => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Files implements WorkspaceFilesystemPort {
  final List<String> written = [];

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String slug,
    String content,
  ) async => written.add(slug);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

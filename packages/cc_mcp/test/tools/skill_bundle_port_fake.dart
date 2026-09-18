import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';

/// In-memory [SkillBundlePort] for MCP skill-tool tests.
class FakeSkillBundles implements SkillBundlePort {
  SkillLockEntry? lastPinned;
  SkillLockEntry? lastInstalled;
  SkillLockEntry? lastUpdated;
  SkillVerifyResult verifyResult = const SkillVerifyResult(matched: ['demo']);
  List<SkillUpdateCandidate> updates = const [];

  SkillLockEntry _entry(String slug) => SkillLockEntry(
    slug: slug,
    source: 'owner/repo',
    sourceType: SkillOrigin.github,
    skillPath: 'skills/$slug/SKILL.md',
    computedHash: 'hash-$slug',
    ref: 'abc123',
  );

  @override
  Future<SkillLockEntry> pinLocal({
    required String workspaceId,
    required String slug,
    SkillOrigin origin = SkillOrigin.manual,
    String source = '',
  }) async {
    lastPinned = SkillLockEntry(
      slug: slug,
      source: source.isEmpty ? 'local' : source,
      sourceType: origin,
      skillPath: 'skills/$slug/SKILL.md',
      computedHash: 'hash-$slug',
    );
    return lastPinned!;
  }

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
  }) async {
    lastInstalled = _entry(slug);
    return lastInstalled!;
  }

  @override
  Future<SkillLockEntry> applyUpdate({
    required String workspaceId,
    required String slug,
    String? ref,
    bool allowQuarantineOverride = false,
    String? spaceId,
    String? agentId,
  }) async {
    lastUpdated = _entry(slug);
    return lastUpdated!;
  }

  @override
  Future<SkillVerifyResult> verify(String workspaceId) async => verifyResult;

  @override
  Future<List<SkillUpdateCandidate>> checkUpdates(String workspaceId) async =>
      updates;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

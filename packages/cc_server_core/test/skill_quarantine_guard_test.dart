import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_server_core/src/skill_quarantine_guard.dart';
import 'package:test/test.dart';

/// PRD 23 §6 enforcement: a skill whose lock verdict is `quarantine` is
/// detached from every agent that had it attached — the link filter inside
/// `syncAgentSkillLinks` does the stripping; the guard just re-runs each
/// affected agent's sync and reports who was detached. Attachments (the
/// agent's `Agent.skills`) are deliberately left untouched.
void main() {
  Agent agent(String id, String name, List<String> skills) => Agent(
    id: id,
    name: name,
    title: name,
    agentMdPath: '/agents/$name.md',
    workspaceId: 'ws-1',
    skills: AgentSkills(skills),
    createdAt: DateTime(2026, 1, 1),
  );

  SkillLock lockWith(Map<String, SkillScanVerdict> verdicts) => SkillLock(
    skills: {
      for (final e in verdicts.entries)
        e.key: SkillLockEntry(
          slug: e.key,
          source: 'ws',
          sourceType: SkillOrigin.manual,
          skillPath: 'skills/${e.key}/SKILL.md',
          computedHash: 'h-${e.key}',
          scanVerdict: e.value,
          rulesVersion: 1,
        ),
    },
  );

  test('returns empty when nothing is quarantined', () async {
    final deps = _Deps(lock: lockWith({'a': SkillScanVerdict.pass}));
    deps.agents.seed([agent('1', 'ceo', const ['a'])]);
    final guard = deps.build();
    expect(await guard.detachQuarantined('ws-1'), isEmpty);
    expect(deps.fs.syncCalls, isEmpty);
  });

  test('detaches every quarantined skill from every attached agent', () async {
    final deps = _Deps(
      lock: lockWith({
        'bad1': SkillScanVerdict.quarantine,
        'bad2': SkillScanVerdict.quarantine,
        'ok': SkillScanVerdict.pass,
      }),
    );
    deps.agents.seed([
      agent('1', 'ceo', const ['bad1', 'ok']),
      agent('2', 'dev', const ['bad2']),
      agent('3', 'clean', const ['ok']),
    ]);
    final guard = deps.build();
    final detached = await guard.detachQuarantined('ws-1');
    expect(detached, containsAll(['ceo', 'dev']));
    // Each affected agent is re-synced with its FULL attachment list — the
    // link filter (not the guard) decides which links survive.
    expect(deps.fs.syncCalls, hasLength(2));
    final ceoCall = deps.fs.syncCalls.firstWhere((c) => c.$2 == 'ceo');
    expect(ceoCall.$3, ['bad1', 'ok']);
  });

  test('a slug-scoped call only considers that slug', () async {
    final deps = _Deps(
      lock: lockWith({
        'bad1': SkillScanVerdict.quarantine,
        'bad2': SkillScanVerdict.quarantine,
      }),
    );
    deps.agents.seed([agent('1', 'ceo', const ['bad1', 'bad2'])]);
    final guard = deps.build();
    expect(await guard.detachQuarantined('ws-1', slug: 'bad2'), ['ceo']);
    // A non-quarantined slug is a no-op even when scoped.
    expect(await guard.detachQuarantined('ws-1', slug: 'ok'), isEmpty);
  });

  test('one agent sync failure does not abort the pass', () async {
    final deps = _Deps(lock: lockWith({'bad': SkillScanVerdict.quarantine}));
    deps.agents.seed([
      agent('1', 'throws', const ['bad']),
      agent('2', 'fine', const ['bad']),
    ]);
    deps.fs.failFor.add('throws');
    final guard = deps.build();
    expect(await guard.detachQuarantined('ws-1'), ['fine']);
  });

  test('isQuarantined reads the lock verdict', () async {
    final deps = _Deps(
      lock: lockWith({
        'bad': SkillScanVerdict.quarantine,
        'ok': SkillScanVerdict.pass,
      }),
    );
    final guard = deps.build();
    expect(await guard.isQuarantined('ws-1', 'bad'), isTrue);
    expect(await guard.isQuarantined('ws-1', 'ok'), isFalse);
    expect(await guard.isQuarantined('ws-1', 'absent'), isFalse);
  });
}

/// Collapsed fixture bag: three interface fakes wired together.
class _Deps {
  _Deps({required this.lock});

  final SkillLock lock;
  final _FakeAgents _agents = _FakeAgents();
  final _FakeFs _fs = _FakeFs();

  _FakeAgents get agents => _agents;
  _FakeFs get fs => _fs;

  SkillQuarantineGuard build() => SkillQuarantineGuard(
    agents: _agents,
    bundles: _FakeBundles(lock),
    filesystem: _fs,
  );
}

class _FakeBundles implements SkillBundlePort {
  _FakeBundles(this._lock);
  final SkillLock _lock;

  @override
  Future<SkillLock> readLock(String workspaceId) async => _lock;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Fake agent repository: only [watchByWorkspace] is implemented.
class _FakeAgents implements AgentRepository {
  final List<Agent> _agents = [];

  void seed(List<Agent> agents) => _agents.addAll(agents);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(List.of(_agents));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Fake filesystem port: records `syncAgentSkillLinks` calls, can fail for a
/// chosen agent slug.
class _FakeFs implements WorkspaceFilesystemPort {
  /// (workspaceId, agentSlug, skillSlugs) per call.
  final List<(String, String, List<String>)> syncCalls = [];
  final Set<String> failFor = {};

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String agentSlug,
    List<String> skillSlugs,
  ) async {
    if (failFor.contains(agentSlug)) {
      throw StateError('sync failed for $agentSlug');
    }
    syncCalls.add((workspaceId, agentSlug, List.of(skillSlugs)));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

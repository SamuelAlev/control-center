import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart';
import 'package:cc_domain/features/sandboxing/domain/repositories/sandbox_exec_grant_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/services/sandbox_exec_grant_service.dart';
import 'package:test/test.dart';

/// In-memory store with the same "most specific covering grant wins" rule as
/// the drift-backed repository.
class _FakeRepo implements SandboxExecGrantRepository {
  final List<SandboxExecGrant> rows = [];

  @override
  Future<List<SandboxExecGrant>> grants(String workspaceId) async => [
    for (final g in rows)
      if (g.workspaceId == workspaceId) g,
  ];

  @override
  Stream<List<SandboxExecGrant>> watchGrants(String workspaceId) =>
      Stream.fromFuture(grants(workspaceId));

  @override
  Future<SandboxExecGrant?> decisionFor(String workspaceId, String path) async {
    SandboxExecGrant? best;
    for (final g in await grants(workspaceId)) {
      if (!g.covers(path)) {
        continue;
      }
      if (best == null || g.path.length > best.path.length) {
        best = g;
      }
    }
    return best;
  }

  @override
  Future<void> upsert(SandboxExecGrant grant) async {
    rows.removeWhere(
      (g) => g.workspaceId == grant.workspaceId && g.path == grant.path,
    );
    rows.add(grant);
  }

  @override
  Future<void> revoke(String workspaceId, String id) =>
      Future.sync(() => rows.removeWhere((g) => g.id == id));
}

class _FakePort implements ConfirmationPort {
  _FakePort(this.answer);
  final bool answer;
  final List<ConfirmationRequest> asked = [];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    asked.add(request);
    return answer;
  }
}

void main() {
  const worktree = '/data/spaces/s1/repos';
  const tool = '$worktree/web-app/node_modules/.bin/husky';

  late _FakeRepo repo;
  var nextId = 0;

  SandboxExecGrantService serviceWith(ConfirmationPort? port) =>
      SandboxExecGrantService(
        repository: repo,
        confirmationPort: port,
        idFactory: () => 'g${nextId++}',
        clock: () => DateTime.utc(2026, 1, 1),
      );

  setUp(() {
    repo = _FakeRepo();
    nextId = 0;
  });

  group('approvedRoots (asked before the profile is written)', () {
    test('asks once, then returns the tree on approval', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [worktree],
        ),
        [worktree],
      );
      expect(port.asked, hasLength(1));
      expect(port.asked.single.command, worktree);
      expect(port.asked.single.workspaceId, 'ws1');
    });

    test('a recorded answer is never re-asked', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);

      await service.approvedRoots(
        workspaceId: 'ws1',
        candidateRoots: const [worktree],
      );
      final second = await service.approvedRoots(
        workspaceId: 'ws1',
        candidateRoots: const [worktree],
      );

      expect(second, [worktree]);
      expect(
        port.asked,
        hasLength(1),
        reason: 'the stored decision must answer without prompting again',
      );
    });

    test('a decline is remembered, so it does not nag every run', () async {
      final port = _FakePort(false);
      final service = serviceWith(port);

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [worktree],
        ),
        isEmpty,
      );
      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [worktree],
        ),
        isEmpty,
      );
      expect(port.asked, hasLength(1));
      expect(repo.rows.single.decision, SandboxExecGrantDecision.deny);
    });

    test('with no approver it grants nothing and records nothing', () async {
      // Fail-closed, matching the action guard's "prompt with no approver ⇒
      // deny". Recording a deny here would turn a temporarily headless host
      // into a permanent refusal the operator never made.
      final service = serviceWith(null);

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [worktree],
        ),
        isEmpty,
      );
      expect(repo.rows, isEmpty);
    });
  });

  group('recordDeniedExec (asked after the kernel refused)', () {
    test('offers the enclosing worktree for a blocked tool', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);

      expect(
        await service.recordDeniedExec(
          workspaceId: 'ws1',
          deniedPath: tool,
          candidateRoots: const [worktree],
        ),
        worktree,
      );
      expect(port.asked.single.title, contains('husky'));
      expect(
        port.asked.single.detail,
        contains('applies from the next command'),
        reason: 'the copy must not imply the blocked run can be resumed',
      );
    });

    test('never offers a grant for a path outside the worktree', () async {
      // A denial under /nix/store or /usr is a profile bug to fix, not a tree
      // the operator should be talked into opening.
      final port = _FakePort(true);
      final service = serviceWith(port);

      expect(
        await service.recordDeniedExec(
          workspaceId: 'ws1',
          deniedPath: '/nix/store/abc-coreutils-9.11/bin/coreutils',
          candidateRoots: const [worktree],
        ),
        isNull,
      );
      expect(port.asked, isEmpty);
      expect(repo.rows, isEmpty);
    });

    test('an existing decline is not re-litigated by a later denial', () async {
      final port = _FakePort(false);
      final service = serviceWith(port);

      await service.recordDeniedExec(
        workspaceId: 'ws1',
        deniedPath: tool,
        candidateRoots: const [worktree],
      );
      final second = await service.recordDeniedExec(
        workspaceId: 'ws1',
        deniedPath: tool,
        candidateRoots: const [worktree],
      );

      expect(second, isNull);
      expect(port.asked, hasLength(1));
    });
  });
}

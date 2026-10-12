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
  // The provisioner's layout: <spaceRoot>/repos beside
  // <spaceRoot>/agents/<overlay>.
  const spaceRoot = '/data/spaces/s1';
  const overlay = '$spaceRoot/agents/dev--conv-1';

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

  group('approvedRoots — server-created disposable trees', () {
    test('a fresh conversation grants its overlay and worktrees with no '
        'question', () async {
      // The regression this exists for: the overlay is per conversation, so
      // before the managed root a brand-new conversation was a brand-new
      // unknown tree and asked again — every time.
      final port = _FakePort(true);
      final service = serviceWith(port);

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [overlay, worktree],
          managedRoots: const [spaceRoot],
        ),
        [overlay, worktree],
      );
      expect(port.asked, isEmpty);
      expect(
        repo.rows,
        isEmpty,
        reason: 'the implicit grant is not a decision the operator made',
      );
    });

    test('the next conversation is covered by the same space root', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);

      await service.approvedRoots(
        workspaceId: 'ws1',
        candidateRoots: const [overlay],
        managedRoots: const [spaceRoot],
      );
      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const ['$spaceRoot/agents/dev--conv-2'],
          managedRoots: const [spaceRoot],
        ),
        ['$spaceRoot/agents/dev--conv-2'],
      );
      expect(port.asked, isEmpty);
    });

    test('a path outside the managed root is still a question', () async {
      // The boundary: only the server's own trees are implicit. An original
      // checkout (and anything else on the host) keeps asking.
      final port = _FakePort(true);
      final service = serviceWith(port);

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const ['/data/checkouts/original'],
          managedRoots: const [spaceRoot],
        ),
        ['/data/checkouts/original'],
      );
      expect(port.asked, hasLength(1));
    });

    test('a segment sibling is not covered by the managed root', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const ['/data/spaces/s1-secrets'],
          managedRoots: const [spaceRoot],
        ),
        ['/data/spaces/s1-secrets'],
      );
      expect(
        port.asked,
        hasLength(1),
        reason:
            'a name that merely starts with the managed root is not it — '
            'it must go through a real decision',
      );
    });

    test('an explicit deny on the tree keeps it blocked and silent', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);
      await repo.upsert(
        SandboxExecGrant(
          id: 'g-deny',
          workspaceId: 'ws1',
          path: spaceRoot,
          decision: SandboxExecGrantDecision.deny,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [overlay, worktree],
          managedRoots: const [spaceRoot],
        ),
        isEmpty,
        reason: 'a covering deny outranks the implicit managed grant',
      );
      expect(port.asked, isEmpty);
    });

    test('an explicit allow answers without the implicit path', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);
      await repo.upsert(
        SandboxExecGrant(
          id: 'g-allow',
          workspaceId: 'ws1',
          path: overlay,
          decision: SandboxExecGrantDecision.allow,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [overlay],
          managedRoots: const [worktree],
        ),
        [overlay],
      );
      expect(port.asked, isEmpty);
    });

    test('a stored parent allow cannot reopen a denied descendant', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);
      for (final (path, decision) in [
        (worktree, SandboxExecGrantDecision.allow),
        ('$worktree/web-app', SandboxExecGrantDecision.deny),
      ]) {
        await repo.upsert(
          SandboxExecGrant(
            id: path,
            workspaceId: 'ws1',
            path: path,
            decision: decision,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
      }
      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [worktree],
          managedRoots: const [spaceRoot],
        ),
        isEmpty,
      );
      expect(
        await service.recordDeniedExec(
          workspaceId: 'ws1',
          deniedPath: tool,
          candidateRoots: const [worktree],
          managedRoots: const [spaceRoot],
        ),
        isNull,
      );
      expect(port.asked, isEmpty);
    });

    test('a denied DESCENDANT withholds the whole managed root', () async {
      // The profile carries exec roots as one allow list, so it cannot say
      // "everything here except that subtree". Reaching for the root would
      // silently re-open the refused path; the tree is held closed instead.
      final port = _FakePort(true);
      final service = serviceWith(port);
      await repo.upsert(
        SandboxExecGrant(
          id: 'g-deny',
          workspaceId: 'ws1',
          path: '$worktree/web-app',
          decision: SandboxExecGrantDecision.deny,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [overlay, worktree],
          managedRoots: const [spaceRoot],
        ),
        [overlay],
        reason: 'only the candidate containing the refused subtree is closed',
      );
      expect(
        port.asked,
        isEmpty,
        reason: 'the operator already answered about that tree',
      );
    });

    test('a denied sibling does not withhold the managed root', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);
      await repo.upsert(
        SandboxExecGrant(
          id: 'g-deny',
          workspaceId: 'ws1',
          path: '$spaceRoot/agents/dev--conv-9',
          decision: SandboxExecGrantDecision.deny,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(
        await service.approvedRoots(
          workspaceId: 'ws1',
          candidateRoots: const [overlay, worktree],
          managedRoots: const [spaceRoot],
        ),
        [overlay, worktree],
      );
      expect(port.asked, isEmpty);
    });
  });

  group('recordDeniedExec — server-created disposable trees', () {
    test(
      'a denial inside a managed tree is covered, not asked about',
      () async {
        final port = _FakePort(true);
        final service = serviceWith(port);

        expect(
          await service.recordDeniedExec(
            workspaceId: 'ws1',
            deniedPath: tool,
            candidateRoots: const [overlay, worktree],
            managedRoots: const [spaceRoot],
          ),
          worktree,
        );
        expect(port.asked, isEmpty);
        expect(repo.rows, isEmpty);
      },
    );

    test('a covering deny still wins over the implicit grant', () async {
      final port = _FakePort(true);
      final service = serviceWith(port);
      await repo.upsert(
        SandboxExecGrant(
          id: 'g-deny',
          workspaceId: 'ws1',
          path: worktree,
          decision: SandboxExecGrantDecision.deny,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(
        await service.recordDeniedExec(
          workspaceId: 'ws1',
          deniedPath: tool,
          candidateRoots: const [overlay, worktree],
          managedRoots: const [spaceRoot],
        ),
        isNull,
      );
      expect(port.asked, isEmpty);
    });

    test('a denied descendant leaves nothing to announce', () async {
      // The root is withheld by approvedRoots in this state, so claiming it was
      // granted would promise a profile the next command will not get.
      final port = _FakePort(true);
      final service = serviceWith(port);
      await repo.upsert(
        SandboxExecGrant(
          id: 'g-deny',
          workspaceId: 'ws1',
          path: '$worktree/web-app',
          decision: SandboxExecGrantDecision.deny,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(
        await service.recordDeniedExec(
          workspaceId: 'ws1',
          deniedPath: tool,
          candidateRoots: const [overlay, worktree],
          managedRoots: const [spaceRoot],
        ),
        isNull,
      );
      expect(port.asked, isEmpty);
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

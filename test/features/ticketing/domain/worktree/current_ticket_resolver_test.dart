import 'package:cc_domain/features/ticketing/domain/worktree/current_ticket_resolver.dart';
import 'package:cc_domain/features/ticketing/domain/worktree/worktree_ticket_link.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLinkPort implements WorktreeTicketLinkPort {
  _FakeLinkPort(this.refs);
  final List<WorktreeTicketRef> refs;
  final List<({String worktreeId, String? ticketId})> linked = [];

  @override
  Future<List<WorktreeTicketRef>> forWorkspace(String w) async =>
      refs.where((r) => r.workspaceId == w).toList();
  @override
  Future<WorktreeTicketRef?> byId(String w, String id) async =>
      refs.where((r) => r.workspaceId == w && r.worktreeId == id).firstOrNull;
  @override
  Future<void> linkTicket({
    required String workspaceId,
    required String worktreeId,
    String? ticketId,
    String? vendor,
    String? externalId,
  }) async => linked.add((worktreeId: worktreeId, ticketId: ticketId));
}

void main() {
  const ws = 'ws-1';

  test('resolves the ticket from the worktree containing the cwd', () async {
    final port = _FakeLinkPort([
      const WorktreeTicketRef(
        worktreeId: 'wt1',
        workspaceId: ws,
        path: '/work/ws/agent-a',
        ticketId: 't-123',
        vendor: 'linear',
        externalId: 'ENG-123',
      ),
    ]);
    final resolver = CurrentTicketResolver(port);

    final ref = await resolver.resolve(
      workspaceId: ws,
      workingDirectory: '/work/ws/agent-a/repos/app/lib',
    );

    expect(ref, isNotNull);
    expect(ref!.ticketId, 't-123');
    expect(ref.externalId, 'ENG-123');
  });

  test('picks the deepest (longest-prefix) worktree when nested', () async {
    final port = _FakeLinkPort([
      const WorktreeTicketRef(
        worktreeId: 'outer',
        workspaceId: ws,
        path: '/work',
        ticketId: 'outer-t',
      ),
      const WorktreeTicketRef(
        worktreeId: 'inner',
        workspaceId: ws,
        path: '/work/ws/agent-a',
        ticketId: 'inner-t',
      ),
    ]);
    final resolver = CurrentTicketResolver(port);

    final ref = await resolver.resolve(
      workspaceId: ws,
      workingDirectory: '/work/ws/agent-a/sub',
    );
    expect(ref!.ticketId, 'inner-t');
  });

  test('returns null when no linked worktree contains the cwd', () async {
    final port = _FakeLinkPort([
      const WorktreeTicketRef(
        worktreeId: 'wt1',
        workspaceId: ws,
        path: '/other/place',
        ticketId: 't1',
      ),
    ]);
    final resolver = CurrentTicketResolver(port);
    final ref = await resolver.resolve(
      workspaceId: ws,
      workingDirectory: '/work/ws/agent-a',
    );
    expect(ref, isNull);
  });

  test('does not match a sibling prefix (/a/b vs /a/bc)', () async {
    final port = _FakeLinkPort([
      const WorktreeTicketRef(
        worktreeId: 'wt1',
        workspaceId: ws,
        path: '/a/b',
        ticketId: 't1',
      ),
    ]);
    final resolver = CurrentTicketResolver(port);
    final ref = await resolver.resolve(
      workspaceId: ws,
      workingDirectory: '/a/bc',
    );
    expect(ref, isNull);
  });

  test('ignores worktrees with no ticket link', () async {
    final port = _FakeLinkPort([
      const WorktreeTicketRef(
        worktreeId: 'wt1',
        workspaceId: ws,
        path: '/work/ws/a',
      ),
    ]);
    final resolver = CurrentTicketResolver(port);
    final ref = await resolver.resolve(
      workspaceId: ws,
      workingDirectory: '/work/ws/a',
    );
    expect(ref, isNull);
  });
}

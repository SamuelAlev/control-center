import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every conversation watch it is asked for, so a test can assert
/// which `(workspaceId, spaceId)` pairs ever reached the transport. Every
/// other method is unreachable from the watch path under test.
class _RecordingConversationRepository implements ConversationRepository {
  final List<({String workspaceId, String spaceId})> watched = [];

  @override
  Stream<List<Conversation>> watchForSpace({
    required String workspaceId,
    required String spaceId,
  }) {
    watched.add((workspaceId: workspaceId, spaceId: spaceId));
    // Deliberately non-empty, so "the guard closed the stream down" is
    // distinguishable from "the provider never re-ran".
    return Stream.value([
      Conversation(
        id: 'conv-of-$spaceId',
        workspaceId: workspaceId,
        spaceId: spaceId,
        title: spaceId,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not under test');
}

/// Records every read-cursor watch it is asked for, so a test can assert which
/// `(workspaceId, spaceId)` pairs ever reached the transport.
class _RecordingSpaceReadRepository implements SpaceReadRepository {
  final List<({String workspaceId, String spaceId})> watched = [];

  @override
  Future<void> markSpaceRead(
    String workspaceId,
    String spaceId,
    String userId,
  ) async {}

  @override
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String spaceId,
    String userId,
  ) {
    watched.add((workspaceId: workspaceId, spaceId: spaceId));
    return Stream<DateTime?>.value(DateTime(2024));
  }
}

void main() {
  group('SelectSpaceNotifier', () {
    test('builds with null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedSpaceIdProvider), isNull);
    });

    test('select sets new value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedSpaceIdProvider.notifier).select('ch-1');
      expect(container.read(selectedSpaceIdProvider), 'ch-1');
    });

    test('select null clears value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedSpaceIdProvider.notifier).select('ch-1');
      container.read(selectedSpaceIdProvider.notifier).select(null);
      expect(container.read(selectedSpaceIdProvider), isNull);
    });
  });

  group('visibleSpacesProvider', () {
    Space space(
      String id, {
      SpaceKind kind = SpaceKind.topic,
      String? pipelineRunId,
    }) => Space(
      id: id,
      name: id,
      kind: kind,
      pipelineRunId: pipelineRunId,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    test('excludes pipeline-managed spaces', () {
      final visible = space('ch-1');
      final hidden = space('ch-2', pipelineRunId: 'run-1');

      final container = ProviderContainer(
        overrides: [
          spacesProvider.overrideWithValue(AsyncData([visible, hidden])),
        ],
      );
      addTearDown(container.dispose);

      final spaces = container.read(visibleSpacesProvider);
      expect(spaces, hasLength(1));
      expect(spaces.first.id, 'ch-1');
    });

    test('returns all spaces when none are pipeline-managed', () {
      final a = space('ch-1');
      final b = space('ch-2');

      final container = ProviderContainer(
        overrides: [
          spacesProvider.overrideWithValue(AsyncData([a, b])),
        ],
      );
      addTearDown(container.dispose);

      final spaces = container.read(visibleSpacesProvider);
      expect(spaces, hasLength(2));
    });

    test('returns empty when there are no spaces', () {
      final container = ProviderContainer(
        overrides: [spacesProvider.overrideWithValue(const AsyncData([]))],
      );
      addTearDown(container.dispose);

      expect(container.read(visibleSpacesProvider), isEmpty);
    });

    test('excludes PR-workbench spaces (no workspace activity to consult)', () {
      final manual = space('ch-1');
      final workbench = Space(
        id: 'ch-2',
        name: 'PR #7',
        kind: SpaceKind.pr,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final container = ProviderContainer(
        overrides: [
          spacesProvider.overrideWithValue(AsyncData([manual, workbench])),
        ],
      );
      addTearDown(container.dispose);

      final spaces = container.read(visibleSpacesProvider);
      expect(spaces.map((c) => c.id), ['ch-1']);
    });
  });

  group('workspaceVisibleSpacesProvider', () {
    const ws = 'ws-1';

    Space space(String id, {SpaceKind kind = SpaceKind.topic}) => Space(
      id: id,
      name: id,
      workspaceId: ws,
      kind: kind,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    ProviderContainer containerWith(
      List<Space> spaces,
      Map<String, SpaceActivity> activity,
    ) {
      final container = ProviderContainer(
        overrides: [
          workspaceSpacesProvider(ws).overrideWithValue(AsyncData(spaces)),
          workspaceSpaceActivityProvider(
            ws,
          ).overrideWithValue(AsyncData(activity)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('hides a never-messaged PR-workbench space', () {
      final container = containerWith([
        space('ch-manual'),
        space('ch-pr', kind: SpaceKind.pr),
      ], const {});

      final visible = container.read(workspaceVisibleSpacesProvider(ws));
      expect(visible.map((c) => c.id), ['ch-manual']);
    });

    test('surfaces a PR-workbench space once it has messages', () {
      final container = containerWith(
        [space('ch-pr', kind: SpaceKind.pr)],
        {
          'ch-pr': SpaceActivity(
            spaceId: 'ch-pr',
            lastMessageAt: DateTime(2024, 2),
          ),
        },
      );

      final visible = container.read(workspaceVisibleSpacesProvider(ws));
      expect(visible.map((c) => c.id), ['ch-pr']);
    });

    test('hides PR-workbench spaces while the activity aggregate loads', () {
      final container = ProviderContainer(
        overrides: [
          workspaceSpacesProvider(
            ws,
          ).overrideWithValue(AsyncData([space('ch-pr', kind: SpaceKind.pr)])),
          workspaceSpaceActivityProvider(
            ws,
          ).overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(workspaceVisibleSpacesProvider(ws)), isEmpty);
    });

    test('keeps user spaces visible regardless of activity', () {
      final container = containerWith([space('ch-manual')], const {});

      final visible = container.read(workspaceVisibleSpacesProvider(ws));
      expect(visible.map((c) => c.id), ['ch-manual']);
    });
  });

  group('spaceUserLastReadAtProvider', () {
    const ws = 'ws-1';

    Space space(String id, {String? workspaceId = ws}) => Space(
      id: id,
      name: id,
      workspaceId: workspaceId,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    ProviderContainer containerWith(
      List<Space> spaces,
      _RecordingSpaceReadRepository repo,
    ) {
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_StubActiveWorkspaceId.new),
          workspaceSpacesProvider(ws).overrideWithValue(AsyncData(spaces)),
          spaceReadRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    /// Reads the cursor while holding a listener open — the provider is
    /// autoDispose, so a bare `read(...future)` would dispose it mid-loading.
    Future<DateTime?> readCursor(
      ProviderContainer container,
      String spaceId,
    ) async {
      final sub = container.listen(
        spaceUserLastReadAtProvider(spaceId),
        (_, _) {},
      );
      addTearDown(sub.close);
      return container.read(spaceUserLastReadAtProvider(spaceId).future);
    }

    test('watches the cursor for a space of the active workspace', () async {
      final repo = _RecordingSpaceReadRepository();
      final container = containerWith([space('ch-1')], repo);

      await readCursor(container, 'ch-1');

      expect(repo.watched, [(workspaceId: ws, spaceId: 'ch-1')]);
    });

    test('never watches a space belonging to another workspace', () async {
      // The space list is the answer to a workspace-scoped subscription, but
      // a mis-scoped one can hand back a FOREIGN workspace's spaces (the
      // switch-race this guard backstops). Matching on the space's own
      // workspaceId — not merely on its presence in the list — keeps the pair
      // the server would reject ("Space belongs to a different workspace")
      // off the wire, instead of re-issuing it on every resubscribe.
      final repo = _RecordingSpaceReadRepository();
      final container = containerWith([
        space('ch-foreign', workspaceId: 'ws-2'),
      ], repo);

      final cursor = await readCursor(container, 'ch-foreign');

      expect(cursor, isNull);
      expect(repo.watched, isEmpty);
    });
  });

  group('spaceConversationsProvider', () {
    const wsA = 'ws-1';
    const wsB = 'ws-2';

    Space space(String id, String? workspaceId) => Space(
      id: id,
      name: id,
      workspaceId: workspaceId,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    ProviderContainer containerWith({
      required AsyncValue<List<Space>> inA,
      required AsyncValue<List<Space>> inB,
      required _RecordingConversationRepository repo,
    }) {
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_MutableActiveWorkspaceId.new),
          workspaceSpacesProvider(wsA).overrideWithValue(inA),
          workspaceSpacesProvider(wsB).overrideWithValue(inB),
          conversationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    /// Reads the conversation list while holding a listener open — the
    /// provider is autoDispose, so a bare `read(...future)` would dispose it
    /// mid-loading.
    Future<List<Conversation>> readConversations(
      ProviderContainer container,
      String spaceId,
    ) async {
      final sub = container.listen(
        spaceConversationsProvider(spaceId),
        (_, _) {},
      );
      addTearDown(sub.close);
      return container.read(spaceConversationsProvider(spaceId).future);
    }

    test('watches a space of the active workspace', () async {
      final repo = _RecordingConversationRepository();
      final container = containerWith(
        inA: AsyncData([space('ch-a', wsA)]),
        inB: const AsyncLoading(),
        repo: repo,
      );

      await readConversations(container, 'ch-a');

      expect(repo.watched, [(workspaceId: wsA, spaceId: 'ch-a')]);
    });

    test('never watches a space belonging to another workspace', () async {
      final repo = _RecordingConversationRepository();
      final container = containerWith(
        inA: AsyncData([space('ch-foreign', wsB)]),
        inB: const AsyncLoading(),
        repo: repo,
      );

      expect(await readConversations(container, 'ch-foreign'), isEmpty);
      expect(repo.watched, isEmpty);
    });

    test(
      'opens no watch for the previous workspace\'s spaces on a switch',
      () async {
        // The switch race this guard exists for. The sidebar renders a row per
        // space and survives a workspace switch, so when the ambient workspace
        // id flips, Riverpod recomputes this provider for every row — still
        // keyed on the OLD workspace's spaces — one frame before the rebuild
        // that drops those rows. Ungated, each recompute sent the server a
        // `(new workspace, old space)` pair it must reject
        // ("Space belongs to a different workspace"), one warning per visible
        // space per switch.
        final repo = _RecordingConversationRepository();
        final container = containerWith(
          inA: AsyncData([space('ch-a', wsA)]),
          // ws-2's space list is still loading at the instant of the flip —
          // exactly the window the recompute lands in.
          inB: const AsyncLoading(),
          repo: repo,
        );

        expect(
          (await readConversations(container, 'ch-a')).single.id, //
          'conv-of-ch-a',
        );
        expect(repo.watched, [(workspaceId: wsA, spaceId: 'ch-a')]);

        (container.read(activeWorkspaceIdProvider.notifier)
                as _MutableActiveWorkspaceId)
            .switchTo(wsB);

        // Empty rather than the recorded conversation proves the provider DID
        // re-run under the new workspace and the guard closed it down — and
        // `watched` is unchanged, so nothing new went on the wire.
        expect(await readConversations(container, 'ch-a'), isEmpty);
        expect(repo.watched, [(workspaceId: wsA, spaceId: 'ch-a')]);
      },
    );
  });

  group('spaceBusyConversationIdsProvider', () {
    AgentRunLog run(String id, {String? conversationId}) => AgentRunLog(
      id: id,
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      spaceId: 'ch-1',
      conversationId: conversationId,
      startedAt: DateTime(2024),
      status: RunStatus.running,
    );

    ProviderContainer containerWith(List<AgentRunLog> runs) {
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_StubActiveWorkspaceId.new),
          // The provider only opens the space's run stream for a space the
          // active workspace owns, so the list has to carry it — see
          // `_workspaceOwningSpace`.
          workspaceSpacesProvider('ws-1').overrideWithValue(
            AsyncData([
              Space(
                id: 'ch-1',
                name: 'ch-1',
                workspaceId: 'ws-1',
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
              ),
            ]),
          ),
          spaceActiveRunsProvider((
            workspaceId: 'ws-1',
            spaceId: 'ch-1',
          )).overrideWith((ref) => Stream.value(runs)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    /// Reads while holding a listener open: the provider is autoDispose, and a
    /// bare `read` would tear the stream down before it emitted.
    Future<Set<String>> busyIds(ProviderContainer container) async {
      final sub = container.listen(
        spaceBusyConversationIdsProvider('ch-1'),
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(
        spaceActiveRunsProvider((workspaceId: 'ws-1', spaceId: 'ch-1')).future,
      );
      return container.read(spaceBusyConversationIdsProvider('ch-1'));
    }

    test('reports the conversations their runs name', () async {
      final ids = await busyIds(
        containerWith([
          run('r1', conversationId: 'conv-a'),
          run('r2', conversationId: 'conv-c'),
        ]),
      );

      expect(ids, {'conv-a', 'conv-c'});
    });

    test('is empty while nothing is running', () async {
      expect(await busyIds(containerWith(const [])), isEmpty);
    });

    test('drops a run that names no conversation', () async {
      // Unattributable to any row, so the sidebar leaves its signal on the
      // space — dropping it here is what keeps the space row spinning for it
      // rather than the whole space reading as idle.
      final ids = await busyIds(
        containerWith([run('r1'), run('r2', conversationId: 'conv-b')]),
      );

      expect(ids, {'conv-b'});
    });
  });

  group('userHistoryFromMessages', () {
    Message msg(
      String content, {
      String senderId = 'me',
      SenderType senderType = SenderType.user,
      MessageType type = MessageType.text,
      bool compacted = false,
    }) => Message(
      id: 'm-${content.hashCode}',
      spaceId: 'sp',
      conversationId: 'conv',
      senderId: senderId,
      senderType: senderType,
      content: content,
      messageType: type,
      compacted: compacted,
      createdAt: DateTime(2024),
    );

    test('keeps only the current user’s plain-text prompts, oldest first', () {
      final history = userHistoryFromMessages([
        msg('hello', senderId: 'me'),
        msg('agent reply', senderId: 'agent-1', senderType: SenderType.agent),
        msg('teammate says hi', senderId: 'someone-else'),
        msg('run the tests'),
        msg('a card', type: MessageType.ticketCard),
      ], 'me');

      expect(history, ['hello', 'run the tests']);
    });

    test('drops compacted rows and collapses consecutive duplicates', () {
      final history = userHistoryFromMessages([
        msg('ship it'),
        msg('ship it'),
        msg('folded away', compacted: true),
        msg('ship it'),
        msg('then refactor'),
      ], 'me');

      // The non-consecutive repeat survives: only back-to-back duplicates
      // collapse (a shell's ignoredups).
      expect(history, ['ship it', 'ship it', 'then refactor']);
    });

    test('is empty while the user is unresolved', () {
      // No attribution → no history, rather than guessing whose prompts these
      // are. The composer simply offers no recall until identity resolves.
      expect(userHistoryFromMessages([msg('hello')], null), isEmpty);
    });
  });

  group('spaceMeteredAgentIdProvider', () {
    SpaceParticipant participant(String id, {bool user = false}) =>
        SpaceParticipant(
          id: 'p-$id',
          spaceId: 'ch-1',
          principalId: id,
          participantType: user ? PrincipalType.user : PrincipalType.agent,
          role: 'member',
          joinedAt: DateTime(2024),
        );

    /// A finished run by default — the log is mostly history, and history is
    /// what the meter falls back on between turns.
    AgentRunLog run(
      String agentId, {
      required DateTime startedAt,
      DateTime? completedAt,
      DateTime? lastOutputAt,
      RunStatus status = RunStatus.completed,
    }) => AgentRunLog(
      id: 'run-$agentId-${startedAt.millisecondsSinceEpoch}',
      agentId: agentId,
      workspaceId: 'ws-1',
      spaceId: 'ch-1',
      startedAt: startedAt,
      completedAt:
          completedAt ?? (status == RunStatus.completed ? startedAt : null),
      lastOutputAt: lastOutputAt,
      status: status,
    );

    ProviderContainer containerWith({
      required List<SpaceParticipant> participants,
      required Stream<List<AgentRunLog>> runs,
    }) {
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_StubActiveWorkspaceId.new),
          // The run stream only opens for a space the active workspace owns —
          // see `_workspaceOwningSpace`.
          workspaceSpacesProvider('ws-1').overrideWithValue(
            AsyncData([
              Space(
                id: 'ch-1',
                name: 'ch-1',
                workspaceId: 'ws-1',
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
              ),
            ]),
          ),
          spaceParticipantsProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(participants)),
          spaceRunLogsProvider((
            workspaceId: 'ws-1',
            spaceId: 'ch-1',
          )).overrideWith((ref) => runs),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    /// Subscribes (the provider is autoDispose) and lets both streams land.
    Future<String? Function()> metered(ProviderContainer container) async {
      final sub = container.listen(
        spaceMeteredAgentIdProvider('ch-1'),
        (_, _) {},
      );
      addTearDown(sub.close);
      await pumpEventQueue();
      return () => container.read(spaceMeteredAgentIdProvider('ch-1'));
    }

    test('answers the only agent in a single-agent space', () async {
      final read = await metered(
        containerWith(
          participants: [participant('user-1', user: true), participant('a-1')],
          runs: const Stream.empty(),
        ),
      );

      expect(read(), 'a-1');
    });

    test('is null for a space with no agent in it', () async {
      final read = await metered(
        containerWith(
          participants: [participant('user-1', user: true)],
          runs: const Stream.empty(),
        ),
      );

      expect(read(), isNull);
    });

    test('follows the agent that spoke last, run finished or not', () async {
      // The bug this replaced: with only live runs consulted, an idle space
      // fell back to the first participant and reported the same agent's
      // window forever, whoever had actually been talking.
      final read = await metered(
        containerWith(
          participants: [participant('a-1'), participant('a-2')],
          runs: Stream.value([
            run(
              'a-1',
              startedAt: DateTime(2024, 5, 1, 9),
              completedAt: DateTime(2024, 5, 1, 10),
            ),
            run(
              'a-2',
              startedAt: DateTime(2024, 5, 1, 10, 30),
              completedAt: DateTime(2024, 5, 1, 11),
            ),
          ]),
        ),
      );

      expect(read(), 'a-2');
    });

    test('a streaming run wins on its own output stamp', () async {
      // Not because it is "active" — because it is what happened last. The
      // stamp advances with every chunk, so the working agent stays the
      // subject without needing a special case.
      final read = await metered(
        containerWith(
          participants: [participant('a-1'), participant('a-2')],
          runs: Stream.value([
            run(
              'a-2',
              startedAt: DateTime(2024, 5, 1, 11),
              completedAt: DateTime(2024, 5, 1, 11, 3),
            ),
            run(
              'a-1',
              startedAt: DateTime(2024, 5, 1, 10),
              lastOutputAt: DateTime(2024, 5, 1, 11, 30),
              status: RunStatus.running,
            ),
          ]),
        ),
      );

      expect(read(), 'a-1');
    });

    test('a stale in-flight row does not pin the meter', () async {
      // An orphaned `running` row (killed process, not yet reaped) would
      // otherwise hold the meter on its agent forever — the exact "always the
      // same agent" failure this ranking exists to fix.
      final read = await metered(
        containerWith(
          participants: [participant('a-1'), participant('a-2')],
          runs: Stream.value([
            run(
              'a-1',
              startedAt: DateTime(2024, 5, 1, 8),
              status: RunStatus.running,
            ),
            run(
              'a-2',
              startedAt: DateTime(2024, 5, 1, 11),
              completedAt: DateTime(2024, 5, 1, 11, 3),
            ),
          ]),
        ),
      );

      expect(read(), 'a-2');
    });

    test('the newer of two live runs wins', () async {
      final read = await metered(
        containerWith(
          participants: [participant('a-1'), participant('a-2')],
          runs: Stream.value([
            run(
              'a-1',
              startedAt: DateTime(2024, 5, 1, 10),
              status: RunStatus.running,
            ),
            run(
              'a-2',
              startedAt: DateTime(2024, 5, 1, 11),
              status: RunStatus.running,
            ),
          ]),
        ),
      );

      expect(read(), 'a-2');
    });

    test('ignores a run whose agent is not a participant', () async {
      // A spawned subagent logs under a name the roster has no row for; the
      // window a human can act on is still the parent's.
      final read = await metered(
        containerWith(
          participants: [participant('a-1'), participant('a-2')],
          runs: Stream.value([
            run('subagent', startedAt: DateTime(2024, 5, 1, 12)),
          ]),
        ),
      );

      expect(read(), 'a-1');
    });

    test('holds its subject when the log stops naming it', () async {
      final runs = StreamController<List<AgentRunLog>>();
      addTearDown(runs.close);
      final read = await metered(
        containerWith(
          participants: [participant('a-1'), participant('a-2')],
          runs: runs.stream,
        ),
      );

      runs.add([run('a-2', startedAt: DateTime(2024, 5, 1, 10))]);
      await pumpEventQueue();
      expect(read(), 'a-2');

      // Retention pruned the row: the meter must not swap to a different
      // window on a change that says nothing about who is working.
      runs.add(const []);
      await pumpEventQueue();
      expect(read(), 'a-2');
    });

    test('drops a held agent that leaves the space', () async {
      final participants = StreamController<List<SpaceParticipant>>();
      addTearDown(participants.close);
      final runs = StreamController<List<AgentRunLog>>();
      addTearDown(runs.close);
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_StubActiveWorkspaceId.new),
          workspaceSpacesProvider('ws-1').overrideWithValue(
            AsyncData([
              Space(
                id: 'ch-1',
                name: 'ch-1',
                workspaceId: 'ws-1',
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
              ),
            ]),
          ),
          spaceParticipantsProvider(
            'ch-1',
          ).overrideWith((ref) => participants.stream),
          spaceRunLogsProvider((
            workspaceId: 'ws-1',
            spaceId: 'ch-1',
          )).overrideWith((ref) => runs.stream),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        spaceMeteredAgentIdProvider('ch-1'),
        (_, _) {},
      );
      addTearDown(sub.close);

      participants.add([participant('a-1'), participant('a-2')]);
      runs.add([run('a-2', startedAt: DateTime(2024, 5, 1, 10))]);
      await pumpEventQueue();
      expect(container.read(spaceMeteredAgentIdProvider('ch-1')), 'a-2');

      participants.add([participant('a-1'), participant('a-3')]);
      runs.add(const []);
      await pumpEventQueue();
      expect(container.read(spaceMeteredAgentIdProvider('ch-1')), 'a-1');
    });
  });
}

/// Pins the active workspace to `ws-1` without touching preferences/database.
class _StubActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';
}

/// Starts at `ws-1` and can be flipped, so a test can reproduce a workspace
/// switch without the real notifier's preference write.
class _MutableActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';

  void switchTo(String id) => state = id;
}

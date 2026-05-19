import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/space_factory.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:test/test.dart';

class _FakeMessagingRepository implements MessagingRepository {
  final List<
    ({
      String workspaceId,
      String name,
      List<String> agentIds,
      Mode mode,
      SpaceKind kind,
      List<String>? repoIds,
      String? pipelineRunId,
    })
  >
  created = [];

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  }) async {
    created.add((
      workspaceId: workspaceId,
      name: name,
      agentIds: agentIds,
      mode: mode,
      kind: kind,
      repoIds: repoIds,
      pipelineRunId: pipelineRunId,
    ));
    final now = DateTime(2026);
    return Space(
      id: 'space-${created.length}',
      name: name,
      workspaceId: workspaceId,
      createdAt: now,
      updatedAt: now,
      mode: mode,
      kind: kind,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

void main() {
  group('SpaceFactory', () {
    test('writes the row and announces it', () async {
      final repo = _FakeMessagingRepository();
      final bus = DomainEventBus();
      final seen = <SpaceCreated>[];
      final sub = bus.on<SpaceCreated>().listen(seen.add);
      addTearDown(sub.cancel);

      final space = await SpaceFactory(
        repository: repo,
        eventBus: bus,
      ).create('ws-1', 'review', const ['agent-a'], repoIds: const ['repo-1']);

      await Future<void>.delayed(Duration.zero);

      expect(repo.created.single.workspaceId, 'ws-1');
      expect(repo.created.single.repoIds, ['repo-1']);
      expect(seen.single.spaceId, space.id);
      // The method's argument, not the entity's nullable field.
      expect(seen.single.workspaceId, 'ws-1');
    });

    // The provisioner reads the PR association to decide which ref to check
    // out, so a listener that wakes before it is written checks out the default
    // branch and calls it the review's tree.
    test('runs beforeAnnounce between the write and the event', () async {
      final repo = _FakeMessagingRepository();
      final bus = DomainEventBus();
      final order = <String>[];
      final sub = bus.on<SpaceCreated>().listen((_) => order.add('announced'));
      addTearDown(sub.cancel);

      await SpaceFactory(repository: repo, eventBus: bus).create(
        'ws-1',
        'PR #42',
        const [],
        kind: SpaceKind.pr,
        beforeAnnounce: (space) async {
          order.add('association:${space.id}');
        },
      );

      await Future<void>.delayed(Duration.zero);

      expect(order, ['association:space-1', 'announced']);
    });

    // A host with no event-driven background work publishes nothing, which is
    // the correct behaviour there — not a step silently skipped on a host that
    // does have one.
    test('creates without a bus', () async {
      final repo = _FakeMessagingRepository();

      final space = await SpaceFactory(
        repository: repo,
      ).create('ws-1', 'quiet', const []);

      expect(space.id, 'space-1');
      expect(repo.created, hasLength(1));
    });
  });
}

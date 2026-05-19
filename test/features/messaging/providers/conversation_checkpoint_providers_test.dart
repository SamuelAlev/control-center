import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/conversation_checkpoint_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/active_workspace.dart';

class _FakeMessaging implements MessagingRepository {
  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async => null;

  final List<({String workspaceId, String spaceId, String messageId})> reverts =
      [];

  /// Workspaces the unrevert calls were scoped to, newest last.
  final List<String> unrevertWorkspaces = [];
  int unreverts = 0;
  List<String> revertResult = const ['m2', 'm3'];
  List<String> unrevertResult = const ['m2', 'm3'];

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async {
    reverts.add((
      workspaceId: workspaceId,
      spaceId: spaceId,
      messageId: messageId,
    ));
    return revertResult;
  }

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async {
    unrevertWorkspaces.add(workspaceId);
    unreverts++;
    return unrevertResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');

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
  late _FakeMessaging messaging;
  late ProviderContainer container;

  setUp(() {
    messaging = _FakeMessaging();
    container = ProviderContainer(
      overrides: [
        activeWorkspaceIdOverride(),
        messagingRepositoryProvider.overrideWithValue(messaging),
      ],
    );
    addTearDown(container.dispose);
  });

  test('revertTo reverts via the repo and records an undoable batch', () async {
    expect(container.read(spaceHasUndoableRevertProvider('c1')), isFalse);

    final count = await container
        .read(conversationCheckpointControllerProvider)
        .revertTo('c1', 'm1');

    expect(count, 2);
    expect(messaging.reverts.single.messageId, 'm1');
    // The revert is scoped to the active workspace: a space id alone does not
    // name a database file, so it can never roll back a neighbour's history.
    expect(messaging.reverts.single.workspaceId, kTestWorkspaceId);
    expect(container.read(spaceHasUndoableRevertProvider('c1')), isTrue);
  });

  test('unrevert decrements the undo depth back to none', () async {
    final controller = container.read(conversationCheckpointControllerProvider);
    await controller.revertTo('c1', 'm1');
    expect(container.read(spaceHasUndoableRevertProvider('c1')), isTrue);

    final restored = await controller.unrevert('c1');

    expect(restored, 2);
    expect(messaging.unreverts, 1);
    expect(container.read(spaceHasUndoableRevertProvider('c1')), isFalse);
  });

  test('a no-op revert (nothing after the message) records nothing', () async {
    messaging.revertResult = const [];

    final count = await container
        .read(conversationCheckpointControllerProvider)
        .revertTo('c1', 'last');

    expect(count, 0);
    expect(container.read(spaceHasUndoableRevertProvider('c1')), isFalse);
  });

  test('revert depth is tracked per space', () async {
    final controller = container.read(conversationCheckpointControllerProvider);
    await controller.revertTo('c1', 'm1');

    expect(container.read(spaceHasUndoableRevertProvider('c1')), isTrue);
    expect(container.read(spaceHasUndoableRevertProvider('c2')), isFalse);
  });
}

import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/conversation_checkpoint_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/active_workspace.dart';

class _FakeMessaging implements MessagingRepository {
  @override
  Future<Channel?> getChannelById(String workspaceId, String channelId) async =>
      null;

  final List<({String workspaceId, String channelId, String messageId})>
  reverts = [];

  /// Workspaces the unrevert calls were scoped to, newest last.
  final List<String> unrevertWorkspaces = [];
  int unreverts = 0;
  List<String> revertResult = const ['m2', 'm3'];
  List<String> unrevertResult = const ['m2', 'm3'];

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async {
    reverts.add((
      workspaceId: workspaceId,
      channelId: channelId,
      messageId: messageId,
    ));
    return revertResult;
  }

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) async {
    unrevertWorkspaces.add(workspaceId);
    unreverts++;
    return unrevertResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
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
    expect(container.read(channelHasUndoableRevertProvider('c1')), isFalse);

    final count = await container
        .read(conversationCheckpointControllerProvider)
        .revertTo('c1', 'm1');

    expect(count, 2);
    expect(messaging.reverts.single.messageId, 'm1');
    // The revert is scoped to the active workspace: a channel id alone does not
    // name a database file, so it can never roll back a neighbour's history.
    expect(messaging.reverts.single.workspaceId, kTestWorkspaceId);
    expect(container.read(channelHasUndoableRevertProvider('c1')), isTrue);
  });

  test('unrevert decrements the undo depth back to none', () async {
    final controller = container.read(conversationCheckpointControllerProvider);
    await controller.revertTo('c1', 'm1');
    expect(container.read(channelHasUndoableRevertProvider('c1')), isTrue);

    final restored = await controller.unrevert('c1');

    expect(restored, 2);
    expect(messaging.unreverts, 1);
    expect(container.read(channelHasUndoableRevertProvider('c1')), isFalse);
  });

  test('a no-op revert (nothing after the message) records nothing', () async {
    messaging.revertResult = const [];

    final count = await container
        .read(conversationCheckpointControllerProvider)
        .revertTo('c1', 'last');

    expect(count, 0);
    expect(container.read(channelHasUndoableRevertProvider('c1')), isFalse);
  });

  test('revert depth is tracked per channel', () async {
    final controller = container.read(conversationCheckpointControllerProvider);
    await controller.revertTo('c1', 'm1');

    expect(container.read(channelHasUndoableRevertProvider('c1')), isTrue);
    expect(container.read(channelHasUndoableRevertProvider('c2')), isFalse);
  });
}

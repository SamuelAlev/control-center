import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/message_edit_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/active_workspace.dart';

class _FakeMessagingRepo implements MessagingRepository {
  @override
  Future<Channel?> getChannelById(String workspaceId, String channelId) async =>
      null;

  final List<({String id, String? content, Map<String, dynamic>? metadata})>
  updates = [];

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    updates.add((id: messageId, content: content, metadata: metadata));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ChannelMessage _msg({
  String content = 'hello',
  Map<String, dynamic>? metadata,
}) => ChannelMessage(
  id: 'm1',
  channelId: 'c1',
  conversationId: 'c1',
  senderId: 'u1',
  senderType: ChannelSenderType.user,
  content: content,
  messageType: ChannelMessageType.text,
  metadata: metadata,
  createdAt: DateTime(2026, 7, 1),
);

void main() {
  late _FakeMessagingRepo repo;
  late ProviderContainer container;
  late MessageEditController controller;

  setUp(() {
    repo = _FakeMessagingRepo();
    container = ProviderContainer(
      overrides: [
        messagingRepositoryProvider.overrideWithValue(repo),
        // The controller writes through a workspace-scoped repository, so the
        // route-driven workspace has to be seeded.
        activeWorkspaceIdOverride(),
      ],
    );
    controller = container.read(messageEditControllerProvider);
  });

  tearDown(() => container.dispose());

  group('MessageEditController.edit', () {
    test(
      'writes new content + an editedAt stamp, preserving other metadata',
      () async {
        final wrote = await controller.edit(
          _msg(
            metadata: {
              'segments': ['a'],
            },
          ),
          '  edited text  ',
        );
        expect(wrote, isTrue);
        expect(repo.updates.single.id, 'm1');
        expect(repo.updates.single.content, 'edited text'); // trimmed
        expect(repo.updates.single.metadata!['editedAt'], isNotNull);
        expect(repo.updates.single.metadata!['segments'], ['a']);
      },
    );

    test('is a no-op for empty or unchanged text', () async {
      expect(await controller.edit(_msg(content: 'hi'), '   '), isFalse);
      expect(await controller.edit(_msg(content: 'hi'), 'hi'), isFalse);
      expect(repo.updates, isEmpty);
    });
  });

  group('MessageEditController.softDelete', () {
    test(
      'stamps deletedAt and leaves content untouched (metadata-only)',
      () async {
        await controller.softDelete(_msg());
        expect(repo.updates.single.content, isNull);
        expect(repo.updates.single.metadata!['deletedAt'], isNotNull);
      },
    );

    test(
      'is idempotent — an already-deleted message is not re-written',
      () async {
        await controller.softDelete(_msg(metadata: {'deletedAt': 1}));
        expect(repo.updates, isEmpty);
      },
    );
  });
}

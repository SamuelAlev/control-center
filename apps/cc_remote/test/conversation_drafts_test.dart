@TestOn('browser')
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/attachments.dart';
import 'package:cc_remote/conversation_drafts.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'drafts survive reconnect, stay scoped, and clear when pairing ends',
    () async {
      final (host, channel) = InProcessRpcChannel.pair();
      final client = RemoteRpcClient(channel);
      final clients = StreamController<RemoteRpcClient>();
      final states = StreamController<RemoteUiState>();
      final container = ProviderContainer(
        overrides: [
          rpcClientProvider.overrideWith((ref) async* {
            yield client;
            yield* clients.stream;
          }),
          remoteUiStateProvider.overrideWith((ref) async* {
            yield const RemoteUiState.connected();
            yield* states.stream;
          }),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(host.close);
      addTearDown(clients.close);
      addTearDown(states.close);
      container.listen(rpcClientProvider, (_, _) {});
      container.listen(remoteUiStateProvider, (_, _) {});
      await container.read(rpcClientProvider.future);
      await container.read(remoteUiStateProvider.future);

      Future<void> publishState(RemoteUiState state) async {
        final delivered = Completer<void>();
        final subscription = container.listen(remoteUiStateProvider, (_, next) {
          if (identical(next.value, state) && !delivered.isCompleted) {
            delivered.complete();
          }
        });
        states.add(state);
        await delivered.future;
        subscription.close();
        await container.pump();
      }

      const first = (
        workspaceId: 'ws-one',
        spaceId: 'space',
        conversationId: 'thread',
      );
      const second = (
        workspaceId: 'ws-two',
        spaceId: 'space',
        conversationId: 'thread',
      );
      const otherConversation = (
        workspaceId: 'ws-one',
        spaceId: 'space',
        conversationId: 'other',
      );
      final store = container.read(conversationDraftsProvider);
      final draft = store.putIfAbsent(first, ConversationDraft.new);
      draft.controller.text = 'Keep this question and image';
      draft.attachments.add(
        DraftAttachment(
          PickedAttachment(
            name: 'planning.jpg',
            bytes: Uint8List.fromList([5, 6, 7]),
            mediaType: 'image/jpeg',
          ),
        ),
      );

      expect(
        store
            .putIfAbsent(otherConversation, ConversationDraft.new)
            .controller
            .text,
        isEmpty,
      );
      final secondDraft = store.putIfAbsent(second, ConversationDraft.new);
      expect(secondDraft.controller.text, isEmpty);
      expect(secondDraft.attachments, isEmpty);
      secondDraft.controller.text = 'Different workspace';

      await publishState(const RemoteUiState.connecting());
      final reconnecting = container.read(conversationDraftsProvider);
      expect(
        reconnecting[first]!.controller.text,
        'Keep this question and image',
      );
      expect(
        reconnecting[first]!.attachments.single.picked.bytes,
        orderedEquals([5, 6, 7]),
      );
      expect(reconnecting[second]!.controller.text, 'Different workspace');

      await publishState(const RemoteUiState.connected());
      expect(
        container.read(conversationDraftsProvider)[first]!.controller.text,
        'Keep this question and image',
      );

      final (nextHost, nextChannel) = InProcessRpcChannel.pair();
      addTearDown(nextHost.close);
      final nextClient = RemoteRpcClient(nextChannel);
      final delivered = Completer<void>();
      final subscription = container.listen(rpcClientProvider, (_, next) {
        if (identical(next.value, nextClient) && !delivered.isCompleted) {
          delivered.complete();
        }
      });
      clients.add(nextClient);
      await delivered.future;
      subscription.close();
      await container.pump();
      final nextPairing = container.read(conversationDraftsProvider);
      expect(nextPairing[first], isNull);
      expect(nextPairing[second], isNull);
      final privateDraft = nextPairing.putIfAbsent(
        first,
        ConversationDraft.new,
      );
      expect(privateDraft.controller.text, isEmpty);
      expect(privateDraft.attachments, isEmpty);
      privateDraft.controller.text =
          'Do not retain after forgetting the server';

      await publishState(const RemoteUiState.notPaired());
      expect(container.read(conversationDraftsProvider), isEmpty);
    },
  );

  test('ambiguous retry preserves logical key and original queue decision', () {
    final draft = ConversationDraft();
    addTearDown(draft.dispose);
    draft.controller.text = 'Please review';
    final firstKey = draft.intentKey(draft.controller.text);
    expect(draft.queueForIntent(true), isTrue);

    // The server may persist the first request before its response is lost;
    // when the run ends, repeating it must target the same queue ledger entry.
    final retryKey = draft.intentKey(draft.controller.text);
    expect(retryKey, firstKey);
    expect(draft.queueForIntent(false), isTrue);

    draft.controller.text = 'Please review the changed version';
    final revisedKey = draft.intentKey(draft.controller.text);
    expect(revisedKey, isNot(firstKey));
    expect(draft.queueForIntent(false), isFalse);

    // The visible sentence may stay the same while its claimed file changes.
    final attachedKey = draft.intentKey('Please review\u0000catalog-a');
    expect(attachedKey, isNot(revisedKey));
    expect(draft.intentKey('Please review\u0000catalog-a'), attachedKey);
    expect(draft.intentKey('Please review\u0000catalog-b'), isNot(attachedKey));

    draft.sent();
    expect(draft.controller.text, isEmpty);
    expect(draft.intentKey('Please review'), isNot(firstKey));
  });

  test('dispatch retry stays dispatch when a run starts before retry', () {
    final draft = ConversationDraft();
    addTearDown(draft.dispose);
    final key = draft.intentKey('Dispatch now');
    expect(draft.queueForIntent(false), isFalse);
    expect(draft.intentKey('Dispatch now'), key);
    expect(draft.queueForIntent(true), isFalse);
  });
}

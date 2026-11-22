import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:control_center/features/messaging/providers/space_conversation_tab_order_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Conversation _conversation(String id) => Conversation(
  id: id,
  workspaceId: 'ws-1',
  spaceId: 'space-1',
  title: id,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

List<String> _ids(List<Conversation> conversations) => [
  for (final c in conversations) c.id,
];

void main() {
  group('orderByConversationTabs', () {
    final list = [
      for (final id in ['a', 'b', 'c', 'd']) _conversation(id),
    ];

    test('no tab order keeps the list order', () {
      expect(_ids(orderByConversationTabs(list, const [])), [
        'a',
        'b',
        'c',
        'd',
      ]);
    });

    test('tabbed conversations come first in tab order, the rest after in '
        'list order', () {
      expect(_ids(orderByConversationTabs(list, const ['c', 'a'])), [
        'c',
        'a',
        'b',
        'd',
      ]);
    });

    test('a tab for a conversation not in the list is ignored', () {
      expect(_ids(orderByConversationTabs(list, const ['gone', 'd'])), [
        'd',
        'a',
        'b',
        'c',
      ]);
    });
  });

  group('spaceConversationTabOrderProvider', () {
    test('notifies on a new order and stays quiet on the same one', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = spaceConversationTabOrderProvider('space-1');
      var notified = 0;
      container.listen(provider, (_, _) => notified++);

      container.read(provider.notifier).set(['a', 'b']);
      container.read(provider.notifier).set(['a', 'b']);
      expect(notified, 1);

      container.read(provider.notifier).set(['b', 'a']);
      expect(notified, 2);
      expect(container.read(provider), ['b', 'a']);
      // Another space's order is its own.
      expect(
        container.read(spaceConversationTabOrderProvider('other')),
        isEmpty,
      );
    });
  });
}

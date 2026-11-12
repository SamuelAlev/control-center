import 'dart:ui';

import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_item_state.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/di/notification_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/shell/providers/notification_center_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _English extends LocaleNotifier {
  @override
  Locale? build() => const Locale('en');
}

NotificationFeedItem _wait(String id, {String? resolvedAt, int seq = 0}) =>
    NotificationFeedItem(
      id: id,
      workspaceId: 'ws-1',
      method: 'notifications/agent_awaiting_input',
      params: {
        'workspace_id': 'ws-1',
        'wait_id': 'wait-$id',
        'kind': 'approval',
        'summary': 'Let agents run programs from this workspace copy?',
        NotificationFeedItem.resolvedAtKey: ?resolvedAt,
      },
      createdAt: DateTime.utc(2026, 10, 9, 10),
      seq: seq,
    );

void main() {
  Future<Map<String, bool>> readById(
    List<NotificationFeedItem> items, {
    List<NotificationItemState> states = const [],
    NotificationReadMark? mark,
  }) async {
    final container = ProviderContainer(
      overrides: [
        localeProvider.overrideWith(_English.new),
        currentUserIdProvider.overrideWithValue('user-1'),
        mutedReposProvider.overrideWith((ref) async => const <String>{}),
        viewerLoginSetProvider.overrideWithValue(const <String>{}),
        notificationFeedProvider.overrideWith((ref) => Stream.value(items)),
        // Never acknowledged anything: only the item itself can say read.
        notificationReadMarkProvider.overrideWith(
          (ref) => Stream.value(
            mark ?? NotificationReadMark(workspaceId: 'ws-1', userId: 'user-1'),
          ),
        ),
        notificationItemStatesProvider.overrideWith(
          (ref) => Stream.value({for (final s in states) s.itemId: s}),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(notificationFeedProvider, (_, _) {})
      ..listen(notificationReadMarkProvider, (_, _) {})
      ..listen(notificationItemStatesProvider, (_, _) {});
    await container.read(notificationFeedProvider.future);
    await container.read(notificationReadMarkProvider.future);
    await container.read(notificationItemStatesProvider.future);
    return {
      for (final entry in container.read(notificationCenterProvider))
        entry.id: entry.read,
    };
  }

  test('an answered approval reads as read', () async {
    expect(
      await readById([
        _wait('open'),
        _wait('answered', resolvedAt: '2026-10-09T10:01:00.000Z'),
      ]),
      {'open': false, 'answered': true},
    );
  });

  test('an explicit "mark as unread" outranks the resolution', () async {
    expect(
      await readById(
        [_wait('answered', resolvedAt: '2026-10-09T10:01:00.000Z')],
        states: [
          NotificationItemState(
            workspaceId: 'ws-1',
            userId: 'user-1',
            itemId: 'answered',
          ),
        ],
      ),
      {'answered': false},
    );
  });

  test(
    'marks compare positions: a same-second item after them shows',
    () async {
      // Every item here shares one second; only the sequence orders them.
      final position = FeedPosition(at: DateTime.utc(2026, 10, 9, 10), seq: 2);
      expect(
        await readById(
          [
            _wait('cleared', seq: 1),
            _wait('seen', seq: 3),
            _wait('new', seq: 5),
          ],
          mark: NotificationReadMark(
            workspaceId: 'ws-1',
            userId: 'user-1',
            lastSeen: FeedPosition(at: position.at, seq: 4),
            cleared: position,
          ),
        ),
        {'seen': true, 'new': false},
      );
    },
  );
}

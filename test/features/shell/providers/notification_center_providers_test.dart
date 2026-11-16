import 'dart:ui';

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_page.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_item_state.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/di/notification_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/shell/providers/notification_center_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
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

class _ActiveWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';

  void select(String id) => state = id;
}

/// A stored feed of [total] rows: each window gets the newest `limit` of them.
class _WindowedFeed implements NotificationFeedRepository {
  _WindowedFeed(this.total);

  final int total;
  final List<int> limits = [];

  @override
  Stream<NotificationFeedPage> watchFeed(
    String workspaceId, {
    int limit = NotificationFeedRepository.pageSize,
  }) {
    limits.add(limit);
    return Stream.value(
      NotificationFeedPage(
        items: [
          for (var i = 0; i < limit && i < total; i++)
            _wait('$workspaceId-$i', seq: total - i),
        ],
        hasMore: total > limit,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('feed window', () {
    Future<ProviderContainer> containerFor(_WindowedFeed feed) async {
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_ActiveWorkspace.new),
          notificationFeedRepositoryProvider.overrideWithValue(feed),
        ],
      );
      addTearDown(container.dispose);
      container.listen(notificationFeedProvider, (_, _) {});
      await container.read(notificationFeedProvider.future);
      return container;
    }

    test('grows a page at a time while older rows exist', () async {
      final feed = _WindowedFeed(120);
      final container = await containerFor(feed);
      final actions = container.read(notificationCenterActionsProvider);

      actions.loadMore();
      // A second call while the grown page is still loading stacks nothing.
      actions.loadMore();
      await container.read(notificationFeedProvider.future);
      expect(
        container.read(notificationFeedProvider).value!.items,
        hasLength(100),
      );

      actions.loadMore();
      await container.read(notificationFeedProvider.future);
      expect(container.read(notificationFeedHasMoreProvider), isFalse);
      expect(
        container.read(notificationFeedProvider).value!.items,
        hasLength(120),
      );

      // Past the end of the stored feed, nothing more is asked for.
      actions.loadMore();
      await container.read(notificationFeedProvider.future);
      expect(feed.limits, [50, 100, 150]);
    });

    test('a different workspace starts over at one page', () async {
      final feed = _WindowedFeed(120);
      final container = await containerFor(feed);
      container.read(notificationCenterActionsProvider).loadMore();
      await container.read(notificationFeedProvider.future);

      (container.read(activeWorkspaceIdProvider.notifier) as _ActiveWorkspace)
          .select('ws-2');
      await container.read(notificationFeedProvider.future);
      expect(container.read(notificationFeedWindowProvider), 50);
      expect(feed.limits.last, 50);
    });
  });

  Future<Map<String, bool>> readById(
    List<NotificationFeedItem> items, {
    List<NotificationItemState> states = const [],
    NotificationReadMark? mark,
    Set<NotificationCategory> disabled = const {},
  }) async {
    final container = ProviderContainer(
      overrides: [
        localeProvider.overrideWith(_English.new),
        currentUserIdProvider.overrideWithValue('user-1'),
        mutedReposProvider.overrideWith((ref) async => const <String>{}),
        disabledNotificationCategoriesProvider.overrideWith(
          (ref) async => disabled,
        ),
        viewerLoginSetProvider.overrideWithValue(const <String>{}),
        notificationFeedProvider.overrideWith(
          (ref) =>
              Stream.value(NotificationFeedPage(items: items, hasMore: false)),
        ),
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
      ..listen(notificationItemStatesProvider, (_, _) {})
      ..listen(disabledNotificationCategoriesProvider, (_, _) {});
    await container.read(disabledNotificationCategoriesProvider.future);
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

  test('a category switched off in Settings leaves the bell', () async {
    final merged = NotificationFeedItem(
      id: 'merged',
      workspaceId: 'ws-1',
      method: 'notifications/pr_merged',
      params: const {'workspace_id': 'ws-1'},
      createdAt: DateTime.utc(2026, 10, 9, 10),
      seq: 1,
    );
    expect(await readById([_wait('open'), merged]), {
      'open': false,
      'merged': false,
    });
    expect(
      await readById(
        [_wait('open'), merged],
        disabled: {NotificationCategory.prMerged},
      ),
      {'open': false},
    );
  });
}

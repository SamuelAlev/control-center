import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every read-cursor watch it is asked for, so a test can assert which
/// `(workspaceId, channelId)` pairs ever reached the transport.
class _RecordingChannelReadRepository implements ChannelReadRepository {
  final List<({String workspaceId, String channelId})> watched = [];

  @override
  Future<void> markChannelRead(
    String workspaceId,
    String channelId,
    String userId,
  ) async {}

  @override
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String channelId,
    String userId,
  ) {
    watched.add((workspaceId: workspaceId, channelId: channelId));
    return Stream<DateTime?>.value(DateTime(2024));
  }
}

void main() {
  group('SelectChannelNotifier', () {
    test('builds with null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedChannelIdProvider), isNull);
    });

    test('select sets new value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedChannelIdProvider.notifier).select('ch-1');
      expect(container.read(selectedChannelIdProvider), 'ch-1');
    });

    test('select null clears value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedChannelIdProvider.notifier).select('ch-1');
      container.read(selectedChannelIdProvider.notifier).select(null);
      expect(container.read(selectedChannelIdProvider), isNull);
    });
  });

  group('visibleChannelsProvider', () {
    Channel channel(String id, {String? pipelineRunId}) => Channel(
      id: id,
      name: id,
      pipelineRunId: pipelineRunId,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    test('excludes pipeline-managed channels', () {
      final visible = channel('ch-1');
      final hidden = channel('ch-2', pipelineRunId: 'run-1');

      final container = ProviderContainer(
        overrides: [
          channelsProvider.overrideWithValue(AsyncData([visible, hidden])),
        ],
      );
      addTearDown(container.dispose);

      final channels = container.read(visibleChannelsProvider);
      expect(channels, hasLength(1));
      expect(channels.first.id, 'ch-1');
    });

    test('returns all channels when none are pipeline-managed', () {
      final a = channel('ch-1');
      final b = channel('ch-2');

      final container = ProviderContainer(
        overrides: [
          channelsProvider.overrideWithValue(AsyncData([a, b])),
        ],
      );
      addTearDown(container.dispose);

      final channels = container.read(visibleChannelsProvider);
      expect(channels, hasLength(2));
    });

    test('returns empty when there are no channels', () {
      final container = ProviderContainer(
        overrides: [channelsProvider.overrideWithValue(const AsyncData([]))],
      );
      addTearDown(container.dispose);

      expect(container.read(visibleChannelsProvider), isEmpty);
    });

    test(
      'excludes PR-workbench channels (no workspace activity to consult)',
      () {
        final manual = channel('ch-1');
        final workbench = Channel(
          id: 'ch-2',
          name: 'PR #7',
          origin: ChannelOrigin.prWorkbench,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        final container = ProviderContainer(
          overrides: [
            channelsProvider.overrideWithValue(AsyncData([manual, workbench])),
          ],
        );
        addTearDown(container.dispose);

        final channels = container.read(visibleChannelsProvider);
        expect(channels.map((c) => c.id), ['ch-1']);
      },
    );
  });

  group('workspaceVisibleChannelsProvider', () {
    const ws = 'ws-1';

    Channel channel(String id, {ChannelOrigin origin = ChannelOrigin.user}) =>
        Channel(
          id: id,
          name: id,
          workspaceId: ws,
          origin: origin,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

    ProviderContainer containerWith(
      List<Channel> channels,
      Map<String, ChannelActivity> activity,
    ) {
      final container = ProviderContainer(
        overrides: [
          workspaceChannelsProvider(ws).overrideWithValue(AsyncData(channels)),
          workspaceChannelActivityProvider(
            ws,
          ).overrideWithValue(AsyncData(activity)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('hides a never-messaged PR-workbench channel', () {
      final container = containerWith([
        channel('ch-manual'),
        channel('ch-pr', origin: ChannelOrigin.prWorkbench),
      ], const {});

      final visible = container.read(workspaceVisibleChannelsProvider(ws));
      expect(visible.map((c) => c.id), ['ch-manual']);
    });

    test('surfaces a PR-workbench channel once it has messages', () {
      final container = containerWith(
        [channel('ch-pr', origin: ChannelOrigin.prWorkbench)],
        {
          'ch-pr': ChannelActivity(
            channelId: 'ch-pr',
            lastMessageAt: DateTime(2024, 2),
          ),
        },
      );

      final visible = container.read(workspaceVisibleChannelsProvider(ws));
      expect(visible.map((c) => c.id), ['ch-pr']);
    });

    test('hides PR-workbench channels while the activity aggregate loads', () {
      final container = ProviderContainer(
        overrides: [
          workspaceChannelsProvider(ws).overrideWithValue(
            AsyncData([channel('ch-pr', origin: ChannelOrigin.prWorkbench)]),
          ),
          workspaceChannelActivityProvider(
            ws,
          ).overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(workspaceVisibleChannelsProvider(ws)), isEmpty);
    });

    test('keeps user channels visible regardless of activity', () {
      final container = containerWith([channel('ch-manual')], const {});

      final visible = container.read(workspaceVisibleChannelsProvider(ws));
      expect(visible.map((c) => c.id), ['ch-manual']);
    });
  });

  group('channelUserLastReadAtProvider', () {
    const ws = 'ws-1';

    Channel channel(String id, {String? workspaceId = ws}) => Channel(
      id: id,
      name: id,
      workspaceId: workspaceId,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    ProviderContainer containerWith(
      List<Channel> channels,
      _RecordingChannelReadRepository repo,
    ) {
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_StubActiveWorkspaceId.new),
          workspaceChannelsProvider(ws).overrideWithValue(AsyncData(channels)),
          channelReadRepositoryProvider.overrideWithValue(repo),
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
      String channelId,
    ) async {
      final sub = container.listen(
        channelUserLastReadAtProvider(channelId),
        (_, _) {},
      );
      addTearDown(sub.close);
      return container.read(channelUserLastReadAtProvider(channelId).future);
    }

    test('watches the cursor for a channel of the active workspace', () async {
      final repo = _RecordingChannelReadRepository();
      final container = containerWith([channel('ch-1')], repo);

      await readCursor(container, 'ch-1');

      expect(repo.watched, [(workspaceId: ws, channelId: 'ch-1')]);
    });

    test('never watches a channel belonging to another workspace', () async {
      // The channel list is the answer to a workspace-scoped subscription, but
      // a mis-scoped one can hand back a FOREIGN workspace's channels (the
      // switch-race this guard backstops). Matching on the channel's own
      // workspaceId — not merely on its presence in the list — keeps the pair
      // the server would reject ("Channel belongs to a different workspace")
      // off the wire, instead of re-issuing it on every resubscribe.
      final repo = _RecordingChannelReadRepository();
      final container = containerWith([
        channel('ch-foreign', workspaceId: 'ws-2'),
      ], repo);

      final cursor = await readCursor(container, 'ch-foreign');

      expect(cursor, isNull);
      expect(repo.watched, isEmpty);
    });
  });
}

/// Pins the active workspace to `ws-1` without touching preferences/database.
class _StubActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';
}

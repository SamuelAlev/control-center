import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('dmChannelsProvider', () {
    test('filters DM channels', () {
      final dm = Channel(
        id: 'dm-1',
        name: '',
        isDm: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final group = Channel(
        id: 'g-1',
        name: 'Team',
        isDm: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final container = ProviderContainer(
        overrides: [
          channelsProvider.overrideWithValue(AsyncData([dm, group])),
        ],
      );
      addTearDown(container.dispose);

      final dms = container.read(dmChannelsProvider);
      expect(dms, hasLength(1));
      expect(dms.first.id, 'dm-1');
    });

    test('returns empty when no DMs', () {
      final group = Channel(
        id: 'g-1',
        name: 'Team',
        isDm: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final container = ProviderContainer(
        overrides: [
          channelsProvider.overrideWithValue(AsyncData([group])),
        ],
      );
      addTearDown(container.dispose);

      final dms = container.read(dmChannelsProvider);
      expect(dms, isEmpty);
    });
  });

  group('groupChannelsProvider', () {
    test('filters group channels', () {
      final dm = Channel(
        id: 'dm-1',
        name: '',
        isDm: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final group = Channel(
        id: 'g-1',
        name: 'Team',
        isDm: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final container = ProviderContainer(
        overrides: [
          channelsProvider.overrideWithValue(AsyncData([dm, group])),
        ],
      );
      addTearDown(container.dispose);

      final groups = container.read(groupChannelsProvider);
      expect(groups, hasLength(1));
      expect(groups.first.id, 'g-1');
    });

    test('emits empty when no groups', () {
      final dm = Channel(
        id: 'dm-1',
        name: '',
        isDm: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final container = ProviderContainer(
        overrides: [
          channelsProvider.overrideWithValue(AsyncData([dm])),
        ],
      );
      addTearDown(container.dispose);

      final groups = container.read(groupChannelsProvider);
      expect(groups, isEmpty);
    });
  });
}

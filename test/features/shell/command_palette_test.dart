import 'dart:async';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A simple fake [CommandSource] for testing.
class FakeCommandSource implements CommandSource {
  FakeCommandSource({
    this.id = 'fake',
    this.category = 'Fake',
    this.isDynamic = false,
    this.items = const [],
  });

  @override
  final String id;
  @override
  final String category;
  @override
  final bool isDynamic;
  final List<CommandItem> items;

  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) => items;
}

CommandItem fakeItem(String id, String label) => CommandItem(
  id: id,
  label: label,
  icon: LucideIcons.star,
  category: 'Fake',
  onExecute: () {},
);


void main() {
  late AppPreferences prefs;
  setUp(() async {
    prefs = AppPreferences.inMemory();
  });

  group('CommandSource interface', () {
    test('CommandSource collects items via provider', () {
      final source = FakeCommandSource(
        items: [fakeItem('a', 'Alpha'), fakeItem('b', 'Beta')],
      );
      final container = ProviderContainer(
        overrides: [
          commandSourcesProvider.overrideWith((ref) => [source]),
        ],
      );
      addTearDown(container.dispose);

      final sources = container.read(commandSourcesProvider);
      expect(sources, hasLength(1));
      expect(sources.first.id, 'fake');
    });

    test('commandSourcesProvider returns built-in sources', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sources = container.read(commandSourcesProvider);
      // Should include navigation, view, PR, and ticketing sources.
      expect(sources.length, greaterThanOrEqualTo(4));
      expect(sources.any((s) => s.id == 'navigation'), isTrue);
      expect(sources.any((s) => s.id == 'view'), isTrue);
      expect(sources.any((s) => s.id == 'pull-requests'), isTrue);
      expect(sources.any((s) => s.id == 'ticketing'), isTrue);
    });

    test('multiple sources aggregate correctly', () {
      final fakeA = FakeCommandSource(
        id: 'a',
        category: 'Cat A',
        items: [fakeItem('a1', 'Alpha 1'), fakeItem('a2', 'Alpha 2')],
      );
      final fakeB = FakeCommandSource(
        id: 'b',
        category: 'Cat B',
        items: [fakeItem('b1', 'Beta 1')],
      );
      final container = ProviderContainer(
        overrides: [
          commandSourcesProvider.overrideWith((ref) => [fakeA, fakeB]),
        ],
      );
      addTearDown(container.dispose);

      final sources = container.read(commandSourcesProvider);
      expect(sources, hasLength(2));
      expect(sources[0].id, 'a');
      expect(sources[1].id, 'b');
    });

    test('empty dynamic source does not break aggregation', () {
      final empty = FakeCommandSource(
        id: 'empty',
        isDynamic: true,
        items: [],
      );
      final populated = FakeCommandSource(
        id: 'populated',
      );
      final container = ProviderContainer(
        overrides: [
          commandSourcesProvider.overrideWith((ref) => [empty, populated]),
        ],
      );
      addTearDown(container.dispose);

      final sources = container.read(commandSourcesProvider);
      expect(sources, hasLength(2));

      // Fake sources have no items by default.
      final allItems = <CommandItem>[];
      for (final s in sources) {
        final fake = s as FakeCommandSource;
        allItems.addAll(fake.items);
      }
      expect(allItems, isEmpty);
    });
  });

  group('FakeCommandSource', () {
    test('reports correct id, category, isDynamic', () {
      final source = FakeCommandSource(
        id: 'test-id',
        category: 'Test Cat',
        isDynamic: true,
      );
      expect(source.id, 'test-id');
      expect(source.category, 'Test Cat');
      expect(source.isDynamic, isTrue);
    });

    test('defaults to static, empty items', () {
      final source = FakeCommandSource();
      expect(source.isDynamic, isFalse);
      expect(source.items, isEmpty);
    });
  });

  group('buildGlobalCommands with sources', () {
    testWidgets('collects items from all sources via Consumer widget', (
      tester,
    ) async {
      final completer = Completer<List<CommandItem>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            commandSourcesProvider.overrideWith(
              (ref) => [
                FakeCommandSource(
                  id: 'src-a',
                  category: 'A',
                  items: [fakeItem('a1', 'Item A1')],
                ),
                FakeCommandSource(
                  id: 'src-b',
                  category: 'B',
                  items: [fakeItem('b1', 'Item B1')],
                ),
              ],
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final items = buildGlobalCommands(context, ref);
                completer.complete(items);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final items = await completer.future;
      expect(items, hasLength(2));
      expect(items.map((i) => i.id), containsAll(['a1', 'b1']));
    });
  });
}

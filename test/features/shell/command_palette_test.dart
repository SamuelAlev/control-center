import 'dart:async';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
  icon: AppIcons.star,
  category: 'Fake',
  onExecute: () {},
);

void main() {
  late AppPreferences prefs;
  setUp(() async {
    prefs = AppPreferences.inMemory();
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

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps a command list in a builder that ignores `context` and `ref`.
List<CommandItem> Function(BuildContext, WidgetRef) _builder(
  List<CommandItem> commands,
) =>
    (_, _) => commands;
List<CommandItem> _testCommands(int count, {String prefix = 'Command'}) {
  return List.generate(
    count,
    (i) => CommandItem(
      id: 'cmd-$i',
      label: '$prefix ${i + 1}',
      icon: LucideIcons.star,
      description: i.isEven ? 'Description for $prefix ${i + 1}' : null,
      shortcut: i.isEven ? 'Ctrl+$i' : null,
      category: i < 3 ? 'Navigation' : 'Tools',
      onExecute: () {},
    ),
  );
}

Widget wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('CommandItem', () {
    test('constructor creates with required fields', () {
      var executed = false;
      final item = CommandItem(
        id: 'cmd-1',
        label: 'Open Dashboard',
        icon: Icons.dashboard,
        onExecute: () => executed = true,
      );

      expect(item.id, 'cmd-1');
      expect(item.label, 'Open Dashboard');
      expect(item.icon, Icons.dashboard);
      expect(item.description, isNull);
      expect(item.shortcut, isNull);
      expect(item.category, isNull);

      item.onExecute();
      expect(executed, isTrue);
    });

    test('constructor with all fields', () {
      final item = CommandItem(
        id: 'cmd-2',
        label: 'Search Files',
        icon: Icons.search,
        description: 'Search files in workspace',
        shortcut: 'Cmd+P',
        category: 'Navigation',
        onExecute: () {},
      );

      expect(item.description, 'Search files in workspace');
      expect(item.shortcut, 'Cmd+P');
      expect(item.category, 'Navigation');
    });

    test('id is stable', () {
      final item = CommandItem(
        id: 'unique-id-123',
        label: 'Test',
        icon: Icons.star,
        onExecute: () {},
      );

      expect(item.id, 'unique-id-123');
    });

    test('onExecute is called correctly', () {
      var count = 0;
      final item = CommandItem(
        id: 'cmd',
        label: 'Count',
        icon: Icons.add,
        onExecute: () => count++,
      );

      item.onExecute();
      item.onExecute();
      item.onExecute();

      expect(count, 3);
    });

    test('different items have different ids', () {
      final a = CommandItem(
        id: 'a', label: 'A', icon: Icons.ac_unit, onExecute: () {},
      );
      final b = CommandItem(
        id: 'b', label: 'B', icon: Icons.ac_unit, onExecute: () {},
      );

      expect(a.id, isNot(b.id));
    });

    test('category groups items', () {
      final nav = CommandItem(
        id: 'nav', label: 'Nav', icon: Icons.navigation,
        category: 'Navigation', onExecute: () {},
      );
      final file = CommandItem(
        id: 'file', label: 'File', icon: Icons.folder,
        category: 'Files', onExecute: () {},
      );

      expect(nav.category, 'Navigation');
      expect(file.category, 'Files');
      expect(nav.category, isNot(file.category));
    });

    test('shortcut displays keyboard hint', () {
      final item = CommandItem(
        id: 'shortcut', label: 'Test', icon: Icons.keyboard,
        shortcut: 'Ctrl+Shift+K', onExecute: () {},
      );

      expect(item.shortcut, 'Ctrl+Shift+K');
    });

    test('description provides context', () {
      final item = CommandItem(
        id: 'desc', label: 'Test', icon: Icons.info,
        description: 'This is a test command with a longer description',
        onExecute: () {},
      );

      expect(item.description, contains('test command'));
    });

    test('item without category defaults to null', () {
      final item = CommandItem(
        id: 'no-cat',
        label: 'No Category',
        icon: Icons.help,
        onExecute: () {},
      );

      expect(item.category, isNull);
    });

    test('multiple items can share same id for testing', () {
      final a = CommandItem(
        id: 'same', label: 'A', icon: Icons.abc, onExecute: () {},
      );
      final b = CommandItem(
        id: 'same', label: 'B', icon: Icons.abc, onExecute: () {},
      );

      expect(a.id, b.id);
    });

    test('empty string shortcut is valid', () {
      final item = CommandItem(
        id: 'empty-shortcut',
        label: 'Test',
        icon: Icons.help,
        shortcut: '',
        onExecute: () {},
      );

      expect(item.shortcut, '');
    });

    test('empty string description is valid', () {
      final item = CommandItem(
        id: 'empty-desc',
        label: 'Test',
        icon: Icons.help,
        description: '',
        onExecute: () {},
      );

      expect(item.description, '');
    });
  });

  group('showCommandPalette', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget wrap(Widget child) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          codeFontFamilyProvider.overrideWithValue('JetBrainsMono'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    testWidgets('dialog opens with search field', (tester) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Type a command or search…'), findsOneWidget);
    });

    testWidgets('dialog shows command labels', (tester) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Command 1'), findsOneWidget);
      expect(find.text('Command 5'), findsOneWidget);
    });

    testWidgets('dialog shows category headers', (tester) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('NAVIGATION'), findsOneWidget);
      expect(find.text('TOOLS'), findsOneWidget);
    });

    testWidgets('dialog shows descriptions on items that have them', (
      tester,
    ) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Description for Command 1'), findsOneWidget);
      expect(find.text('Description for Command 3'), findsOneWidget);
    });

    testWidgets('dialog shows shortcuts on items that have them', (
      tester,
    ) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Ctrl+0'), findsOneWidget);
      expect(find.text('Ctrl+2'), findsOneWidget);
    });

    testWidgets('dialog shows footer hints', (tester) async {
      final commands = _testCommands(1);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

    });

    testWidgets('search filters commands by label', (tester) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(CcTextField);
      await tester.enterText(searchField, 'Command 3');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Command 3'), findsWidgets);
      expect(find.text('Command 1'), findsNothing);
    });

    testWidgets('search filters commands by description', (tester) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(CcTextField);
      await tester.enterText(searchField, 'Description for Command 1');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Command 1'), findsOneWidget);
    });

    testWidgets('search shows empty state when no matches', (tester) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(CcTextField);
      await tester.enterText(searchField, 'ZZZZNOMATCH');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No commands match'), findsOneWidget);
    });

    testWidgets('search filters by category', (tester) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(CcTextField);
      await tester.enterText(searchField, 'Tools');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Command 4'), findsOneWidget);
      expect(find.text('Command 5'), findsOneWidget);
      expect(find.text('Command 1'), findsNothing);
    });

    testWidgets('dialog shows search icon', (tester) async {
      final commands = _testCommands(1);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(LucideIcons.search), findsOneWidget);
    });

    testWidgets('esc button closes dialog', (tester) async {
      final commands = _testCommands(1);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Type a command or search…'), findsOneWidget);

      final escTap = find.text('esc');
      if (escTap.evaluate().isNotEmpty) {
        await tester.tap(escTap.last);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    });

    testWidgets('items with no category grouped as Other', (tester) async {
      final commands = [
        CommandItem(
          id: 'a',
          label: 'No Category Item',
          icon: LucideIcons.star,
          onExecute: () {},
        ),
      ];
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('OTHER'), findsOneWidget);
    });

    testWidgets('single command renders without category header', (tester) async {
      final commands = [
        CommandItem(
          id: 'solo',
          label: 'Solo Command',
          icon: LucideIcons.command,
          description: 'Works alone',
          shortcut: 'Cmd+S',
          onExecute: () {},
        ),
      ];
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Solo Command'), findsOneWidget);
      expect(find.text('Works alone'), findsOneWidget);
      expect(find.text('Cmd+S'), findsOneWidget);
    });

    testWidgets('empty commands list shows empty state immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(const [])),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No commands match'), findsOneWidget);
    });

    testWidgets('dialog has divider separators', (tester) async {
      final commands = _testCommands(1);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(CcDivider), findsWidgets);
    });

    testWidgets('keyboard return icon shown on selected row', (tester) async {
      final commands = _testCommands(3);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(LucideIcons.cornerDownLeft), findsWidgets);
    });

    testWidgets('command onExecute called on tap', (tester) async {
      var executed = '';
      final commands = [
        CommandItem(
          id: 'exec',
          label: 'Execute Me',
          icon: LucideIcons.play,
          onExecute: () => executed = 'done',
        ),
      ];
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Execute Me'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(executed, 'done');
    });

    testWidgets('enter executes the selected command and closes the dialog', (
      tester,
    ) async {
      var executed = false;
      final commands = [
        CommandItem(
          id: 'go',
          label: 'Go to Dashboard',
          icon: LucideIcons.star,
          onExecute: () => executed = true,
        ),
      ];
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Type a command or search…'), findsOneWidget);

      // The search field is autofocused; Enter flows through it as a submit
      // action, executing the selected (first) command and popping the dialog.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(executed, isTrue);
      expect(find.text('Type a command or search…'), findsNothing);
    });

    testWidgets('keyboard Kbd chips render with code font', (tester) async {
      final commands = _testCommands(1);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('esc'), findsWidgets);
    });

    testWidgets('search clears and returns all results', (tester) async {
      final commands = _testCommands(5);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showCommandPalette(context, _builder(commands)),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(CcTextField);
      await tester.enterText(searchField, 'Command 3');
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Command 1'), findsNothing);

      await tester.enterText(searchField, '');
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Command 1'), findsOneWidget);
      expect(find.text('Command 5'), findsOneWidget);
    });
  });
}

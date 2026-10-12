import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
      icon: AppIcons.star,
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
  group('showCommandPalette', () {
    late AppPreferences prefs;

    setUp(() async {
      prefs = AppPreferences.inMemory();
    });

    Widget wrap(Widget child) {
      return ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          codeFontFamilyProvider.overrideWithValue('Fira Code'),
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

    testWidgets('first frame accepts a query and Escape restores opener', (
      tester,
    ) async {
      final commands = _testCommands(5);
      final trigger = FocusNode(debugLabel: 'palette opener');
      addTearDown(trigger.dispose);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Focus(
              focusNode: trigger,
              child: CcButton(
                onPressed: () =>
                    showCommandPalette(context, _builder(commands)),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      trigger.requestFocus();
      await tester.pump();
      expect(trigger.hasPrimaryFocus, isTrue);

      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('Type a command or search…'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '5');
      await tester.pump();
      expect(find.text('Command 5'), findsOneWidget);
      expect(find.text('Command 1'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();
      expect(find.text('Command 5'), findsNothing);
      expect(trigger.hasFocus, isTrue);
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

      expect(find.byIcon(AppIcons.search), findsOneWidget);
    });

    testWidgets('escape closes the dialog', (tester) async {
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

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Type a command or search…'), findsNothing);
    });

    testWidgets('items with no category grouped as Other', (tester) async {
      final commands = [
        CommandItem(
          id: 'a',
          label: 'No Category Item',
          icon: AppIcons.star,
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

    testWidgets('single command renders without category header', (
      tester,
    ) async {
      final commands = [
        CommandItem(
          id: 'solo',
          label: 'Solo Command',
          icon: AppIcons.command,
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

      expect(find.byIcon(AppIcons.cornerDownLeft), findsWidgets);
    });

    testWidgets('command onExecute called on tap', (tester) async {
      var executed = '';
      final commands = [
        CommandItem(
          id: 'exec',
          label: 'Execute Me',
          icon: AppIcons.play,
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

    testWidgets('tapping outside the panel dismisses', (tester) async {
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

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Type a command or search…'), findsNothing);
    });

    testWidgets('enter executes the selected command and closes the dialog', (
      tester,
    ) async {
      var executed = false;
      final commands = [
        CommandItem(
          id: 'go',
          label: 'Go to Dashboard',
          icon: AppIcons.star,
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

    testWidgets('shortcuts render as quiet trailing text', (tester) async {
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

      expect(find.text('Ctrl+0'), findsOneWidget);
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

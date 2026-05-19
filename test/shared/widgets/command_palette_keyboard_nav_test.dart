import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression coverage for arrow-key navigation in the command palette.
///
/// The palette used to drive selection from a global `HardwareKeyboard`
/// handler. That broke in the real app because `KeybindingDispatcher`'s macOS
/// ghost-input workaround calls `HardwareKeyboard.clearState()` when a text
/// field focuses — and `clearState()` removes *every* registered handler,
/// including the palette's. Navigation is now driven through the focus tree
/// (Shortcuts/Actions), which `clearState()` does not touch.
///
/// These tests instantiate a live dispatcher (observing focus) so the
/// regression is actually exercised; without it the bug is invisible.

List<CommandItem> Function(BuildContext, WidgetRef) _builder(
  List<CommandItem> commands,
) =>
    (_, _) => commands;

List<CommandItem> _testCommands(int count) {
  return List.generate(
    count,
    (i) => CommandItem(
      id: 'cmd-$i',
      label: 'Command ${i + 1}',
      icon: LucideIcons.star,
      category: 'Tools',
      onExecute: () {},
    ),
  );
}

/// The index of the currently-selected row, read from which cornerDownLeft
/// icon is rendered opaque (selected rows colour it; others are transparent).
int? _selectedRowIndex(WidgetTester tester) {
  final icons = tester
      .widgetList<Icon>(find.byIcon(LucideIcons.cornerDownLeft))
      .toList();
  for (var i = 0; i < icons.length; i++) {
    if (icons[i].color != null && icons[i].color != Colors.transparent) {
      return i;
    }
  }
  return null;
}

void main() {
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

  Future<void> openPalette(
    WidgetTester tester,
    List<CommandItem> commands,
  ) async {
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
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets(
    'arrow keys move selection while the search field is focused',
    (tester) async {
      // A live dispatcher observing focus calls HardwareKeyboard.clearState()
      // when the search field focuses — the condition that broke the old
      // global-handler implementation.
      final dispatcher = KeybindingDispatcher(registerWithOs: false);
      addTearDown(dispatcher.dispose);

      await openPalette(tester, _testCommands(5));

      expect(_selectedRowIndex(tester), 0, reason: 'starts on first row');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(_selectedRowIndex(tester), 1, reason: 'arrow down -> row 1');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(_selectedRowIndex(tester), 2, reason: 'arrow down -> row 2');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(_selectedRowIndex(tester), 1, reason: 'arrow up -> row 1');
    },
  );

  testWidgets('arrow up from the first row wraps to the last', (tester) async {
    final dispatcher = KeybindingDispatcher(registerWithOs: false);
    addTearDown(dispatcher.dispose);

    await openPalette(tester, _testCommands(5));

    expect(_selectedRowIndex(tester), 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(_selectedRowIndex(tester), 4, reason: 'wraps to last row');
  });
}

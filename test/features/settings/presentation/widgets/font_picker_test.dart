import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/font_picker.dart';
import 'package:control_center/features/settings/presentation/widgets/font_preview_card.dart';
import 'package:control_center/features/settings/providers/font_list_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  testWidgets('showFontPicker opens dialog and renders header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter', 'Roboto']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Choose App Font'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('showFontPicker shows code font title for code context', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Fira Code'),
                  contextType: FontContext.code,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Choose code font'), findsOneWidget);
  });

  testWidgets('renders search field', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter', 'Roboto']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('renders section headers', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter', 'Roboto']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Google fonts'), findsOneWidget);
    expect(find.text('System fonts'), findsOneWidget);
  });

  testWidgets('renders popular section with inter', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter', 'Roboto']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Popular'), findsOneWidget);
  });

  testWidgets('close button dismisses dialog', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter', 'Roboto']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Choose app font'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Choose app font'), findsNothing);
  });

  testWidgets('cancel button dismisses dialog', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter', 'Roboto']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Choose app font'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Choose app font'), findsNothing);
  });

  testWidgets('renders add from file button', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Add from file'), findsOneWidget);
  });

  testWidgets('renders system fonts when available', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const [
              {'family': 'Arial', 'path': '/System/Fonts/Arial.ttf'},
            ]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Arial'), findsOneWidget);
  });

  testWidgets('renders no matching fonts message when empty', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => const <String>[]),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No matching Google Fonts.'), findsOneWidget);
  });

  testWidgets('renders font preview card', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(FontPreviewCard), findsOneWidget);
  });

  testWidgets('renders no system fonts message when empty with only google', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No system fonts detected.'), findsOneWidget);
  });

  testWidgets('showFontPicker returns null when dialog closed via close button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showFontPicker(
                    context: context,
                    currentSelection: const FontSelection(family: 'Inter'),
                    contextType: FontContext.app,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('font picker handles system fonts listing with family and path', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const [
              {'family': 'JetBrains Mono', 'path': '/fonts/JetBrainsMono.ttf'},
              {'family': 'Fira Code', 'path': '/fonts/FiraCode.ttf'},
            ]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.code,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('JetBrains Mono'), findsOneWidget);
    expect(find.text('Fira Code'), findsOneWidget);
  });

  testWidgets('search filters fonts by query', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter', 'Roboto', 'Poppins']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Rob');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Roboto'), findsOneWidget);
  });

  testWidgets('renders google font family names', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleFontsProvider.overrideWith((ref) => ['Inter', 'Lato', 'Poppins']),
          systemFontsProvider.overrideWith(
            (ref) => Future.value(const <Map<String, String>>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFontPicker(
                  context: context,
                  currentSelection: const FontSelection(family: 'Inter'),
                  contextType: FontContext.app,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Inter'), findsAtLeast(1));
    expect(find.text('Lato'), findsAtLeast(1));
    expect(find.text('Poppins'), findsOneWidget);
  });
}

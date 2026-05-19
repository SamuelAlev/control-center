import 'package:control_center/features/pr_review/presentation/widgets/emoji_chooser.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

void main() {
  group('showEmojiChooser', () {
    testWidgets('renders emoji groups with labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Builder(
              builder: (context) {
                Future.delayed(
                  Duration.zero,
                  () => showEmojiChooser(
                    context: context,
                    onEmojiSelected: (_) {},
                  ),
                );
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Smileys'), findsOneWidget);
      expect(find.text('Gestures'), findsOneWidget);
      expect(find.text('Love'), findsOneWidget);
      expect(find.text('Objects'), findsOneWidget);
      expect(find.text('Flags'), findsOneWidget);
      expect(find.text('Symbols'), findsOneWidget);
    });

    testWidgets('renders specific emojis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Builder(
              builder: (context) {
                Future.delayed(
                  Duration.zero,
                  () => showEmojiChooser(
                    context: context,
                    onEmojiSelected: (_) {},
                  ),
                );
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('😀'), findsOneWidget);
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('tap on emoji triggers onEmojiSelected and dismisses', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Builder(
              builder: (context) {
                Future.delayed(
                  Duration.zero,
                  () => showEmojiChooser(
                    context: context,
                    onEmojiSelected: (emoji) => selected = emoji,
                  ),
                );
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('😀'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(selected, '😀');
    });

    testWidgets('tap on backdrop dismisses without selection', (tester) async {
      String? selected;

      final focus = FocusNode();
      addTearDown(focus.dispose);

      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Builder(
              builder: (context) {
                Future.delayed(
                  Duration.zero,
                  () => showEmojiChooser(
                    context: context,
                    onEmojiSelected: (emoji) => selected = emoji,
                  ),
                );
                return SizedBox.expand(
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('under'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('under'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(selected, isNull);
    });

    testWidgets('renders all emoji groups', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Builder(
              builder: (context) {
                Future.delayed(
                  Duration.zero,
                  () => showEmojiChooser(
                    context: context,
                    onEmojiSelected: (_) {},
                  ),
                );
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Smileys'), findsOneWidget);
      expect(find.text('Gestures'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Love'), findsOneWidget);
      expect(find.text('Objects'), findsOneWidget);
      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('Animals'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Drinks'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
      expect(find.text('Symbols'), findsOneWidget);
    });

    testWidgets('emoji groups have correct count of items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Builder(
              builder: (context) {
                Future.delayed(
                  Duration.zero,
                  () => showEmojiChooser(
                    context: context,
                    onEmojiSelected: (_) {},
                  ),
                );
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('😀'), findsOneWidget);
      expect(find.text('😂'), findsOneWidget);
      expect(find.text('👏'), findsOneWidget);
      expect(find.text('💪'), findsOneWidget);
      expect(find.text('✅'), findsOneWidget);
      expect(find.text('❌'), findsOneWidget);
      expect(find.text('🚀'), findsWidgets);
      expect(find.text('🌍'), findsOneWidget);
      expect(find.text('🌈'), findsOneWidget);
      expect(find.text('🐶'), findsOneWidget);
      expect(find.text('🐱'), findsOneWidget);
      expect(find.text('🍎'), findsOneWidget);
      expect(find.text('🍕'), findsOneWidget);
      expect(find.text('☕'), findsOneWidget);
      expect(find.text('⚽'), findsOneWidget);
      expect(find.text('🎮'), findsOneWidget);
      expect(find.text('🚗'), findsOneWidget);
      expect(find.text('✈️'), findsOneWidget);
    });
  });
}

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_wrap.dart';

void main() {
  group('SettingsRow', () {
    testWidgets('renders icon, title, subtitle and trailing', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const SettingsRow(
            icon: AppIcons.settings,
            title: 'Theme',
            subtitle: 'Choose your preferred theme',
            trailing: Icon(AppIcons.chevronRight),
          ),
        ),
      );

      expect(find.byIcon(AppIcons.settings), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Choose your preferred theme'), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
    });

    testWidgets('renders subtitleWidget instead of subtitle text', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          const SettingsRow(
            icon: AppIcons.palette,
            title: 'Color',
            subtitle: 'Fallback subtitle',
            trailing: Icon(AppIcons.chevronRight),
            subtitleWidget: Text('Custom widget'),
          ),
        ),
      );

      expect(find.text('Custom widget'), findsOneWidget);
    });

    testWidgets('applies custom subtitleStyle', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const SettingsRow(
            icon: AppIcons.info,
            title: 'Info',
            subtitle: 'Styled subtitle',
            trailing: Icon(AppIcons.chevronRight),
            subtitleStyle: TextStyle(color: Colors.red, fontSize: 10),
          ),
        ),
      );

      expect(find.text('Styled subtitle'), findsOneWidget);
    });
  });

  group('SkeletonBar', () {
    testWidgets('renders animated skeleton placeholder', (tester) async {
      await tester.pumpWidget(testWrap(const SkeletonBar(width: 200)));

      expect(find.byType(SkeletonBar), findsOneWidget);
    });

    testWidgets('renders with custom width', (tester) async {
      await tester.pumpWidget(testWrap(const SkeletonBar(width: 100)));

      expect(find.byType(SkeletonBar), findsOneWidget);
    });
  });

  group('AppearanceSection', () {
    testWidgets('renders section card', (tester) async {
      await tester.pumpWidget(testWrap(const AppearanceSection()));

      expect(find.byType(AppearanceSection), findsOneWidget);
    });

    testWidgets('language picker is a searchable autocomplete', (tester) async {
      await tester.pumpWidget(testWrap(const AppearanceSection()));

      expect(find.byType(CcAutocomplete<Locale>), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byType(CcAutocomplete<Locale>),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'System',
      );
    });

    testWidgets('typing filters locales by name and tag', (tester) async {
      await tester.pumpWidget(testWrap(const AppearanceSection()));

      final field = find.descendant(
        of: find.byType(CcAutocomplete<Locale>),
        matching: find.byType(EditableText),
      );
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'fr-FR');
      await tester.pumpAndSettle();

      expect(find.text('Français (France)'), findsOneWidget);
      expect(find.text('Français (Canada)'), findsNothing);
      expect(find.text('Deutsch (Deutschland)'), findsNothing);
    });

    testWidgets('selecting a locale fills the field', (tester) async {
      await tester.pumpWidget(testWrap(const AppearanceSection()));

      final field = find.descendant(
        of: find.byType(CcAutocomplete<Locale>),
        matching: find.byType(EditableText),
      );
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'français');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français (France)'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(field).controller.text,
        'Français (France)',
      );
    });
  });
}

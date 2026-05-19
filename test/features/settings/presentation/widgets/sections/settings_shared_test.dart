import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('SettingsRow', () {
    testWidgets('renders icon, title, subtitle, and trailing', (tester) async {
      await tester.pumpWidget(testWrap(
        const SettingsRow(
          icon: LucideIcons.settings,
          title: 'Theme',
          subtitle: 'Choose your preferred theme',
          trailing: Icon(LucideIcons.chevronRight),
        ),
      ));

      expect(find.byIcon(LucideIcons.settings), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Choose your preferred theme'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('renders subtitleWidget instead of subtitle text', (tester) async {
      await tester.pumpWidget(testWrap(
        const SettingsRow(
          icon: LucideIcons.palette,
          title: 'Color',
          subtitle: 'Fallback subtitle',
          trailing: Icon(LucideIcons.chevronRight),
          subtitleWidget: Text('Custom widget'),
        ),
      ));

      expect(find.text('Custom widget'), findsOneWidget);
    });

    testWidgets('applies custom subtitleStyle', (tester) async {
      await tester.pumpWidget(testWrap(
        const SettingsRow(
          icon: LucideIcons.info,
          title: 'Info',
          subtitle: 'Styled subtitle',
          trailing: Icon(LucideIcons.chevronRight),
          subtitleStyle: TextStyle(color: Colors.red, fontSize: 10),
        ),
      ));

      expect(find.text('Styled subtitle'), findsOneWidget);
    });
  });

  group('SkeletonBar', () {
    testWidgets('renders animated skeleton placeholder', (tester) async {
      await tester.pumpWidget(testWrap(
        const SkeletonBar(width: 200),
      ));

      expect(find.byType(SkeletonBar), findsOneWidget);
    });

    testWidgets('renders with custom width', (tester) async {
      await tester.pumpWidget(testWrap(
        const SkeletonBar(width: 100),
      ));

      expect(find.byType(SkeletonBar), findsOneWidget);
    });
  });

  group('AppearanceSection', () {
    testWidgets('renders section card', (tester) async {
      await tester.pumpWidget(testWrap(
        const AppearanceSection(),
      ));

      expect(find.byType(AppearanceSection), findsOneWidget);
    });
  });
}

import 'package:control_center/features/settings/presentation/widgets/skill_assignment_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

Widget _wrap(Widget child) {
  return FTheme(
    data: FThemes.zinc.light.desktop,
    child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
  );
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('SkillAssignmentSection', () {
    testWidgets('renders empty skills message when no skills available', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap(
          SkillAssignmentSection(
            selectedSkills: const {},
            availableSkills: const [],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('No skills available'), findsOneWidget);
    });

    testWidgets('renders available skills as chips', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap(
          SkillAssignmentSection(
            selectedSkills: const {},
            availableSkills: const ['code-review', 'testing'],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('testing'), findsOneWidget);
    });

    testWidgets('renders selected skills as selected chips', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap(
          SkillAssignmentSection(
            selectedSkills: const {'code-review'},
            availableSkills: const ['code-review', 'testing'],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('testing'), findsOneWidget);
    });

    testWidgets('calls onChanged when chip is selected', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Set<String>? received;
      await tester.pumpWidget(
        _wrap(
          SkillAssignmentSection(
            selectedSkills: const {},
            availableSkills: const ['code-review'],
            onChanged: (skills) => received = skills,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(received, isNotNull);
      expect(received, contains('code-review'));
    });

    testWidgets('calls onChanged when chip is deselected', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Set<String>? received;
      await tester.pumpWidget(
        _wrap(
          SkillAssignmentSection(
            selectedSkills: const {'code-review'},
            availableSkills: const ['code-review'],
            onChanged: (skills) => received = skills,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(received, isNotNull);
      expect(received, isEmpty);
    });

    testWidgets('renders many skills in wrap layout', (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final skills = List.generate(10, (i) => 'skill-$i');

      await tester.pumpWidget(
        _wrap(
          SkillAssignmentSection(
            selectedSkills: const {},
            availableSkills: skills,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      for (var i = 0; i < 10; i++) {
        expect(find.text('skill-$i'), findsOneWidget);
      }
    });
  });
}

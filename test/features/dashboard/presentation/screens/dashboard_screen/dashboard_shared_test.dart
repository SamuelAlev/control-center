import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('DashboardEyebrow', () {
    testWidgets('renders text in uppercase', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardEyebrow('priority reviews'),
      ));

      expect(find.text('PRIORITY REVIEWS'), findsOneWidget);
    });

    testWidgets('already uppercase remains uppercase', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardEyebrow('ACTIVE'),
      ));

      expect(find.text('ACTIVE'), findsOneWidget);
    });
  });

  group('DashboardPanel', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardPanel(child: Text('Panel content')),
      ));

      expect(find.text('Panel content'), findsOneWidget);
    });

    testWidgets('renders with bordered decoration', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardPanel(child: SizedBox(height: 40)),
      ));

      final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decorated.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });
  });

  group('DashboardPill', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(testWrap(
        DashboardPill(
          background: Colors.green.withValues(alpha: 0.2),
          child: const Text('Open'),
        ),
      ));

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('renders border when provided', (tester) async {
      await tester.pumpWidget(testWrap(
        DashboardPill(
          background: Colors.grey.withValues(alpha: 0.2),
          border: Colors.grey,
          child: const Text('Draft'),
        ),
      ));

      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('renders without border when not provided', (tester) async {
      await tester.pumpWidget(testWrap(
        DashboardPill(
          background: Colors.purple.withValues(alpha: 0.2),
          child: const Text('Merged'),
        ),
      ));

      expect(find.text('Merged'), findsOneWidget);
    });

    testWidgets('uses custom padding', (tester) async {
      await tester.pumpWidget(testWrap(
        DashboardPill(
          background: Colors.blue.withValues(alpha: 0.2),
          padding: const EdgeInsets.all(16),
          child: const Text('Custom'),
        ),
      ));

      expect(find.text('Custom'), findsOneWidget);
    });
  });

  group('DashboardButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardButton(
          label: 'New ticket',
          style: DashButtonStyle.dark,
        ),
      ));

      expect(find.text('New ticket'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(testWrap(
        DashboardButton(
          label: 'Click me',
          style: DashButtonStyle.dark,
          onTap: () => pressed = true,
        ),
      ));

      await tester.tap(find.text('Click me'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('dark style renders', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardButton(
          label: 'Primary',
          style: DashButtonStyle.dark,
        ),
      ));

      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets('line style renders', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardButton(
          label: 'Secondary',
          style: DashButtonStyle.line,
        ),
      ));

      expect(find.text('Secondary'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardButton(
          label: 'With icon',
          style: DashButtonStyle.dark,
          icon: LucideIcons.plus,
        ),
      ));

      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(find.text('With icon'), findsOneWidget);
    });
  });

  group('DashboardPanelHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardPanelHeader(title: 'Active Processes'),
      ));

      expect(find.text('Active Processes'), findsOneWidget);
    });

    testWidgets('renders count when provided', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardPanelHeader(title: 'Processes', count: '5'),
      ));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardPanelHeader(
          title: 'With trailing',
          trailing: Icon(LucideIcons.settings),
        ),
      ));

      expect(find.byIcon(LucideIcons.settings), findsOneWidget);
    });

    testWidgets('renders title adornment when provided', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardPanelHeader(
          title: 'Header',
          titleAdornment: Icon(LucideIcons.helpCircle, size: 14),
        ),
      ));

      expect(find.byIcon(LucideIcons.helpCircle), findsOneWidget);
    });
  });

  group('DashboardSectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardSectionHeader(title: 'Open Pull Requests'),
      ));

      expect(find.text('Open Pull Requests'), findsOneWidget);
    });

    testWidgets('renders count', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardSectionHeader(title: 'PRs', count: '12'),
      ));

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders trailing', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardSectionHeader(
          title: 'PRs',
          trailing: Text('View all'),
        ),
      ));

      expect(find.text('View all'), findsOneWidget);
    });
  });

  group('DashboardLinkArrow', () {
    testWidgets('renders label with arrow', (tester) async {
      await tester.pumpWidget(testWrap(
        const DashboardLinkArrow(label: 'View all'),
      ));

      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('calls onTap when provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testWrap(
        DashboardLinkArrow(label: 'Click', onTap: () => tapped = true),
      ));

      await tester.tap(find.text('Click'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}

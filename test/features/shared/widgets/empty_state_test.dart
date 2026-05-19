import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders message with default icon', (tester) async {
      await tester.pumpWidget(testWrap(
        const EmptyState(message: 'Nothing here yet'),
      ));

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.byIcon(LucideIcons.folderOpen), findsOneWidget);
    });

    testWidgets('renders with custom icon', (tester) async {
      await tester.pumpWidget(testWrap(
        const EmptyState(
          message: 'No tickets',
          icon: LucideIcons.ticket,
        ),
      ));

      expect(find.text('No tickets'), findsOneWidget);
      expect(find.byIcon(LucideIcons.ticket), findsOneWidget);
    });

    testWidgets('renders with description', (tester) async {
      await tester.pumpWidget(testWrap(
        const EmptyState(
          message: 'No facts',
          description: 'Facts appear here as your agents learn.',
        ),
      ));

      expect(find.text('No facts'), findsOneWidget);
      expect(find.text('Facts appear here as your agents learn.'), findsOneWidget);
    });

    testWidgets('renders with action button', (tester) async {
      var pressed = false;
      await tester.pumpWidget(testWrap(
        EmptyState(
          message: 'No data',
          primaryAction: () => pressed = true,
          actionLabel: 'Add data',
        ),
      ));

      expect(find.text('Add data'), findsOneWidget);
      await tester.tap(find.text('Add data'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(pressed, isTrue);
    });

    testWidgets('renders with query text', (tester) async {
      await tester.pumpWidget(testWrap(
        const EmptyState(
          message: 'No results',
          query: 'search term',
        ),
      ));

      expect(find.text('No results'), findsOneWidget);
      expect(find.text('"search term"'), findsOneWidget);
    });

    testWidgets('renders with custom icon size', (tester) async {
      await tester.pumpWidget(testWrap(
        const EmptyState(
          message: 'Empty',
          iconSize: 64,
        ),
      ));

      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('renders with all optional fields', (tester) async {
      await tester.pumpWidget(testWrap(
        EmptyState(
          message: 'No agents',
          icon: LucideIcons.bot,
          iconSize: 72,
          description: 'Create your first agent to get started.',
          query: 'my-agent',
          primaryAction: () {},
          actionLabel: 'Create Agent',
        ),
      ));

      expect(find.text('No agents'), findsOneWidget);
      expect(find.text('Create your first agent to get started.'), findsOneWidget);
      expect(find.text('"my-agent"'), findsOneWidget);
      expect(find.text('Create Agent'), findsOneWidget);
      expect(find.byIcon(LucideIcons.bot), findsOneWidget);
    });

    testWidgets('renders with empty description omitted', (tester) async {
      await tester.pumpWidget(testWrap(
        const EmptyState(
          message: 'Empty',
          description: '',
        ),
      ));

      // Only the main message should appear, not an empty description line
      expect(find.text('Empty'), findsOneWidget);
    });
  });
}

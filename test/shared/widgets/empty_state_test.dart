import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    home: CcTheme(
        data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('EmptyState', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(message: 'No items found'),
      ));

      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders default icon', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(message: 'Empty'),
      ));

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders custom icon', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          message: 'No results',
          icon: Icons.search_off,
          iconSize: 64,
        ),
      ));

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('renders query when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          message: 'No results found',
          query: 'search term',
        ),
      ));

      expect(find.text('"search term"'), findsOneWidget);
    });

    testWidgets('does not render query when empty', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          message: 'Empty',
          query: '',
        ),
      ));

      expect(find.text('""'), findsNothing);
    });

    testWidgets('renders action button text when action provided', (tester) async {
      await tester.pumpWidget(_wrap(
        EmptyState(
          message: 'No data',
          primaryAction: () {},
          actionLabel: 'Refresh',
        ),
      ));

      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('does not render action when missing', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(message: 'Empty'),
      ));

      expect(find.byType(CcButton), findsNothing);
    });

    testWidgets('has Center widget', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(message: 'Centered'),
      ));

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('has Column widget', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(message: 'Column'),
      ));

      expect(find.byType(Column), findsWidgets);
    });
  });
}

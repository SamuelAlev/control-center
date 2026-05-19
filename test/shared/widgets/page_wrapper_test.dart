import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scaffold(Widget body) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: body),
    ),
  ),
);

void main() {
  testWidgets('renders title and child', (tester) async {
    await tester.pumpWidget(
      _scaffold(
        const PageWrapper(
          title: 'Test Page',
          child: Center(child: Text('Content')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Test Page'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('renders subtitle when provided', (tester) async {
    await tester.pumpWidget(
      _scaffold(
        const PageWrapper(
          title: 'Title',
          subtitle: 'A descriptive subtitle.',
          child: Text('Body'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('A descriptive subtitle.'), findsOneWidget);
  });

  testWidgets('does not render subtitle when null', (tester) async {
    await tester.pumpWidget(
      _scaffold(
        const PageWrapper(title: 'No Subtitle', child: Text('Body')),
      ),
    );
    await tester.pump();
    expect(find.text('A descriptive subtitle.'), findsNothing);
  });

  testWidgets('renders actions when provided', (tester) async {
    await tester.pumpWidget(
      _scaffold(
        PageWrapper(
          title: 'With Actions',
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add',
              onPressed: () {},
            ),
          ],
          child: const Text('Body'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byTooltip('Add'), findsOneWidget);
  });

  testWidgets('renders overline widget when provided', (tester) async {
    await tester.pumpWidget(
      _scaffold(
        const PageWrapper(
          title: 'Overline Test',
          overline: Text('STATUS: ACTIVE'),
          child: Text('Body'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('STATUS: ACTIVE'), findsOneWidget);
  });

  testWidgets('renders titleWidget in the header alongside actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _scaffold(
        PageWrapper(
          titleWidget: const Text('Inline editable title'),
          breadcrumbActions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () {},
            ),
          ],
          child: const Text('Body'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Inline editable title'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsOneWidget);
  });

  testWidgets('renders child content in expanded area', (tester) async {
    await tester.pumpWidget(
      _scaffold(
        const PageWrapper(
          title: 'Child Test',
          child: Center(child: Text('Hello World')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Hello World'), findsOneWidget);
  });
}

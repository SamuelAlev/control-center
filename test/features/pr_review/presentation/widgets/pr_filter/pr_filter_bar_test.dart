import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_bar.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _emptyPopulation = Provider.autoDispose<List<PullRequest>>(
  (_) => const [],
);

final _scope = PrFilterScope(
  filters: prListFiltersProvider,
  population: _emptyPopulation,
);

(ProviderContainer, Widget) _harness() {
  final container = ProviderContainer(
    overrides: [currentUserLoginProvider.overrideWith((ref) => 'me')],
  );
  addTearDown(container.dispose);
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: PrFilterBar(scope: _scope)),
      ),
    ),
  );
  return (container, widget);
}

void main() {
  testWidgets('renders nothing while no filter is active', (tester) async {
    final (_, widget) = _harness();
    await tester.pumpWidget(widget);
    expect(find.text('Author'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(tester.getSize(find.byType(PrFilterBar)), Size.zero);
  });

  testWidgets('shows an "Author is Current user" chip for the own login', (
    tester,
  ) async {
    final (container, widget) = _harness();
    container.read(prListFiltersProvider.notifier).toggleAuthor('me');
    await tester.pumpWidget(widget);

    expect(find.text('Author'), findsOneWidget);
    expect(find.text('is'), findsOneWidget);
    expect(find.text('Current user'), findsOneWidget);
  });

  testWidgets('joins several values under "is any of"', (tester) async {
    final (container, widget) = _harness();
    container.read(prListFiltersProvider.notifier)
      ..toggleAuthor('me')
      ..toggleAuthor('alice');
    await tester.pumpWidget(widget);

    expect(find.text('is any of'), findsOneWidget);
    // The operator's own login renders as "Current user" and sorts first.
    expect(find.text('Current user, alice'), findsOneWidget);
  });

  testWidgets('the chip ✕ clears only its own category', (tester) async {
    final semantics = tester.ensureSemantics();
    final (container, widget) = _harness();
    container.read(prListFiltersProvider.notifier)
      ..toggleAuthor('me')
      ..setContent('login');
    await tester.pumpWidget(widget);

    expect(find.text('Author'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Clear Author filter'));
    await tester.pumpAndSettle();

    final filters = container.read(prListFiltersProvider);
    expect(filters.authors, isEmpty);
    expect(filters.content, 'login');
    expect(find.text('Author'), findsNothing);
    expect(find.text('Content'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the quick-to-review chip toggles the filter off', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (container, widget) = _harness();
    container.read(prListFiltersProvider.notifier).toggleQuickToReview();
    await tester.pumpWidget(widget);

    expect(find.text('Quick to review'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Clear Quick to review filter'));
    await tester.pumpAndSettle();

    expect(container.read(prListFiltersProvider).quickToReview, isFalse);
    expect(find.text('Quick to review'), findsNothing);
    semantics.dispose();
  });

  testWidgets('date chips render "since" with the window label', (
    tester,
  ) async {
    final (container, widget) = _harness();
    container
        .read(prListFiltersProvider.notifier)
        .setOpenedWithin(PrDateWindow.week);
    await tester.pumpWidget(widget);

    expect(find.text('Opened date'), findsOneWidget);
    expect(find.text('since'), findsOneWidget);
    expect(find.text('1 week ago'), findsOneWidget);
  });
}

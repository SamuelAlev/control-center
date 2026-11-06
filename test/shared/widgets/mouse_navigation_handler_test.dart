import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps an app whose pages are wrapped in one [MouseNavigationHandler], the way
/// the shell wraps every page. Returns the
/// router and the provider container so tests can navigate and read history.
Future<({GoRouter router, ProviderContainer container})> _pump(
  WidgetTester tester,
) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/a',
    routes: [
      ShellRoute(
        builder: (context, state, child) => Consumer(
          builder: (context, ref, _) => MouseNavigationHandler(
            historyController: ref.read(navigationHistoryProvider.notifier),
            child: child,
          ),
        ),
        routes: [
          for (final path in const ['/a', '/b', '/c'])
            GoRoute(
              path: path,
              builder: (context, state) => const SizedBox.shrink(),
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, container: container);
}

void main() {
  testWidgets('a replaced entry is skipped by Back', (tester) async {
    final (:router, :container) = await _pump(tester);
    final history = container.read(navigationHistoryProvider.notifier);

    router.go('/b');
    await tester.pumpAndSettle();
    history.replace('/c');
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/c');

    history.goBack();
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/a');
  });

  testWidgets('replacing twice before it lands navigates once', (tester) async {
    final (:router, :container) = await _pump(tester);
    final history = container.read(navigationHistoryProvider.notifier);

    history
      ..replace('/b')
      ..replace('/b');
    await tester.pumpAndSettle();

    // A flag left up would swallow this navigation from the stack.
    router.go('/c');
    await tester.pumpAndSettle();
    history.goBack();
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/b');
  });

  testWidgets('backOr steps back, or to the parent with nothing behind', (
    tester,
  ) async {
    final (:router, :container) = await _pump(tester);
    final history = container.read(navigationHistoryProvider.notifier);

    history.backOr('/c');
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/c');

    router.go('/b');
    await tester.pumpAndSettle();
    history.backOr('/a');
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/c');
  });

  testWidgets('a query-only navigation joins the back/forward stack', (
    tester,
  ) async {
    final (:router, :container) = await _pump(tester);
    NavigationHistoryState history() =>
        container.read(navigationHistoryProvider);

    expect(history().canGoBack, isFalse);

    // A tab switch is a `?tab=` query change on the SAME route — the stack
    // must see it (it did not when the handler tracked matchedLocation).
    router.go('/a?tab=diff');
    await tester.pumpAndSettle();
    expect(history().canGoBack, isTrue);
    expect(history().canGoForward, isFalse);

    container.read(navigationHistoryProvider.notifier).goBack();
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/a');
    expect(history().canGoForward, isTrue);

    container.read(navigationHistoryProvider.notifier).goForward();
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/a?tab=diff');
    expect(history().canGoBack, isTrue);
    expect(history().canGoForward, isFalse);
  });
}

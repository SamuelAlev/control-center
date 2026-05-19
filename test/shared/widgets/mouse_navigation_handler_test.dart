import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pumps a single-route app whose page is wrapped in a
/// [MouseNavigationHandler], the way the shell wraps every page. Returns the
/// router and the provider container so tests can navigate and read history.
Future<({GoRouter router, ProviderContainer container})> _pump(
  WidgetTester tester,
) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/a',
    routes: [
      GoRoute(
        path: '/a',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => MouseNavigationHandler(
            historyController: ref.read(navigationHistoryProvider.notifier),
            child: const SizedBox.shrink(),
          ),
        ),
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

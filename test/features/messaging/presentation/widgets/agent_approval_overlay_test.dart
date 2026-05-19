import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/agent_approval_overlay.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ConfirmationRequestDto _req(int i, {String detail = 'Short detail'}) =>
    ConfirmationRequestDto(
      id: 'req-$i',
      spaceId: 'space-1',
      title: 'Request $i',
      detail: detail,
      severity: 'warning',
      command: 'rm -rf /tmp/$i',
      createdAt: '2026-01-0${i + 1}T00:00:00Z',
    );

Future<void> _pumpOverlay(
  WidgetTester tester,
  List<ConfirmationRequestDto> pending,
) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pendingConfirmationsProvider.overrideWith(
          (ref) => Stream.value(pending),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CcTheme(
            data: CcThemeData.light(),
            child: const Stack(children: [AgentApprovalOverlay()]),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _deckLayers() => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('approvalDeckLayer'),
);

void main() {
  testWidgets('nothing pending renders nothing', (tester) async {
    await _pumpOverlay(tester, const []);
    expect(find.text('Approve'), findsNothing);
    expect(_deckLayers(), findsNothing);
  });

  testWidgets('a single request is one card with no deck behind it', (
    tester,
  ) async {
    await _pumpOverlay(tester, [_req(0)]);
    expect(find.text('Request 0'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(_deckLayers(), findsNothing);
    // No counter: nothing is queued behind.
    expect(find.textContaining('more waiting'), findsNothing);
  });

  testWidgets('the oldest request is answerable and the rest stack behind', (
    tester,
  ) async {
    await _pumpOverlay(tester, [_req(0), _req(1), _req(2)]);

    // FIFO: the front card is the oldest, and only it is answerable.
    expect(find.text('Request 0'), findsOneWidget);
    expect(find.text('Request 1'), findsNothing);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Deny'), findsOneWidget);

    // Two queued behind → two peeked layers, and the count says so.
    expect(_deckLayers(), findsNWidgets(2));
    expect(find.text('2 more waiting'), findsOneWidget);
  });

  testWidgets('the deck stops at three peeks however long the queue gets', (
    tester,
  ) async {
    await _pumpOverlay(tester, [for (var i = 0; i < 9; i++) _req(i)]);

    expect(_deckLayers(), findsNWidgets(3));
    expect(find.text('Approve'), findsOneWidget);
    // The cap hides the depth, so the counter carries it.
    expect(find.text('8 more waiting'), findsOneWidget);
  });

  testWidgets('deck layers rise above and inset behind the front card', (
    tester,
  ) async {
    await _pumpOverlay(tester, [for (var i = 0; i < 5; i++) _req(i)]);

    final card = tester.getRect(find.text('Request 0'));
    final layers = tester
        .widgetList(_deckLayers())
        .map((w) => tester.getRect(find.byKey(w.key!)))
        .toList();

    for (final layer in layers) {
      // Each peeks above the front card and is narrower than it.
      expect(layer.top, lessThan(card.top));
      expect(layer.left, greaterThan(0));
    }
    // Deeper layers rise further: the deck reads as a stack, not one card.
    final tops = layers.map((r) => r.top).toList()..sort();
    expect(tops.first, lessThan(tops.last));
  });

  testWidgets('a very long request keeps its decision buttons on screen', (
    tester,
  ) async {
    await _pumpOverlay(tester, [
      _req(0, detail: List.filled(400, 'a long explanation').join(' ')),
      _req(1),
    ]);

    // No overflow, and the actions did not get pushed off the card: the body
    // scrolls inside the card instead of the whole overlay scrolling.
    expect(tester.takeException(), isNull);
    final approve = tester.getRect(find.text('Approve'));
    expect(approve.bottom, lessThanOrEqualTo(900));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}

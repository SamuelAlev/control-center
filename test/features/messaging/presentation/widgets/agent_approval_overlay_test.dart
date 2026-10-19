import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/agent_approval_overlay.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/features/messaging/providers/visible_conversation_spaces.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

ConfirmationRequestDto _req(
  int i, {
  String detail = 'Short detail',
  String spaceId = 'space-1',
  String? conversationId,
  String? command,
}) => ConfirmationRequestDto(
  id: 'req-$i',
  spaceId: spaceId,
  conversationId: conversationId,
  title: 'Request $i',
  detail: detail,
  severity: 'warning',
  command: command ?? 'rm -rf /tmp/$i',
  createdAt: '2026-01-0${i + 1}T00:00:00Z',
);

class _PinnedVisibleSpaces extends VisibleConversationSpaces {
  _PinnedVisibleSpaces(this.ids);
  final Set<String> ids;

  @override
  Set<String> build() => ids;
}

class _PinnedVisibleConversations extends VisibleConversations {
  _PinnedVisibleConversations(this.ids);
  final Set<String> ids;

  @override
  Set<String> build() => ids;
}

Future<void> _pumpOverlay(
  WidgetTester tester,
  List<ConfirmationRequestDto> pending, {
  Set<String> visibleSpaces = const {},
  Set<String> visibleConversations = const {},
}) async {
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
        visibleConversationSpacesProvider.overrideWith(
          () => _PinnedVisibleSpaces(visibleSpaces),
        ),
        visibleConversationsProvider.overrideWith(
          () => _PinnedVisibleConversations(visibleConversations),
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

  testWidgets('a very long request keeps its decision buttons on screen', (
    tester,
  ) async {
    final script = List.generate(80, (i) => 'echo "line $i"').join('\n');
    await _pumpOverlay(tester, [
      _req(
        0,
        detail: List.filled(400, 'a long explanation').join(' '),
        command: script,
      ),
      _req(1),
    ]);

    final approve = find.text('Approve');
    final actionRect = tester.getRect(approve);
    expect(approve.hitTestable(), findsOneWidget);
    expect(actionRect.bottom, lessThanOrEqualTo(900));
    final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    final position = tester.state<ScrollableState>(vertical).position;
    await tester.drag(vertical, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    expect(tester.getRect(approve), actionRect);
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    final source = tester.getRect(find.text(script, findRichText: true));
    final viewport = tester.getRect(vertical);
    expect(source.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(source.bottom, greaterThan(viewport.top));
    expect(approve.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a request for a conversation already on screen stays out of the overlay',
    (tester) async {
      await _pumpOverlay(
        tester,
        [_req(0, spaceId: 'space-open'), _req(1, spaceId: 'space-other')],
        visibleSpaces: {'space-open'},
      );

      expect(find.text('Request 0'), findsNothing);
      expect(find.text('Request 1'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
    },
  );

  testWidgets(
    'a conversation request floats while only a sibling tab is on screen',
    (tester) async {
      await _pumpOverlay(
        tester,
        [
          _req(0, spaceId: 'space-open', conversationId: 'conv-hidden'),
          _req(1, spaceId: 'space-open', conversationId: 'conv-shown'),
        ],
        visibleSpaces: {'space-open'},
        visibleConversations: {'conv-shown'},
      );

      expect(find.text('Request 0'), findsOneWidget);
      expect(find.text('Request 1'), findsNothing);
    },
  );
}

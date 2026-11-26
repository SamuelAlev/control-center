import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/agent_approval_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/agent_approval_overlay.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/features/messaging/providers/visible_conversation_spaces.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
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
        localizationsDelegates: appLocalizationsDelegates,
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

  testWidgets('the card offers the way to its conversation', (tester) async {
    await _pumpOverlay(tester, [_req(0, conversationId: 'conv-1')]);
    expect(find.text('Open conversation'), findsOneWidget);
  });

  testWidgets('a request that names no space offers no conversation', (
    tester,
  ) async {
    await _pumpOverlay(tester, [_req(0, spaceId: '')]);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Open conversation'), findsNothing);
  });

  testWidgets('a request the server will not remember has one approve', (
    tester,
  ) async {
    await _pumpOverlay(tester, [_req(0)]);
    expect(find.byType(CcSplitButton), findsNothing);
    expect(find.text('Approve for 8 hours'), findsNothing);
  });

  group('a rememberable request', () {
    const request = ConfirmationRequestDto(
      id: 'req-r',
      spaceId: 'space-1',
      title: 'Push',
      detail: 'd',
      severity: 'warning',
      createdAt: '2026-01-01T00:00:00Z',
      rememberScope: 'space',
      actionClasses: ['git_push'],
    );

    Future<List<String>> pumpCard(WidgetTester tester) async {
      final calls = <String>[];
      var leads = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CcTheme(
              data: CcThemeData.light(),
              child: StatefulBuilder(
                builder: (context, setState) => ApprovalCard(
                  request: request,
                  busy: false,
                  onApprove: () => calls.add('once'),
                  onApproveAndRemember: () => calls.add('remember'),
                  onDeny: () => calls.add('deny'),
                  rememberLeads: leads,
                  onRememberLeadsChanged: (v) => setState(() => leads = v),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return calls;
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('More actions'));
      await tester.pumpAndSettle();
    }

    testWidgets('leads with the one-time approve, the other behind the caret', (
      tester,
    ) async {
      final calls = await pumpCard(tester);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Approve for 8 hours'), findsNothing);

      await tester.tap(find.text('Approve'));
      expect(calls, ['once']);
    });

    testWidgets('the choice taken from the caret leads from then on', (
      tester,
    ) async {
      final calls = await pumpCard(tester);

      await openMenu(tester);
      await tester.tap(find.text('Approve for 8 hours'));
      await tester.pumpAndSettle();
      expect(calls, ['remember']);

      // Traded places: the standing approval is the button now.
      expect(find.text('Approve for 8 hours'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      await tester.tap(find.text('Approve for 8 hours'));
      expect(calls, ['remember', 'remember']);

      // And the one-time approve is what the caret holds, and switches back.
      await openMenu(tester);
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(calls, ['remember', 'remember', 'once']);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Approve for 8 hours'), findsNothing);
    });
  });

  test('which approve leads is kept on the device', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(approvalPrefersRememberProvider), isFalse);
    container
        .read(approvalPrefersRememberProvider.notifier)
        .set(remember: true);
    expect(
      container
          .read(appPreferencesProvider)
          .getBool(approvalPrefersRememberKey),
      isTrue,
    );
    container.invalidate(approvalPrefersRememberProvider);
    expect(container.read(approvalPrefersRememberProvider), isTrue);
  });

  test(
    'the conversation route follows the request, not the viewed workspace',
    () {
      ConfirmationRequestDto req({
        String? workspaceId,
        String? conversationId,
      }) => ConfirmationRequestDto(
        id: 'r',
        spaceId: 'space-1',
        conversationId: conversationId,
        workspaceId: workspaceId,
        title: 't',
        detail: 'd',
        severity: 'warning',
        createdAt: '2026-01-01T00:00:00Z',
      );

      expect(
        confirmationConversationRoute(
          req(workspaceId: 'ws-own', conversationId: 'conv-1'),
          activeWorkspaceId: 'ws-viewed',
        ),
        '/workspaces/ws-own/spaces/space-1?tab=chat%3Aconv-1',
      );
      expect(
        confirmationConversationRoute(req(), activeWorkspaceId: 'ws-viewed'),
        '/workspaces/ws-viewed/spaces/space-1',
      );
      expect(
        confirmationConversationRoute(req(), activeWorkspaceId: null),
        null,
      );
    },
  );

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

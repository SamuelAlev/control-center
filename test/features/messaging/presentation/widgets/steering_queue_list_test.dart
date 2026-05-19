import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/steering_queue_list.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/steering_queue_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart'
    show ActiveWorkspaceIdNotifier, activeWorkspaceIdProvider;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _kWorkspaceId = 'ws-1';
const String _kSpaceId = 'space-1';
const String _kConversationId = 'conv-1';
const _kRef = (spaceId: _kSpaceId, conversationId: _kConversationId);

/// Captures the steering port calls the strip makes; everything else on the
/// port is unreachable in these tests.
class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

/// Captures the steering port calls the strip makes; everything else on the
/// port is unreachable in these tests.
class _SteeringPort implements MessagingPort {
  final edits = <(String, String)>[];
  final deletes = <String>[];
  final reorders = <List<String>>[];
  final delivers = <String>[];
  bool deliverResult = true;

  @override
  Future<bool> editSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
    required String content,
  }) async {
    edits.add((messageId, content));
    return true;
  }

  @override
  Future<bool> deleteSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) async {
    deletes.add(messageId);
    return true;
  }

  @override
  Future<void> reorderSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required List<String> orderedIds,
  }) async {
    reorders.add(orderedIds);
  }

  @override
  Future<bool> deliverSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) async => deliverResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Message _queued(String id, String content, {int order = 0}) => Message(
  id: id,
  spaceId: _kSpaceId,
  conversationId: _kConversationId,
  senderId: 'user-1',
  senderType: SenderType.user,
  content: content,
  messageType: MessageType.steering,
  metadata: {'steerState': 'queued', 'steerOrder': order},
  createdAt: DateTime.utc(2026, 8, 29, 12, 0, id.hashCode % 60),
);

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: CcTheme(data: CcThemeData.light(), child: child),
  ),
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required List<Message> windowMessages,
  _SteeringPort? port,
}) async {
  final container = ProviderContainer(
    overrides: [
      activeWorkspaceIdProvider.overrideWith(
        () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
      ),
      spaceFeedWindowedProvider(_kRef).overrideWith(
        (ref) => Stream.value((messages: windowMessages, hasMore: false)),
      ),
      if (port != null) messagingServiceProvider.overrideWith((ref) => port),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _host(
        const SteeringQueueList(
          spaceId: _kSpaceId,
          conversationId: _kConversationId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('steeringQueueProvider keeps only queued rows, in steerOrder', () async {
    final container = ProviderContainer(
      overrides: [
        spaceFeedWindowedProvider(_kRef).overrideWith(
          (ref) => Stream.value((
            messages: [
              _queued('a', 'first typed', order: 2),
              Message(
                id: 'plain',
                spaceId: _kSpaceId,
                conversationId: _kConversationId,
                senderId: 'user-1',
                senderType: SenderType.user,
                content: 'a normal message',
                messageType: MessageType.text,
                createdAt: DateTime.utc(2026, 8, 29),
              ),
              _queued('b', 'second typed', order: 1),
              Message(
                id: 'injected',
                spaceId: _kSpaceId,
                conversationId: _kConversationId,
                senderId: 'user-1',
                senderType: SenderType.user,
                content: 'already steered in',
                messageType: MessageType.steering,
                metadata: const {'steerState': 'injected', 'steerOrder': 0},
                createdAt: DateTime.utc(2026, 8, 29),
              ),
            ],
            hasMore: false,
          )),
        ),
      ],
    );
    addTearDown(container.dispose);
    // A listener, not a read: these are autoDispose providers, and a one-shot
    // read tears the chain down before the stream value lands.
    final sub = container.listen(steeringQueueProvider(_kRef), (_, _) {});
    addTearDown(sub.close);
    await container.pump();
    final queued = container.read(steeringQueueProvider(_kRef));
    expect(queued.map((m) => m.id), [
      'b',
      'a',
    ], reason: 'queued only, ascending steerOrder regardless of createdAt');
  });

  testWidgets('renders nothing when the queue is empty', (tester) async {
    await _pump(tester, windowMessages: const []);
    expect(find.byType(SteeringQueueList), findsOneWidget);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets('renders one card per queued message', (tester) async {
    await _pump(
      tester,
      windowMessages: [
        _queued('a', 'check the flaky test', order: 0),
        _queued('b', 'and the migration', order: 1),
      ],
    );
    expect(find.text('check the flaky test'), findsOneWidget);
    expect(find.text('and the migration'), findsOneWidget);
  });

  testWidgets('hides the steer button when the server said no run can inject', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      windowMessages: [_queued('a', 'nudge', order: 0)],
    );
    container.read(steeringSteerableProvider(_kRef).notifier).set(false);
    await tester.pumpAndSettle();
    expect(
      find.text('Steer'),
      findsNothing,
      reason: 'an external-CLI transport has no mid-run input lane',
    );
  });

  testWidgets('shows the steer button while steerability is unknown', (
    tester,
  ) async {
    await _pump(tester, windowMessages: [_queued('a', 'nudge', order: 0)]);
    expect(
      find.text('Steer'),
      findsOneWidget,
      reason:
          'a card can outlive the client that typed it (reload, second '
          'device); unknown is not the same as "cannot"',
    );
  });

  testWidgets('shows the steer button once an enqueue stamps steerable', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      windowMessages: [_queued('a', 'nudge', order: 0)],
    );
    container.read(steeringSteerableProvider(_kRef).notifier).set(true);
    await tester.pumpAndSettle();
    expect(find.text('Steer'), findsOneWidget);
  });

  testWidgets('cards carry no bottom border, so the strip melts down', (
    tester,
  ) async {
    await _pump(
      tester,
      windowMessages: [
        _queued('a', 'first', order: 0),
        _queued('b', 'second', order: 1),
      ],
    );
    final borders = [
      for (final text in ['first', 'second'])
        ...tester
            .widgetList<Container>(
              find.ancestor(
                of: find.text(text),
                matching: find.byType(Container),
              ),
            )
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .map((d) => d.border)
            .whereType<Border>(),
    ];
    expect(borders, hasLength(2), reason: 'one outlined box per queued card');
    for (final border in borders) {
      expect(
        border.bottom,
        BorderSide.none,
        reason:
            'the next card\'s top border separates two cards, and the '
            "composer's own top border closes the last one — a bottom "
            'border here would double every hairline',
      );
      expect(border.top, isNot(BorderSide.none));
    }
  });

  testWidgets('delete calls the port for that card', (tester) async {
    final port = _SteeringPort();
    await _pump(
      tester,
      windowMessages: [_queued('a', 'gone soon', order: 0)],
      port: port,
    );
    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pumpAndSettle();
    expect(port.deletes, ['a']);
  });

  testWidgets('edit rewrites the card through the port', (tester) async {
    final port = _SteeringPort();
    await _pump(
      tester,
      windowMessages: [_queued('a', 'old text', order: 0)],
      port: port,
    );
    await tester.tap(find.byIcon(AppIcons.pencil));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CcTextField), 'new text');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(port.edits, [('a', 'new text')]);
  });
}

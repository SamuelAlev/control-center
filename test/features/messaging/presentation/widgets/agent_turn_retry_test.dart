import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/agent_turn.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_items.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

final _agent = Agent(
  id: 'agent-1',
  name: 'Architect',
  title: 'Software Architect',
  agentMdPath: '/path',
  workspaceId: 'ws-1',
  skills: AgentSkills([]),
  createdAt: DateTime(2024),
);

/// A finished turn of `agent-1` as the feed lists it: its transcript elided,
/// so the bubble also reads the full row ([messageDetailProvider]).
Message _turn(
  String id, {
  bool failed = true,
  bool retried = false,
  String senderId = 'agent-1',
}) => Message(
  id: id,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  senderId: senderId,
  senderType: SenderType.agent,
  content: 'It did not work out',
  messageType: MessageType.agentTurn,
  metadata: {
    'streamComplete': true,
    'segments_elided': true,
    if (failed) ...{'error': true, 'errorFamily': 'rate_limit'},
    if (retried) 'retried': true,
  },
  createdAt: DateTime(2024),
);

/// The full row as one read returned it BEFORE the turn was retried.
Message _detailBeforeRetry(String id) => Message(
  id: id,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  senderId: 'agent-1',
  senderType: SenderType.agent,
  content: 'It did not work out',
  messageType: MessageType.agentTurn,
  metadata: const {
    'streamComplete': true,
    'error': true,
    'errorFamily': 'rate_limit',
  },
  createdAt: DateTime(2024),
);

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';
}

/// Records every retry asked of the server.
class _Port implements MessagingPort {
  final List<String> asked = [];

  /// Holds the server's answer back until completed.
  Completer<void>? answer;

  /// What the request fails with, when set.
  Object? failure;

  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String spaceId,
    required String failedMessageId,
    String? modelOverride,
    String? requestedByUserId,
  }) async {
    asked.add('$workspaceId/$spaceId/$failedMessageId');
    await answer?.future;
    final error = failure;
    if (error != null) {
      throw error;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _Port port;

  setUp(() => port = _Port());

  /// Pumps the turn the way the feed hands it over. [row] swaps the listed
  /// row afterwards, as a feed emission does.
  Future<void> pumpTurn(
    WidgetTester tester,
    ValueNotifier<({Message message, bool canRetry})> row, {
    TextDirection? textDirection,
  }) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    addTearDown(row.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentDetailProvider('agent-1').overrideWith((ref) async => _agent),
          activeStreamRegistryProvider.overrideWithValue(
            ActiveStreamRegistry(),
          ),
          activeWorkspaceIdProvider.overrideWith(
            _TestActiveWorkspaceNotifier.new,
          ),
          messagingServiceProvider.overrideWithValue(port),
          // One snapshot per turn, as the RPC read is: it never emits again.
          messageDetailProvider(
            't1',
          ).overrideWith((ref) => Stream.value(_detailBeforeRetry('t1'))),
        ],
        child: testWrap(
          SingleChildScrollView(
            child: ValueListenableBuilder(
              valueListenable: row,
              builder: (context, value, _) => AgentTurn(
                message: value.message,
                codeFont: 'monospace',
                canRetry: value.canRetry,
              ),
            ),
          ),
          textDirection: textDirection,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  final retry = find.widgetWithText(CcButton, 'Retry');

  testWidgets('a failed turn offers Retry only when the feed says so', (
    tester,
  ) async {
    final row = ValueNotifier((message: _turn('t1'), canRetry: true));
    await pumpTurn(tester, row);

    expect(find.text('Run failed · rate_limit'), findsOneWidget);
    expect(retry, findsOneWidget);

    // The agent moved on: the failure is history, with nothing to press.
    row.value = (message: _turn('t1'), canRetry: false);
    await tester.pump();

    expect(find.text('Run failed · rate_limit'), findsOneWidget);
    expect(retry, findsNothing);
  });

  testWidgets('the listed row decides, not a full row read before the retry', (
    tester,
  ) async {
    final row = ValueNotifier((message: _turn('t1'), canRetry: true));
    await pumpTurn(tester, row);
    expect(retry, findsOneWidget);

    // The server marked the turn retried. Only the feed's row hears of it;
    // the full row the bubble also reads is a snapshot from before, and it
    // used to be the one the action looked at, so Retry never went away.
    row.value = (message: _turn('t1', retried: true), canRetry: false);
    await tester.pump();

    expect(retry, findsNothing);
    expect(find.text('Run failed · rate_limit'), findsNothing);
    expect(find.text('Retried'), findsOneWidget);
  });

  testWidgets('one press asks once, and stays busy until the answer', (
    tester,
  ) async {
    port.answer = Completer<void>();
    final row = ValueNotifier((message: _turn('t1'), canRetry: true));
    await pumpTurn(tester, row);

    await tester.tap(retry);
    await tester.pump();
    expect(port.asked, ['ws-1/space-1/t1']);
    expect(tester.widget<CcButton>(retry).loading, isTrue);

    // Pressing a busy action asks for nothing more.
    await tester.tap(retry, warnIfMissed: false);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(port.asked, hasLength(1));

    port.answer!.complete();
    await tester.pump();
    await tester.pump();
    expect(tester.widget<CcButton>(retry).loading, isFalse);
  });

  testWidgets('a retry that could not be asked says so and can be pressed '
      'again', (tester) async {
    port.failure = StateError('server unreachable');
    final row = ValueNotifier((message: _turn('t1'), canRetry: true));
    await pumpTurn(tester, row);

    await tester.tap(retry);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('server unreachable'), findsOneWidget);
    expect(tester.widget<CcButton>(retry).loading, isFalse);

    port.failure = null;
    await tester.tap(retry);
    await tester.pump();
    expect(port.asked, hasLength(2));

    // Let the toast's timer run out before the tree is torn down.
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('lays out right to left', (tester) async {
    final row = ValueNotifier((message: _turn('t1'), canRetry: true));
    await pumpTurn(tester, row, textDirection: TextDirection.rtl);

    expect(retry, findsOneWidget);
    // The label leads and the action follows it, mirrored.
    expect(
      tester.getCenter(retry).dx,
      lessThan(tester.getCenter(find.text('Run failed · rate_limit')).dx),
    );
    expect(tester.takeException(), isNull);
  });

  group('which turn the feed offers Retry on', () {
    List<MessageItem> rows(List<Message> messages) => buildFeedItems(
      messages,
      suppressOldestSeparator: true,
    ).whereType<MessageItem>().toList();

    test("only the agent's newest turn, when it failed", () {
      final items = rows([
        _turn('first-failure'),
        _turn('second-failure'),
        _turn('other-agent', senderId: 'agent-2', failed: false),
      ]);

      expect(
        {for (final item in items) item.message.id: item.canRetry},
        {'first-failure': false, 'second-failure': true, 'other-agent': false},
      );
    });

    test('none while a newer turn of the agent exists', () {
      final items = rows([_turn('failure'), _turn('newer', failed: false)]);

      expect(items.map((item) => item.canRetry), everyElement(isFalse));
    });

    test('none once the failure was retried', () {
      final items = rows([_turn('failure', retried: true)]);

      expect(items.single.canRetry, isFalse);
    });
  });
}

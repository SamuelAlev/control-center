import 'package:cc_domain/features/dispatch/domain/repositories/conversation_peer_asks_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/peer_asks_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/test_wrap.dart';
import '../widgets/work/work_test_harness.dart';

PeerAskView _ask(
  String id, {
  PeerAskKind kind = PeerAskKind.ask,
  PeerAskStatus status = PeerAskStatus.pending,
  PeerAskMode mode = PeerAskMode.wait,
  String recipient = 'agent-2',
  DateTime? promisedAt,
  DateTime? createdAt,
  String? error,
}) => PeerAskView(
  id: id,
  workspaceId: kTestWorkspaceId,
  kind: kind,
  mode: mode,
  status: status,
  askerAgentId: 'agent-1',
  askerConversationId: 'conv-1',
  recipientAgentId: recipient,
  createdAt: createdAt ?? past,
  expiresAt: future,
  promisedAt: promisedAt,
  error: error,
);

void main() {
  late FakePeerAsksRepository repo;

  setUp(() => repo = FakePeerAsksRepository());

  Future<void> pump(WidgetTester tester, List<PeerAskView> asks) async {
    // A fresh scope per pump: overrides never carry over.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: workOverrides(asks: repo, askList: asks),
          child: const SingleChildScrollView(
            child: PeerAsksSection(
              workspaceId: kTestWorkspaceId,
              conversationId: 'conv-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hidden when the conversation asked nothing', (tester) async {
    await pump(tester, const []);
    expect(find.text('Asks'), findsNothing);
  });

  testWidgets('a pending ask: who, kind, when asked, expiry, cancel', (
    tester,
  ) async {
    await pump(tester, [
      _ask('q1', promisedAt: past, mode: PeerAskMode.background),
    ]);
    expect(find.text('To Ada'), findsOneWidget);
    expect(find.text('Question'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.textContaining('Asked '), findsOneWidget);
    expect(find.textContaining('Expires '), findsOneWidget);
    expect(find.text('Promised an answer'), findsOneWidget);
    expect(find.text('In the background'), findsOneWidget);
    await tester.tap(tip('Cancel ask'));
    await tester.pump();
    expect(repo.calls, ['cancel:$kTestWorkspaceId:q1']);
  });

  testWidgets('settled asks show their status and no cancel; an ask already '
      'settled says so', (tester) async {
    await pump(tester, [
      _ask('a', kind: PeerAskKind.consult, status: PeerAskStatus.answered),
      _ask('b', kind: PeerAskKind.review, status: PeerAskStatus.expired),
      _ask('c', status: PeerAskStatus.failed, recipient: 'gone'),
      _ask('d', status: PeerAskStatus.cancelled, recipient: 'agent-3'),
    ]);
    expect(find.text('Answered'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Consult'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('To an agent'), findsOneWidget);
    expect(tip('Cancel ask'), findsNothing);
    expect(find.textContaining('Expires '), findsNothing);

    repo.cancelResult = false;
    await pump(tester, [_ask('p')]);
    await tester.tap(tip('Cancel ask'));
    await tester.pump();
    expect(find.text('That ask has already settled.'), findsOneWidget);
  });

  testWidgets('a failed ask says why; an unknown failure shows its kind', (
    tester,
  ) async {
    await pump(tester, [
      _ask('f1', status: PeerAskStatus.failed, error: 'usage_limit: person'),
      _ask('f2', status: PeerAskStatus.failed, error: 'novel_failure'),
    ]);
    expect(
      find.text("Its run stopped at the provider's usage limit."),
      findsOneWidget,
    );
    expect(find.text('novel_failure'), findsOneWidget);
  });
}

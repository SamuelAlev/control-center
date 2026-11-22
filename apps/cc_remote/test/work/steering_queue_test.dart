@TestOn('browser')
library;

import 'package:cc_domain/cc_domain.dart' show MessageDto;
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/messaging/steering_queue.dart';
import 'package:flutter_test/flutter_test.dart';

import 'work_test_host.dart';

MessageDto _card(String id, String content, String senderId, int order) =>
    MessageDto(
      id: id,
      content: content,
      senderId: senderId,
      senderType: 'user',
      messageType: 'steering',
      metadata: {'steerState': 'queued', 'steerOrder': order},
      spaceId: 's1',
      conversationId: 'c1',
    );

void main() {
  late AppLocalizations l;
  WorkRpcHost? host;
  // Made inside each test's zone, so its streams run on the test's clock.
  WorkRpcHost rpc() => host ??= WorkRpcHost();

  setUpAll(() async => l = await english());
  setUp(() => host = null);
  tearDown(() => host?.close());

  Future<void> pump(WidgetTester tester, List<MessageDto> cards) => pumpWork(
    tester,
    SteeringQueue(
      scope: (workspaceId: ws, spaceId: 's1', conversationId: 'c1'),
      messages: cards,
      canWrite: true,
    ),
    overrides: workOverrides(rpc()),
  );

  testWidgets('only the writer edits a queued card; the other actions stay '
      'for everyone who may write', (tester) async {
    await pump(tester, [
      _card('m1', 'Mine', 'u1', 1),
      _card('m2', 'Someone else', 'u2', 2),
    ]);
    expect(find.text(l.mobileEditQueued), findsOneWidget);
    expect(find.text(l.mobileSteerNow), findsNWidgets(2));
    expect(find.text(l.mobileRemove), findsNWidgets(2));
  });

  testWidgets('a steer refused for want of write access says so, and the '
      'card stays', (tester) async {
    rpc().refuse = 'repo_grant_required';
    await pump(tester, [_card('m2', 'Someone else', 'u2', 1)]);
    await tapLabel(tester, l.mobileSteerNow);
    expect(rpc().ops, ['steering.deliver']);
    expect(find.text(l.steeringRefusalNeedsWrite), findsOneWidget);
    expect(find.text('Someone else'), findsOneWidget);
  });
}

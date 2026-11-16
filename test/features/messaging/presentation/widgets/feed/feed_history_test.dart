import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_outline_entry.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_placeholder_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/message_feed.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../helpers/active_workspace.dart';

class _FakeSpaceReadRepository implements SpaceReadRepository {
  @override
  Future<void> markSpaceRead(
    String workspaceId,
    String spaceId,
    String userId, {
    String? conversationId,
  }) async {}

  @override
  Stream<FeedPosition?> watchUserLastReadAt(
    String workspaceId,
    String spaceId,
    String userId,
  ) => Stream.value(null);

  @override
  Stream<Map<String, FeedPosition>> watchUserSpaceReads(
    String workspaceId,
    String userId,
  ) => Stream.value(const {});
}

const int _total = 200;
const int _live = 20;

final _t0 = DateTime(2024, 1, 1, 12);

Message _message(int i) => Message(
  id: 'm$i',
  spaceId: 'ch-1',
  conversationId: 'ch-1',
  senderId: 'agent-1',
  senderType: SenderType.agent,
  content: 'Message $i',
  messageType: MessageType.text,
  createdAt: _t0.add(Duration(minutes: 10 * i)),
);

final _outline = [
  for (var i = 0; i < _total; i++)
    ConversationOutlineEntry(
      id: 'm$i',
      createdAt: _t0.add(Duration(minutes: 10 * i)),
      senderId: 'agent-1',
      senderType: SenderType.agent,
      messageType: MessageType.text,
      contentChars: 'Message $i'.length,
    ),
];

final _feedScrollable = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.up,
);

ScrollPosition _feedPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(_feedScrollable).position;

/// The feed over a [_total]-message conversation whose newest [_live] are the
/// live window. Every history range loads `anchor ± 30` messages, counted in
/// [rangeReads].
Future<ProviderContainer> _pumpFeed(
  WidgetTester tester, {
  required List<String> rangeReads,
  ({String spaceId, String messageId})? permalink,
}) async {
  tester.view.physicalSize = const Size(400, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  const feedRef = (spaceId: 'ch-1', conversationId: 'ch-1');
  final container = ProviderContainer(
    overrides: [
      activeWorkspaceIdOverride(),
      spaceFeedWindowedProvider(feedRef).overrideWith(
        (ref) => Stream.value((
          messages: [for (var i = _total - _live; i < _total; i++) _message(i)],
          hasMore: true,
        )),
      ),
      conversationOutlineProvider(
        feedRef,
      ).overrideWith((ref) async => _outline),
      for (var a = 0; a < _total; a++)
        spaceFeedRangeProvider((
          spaceId: 'ch-1',
          conversationId: 'ch-1',
          anchorId: 'm$a',
        )).overrideWith((ref) {
          rangeReads.add('m$a');
          final from = (a - 30).clamp(0, _total);
          final to = (a + 31).clamp(0, _total);
          return Stream.value((
            messages: [for (var i = from; i < to; i++) _message(i)],
            hasOlder: from > 0,
            hasNewer: to < _total,
          ));
        }),
      spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
      codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
      spaceUserLastReadAtProvider(
        'ch-1',
      ).overrideWith((ref) => Stream.value(null)),
      spaceReadRepositoryProvider.overrideWithValue(_FakeSpaceReadRepository()),
      agentDetailProvider('agent-1').overrideWith((ref) async => null),
    ],
  );
  addTearDown(container.dispose);
  if (permalink != null) {
    container.read(pendingFocusMessageProvider.notifier).set(permalink);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CcTheme(
            data: CcThemeData.light(),
            child: const SpaceMessageFeed(
              spaceId: 'ch-1',
              conversationId: 'ch-1',
            ),
          ),
        ),
      ),
    ),
  );
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

bool _onScreen(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) {
    return false;
  }
  final rect = tester.getRect(finder.first);
  return rect.bottom > 0 && rect.top < 600;
}

/// The numbers of the messages drawn on screen.
List<int> _shownMessages(WidgetTester tester) => [
  for (final e in find.byType(RichText).evaluate())
    if (_onScreen(tester, find.byWidget(e.widget)))
      if (RegExp(
            r'^Message (\d+)$',
          ).firstMatch((e.widget as RichText).text.toPlainText())
          case final match?)
        int.parse(match.group(1)!),
];

void main() {
  testWidgets('the scroll extent covers the whole conversation', (
    tester,
  ) async {
    final reads = <String>[];
    await _pumpFeed(tester, rangeReads: reads);
    await _settle(tester);

    // At the live edge, nothing above the live window is loaded.
    expect(_feedPosition(tester).pixels, 0);
    expect(reads, isEmpty);
    // 180 stand-ins sit above the live window: the scrollbar spans them.
    expect(_feedPosition(tester).maxScrollExtent, greaterThan(180 * 50));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('scrolling into history loads the range around the reader', (
    tester,
  ) async {
    final reads = <String>[];
    await _pumpFeed(tester, rangeReads: reads);
    await _settle(tester);

    final position = _feedPosition(tester);
    // A scrollbar drag to the middle of the conversation.
    position.jumpTo(position.maxScrollExtent / 2);
    await tester.pump();
    expect(find.byType(FeedPlaceholderRow), findsWidgets);
    final dragged = position.pixels;

    await _settle(tester);
    expect(reads, hasLength(1));
    final anchor = int.parse(reads.single.substring(1));
    expect(anchor, inExclusiveRange(40, 160));
    // What is on screen now is the loaded range, and the reader stayed where
    // the drag left them (loading swaps stand-ins in place).
    final shown = _shownMessages(tester);
    expect(shown, isNotEmpty);
    expect(shown.every((i) => (i - anchor).abs() <= 30), isTrue);
    expect((position.pixels - dragged).abs(), lessThan(600));
    expect(
      find.byType(FeedPlaceholderRow).evaluate().where((e) {
        final box = e.renderObject! as RenderBox;
        final top = box.localToGlobal(Offset.zero).dy;
        return top + box.size.height > 0 && top < 600;
      }),
      isEmpty,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('a permalink into unloaded history lands on the message', (
    tester,
  ) async {
    final reads = <String>[];
    final container = await _pumpFeed(
      tester,
      rangeReads: reads,
      permalink: (spaceId: 'ch-1', messageId: 'm3'),
    );
    await _settle(tester);

    expect(reads, contains('m3'));
    expect(container.read(pendingFocusMessageProvider), isNull);
    expect(_shownMessages(tester), contains(3));
    // Far from the live edge.
    expect(_feedPosition(tester).pixels, greaterThan(150 * 40));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

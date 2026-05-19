import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/message_feed.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../../../../../helpers/active_workspace.dart';

/// The window a freshly opened conversation ships: [kSpaceFeedInitialWindow].
const int _windowSize = kSpaceFeedInitialWindow;

/// A conversation of [_windowSize] agent turns, each from a DIFFERENT agent.
///
/// The distinct sender is the instrument: an agent row watches
/// `agentDetailProvider(message.senderId)` as it builds, so the set of agent
/// ids the container was ever asked for IS the set of rows that were built —
/// including the ones built off-screen purely to be measured and thrown away,
/// which is exactly what this test is here to bound.
List<Message> _window() => List.generate(
  _windowSize,
  (i) => Message(
    id: 'm$i',
    spaceId: 'ch-1',
    conversationId: 'ch-1',
    senderId: 'agent-$i',
    senderType: SenderType.agent,
    content: 'Turn $i',
    messageType: MessageType.agentTurn,
    // The shape every history row arrives in: the wire elides the transcript
    // and stamps its size, so building one costs a `getMessageById` round trip.
    metadata: const {'segments_elided': true, 'segment_count': 12},
    createdAt: DateTime(2024, 1, 1, 12).add(Duration(minutes: 10 * i)),
  ),
);

/// The package's own budget, restored between tests.
final _defaultLayoutBudget = SuperSliverList.layoutBudget;

/// A layout budget of exactly one measurement per pass.
///
/// SuperSliverList's shipped budget is 3ms of wall clock and it is spent
/// WITHOUT re-consulting the policy, so a pass can overshoot the row budget by
/// however many rows fit in the slice — which on a real feed is one or two
/// (each is a markdown parse and a syntax-highlighted diff) and in a test with
/// stub rows is however fast the machine is. Pinning one row per pass makes the
/// policy the only thing deciding where measurement stops, which is what this
/// test is about.
class _OneRowPerLayoutPass extends SuperSliverListLayoutBudget {
  bool _spent = false;

  @override
  void reset() => _spent = false;

  @override
  void beginLayout() => _spent = false;

  @override
  void endLayout() {}

  @override
  bool shouldLayoutNextItem() {
    if (_spent) {
      return false;
    }
    _spent = true;
    return true;
  }
}

Future<Set<String>> _openFeed(
  WidgetTester tester, {
  required Duration settle,
}) async {
  final built = <String>{};
  tester.view.physicalSize = const Size(400, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeWorkspaceIdOverride(),
        spaceFeedWindowedProvider((
          spaceId: 'ch-1',
          conversationId: 'ch-1',
        )).overrideWith(
          (ref) => Stream.value((messages: _window(), hasMore: false)),
        ),
        spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
        codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
        spaceUserLastReadAtProvider(
          'ch-1',
        ).overrideWith((ref) => Stream.value(null)),
        for (var i = 0; i < _windowSize; i++)
          agentDetailProvider('agent-$i').overrideWith((ref) async {
            built.add('agent-$i');
            return null;
          }),
        // A row that gets as far as fetching its elided transcript would dial
        // the server; the point of the test is that most rows never do.
        for (var i = 0; i < _windowSize; i++)
          messageTranscriptProvider(
            'm$i',
          ).overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
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
  await tester.pumpAndSettle(settle);
  return built;
}

void main() {
  setUp(() {
    SuperSliverList.layoutBudget = _OneRowPerLayoutPass();
  });

  tearDown(() {
    SuperSliverList.layoutBudget = _defaultLayoutBudget;
  });

  testWidgets('opening a long conversation builds only the rows on screen', (
    tester,
  ) async {
    // Well inside the idle delay that arms extent precalculation: this is the
    // navigate-to-the-chat moment the user actually waits through.
    final built = await _openFeed(
      tester,
      settle: const Duration(milliseconds: 50),
    );

    // A 600px-tall viewport plus its cache area holds a handful of turns. The
    // regression this pins is the whole window being built at open — every row
    // a markdown parse, a syntax-highlighted diff and one transcript round
    // trip — to measure heights nobody was scrolled to.
    expect(built, isNotEmpty);
    expect(built.length, lessThan(_windowSize ~/ 2));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('extent precalculation stays bounded once the feed goes idle', (
    tester,
  ) async {
    final built = await _openFeed(tester, settle: const Duration(seconds: 5));

    // Past the idle delay the feed does refine extents — but against a row
    // budget, so a long scrollback is never measured end to end.
    expect(built.length, lessThanOrEqualTo(kFeedPrecalcRowBudget));
    expect(built.length, lessThan(_windowSize));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

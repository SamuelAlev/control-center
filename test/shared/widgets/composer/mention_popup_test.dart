import 'dart:async';

import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_popup.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

MentionQuery _query(String partial) => MentionQuery(
  trigger: MentionTrigger.slash,
  partial: partial,
  start: 0,
  end: partial.length + 1,
);

MentionSuggestion _item(String label) => MentionSuggestion(
  id: 'cmd:$label',
  kind: 'command',
  label: label,
  replacement: '/$label',
);

/// A slash-trigger source whose per-query latency is controlled by [responder].
class _ControlledSource extends MentionSource {
  _ControlledSource({required this.responder});

  /// Maps a partial to the stream of suggestions to deliver.
  final Stream<List<MentionSuggestion>> Function(String partial) responder;

  @override
  String get kind => 'command';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.slash};

  @override
  Stream<List<MentionSuggestion>> suggest(MentionQuery query) =>
      responder(query.partial);
}

/// A second source kind, used to prove per-source commit gating.
class _ControlledAgentSource extends _ControlledSource {
  _ControlledAgentSource({required super.responder});

  @override
  String get kind => 'agent';
}

void main() {
  group('MentionPopup searching UX', () {
    testWidgets('refining the query keeps rows visible and never flashes '
        '"Searching…" for fast sources', (tester) async {
      // Mirrors ChannelInputBar: the source list is a fresh literal on every
      // rebuild, so identity changes on every keystroke.
      List<MentionSource> sources() => [
        _ControlledSource(
          responder: (partial) => Stream.value([_item('plan'), _item('play')]),
        ),
      ];

      await tester.pumpWidget(
        testWrap(
          MentionPopup(
            query: _query('p'),
            sources: sources(),
            onSelect: (_) {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('plan'), findsOneWidget);

      // Refine the partial with a NEW source-list instance (identity churn).
      await tester.pumpWidget(
        testWrap(
          MentionPopup(
            query: _query('pl'),
            sources: sources(),
            onSelect: (_) {},
            onDismiss: () {},
          ),
        ),
      );
      // Same frame, before any re-delivery: the previous rows are still
      // rendered (no blank flash) and the placeholder is not shown.
      expect(find.text('plan'), findsOneWidget);
      expect(find.text('Searching…'), findsNothing);

      // Let the fresh query deliver; still no placeholder at any point.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('plan'), findsOneWidget);
      expect(find.text('Searching…'), findsNothing);
    });

    testWidgets('"Searching…" appears only after the delay when a source is '
        'genuinely slow', (tester) async {
      await tester.pumpWidget(
        testWrap(
          MentionPopup(
            query: _query('a'),
            sources: [
              _ControlledSource(
                responder: (_) => Stream.fromFuture(
                  Future.delayed(
                    const Duration(milliseconds: 600),
                    () => [_item('alpha')],
                  ),
                ),
              ),
            ],
            onSelect: (_) {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      // Within the delay window: nothing on screen, no placeholder.
      expect(find.text('Searching…'), findsNothing);

      // Past the 300ms delay with nothing delivered: placeholder shows.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Searching…'), findsOneWidget);

      // Delivery swaps the placeholder for rows.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Searching…'), findsNothing);
      expect(find.text('alpha'), findsOneWidget);
    });

    testWidgets('Enter commits only rows whose source answered the current '
        'query', (tester) async {
      final selected = <MentionSuggestion>[];
      var sources = <MentionSource>[
        // Answers 'a' instantly, then hangs on the refined query.
        _ControlledSource(
          responder: (partial) => partial == 'a'
              ? Stream.value([_item('alpha')])
              : Stream.fromFuture(
                  Future.delayed(
                    const Duration(seconds: 5),
                    () => [_item('alpine')],
                  ),
                ),
        ),
      ];

      Widget popup(String partial) => testWrap(
        MentionPopup(
          query: _query(partial),
          sources: sources,
          onSelect: selected.add,
          onDismiss: () {},
        ),
      );

      await tester.pumpWidget(popup('a'));
      await tester.pump();
      expect(find.text('alpha'), findsOneWidget);

      // Refine: the row for 'a' stays visible but is stale.
      sources = [
        _ControlledSource(
          responder: (partial) => partial == 'a'
              ? Stream.value([_item('alpha')])
              : Stream.fromFuture(
                  Future.delayed(
                    const Duration(seconds: 5),
                    () => [_item('alpine')],
                  ),
                ),
        ),
      ];
      await tester.pumpWidget(popup('ab'));
      await tester.pump();
      expect(find.text('alpha'), findsOneWidget);

      // Enter while the row's source has not re-delivered: swallowed, no
      // commit of a suggestion that answers the previous keystroke.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, isEmpty);

      // After re-delivery Enter commits the fresh suggestion.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('alpine'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected.map((s) => s.label), ['alpine']);
    });

    testWidgets('a current fast source stays committable while another '
        'source is still lagging', (tester) async {
      final selected = <MentionSuggestion>[];
      final sources = <MentionSource>[
        _ControlledSource(responder: (_) => Stream.value([_item('plan')])),
        _ControlledAgentSource(
          responder: (_) => Stream.fromFuture(
            Future.delayed(
              const Duration(seconds: 5),
              () => [
                const MentionSuggestion(
                  id: 'agent:ada',
                  kind: 'agent',
                  label: 'ada',
                  replacement: '@ada',
                ),
              ],
            ),
          ),
        ),
      ];

      await tester.pumpWidget(
        testWrap(
          MentionPopup(
            query: _query('p'),
            sources: sources,
            onSelect: selected.add,
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump();
      // The command source delivered; the agent source is still pending.
      // Enter commits the (selected, first) command row.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected.map((s) => s.label), ['plan']);

      // Drain the lagging source's delayed delivery so no timer outlives the
      // test.
      await tester.pump(const Duration(seconds: 5));
    });
  });
}

import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_popup.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

/// A labelled source of described rows: the shape of the real slash list, whose
/// rows are taller than a label alone and sit under a section header.
class _SectionSource extends SyncMentionSource {
  _SectionSource(this.kind, this.labels);

  @override
  final String kind;

  final List<String> labels;

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.slash};

  @override
  String? sectionLabel(BuildContext context) => 'Section $kind';

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) => [
    for (final label in labels)
      if (label.startsWith(query.partial))
        MentionSuggestion(
          id: '$kind:$label',
          kind: kind,
          label: label,
          description: 'What $label does',
          icon: const IconData(0xe000),
          replacement: '/$label',
        ),
  ];
}

Widget _popup(
  MentionQuery query,
  List<MentionSource> sources, {
  void Function(MentionSuggestion)? onSelect,
  TextDirection? textDirection,
}) => testWrap(
  // Loose constraints, as in the composer's overlay: the popup sizes itself.
  Align(
    alignment: AlignmentDirectional.topStart,
    child: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The composer's field keeps focus while the popup is open. Without
          // it the arrow keys walk focus along the rows and Enter activates
          // the focused one, which is not what the app does.
          const Material(child: TextField(autofocus: true)),
          MentionPopup(
            query: query,
            sources: sources,
            onSelect: onSelect ?? (_) {},
            onDismiss: () {},
          ),
        ],
      ),
    ),
  ),
  textDirection: textDirection,
);

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await _settleScroll(tester);
}

/// Runs the post-frame scroll and its animation to the end. Takes two timed
/// pumps: a ticker's first tick only records its start time, so a single long
/// pump leaves the animation at zero.
Future<void> _settleScroll(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 200));
}

/// Fails unless the whole row for [label], description included, is on screen
/// inside the popup rather than clipped by its scroll viewport.
void _expectRowFullyVisible(WidgetTester tester, String label) {
  final popup = tester.getRect(find.byType(MentionPopup));
  final top = tester.getRect(find.text(label)).top;
  final bottom = tester.getRect(find.text('What $label does')).bottom;
  expect(top, greaterThanOrEqualTo(popup.top), reason: '$label clipped above');
  expect(
    bottom,
    lessThanOrEqualTo(popup.bottom),
    reason: '$label clipped below',
  );
}

void main() {
  group('MentionPopup keyboard scrolling', () {
    const first = ['plan', 'goal', 'loop', 'tree', 'export', 'share'];
    const second = ['alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta'];
    final labels = [...first, ...second];
    List<MentionSource> sources() => [
      _SectionSource('a', first),
      _SectionSource('b', second),
    ];

    testWidgets('arrow down keeps every active row fully in view', (
      tester,
    ) async {
      await tester.pumpWidget(_popup(_query(''), sources()));
      await tester.pump();

      for (final label in labels.skip(1)) {
        await _press(tester, LogicalKeyboardKey.arrowDown);
        _expectRowFullyVisible(tester, label);
      }
    });

    testWidgets('arrow up keeps every active row fully in view', (
      tester,
    ) async {
      await tester.pumpWidget(_popup(_query(''), sources()));
      await tester.pump();

      // Up from the first row wraps to the last, which has never been on
      // screen.
      await _press(tester, LogicalKeyboardKey.arrowUp);
      _expectRowFullyVisible(tester, labels.last);

      for (final label in labels.reversed.skip(1)) {
        await _press(tester, LogicalKeyboardKey.arrowUp);
        _expectRowFullyVisible(tester, label);
      }
    });

    testWidgets('wrapping to the first row brings its section header back', (
      tester,
    ) async {
      await tester.pumpWidget(_popup(_query(''), sources()));
      await tester.pump();

      final popup = tester.getRect(find.byType(MentionPopup));
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(
        tester.getRect(find.text('SECTION A')).bottom,
        lessThanOrEqualTo(popup.top),
      );

      await _press(tester, LogicalKeyboardKey.arrowDown);
      _expectRowFullyVisible(tester, labels.first);
      expect(
        tester.getRect(find.text('SECTION A')).top,
        greaterThanOrEqualTo(popup.top),
      );
    });

    testWidgets('a pointer resting over the list does not steal the selection '
        'as rows scroll under it', (tester) async {
      MentionSuggestion? picked;
      await tester.pumpWidget(
        _popup(_query(''), sources(), onSelect: (s) => picked = s),
      );
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(find.text('goal')));
      await tester.pump();

      for (var i = 0; i < 7; i++) {
        await _press(tester, LogicalKeyboardKey.arrowDown);
      }
      await _press(tester, LogicalKeyboardKey.enter);
      expect(picked?.label, 'beta');

      await gesture.removePointer();
    });

    testWidgets('moving the pointer still selects the row under it', (
      tester,
    ) async {
      MentionSuggestion? picked;
      await tester.pumpWidget(
        _popup(_query(''), sources(), onSelect: (s) => picked = s),
      );
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('loop')));
      await tester.pump();

      await _press(tester, LogicalKeyboardKey.enter);
      expect(picked?.label, 'loop');

      await gesture.removePointer();
    });

    testWidgets('refining the query reveals the reset selection', (
      tester,
    ) async {
      await tester.pumpWidget(_popup(_query(''), sources()));
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await _press(tester, LogicalKeyboardKey.arrowDown);
      }

      // Selection resets to the first row, which must not stay scrolled off.
      const many = ['aa', 'ab', 'ac', 'ad', 'ae', 'af'];
      await tester.pumpWidget(
        _popup(_query('a'), [
          _SectionSource('a', many),
          _SectionSource('b', [for (final m in many) '${m}x']),
        ]),
      );
      await _settleScroll(tester);

      _expectRowFullyVisible(tester, 'aa');
    });

    testWidgets('scrolling follows the selection under RTL', (tester) async {
      await tester.pumpWidget(
        _popup(_query(''), sources(), textDirection: TextDirection.rtl),
      );
      await tester.pump();

      for (final label in labels.skip(1)) {
        await _press(tester, LogicalKeyboardKey.arrowDown);
        _expectRowFullyVisible(tester, label);
      }
    });

    testWidgets('two suggestions sharing an id both render', (tester) async {
      // Sources do not promise unique ids, and a non-lazy list must not turn
      // a duplicate into a build failure.
      await tester.pumpWidget(
        _popup(_query(''), [
          _SectionSource('a', const ['same', 'same']),
        ]),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('same'), findsNWidgets(2));
    });
  });

  group('MentionPopup searching UX', () {
    testWidgets('refining the query keeps rows visible and never flashes '
        '"Searching…" for fast sources', (tester) async {
      // Mirrors SpaceInputBar: the source list is a fresh literal on every
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

    testWidgets('moving the pointer between rows fades the hover wash '
        'without dipping through black', (tester) async {
      await tester.pumpWidget(
        testWrap(
          MentionPopup(
            query: _query('p'),
            sources: [
              _ControlledSource(
                responder: (_) => Stream.value([
                  _item('plan'),
                  _item('play'),
                  _item('pause'),
                ]),
              ),
            ],
            onSelect: (_) {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.text('play')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      final wash = tester
          .element(find.byType(MentionPopup))
          .designSystem!
          .bgPrimaryHover;
      final colors = tester
          .renderObjectList<RenderDecoratedBox>(
            find.descendant(
              of: find.byType(AnimatedContainer),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as BoxDecoration).color)
          .whereType<Color>();
      expect(colors, isNotEmpty);
      for (final color in colors) {
        // Composited over the white popup. A lerp from transparent black
        // lands near mid-gray here; a fade of the wash stays near white.
        final overWhite = color.a * color.r + (1 - color.a);
        expect(overWhite, greaterThan(0.9));
        expect(
          (color.r - wash.r).abs(),
          lessThan(0.02),
          reason: 'row wash must stay the hover color while its alpha fades',
        );
      }

      await gesture.removePointer();
    });
  });
}

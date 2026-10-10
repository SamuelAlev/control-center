import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_notes_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_overview_speakers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _ws = 'ws1';
const _id = 'm1';
final _at = DateTime(2026, 9, 27, 21, 17);

Meeting _meeting({MeetingStatus status = MeetingStatus.done}) => Meeting(
  id: _id,
  workspaceId: _ws,
  title: 'Weekly sync',
  status: status,
  createdAt: _at,
  updatedAt: _at,
  startedAt: _at,
  endedAt: _at.add(const Duration(minutes: 30)),
);

MeetingSegment _seg(
  String id,
  MeetingSpeaker speaker,
  int startS,
  int endS, {
  String? label,
}) => MeetingSegment(
  id: id,
  meetingId: _id,
  workspaceId: _ws,
  speaker: speaker,
  speakerLabel: label,
  text: 'Line $id',
  startMs: startS * 1000,
  endMs: endS * 1000,
  createdAt: _at,
);

final _segments = [
  _seg('a', MeetingSpeaker.me, 0, 60),
  _seg('b', MeetingSpeaker.them, 60, 90, label: 'Person 1'),
  _seg('c', MeetingSpeaker.me, 90, 150),
  _seg('d', MeetingSpeaker.them, 150, 180, label: 'Person 2'),
];

final _items = [
  MeetingActionItem(
    id: 'i1',
    meetingId: _id,
    workspaceId: _ws,
    content: 'Ship the overview rail',
    owner: 'Sam',
    createdAt: _at,
  ),
  MeetingActionItem(
    id: 'i2',
    meetingId: _id,
    workspaceId: _ws,
    content: 'Already handled',
    done: true,
    createdAt: _at,
  ),
];

final _decisions = [
  MeetingDecision(
    id: 'd1',
    meetingId: _id,
    workspaceId: _ws,
    content: 'Keep notes as the default tab',
    createdAt: _at,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  Meeting? meeting,
  List<MeetingSegment>? segments,
  List<MeetingActionItem>? items,
  List<MeetingDecision>? decisions,
  VoidCallback? onGenerate,
  ValueChanged<MeetingNotesMode>? onModeChanged,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final controller = TextEditingController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        meetingSpeakersProvider((
          workspaceId: _ws,
          meetingId: _id,
        )).overrideWith(
          (ref) => Stream.value([
            MeetingSpeakerLabel(
              id: 's1',
              meetingId: _id,
              workspaceId: _ws,
              channel: MeetingSpeaker.them,
              label: 'Person 1',
              displayName: 'Ana',
              createdAt: _at,
            ),
          ]),
        ),
      ],
      child: testWrap(
        SingleChildScrollView(
          child: MeetingNotesTab(
            meeting: meeting ?? _meeting(),
            mode: MeetingNotesMode.enhanced,
            onModeChanged: onModeChanged ?? (_) {},
            notesController: controller,
            onNotesChanged: (_) {},
            savingLabel: 'Saved',
            segments: segments ?? _segments,
            actionItems: items ?? _items,
            decisions: decisions ?? _decisions,
            onViewFullTranscript: () {},
            onViewActionItems: () {},
            onViewDecisions: () {},
            onGenerateNotes: onGenerate ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MeetingTalkTime.from', () {
    test('groups by diarized label, else channel, loudest first', () {
      final talk = MeetingTalkTime.from(_segments);
      expect(talk.map((t) => t.label), [null, 'Person 1', 'Person 2']);
      expect(talk.first.speaker, MeetingSpeaker.me);
      expect(talk.first.spoken, const Duration(minutes: 2));
      expect(talk.first.share, closeTo(120 / 180, 1e-9));
      expect(talk.fold<double>(0, (a, t) => a + t.share), closeTo(1, 1e-9));
    });

    test('is empty without segments and ignores inverted ranges', () {
      expect(MeetingTalkTime.from(const []), isEmpty);
      final talk = MeetingTalkTime.from([_seg('x', MeetingSpeaker.me, 10, 5)]);
      expect(talk.single.spoken, Duration.zero);
      expect(talk.single.share, 0);
    });
  });

  group('MeetingNotesTab overview', () {
    testWidgets('wide windows put the overview in a third column', (
      tester,
    ) async {
      await _pump(tester, width: 1600);

      final speakers = tester.getTopLeft(find.text('SPEAKERS'));
      final notes = tester.getTopLeft(find.text('NOTES'));
      final transcript = tester.getTopLeft(find.text('TRANSCRIPT'));
      expect(speakers.dx, greaterThan(transcript.dx));
      expect(transcript.dx, greaterThan(notes.dx));
      // The renamed diarized speaker shows by name; the local mic as "You".
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('You'), findsWidgets);
      // Only open action items are previewed; the count covers all of them.
      expect(find.text('Ship the overview rail'), findsOneWidget);
      expect(find.text('Already handled'), findsNothing);
      expect(find.text('View all 2'), findsOneWidget);
      expect(find.text('Keep notes as the default tab'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mid-width windows run the overview beneath the notes', (
      tester,
    ) async {
      await _pump(tester, width: 1100);

      final speakers = tester.getTopLeft(find.text('SPEAKERS'));
      final decisions = tester.getTopLeft(find.text('DECISIONS'));
      final notes = tester.getTopLeft(find.text('NOTES'));
      expect(speakers.dy, greaterThan(notes.dy));
      // Side by side: same row, decisions to the end.
      expect(decisions.dy, speakers.dy);
      expect(decisions.dx, greaterThan(speakers.dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow windows stack every section', (tester) async {
      await _pump(tester, width: 600);

      final speakers = tester.getTopLeft(find.text('SPEAKERS'));
      final decisions = tester.getTopLeft(find.text('DECISIONS'));
      expect(decisions.dy, greaterThan(speakers.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('all-done action items say so instead of listing nothing', (
      tester,
    ) async {
      await _pump(tester, width: 1600, items: [_items.last]);

      expect(find.text('All action items are done.'), findsOneWidget);
    });
  });

  group('MeetingNotesTab empty notes', () {
    testWidgets('offers to generate notes when there is a transcript', (
      tester,
    ) async {
      var generated = 0;
      await _pump(tester, width: 1600, onGenerate: () => generated++);

      expect(find.text('No enhanced notes yet.'), findsOneWidget);
      await tester.tap(find.text('Generate notes'));
      expect(generated, 1);
    });

    testWidgets(
      'a finished meeting with no transcript drops the excerpt and offers '
      'only your own notes',
      (tester) async {
        MeetingNotesMode? switchedTo;
        await _pump(
          tester,
          width: 1600,
          segments: const [],
          items: const [],
          decisions: const [],
          onModeChanged: (m) => switchedTo = m,
        );

        expect(find.text('Nothing was transcribed.'), findsOneWidget);
        expect(find.text('Generate notes'), findsNothing);
        expect(find.text('TRANSCRIPT'), findsNothing);
        expect(find.text('View full transcript'), findsNothing);
        await tester.tap(find.text('Write your own'));
        expect(switchedTo, MeetingNotesMode.yours);
      },
    );

    testWidgets('a meeting still processing keeps the transcript column', (
      tester,
    ) async {
      await _pump(
        tester,
        width: 1600,
        meeting: _meeting(status: MeetingStatus.processing),
        segments: const [],
      );

      expect(find.text('TRANSCRIPT'), findsOneWidget);
      expect(find.text('No transcript yet.'), findsOneWidget);
      expect(find.text('View full transcript'), findsNothing);
    });
  });
}

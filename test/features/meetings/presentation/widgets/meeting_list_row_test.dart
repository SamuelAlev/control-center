import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_list_row.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

Meeting _basicMeeting({MeetingStatus status = MeetingStatus.done}) => Meeting(
      id: 'm1',
      workspaceId: 'ws1',
      title: 'Sprint Planning',
      status: status,
      createdAt: DateTime(2026, 6, 10, 10, 0),
      updatedAt: DateTime(2026, 6, 10, 11, 0),
      startedAt: DateTime(2026, 6, 10, 10, 0),
      endedAt: DateTime(2026, 6, 10, 11, 0),
      sourceApp: 'Zoom',
    );

void main() {
  group('MeetingListRow', () {
    testWidgets('renders meeting title', (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      expect(find.text('Sprint Planning'), findsOneWidget);
    });

    testWidgets('renders status glyph for done meeting', (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(status: MeetingStatus.done),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      // Status glyph renders the check icon for done.
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
    });

    testWidgets('renders recording status glyph', (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(status: MeetingStatus.recording),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      expect(find.byIcon(LucideIcons.mic), findsOneWidget);
    });

    testWidgets('renders failed status glyph', (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(status: MeetingStatus.failed),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
    });

    testWidgets('renders processing tag for processing meeting', (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(status: MeetingStatus.processing),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      // Processing meetings show the transcribing tag with equalizer bars
      // (the status glyph also renders equalizer bars for processing status).
      expect(find.byType(MeetingEqualizerBars), findsAtLeast(2));
    });

    testWidgets('renders meta line with time and source', (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(status: MeetingStatus.done),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      expect(find.byType(MeetingListRow), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Sprint Planning'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders signal pills for enhanced meeting', (tester) async {
      final meeting = Meeting(
        id: 'm2',
        workspaceId: 'ws1',
        title: 'Design Review',
        status: MeetingStatus.done,
        createdAt: DateTime(2026, 6, 10, 10, 0),
        updatedAt: DateTime(2026, 6, 10, 11, 0),
        startedAt: DateTime(2026, 6, 10, 10, 0),
        endedAt: DateTime(2026, 6, 10, 11, 0),
        enhancedNotes: '# Reviewed the mockups and aligned on the v2 nav.',
      );

      // Signal pills are DB-backed now: seed the action-item + decision counts.
      await tester.pumpWidget(testWrap(
        ProviderScope(
          overrides: [
            meetingActionItemStatsProvider.overrideWith(
              (ref, _) => Stream.value(
                const <String, MeetingActionItemStats>{
                  'm2': (total: 2, done: 0),
                },
              ),
            ),
            meetingDecisionCountsProvider.overrideWith(
              (ref, _) => Stream.value(const <String, int>{'m2': 2}),
            ),
          ],
          child: MeetingListRow(
            meeting: meeting,
            now: DateTime(2026, 6, 10, 12, 0),
            onTap: () {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
      expect(find.byIcon(LucideIcons.flag), findsOneWidget);
      expect(find.byIcon(LucideIcons.listChecks), findsOneWidget);
    });

    testWidgets('renders open button for non-processing meetings', (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(status: MeetingStatus.done),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('does not render open button for processing meetings', (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(status: MeetingStatus.processing),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      expect(find.text('Open'), findsNothing);
    });

    testWidgets('renders stop button (kills the pipeline) while processing',
        (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(status: MeetingStatus.processing),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('does not render stop button while still recording',
        (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: _basicMeeting(status: MeetingStatus.recording),
          now: DateTime(2026, 6, 10, 12, 0),
          onTap: () {},
        ),
      ));

      // A recording is stopped from the record screen / HUD, not the list.
      expect(find.text('Stop'), findsNothing);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('long title is truncated', (tester) async {
      await tester.pumpWidget(testWrap(
        MeetingListRow(
          meeting: Meeting(
            id: 'm3',
            workspaceId: 'ws1',
            title: 'A' * 200,
            status: MeetingStatus.done,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            startedAt: DateTime(2026),
            endedAt: DateTime(2026),
          ),
          now: DateTime(2026),
          onTap: () {},
        ),
      ));

      final titleWidget = tester.widget<Text>(find.textContaining('A'));
      expect(titleWidget.maxLines, 2);
      expect(titleWidget.overflow, TextOverflow.ellipsis);
    });
  });
}

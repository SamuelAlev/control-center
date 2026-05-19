import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_detection_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/presentation/screens/meeting_record_screen.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// A test-only [ActiveWorkspaceIdNotifier] that returns a fixed id.
class _FixedWsId extends ActiveWorkspaceIdNotifier {
  _FixedWsId(this._id);
  final String _id;

  @override
  String? build() => _id;
}

/// A test-only [MeetingRecorderController] that returns a fixed state.
class _FixedMeetingRecorderController extends MeetingRecorderController {
  _FixedMeetingRecorderController(this._state);
  final MeetingRecorderState _state;

  @override
  MeetingRecorderState build() => _state;
}

/// Disables auto-detection so the screen never starts the polling timer /
/// process scan in a widget test.
class _DetectOff extends MeetingAutoDetectEnabledNotifier {
  @override
  bool build() => false;
}

Meeting _testMeeting() {
  final now = DateTime(2026, 6, 11);
  return Meeting(
    id: 'meeting-1',
    workspaceId: 'ws1',
    title: 'Test Meeting',
    status: MeetingStatus.recording,
    createdAt: now,
    updatedAt: now,
    startedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('MeetingRecordScreen', () {
    group('not recording', () {
      testWidgets('renders not recording state when meetingId is null',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeWorkspaceIdProvider.overrideWith(() => _FixedWsId('ws1')),
              meetingRecorderControllerProvider.overrideWith(
                () => _FixedMeetingRecorderController(
                  const MeetingRecorderState(),
                ),
              ),
            ],
            child: testWrap(const MeetingRecordScreen()),
          ),
        );

        // Let the widget build and settle initial frame.
        await tester.pump();

        expect(find.text('No active recording.'), findsOneWidget);
        expect(find.text('Meetings'), findsOneWidget);

        // Dispose the screen to cancel its periodic ticker, avoiding pending
        // timer warnings.
        await tester.pumpWidget(const SizedBox());
      });
    });

    group('recording', () {
      testWidgets('renders recording UI when recording is active',
          (tester) async {
        final meeting = _testMeeting();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeWorkspaceIdProvider.overrideWith(() => _FixedWsId('ws1')),
              meetingAutoDetectEnabledProvider.overrideWith(_DetectOff.new),
              meetingRecorderControllerProvider.overrideWith(
                () => _FixedMeetingRecorderController(
                  MeetingRecorderState.recording(
                    'meeting-1',
                    DateTime(2026, 1, 1),
                  ),
                ),
              ),
              meetingDetailProvider((
                workspaceId: 'ws1',
                meetingId: 'meeting-1',
              )).overrideWith((ref) => Stream.value(meeting)),
              meetingSegmentsProvider((
                workspaceId: 'ws1',
                meetingId: 'meeting-1',
              )).overrideWith(
                (ref) => Stream.value(const <MeetingSegment>[]),
              ),
            ],
            child: testWrap(const MeetingRecordScreen()),
          ),
        );

        // Pump frames to let streams emit and widget build.
        await tester.pump();
        await tester.pump();

        // Recording bar renders with control buttons.
        expect(find.text('Pause'), findsOneWidget);
        expect(find.text('Stop & summarize'), findsOneWidget);

        // The meeting title is pre-filled from the streamed meeting.
        expect(find.text('Meeting title'), findsOneWidget);

        // Dispose the screen to cancel its periodic ticker, avoiding pending
        // timer warnings.
        await tester.pumpWidget(const SizedBox());
      });
    });
  });
}

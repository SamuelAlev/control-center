import 'dart:async';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/presentation/screens/meeting_detail_screen.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_playback_bar.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _workspaceId = 'ws1';
const _meetingId = 'm1';
const _meetingRef =
    (workspaceId: _workspaceId, meetingId: _meetingId);

Meeting _makeMeeting({
  MeetingStatus status = MeetingStatus.done,
  String? audioPath,
}) {
  final now = DateTime(2026, 6, 11, 14, 30);
  return Meeting(
    id: _meetingId,
    workspaceId: _workspaceId,
    title: 'Test Standup',
    status: status,
    audioPath: audioPath,
    createdAt: now,
    updatedAt: now,
    startedAt: now.subtract(const Duration(minutes: 30)),
  );
}

class _FixedWsId extends ActiveWorkspaceIdNotifier {
  _FixedWsId(this._id);
  final String _id;
  @override
  String? build() => _id;
}

class _FakeRecorder extends MeetingRecorderController {
  @override
  MeetingRecorderState build() => const MeetingRecorderState();
}

void main() {
  group('MeetingDetailScreen', () {
    testWidgets('renders meeting title in the detail header', (tester) async {
      final meeting = _makeMeeting();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider
                .overrideWith(() => _FixedWsId(_workspaceId)),
            meetingRecorderControllerProvider
                .overrideWith(_FakeRecorder.new),
            meetingDetailProvider(_meetingRef)
                .overrideWith((ref) => Stream.value(meeting)),
            meetingSegmentsProvider(_meetingRef)
                .overrideWith((ref) => Stream.value(const <MeetingSegment>[])),
          ],
          child: testWrap(
            const MeetingDetailScreen(meetingId: _meetingId),
          ),
        ),
      );

      // Allow async streams to settle.
      await tester.pump();
      await tester.pump();

      expect(find.text('Test Standup'), findsOneWidget);
    });

    testWidgets('renders loading indicator while meeting stream has not emitted',
        (tester) async {
      // A stream that never emits keeps the provider in loading state.
      final loadingController = StreamController<Meeting?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider
                .overrideWith(() => _FixedWsId(_workspaceId)),
            meetingRecorderControllerProvider
                .overrideWith(_FakeRecorder.new),
            meetingDetailProvider(_meetingRef)
                .overrideWith((ref) => loadingController.stream),
            meetingSegmentsProvider(_meetingRef)
                .overrideWith((ref) => Stream.value(const <MeetingSegment>[])),
          ],
          child: testWrap(
            const MeetingDetailScreen(meetingId: _meetingId),
          ),
        ),
      );

      addTearDown(loadingController.close);

      await tester.pump();
      await tester.pump();

      expect(find.byType(CcSpinner), findsOneWidget);
    });

    testWidgets(
        'hides the playback bar while recording (audio files still open)',
        (tester) async {
      final meeting = _makeMeeting(
        status: MeetingStatus.recording,
        audioPath: '/tmp/meeting-audio',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider
                .overrideWith(() => _FixedWsId(_workspaceId)),
            meetingRecorderControllerProvider
                .overrideWith(_FakeRecorder.new),
            meetingDetailProvider(_meetingRef)
                .overrideWith((ref) => Stream.value(meeting)),
            meetingSegmentsProvider(_meetingRef)
                .overrideWith((ref) => Stream.value(const <MeetingSegment>[])),
            // Keep the loader off the real isolate/filesystem.
            meetingAudioClipProvider.overrideWith((ref, arg) => null),
          ],
          child: testWrap(
            const MeetingDetailScreen(meetingId: _meetingId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // audioPath is set, but the recording is still in progress, so the bar
      // must stay hidden until the meeting finalizes.
      expect(find.byType(MeetingPlaybackBar), findsNothing);
    });

    testWidgets('shows the playback bar once the meeting has finished recording',
        (tester) async {
      final meeting = _makeMeeting(
        status: MeetingStatus.done,
        audioPath: '/tmp/meeting-audio',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider
                .overrideWith(() => _FixedWsId(_workspaceId)),
            meetingRecorderControllerProvider
                .overrideWith(_FakeRecorder.new),
            meetingDetailProvider(_meetingRef)
                .overrideWith((ref) => Stream.value(meeting)),
            meetingSegmentsProvider(_meetingRef)
                .overrideWith((ref) => Stream.value(const <MeetingSegment>[])),
            // Return no clip so the bar mounts without spinning up an
            // AudioPlayer; this test only asserts the bar's presence.
            meetingAudioClipProvider.overrideWith((ref, arg) => null),
          ],
          child: testWrap(
            const MeetingDetailScreen(meetingId: _meetingId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(MeetingPlaybackBar), findsOneWidget);
    });
  });
}

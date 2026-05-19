import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/providers/record_and_link_provider.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_calendar_repository.dart';

/// A recorder that transitions to recording (or failed) without touching audio.
class _FakeRecorder extends MeetingRecorderController {
  _FakeRecorder({required this.succeed});

  final bool succeed;

  @override
  MeetingRecorderState build() => MeetingRecorderState.idle;

  @override
  Future<void> start({
    String? title,
    String? sourceId,
    MeetingMode mode = MeetingMode.remote,
  }) async {
    state = succeed
        ? MeetingRecorderState.recording('meeting-123', DateTime(2026, 6, 11))
        : MeetingRecorderState.failed('Voice model not installed');
  }
}

CalendarEvent _event() => CalendarEvent(
      id: 'evt-1',
      workspaceId: 'ws-A',
      accountId: 'acc',
      externalEventId: 'x',
      calendarId: 'primary',
      title: 'Standup',
      startTime: DateTime(2026, 6, 11, 10),
      endTime: DateTime(2026, 6, 11, 10, 30),
      updatedAt: DateTime(2026, 6, 11),
    );

ProviderContainer _container(FakeCalendarRepository repo, {required bool succeed}) {
  return ProviderContainer(
    overrides: [
      calendarRepositoryProvider.overrideWithValue(repo),
      meetingRecorderControllerProvider.overrideWith(
        () => _FakeRecorder(succeed: succeed),
      ),
    ],
  );
}

void main() {
  group('CalendarRecordAndLinkUseCase', () {
    test('on success writes exactly one link and returns the meeting id', () async {
      final repo = FakeCalendarRepository();
      final container = _container(repo, succeed: true);
      addTearDown(container.dispose);

      final meetingId = await container
          .read(calendarRecordAndLinkProvider)
          .startRecordingForEvent(_event());

      expect(meetingId, 'meeting-123');
      expect(repo.links, hasLength(1));
      expect(repo.links.single.meetingId, 'meeting-123');
      expect(repo.links.single.calendarEventId, 'evt-1');
      expect(repo.links.single.workspaceId, 'ws-A');
    });

    test('on failure writes no link and returns null', () async {
      final repo = FakeCalendarRepository();
      final container = _container(repo, succeed: false);
      addTearDown(container.dispose);

      final meetingId = await container
          .read(calendarRecordAndLinkProvider)
          .startRecordingForEvent(_event());

      expect(meetingId, isNull);
      expect(repo.links, isEmpty);
    });
  });
}

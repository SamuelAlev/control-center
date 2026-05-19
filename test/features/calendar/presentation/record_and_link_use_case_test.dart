import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/providers/record_and_link_provider.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_calendar_repository.dart';

/// Minimal meeting repo for the link use case's title-sync path: getById +
/// upsert only (everything else throws, and isn't called here).
class _FakeMeetingRepo implements MeetingRepository {
  Meeting? meeting;
  Meeting? upserted;

  @override
  Future<Meeting?> getById(String workspaceId, String id) async => meeting;

  @override
  Future<void> upsert(Meeting meeting) async => upserted = meeting;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

ProviderContainer _container(
  FakeCalendarRepository repo, {
  required bool succeed,
  _FakeMeetingRepo? meetingRepo,
}) {
  return ProviderContainer(
    overrides: [
      calendarRepositoryProvider.overrideWithValue(repo),
      meetingRepositoryProvider.overrideWithValue(
        meetingRepo ?? _FakeMeetingRepo(),
      ),
      meetingRecorderControllerProvider.overrideWith(
        () => _FakeRecorder(succeed: succeed),
      ),
    ],
  );
}

void main() {
  group('CalendarRecordAndLinkUseCase', () {
    test('on success writes exactly one link and returns the meeting id', () async {
      final repo = FakeCalendarRepository()..eventForMeeting = _event();
      // A default-titled, non-custom meeting that should adopt the event title.
      final now = DateTime(2026, 6, 11);
      final meetingRepo = _FakeMeetingRepo()
        ..meeting = Meeting(
          id: 'meeting-123',
          workspaceId: 'ws-A',
          title: 'Meeting 2026-06-11 10:00',
          status: MeetingStatus.recording,
          createdAt: now,
          updatedAt: now,
          startedAt: now,
        );
      final container = _container(repo, succeed: true, meetingRepo: meetingRepo);
      addTearDown(container.dispose);

      final meetingId = await container
          .read(calendarRecordAndLinkProvider)
          .startRecordingForEvent(_event());

      expect(meetingId, 'meeting-123');
      expect(repo.links, hasLength(1));
      expect(repo.links.single.meetingId, 'meeting-123');
      expect(repo.links.single.calendarEventId, 'evt-1');
      expect(repo.links.single.workspaceId, 'ws-A');
      // The non-custom meeting adopted the linked event's title.
      expect(meetingRepo.upserted?.title, 'Standup');
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

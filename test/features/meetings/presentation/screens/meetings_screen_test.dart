import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_detection_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Meeting _meeting({
  String id = 'm1',
  String workspaceId = 'ws1',
  String title = 'Sprint Planning',
  MeetingStatus status = MeetingStatus.done,
}) =>
    Meeting(
      id: id,
      workspaceId: workspaceId,
      title: title,
      status: status,
      createdAt: DateTime(2026, 6, 11, 10, 0),
      updatedAt: DateTime(2026, 6, 11, 11, 0),
      startedAt: DateTime(2026, 6, 11, 10, 0),
      endedAt: DateTime(2026, 6, 11, 11, 0),
      sourceApp: 'Zoom',
    );

class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceId(this._id);
  final String _id;

  @override
  String? build() => _id;
}

class _NullWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

class _FakeRecorderNotifier extends MeetingRecorderController {
  @override
  MeetingRecorderState build() => MeetingRecorderState.idle;
}

/// Disables auto-detection so the screen never starts the polling timer /
/// process scan in a widget test.
class _DetectOff extends MeetingAutoDetectEnabledNotifier {
  @override
  bool build() => false;
}

/// Wraps [child] with testWrap and provider overrides for the meetings screen.
Widget _testWrap(
  Widget child, {
  String? workspaceId,
  List<Meeting> meetings = const [],
  MeetingRecorderController Function()? recorderFactory,
}) {
  return ProviderScope(
    overrides: [
      if (workspaceId != null) ...[
        activeWorkspaceIdProvider.overrideWith(
          () => _FixedWorkspaceId(workspaceId),
        ),
        meetingsProvider(workspaceId)
            .overrideWith((ref) => Stream.value(meetings)),
      ] else
        activeWorkspaceIdProvider.overrideWith(_NullWorkspaceId.new),
      meetingRecorderControllerProvider.overrideWith(
        recorderFactory ?? _FakeRecorderNotifier.new,
      ),
      meetingAutoDetectEnabledProvider.overrideWith(_DetectOff.new),
    ],
    child: testWrap(child),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MeetingsScreen', () {
    testWidgets('renders no-workspace message when workspaceId is null',
        (tester) async {
      await tester.pumpWidget(_testWrap(
        const MeetingsScreen(),
        workspaceId: null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select a workspace to see meetings.'), findsOneWidget);
    });

    testWidgets('renders meetings list with meeting titles', (tester) async {
      final meetings = [
        _meeting(id: 'm1', title: 'Sprint Planning'),
        _meeting(id: 'm2', title: 'Architecture Review'),
      ];

      await tester.pumpWidget(_testWrap(
        const MeetingsScreen(),
        workspaceId: 'ws1',
        meetings: meetings,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sprint Planning'), findsOneWidget);
      expect(find.text('Architecture Review'), findsOneWidget);
    });

    testWidgets('renders empty state when no meetings', (tester) async {
      await tester.pumpWidget(_testWrap(
        const MeetingsScreen(),
        workspaceId: 'ws1',
        meetings: const [],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No meetings match'), findsOneWidget);
    });
  });
}

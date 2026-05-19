import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_live_strip.dart';
import 'package:control_center/features/meetings/providers/meeting_auto_detect_provider.dart';
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
  DateTime? startedAt,
  DateTime? endedAt,
}) => Meeting(
  id: id,
  workspaceId: workspaceId,
  title: title,
  status: status,
  createdAt: DateTime(2026, 6, 11, 10, 0),
  updatedAt: DateTime(2026, 6, 11, 11, 0),
  startedAt: startedAt ?? DateTime(2026, 6, 11, 10, 0),
  endedAt: endedAt ?? DateTime(2026, 6, 11, 11, 0),
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

/// A recorder that reports an in-flight capture, so the live strip mounts.
class _RecordingRecorderNotifier extends MeetingRecorderController {
  @override
  MeetingRecorderState build() =>
      MeetingRecorderState.recording('m1', DateTime(2026, 6, 11, 10));
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
        meetingsProvider(
          workspaceId,
        ).overrideWith((ref) => Stream.value(meetings)),
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
    testWidgets('renders no-workspace message when workspaceId is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testWrap(const MeetingsScreen(), workspaceId: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select a workspace to see meetings.'), findsOneWidget);
    });

    testWidgets('renders meetings list with meeting titles', (tester) async {
      final meetings = [
        _meeting(id: 'm1', title: 'Sprint Planning'),
        _meeting(id: 'm2', title: 'Architecture Review'),
      ];

      await tester.pumpWidget(
        _testWrap(
          const MeetingsScreen(),
          workspaceId: 'ws1',
          meetings: meetings,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sprint Planning'), findsOneWidget);
      expect(find.text('Architecture Review'), findsOneWidget);
    });

    testWidgets('renders empty state when no meetings', (tester) async {
      await tester.pumpWidget(
        _testWrap(
          const MeetingsScreen(),
          workspaceId: 'ws1',
          meetings: const [],
        ),
      );
      await tester.pumpAndSettle();

      // The never-recorded state, not the filtered-to-nothing one: the screen
      // distinguishes them and "no meetings match" would tell a first-time user
      // to adjust a filter they never set.
      expect(find.text('No meetings yet'), findsOneWidget);
    });

    testWidgets('groups the list by day bucket with a per-day count', (
      tester,
    ) async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      await tester.pumpWidget(
        _testWrap(
          const MeetingsScreen(),
          workspaceId: 'ws1',
          meetings: [
            _meeting(
              id: 'a',
              title: 'Standup',
              startedAt: today,
              endedAt: today,
            ),
            _meeting(id: 'b', title: 'Retro', startedAt: today, endedAt: today),
            _meeting(
              id: 'c',
              title: 'One-on-one',
              startedAt: yesterday,
              endedAt: yesterday,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Buckets that hold nothing render no header at all.
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Earlier this week'), findsNothing);
      // Each header carries its own count chip.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('a day section folds away and back', (tester) async {
      final today = DateTime.now();
      await tester.pumpWidget(
        _testWrap(
          const MeetingsScreen(),
          workspaceId: 'ws1',
          meetings: [
            _meeting(
              id: 'a',
              title: 'Standup',
              startedAt: today,
              endedAt: today,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Standup'), findsOneWidget);

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('Standup'), findsNothing);
      // The header — and its count chip — stay, so a folded day is still
      // legible. Scoped to the header row: the ledger above happens to render
      // the same "1" for its this-week total.
      expect(find.text('Today'), findsOneWidget);
      expect(
        find.descendant(
          of: find
              .ancestor(of: find.text('Today'), matching: find.byType(Row))
              .first,
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('Standup'), findsOneWidget);
    });

    testWidgets('shows no live strip while idle', (tester) async {
      await tester.pumpWidget(
        _testWrap(
          const MeetingsScreen(),
          workspaceId: 'ws1',
          meetings: [_meeting()],
        ),
      );
      await tester.pumpAndSettle();

      // The band the old permanent capture banner occupied costs nothing when
      // nothing is being captured.
      expect(find.byType(MeetingLiveStrip), findsNothing);
    });

    testWidgets('shows the live strip while recording', (tester) async {
      await tester.pumpWidget(
        _testWrap(
          const MeetingsScreen(),
          workspaceId: 'ws1',
          meetings: [_meeting()],
          recorderFactory: _RecordingRecorderNotifier.new,
        ),
      );
      // Pumps rather than pumpAndSettle: the strip's live dot pulses forever
      // by design, so settling would never return.
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(MeetingLiveStrip), findsOneWidget);
      // Stop keeps its label at every width, so it is the stable assertion.
      expect(find.text('Stop & summarize'), findsOneWidget);

      // Tear the screen down so the strip's 1s ticker does not outlive it.
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('MeetingsScreen responsive', () {
    // The window widths DESIGN.md asks every surface to survive. The test font
    // renders wider than the shipped one, so clearing these is a strictly
    // harder bar than the real UI faces.
    for (final width in [360.0, 768.0, 1024.0, 1280.0, 1920.0]) {
      // The recording strip is exercised from 768 up. Widget tests render in a
      // fixed-advance fallback font where every glyph is a full em box, so a
      // button label measures roughly twice its shipped width; at 360 that
      // pushes "Stop & summarize" past what any layout could hold and the case
      // would be measuring the test font, not the strip. The idle matrix still
      // covers 360.
      for (final recording in width >= 768 ? [false, true] : [false]) {
        testWidgets('lays out without overflow at ${width.toInt()}px'
            '${recording ? ' while recording' : ''}', (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final overflows = <String>[];
          final previousOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains(
              'A RenderFlex overflowed',
            )) {
              overflows.add(details.exceptionAsString().split('\n').first);
              return;
            }
            previousOnError?.call(details);
          };

          await tester.pumpWidget(
            _testWrap(
              const MeetingsScreen(),
              workspaceId: 'ws1',
              meetings: [
                _meeting(id: 'a', title: 'Sprint planning with a long title'),
                _meeting(id: 'b', title: 'Retro'),
              ],
              recorderFactory: recording
                  ? _RecordingRecorderNotifier.new
                  : null,
            ),
          );
          // The recording branch animates forever, so it is pumped rather
          // than settled.
          if (recording) {
            await tester.pump(const Duration(milliseconds: 16));
            await tester.pump(const Duration(milliseconds: 16));
          } else {
            await tester.pumpAndSettle();
          }
          FlutterError.onError = previousOnError;

          expect(overflows, isEmpty, reason: overflows.join('\n'));

          // Tear the tree down so the strip's 1s ticker does not outlive it.
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}

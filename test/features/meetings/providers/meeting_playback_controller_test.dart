import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeetingPlaybackController', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    // The reset on detach is deferred to an event-loop task (it can't mutate the
    // provider synchronously during widget-tree finalization). Flush it.
    Future<void> flush() => Future<void>(() {});

    test('starts in the default state', () {
      final container = makeContainer();
      expect(
        container.read(meetingPlaybackProvider),
        const MeetingPlaybackState(),
      );
    });

    test('seekToMs drives the attached handler and reports position', () async {
      final container = makeContainer();
      final controller = container.read(meetingPlaybackProvider.notifier);

      Duration? seeked;
      Future<void> seek(Duration position) async => seeked = position;
      controller.attach(seek);

      await controller.seekToMs(1500);

      expect(seeked, const Duration(milliseconds: 1500));
      expect(container.read(meetingPlaybackProvider).positionMs, 1500);
    });

    test('detach with the SAME handler clears it and resets the state',
        () async {
      final container = makeContainer();
      final controller = container.read(meetingPlaybackProvider.notifier);

      Duration? seeked;
      Future<void> seek(Duration position) async => seeked = position;
      controller
        ..attach(seek)
        ..report(playing: true, ready: true, positionMs: 4200);
      expect(container.read(meetingPlaybackProvider).playing, isTrue);

      controller.detach(seek);
      await flush();

      // State is back to default and the handler is gone, so seekToMs — which
      // the transcript still calls — no longer drives the disposed player.
      expect(
        container.read(meetingPlaybackProvider),
        const MeetingPlaybackState(),
      );
      seeked = null;
      await controller.seekToMs(900);
      expect(seeked, isNull);
    });

    test(
        'detach with a DIFFERENT handler is a no-op so the new player survives '
        'the switch-meetings handoff', () async {
      final container = makeContainer();
      final controller = container.read(meetingPlaybackProvider.notifier);

      Duration? newPlayerSeeked;
      Future<void> oldSeek(Duration position) async {}
      Future<void> newSeek(Duration position) async =>
          newPlayerSeeked = position;

      // The next player has already attached when the previous one disposes;
      // the stale detach must not clobber the new player's state/handler.
      controller
        ..attach(newSeek)
        ..report(ready: true, playing: true);
      controller.detach(oldSeek);
      await flush();

      expect(container.read(meetingPlaybackProvider).ready, isTrue);
      expect(container.read(meetingPlaybackProvider).playing, isTrue);
      await controller.seekToMs(700);
      expect(newPlayerSeeked, const Duration(milliseconds: 700));
    });
  });
}

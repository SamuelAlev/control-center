import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_domain/features/messaging/domain/ports/channel_turn_relay_port.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRelay implements ChannelTurnRelayPort {
  final StreamController<ChannelTurnEvent> controller =
      StreamController<ChannelTurnEvent>.broadcast();

  @override
  Stream<ChannelTurnEvent> watchChannelTurns(String channelId) =>
      controller.stream;

  /// Closes the broadcast controller so no sink leaks across tests.
  void dispose() => controller.close();
}

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  late _FakeRelay relay;
  late ProviderContainer container;

  setUp(() {
    relay = _FakeRelay();
    container = ProviderContainer(
      overrides: [channelTurnRelayPortProvider.overrideWithValue(relay)],
    );
  });

  tearDown(() {
    container.dispose();
    relay.dispose();
  });

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('TranscriptLruCache', () {
    test('evicts least-recently-used beyond capacity', () {
      final cache = TranscriptLruCache(capacity: 2);
      final seg = [TextSegment(text: 'x', startedAt: ts)];
      cache.put('a', seg);
      cache.put('b', seg);
      // Touch 'a' so 'b' becomes the LRU entry.
      expect(cache.get('a'), isNotNull);
      cache.put('c', seg);
      expect(cache.get('b'), isNull);
      expect(cache.get('a'), isNotNull);
      expect(cache.get('c'), isNotNull);
    });
  });

  group('channelTurnRelayProvider fold', () {
    test('seed frame registers active turns with their snapshots', () async {
      final sub = container.listen(channelTurnRelayProvider('c1'), (_, _) {});
      addTearDown(sub.close);
      final registry = container.read(activeStreamRegistryProvider);

      relay.controller.add(
        TurnRelaySeed([
          (
            messageId: 'm1',
            segments: [TextSegment(text: 'streamed so far', startedAt: ts)],
          ),
        ]),
      );
      await settle();

      expect(registry.isActive('m1'), isTrue);
      final snap = registry.snapshot('m1')!;
      expect((snap.single as TextSegment).text, 'streamed so far');
    });

    test('updates for an unknown turn register it on first contact', () async {
      final sub = container.listen(channelTurnRelayProvider('c1'), (_, _) {});
      addTearDown(sub.close);
      final registry = container.read(activeStreamRegistryProvider);

      relay.controller.add(const TurnRelaySeed([]));
      relay.controller.add(
        TurnRelayUpdates('m2', [
          SegmentOpened(0, TextSegment(text: '', startedAt: ts)),
          const SegmentDelta(0, 'hi'),
        ]),
      );
      await settle();

      expect(registry.isActive('m2'), isTrue);
      expect((registry.snapshot('m2')!.single as TextSegment).text, 'hi');
    });

    test(
      'TurnFinished caches the final snapshot BEFORE unregistering',
      () async {
        final sub = container.listen(channelTurnRelayProvider('c1'), (_, _) {});
        addTearDown(sub.close);
        final registry = container.read(activeStreamRegistryProvider);
        final cache = container.read(transcriptCacheProvider);

        relay.controller.add(
          TurnRelayUpdates('m1', [
            SegmentOpened(0, TextSegment(text: '', startedAt: ts)),
            const SegmentDelta(0, 'final answer'),
            SegmentClosed(
              0,
              TextSegment(text: 'final answer', startedAt: ts, durationMs: 9),
            ),
            const TurnFinished(0, TurnOutcome.completed),
          ]),
        );
        await settle();

        // The live turn ended…
        expect(registry.isActive('m1'), isFalse);
        // …but its transcript is already in the cache, so the bubble never
        // flashes empty between stream end and the lite list row landing.
        final cached = cache.get('m1');
        expect(cached, isNotNull);
        expect((cached!.single as TextSegment).text, 'final answer');
      },
    );

    test(
      'a reconnect seed drops owned turns that are no longer active',
      () async {
        final sub = container.listen(channelTurnRelayProvider('c1'), (_, _) {});
        addTearDown(sub.close);
        final registry = container.read(activeStreamRegistryProvider);

        relay.controller.add(
          TurnRelaySeed([
            (
              messageId: 'm1',
              segments: [TextSegment(text: 'a', startedAt: ts)],
            ),
          ]),
        );
        await settle();
        expect(registry.isActive('m1'), isTrue);

        // Reconnect: the authoritative seed carries only m2 now.
        relay.controller.add(
          TurnRelaySeed([
            (
              messageId: 'm2',
              segments: [TextSegment(text: 'b', startedAt: ts)],
            ),
          ]),
        );
        await settle();
        expect(registry.isActive('m1'), isFalse);
        expect(registry.isActive('m2'), isTrue);
      },
    );

    test('dispose unregisters the turns this fold owns', () async {
      final sub = container.listen(channelTurnRelayProvider('c1'), (_, _) {});
      final registry = container.read(activeStreamRegistryProvider);

      relay.controller.add(
        const TurnRelaySeed([
          (messageId: 'm1', segments: <TranscriptSegment>[]),
        ]),
      );
      await settle();
      expect(registry.isActive('m1'), isTrue);

      // The feed hides/closes: the autoDispose provider goes away and the
      // owned turn is dropped; a later re-watch re-seeds from the server.
      sub.close();
      await settle();
      expect(registry.isActive('m1'), isFalse);
    });
  });
}

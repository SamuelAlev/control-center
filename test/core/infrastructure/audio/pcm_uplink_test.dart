import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/infrastructure/audio/pcm_uplink.dart';
import 'package:flutter_test/flutter_test.dart';

/// A chunk of [length] bytes whose every byte is [fill], so batches can be
/// checked for capture order.
Uint8List _chunk(int length, [int fill = 0]) =>
    Uint8List(length)..fillRange(0, length, fill);

void main() {
  group('PcmUplink', () {
    test('coalesces small capture chunks into minimum-size batches', () async {
      final sent = <(int, int)>[];
      final uplink = PcmUplink(
        send: (seq, pcm) async => sent.add((seq, pcm.length)),
        minBatchBytes: 100,
        maxBatchBytes: 1000,
      );

      // 10 ms system-tap chunks at 16 kHz mono PCM16 are 320 bytes; use
      // smaller ones here so several are needed per batch.
      for (var i = 0; i < 9; i++) {
        uplink.add(_chunk(20));
      }
      await pumpEventQueue();
      expect(sent, [(0, 100)], reason: 'one batch once 100 bytes are pending');
      expect(uplink.pendingBytes, 80);

      await uplink.flush();
      expect(sent, [(0, 100), (1, 80)], reason: 'flush sends the short tail');
      expect(uplink.pendingBytes, 0);
    });

    test('audio arriving during a send joins the next batch', () async {
      final gate = Completer<void>();
      final sent = <int>[];
      final uplink = PcmUplink(
        send: (seq, pcm) async {
          sent.add(pcm.length);
          if (seq == 0) {
            await gate.future;
          }
        },
        minBatchBytes: 100,
        maxBatchBytes: 1000,
      );

      uplink.add(_chunk(100));
      await pumpEventQueue();
      for (var i = 0; i < 30; i++) {
        uplink.add(_chunk(10));
      }
      await pumpEventQueue();
      expect(sent, [100], reason: 'one call in flight at a time');

      gate.complete();
      await uplink.flush();
      expect(sent, [100, 300]);
    });

    test('caps one batch and keeps capture order across the split', () async {
      final batches = <Uint8List>[];
      final gate = Completer<void>();
      final uplink = PcmUplink(
        send: (seq, pcm) async {
          batches.add(Uint8List.fromList(pcm));
          if (seq == 0) {
            await gate.future;
          }
        },
        minBatchBytes: 100,
        maxBatchBytes: 200,
      );

      uplink.add(_chunk(100, 1));
      await pumpEventQueue();
      uplink
        ..add(_chunk(150, 2))
        ..add(_chunk(150, 3));
      gate.complete();
      await uplink.flush();

      expect(batches.map((b) => b.length), [100, 200, 100]);
      expect(batches[1].sublist(0, 150), everyElement(2));
      expect(batches[1].sublist(150), everyElement(3));
      expect(batches[2], everyElement(3));
    });

    test('keeps every byte while the host is unreachable', () async {
      var reachable = false;
      final delivered = BytesBuilder();
      final seqs = <int>[];
      final uplink = PcmUplink(
        send: (seq, pcm) async {
          if (!reachable) {
            throw TimeoutException('host unreachable');
          }
          seqs.add(seq);
          delivered.add(pcm);
        },
        isRetryable: (_) => true,
        minBatchBytes: 100,
        maxBatchBytes: 400,
        initialRetryDelay: const Duration(milliseconds: 1),
        maxRetryDelay: const Duration(milliseconds: 4),
      );

      for (var i = 0; i < 20; i++) {
        uplink.add(_chunk(50, i));
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      reachable = true;
      expect(await uplink.flush(), isTrue);

      final bytes = delivered.takeBytes();
      expect(bytes, hasLength(20 * 50), reason: 'nothing captured is dropped');
      for (var i = 0; i < 20; i++) {
        expect(bytes.sublist(i * 50, i * 50 + 50), everyElement(i));
      }
      expect(seqs, List.generate(seqs.length, (i) => i));
    });

    test('a retried batch keeps its seq and bytes', () async {
      final attempts = <(int, int)>[];
      var failures = 2;
      final uplink = PcmUplink(
        send: (seq, pcm) async {
          attempts.add((seq, pcm.length));
          if (failures-- > 0) {
            throw TimeoutException('lost answer');
          }
        },
        isRetryable: (_) => true,
        minBatchBytes: 100,
        maxBatchBytes: 1000,
        initialRetryDelay: const Duration(milliseconds: 1),
      );

      uplink.add(_chunk(100));
      expect(await uplink.flush(), isTrue);
      expect(attempts, [(0, 100), (0, 100), (0, 100)]);
    });

    test('a refusal that cannot succeed drops only that batch', () async {
      final errors = <(Object, bool)>[];
      final sent = <int>[];
      final uplink = PcmUplink(
        send: (seq, pcm) async {
          if (seq == 0) {
            throw StateError('no such session');
          }
          sent.add(seq);
        },
        isRetryable: (e) => e is! StateError,
        minBatchBytes: 100,
        maxBatchBytes: 1000,
        onError: (e, {required willRetry}) => errors.add((e, willRetry)),
      );

      uplink.add(_chunk(100));
      await pumpEventQueue();
      uplink.add(_chunk(100));
      await uplink.flush();

      expect(errors, hasLength(1));
      expect(errors.single.$2, isFalse);
      expect(sent, [1]);
      expect(uplink.batchesSent, 2);
    });

    test('flush with a timeout gives up and reports what is lost', () async {
      final lost = <int>[];
      final uplink = PcmUplink(
        send: (_, _) async => throw TimeoutException('host down'),
        isRetryable: (_) => true,
        minBatchBytes: 100,
        maxBatchBytes: 100,
        initialRetryDelay: const Duration(milliseconds: 1),
        onDrop: lost.add,
      );

      uplink
        ..add(_chunk(100))
        ..add(_chunk(60));
      final delivered = await uplink.flush(
        timeout: const Duration(milliseconds: 30),
      );

      expect(delivered, isFalse);
      expect(lost, [160], reason: 'the batch in flight plus the pending tail');
      uplink.add(_chunk(100));
      expect(
        uplink.pendingBytes,
        0,
        reason: 'no audio accepted after giving up',
      );
    });

    test('reports the backlog as it grows', () async {
      final gate = Completer<void>();
      final reports = <int>[];
      final uplink = PcmUplink(
        send: (seq, pcm) => seq == 0 ? gate.future : Future<void>.value(),
        minBatchBytes: 100,
        maxBatchBytes: 1000,
        backlogReportBytes: 200,
        onBacklog: reports.add,
      );

      uplink.add(_chunk(100));
      await pumpEventQueue();
      for (var i = 0; i < 5; i++) {
        uplink.add(_chunk(100));
      }
      expect(reports, [200, 400]);

      gate.complete();
      await uplink.flush();
    });

    test('flush with nothing pending completes at once', () async {
      var calls = 0;
      final uplink = PcmUplink(send: (_, _) async => calls++);
      await uplink.flush();
      expect(calls, 0);
    });
  });
}

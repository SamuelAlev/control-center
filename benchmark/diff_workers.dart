// Pure-Dart component benchmark of the production diff worker, not UI latency.
// Build with: fvm dart compile exe benchmark/diff_workers.dart -o /tmp/cc-diff-workers
// Run separate processes, interleaving counts: /tmp/cc-diff-workers 2 (then 4, 12).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:control_center/features/pr_review/presentation/utils/diff_worker_core.dart';
import 'package:isolate_manager/isolate_manager.dart';

Future<void> main(List<String> args) async {
  final count = args.length == 1 ? int.tryParse(args.single) : null;
  if (count == null || count < 1 || count > 32) {
    stderr.writeln('Usage: diff_workers <worker count: 1..32>');
    exitCode = 64;
    return;
  }
  const files = 64;
  const changes = 80;
  final patch = StringBuffer('@@ -1,$changes +1,$changes @@\n');
  for (var row = 0; row < changes; row++) {
    patch
      ..writeln('-final value$row = $row;')
      ..writeln('+final value$row = ${row + 1};');
  }
  final payload = jsonEncode(
    buildDiffJob(
      patch: patch.toString(),
      language: 'dart',
      dark: false,
      palette: const {'addition': 0xff008000, 'deletion': 0xff800000},
    ),
  );
  final manager = IsolateManager<String, String>.createCustom(
    diffWorker,
    workerName: 'diffWorker',
    concurrent: count,
  );
  var completed = 0;
  var coloredChunks = 0;
  Future<void> compute() async {
    var sawChangedText = false;
    await manager
        .compute(
          payload,
          callback: (encoded) {
            final event = jsonDecode(encoded) as Map<String, dynamic>;
            switch (event[DiffWire.type]) {
              case DiffWire.tok:
                sawChangedText |= (event[DiffWire.texts] as List)
                    .join()
                    .contains('final value79 = 80;');
                if ((event[DiffWire.colors] as List).any(
                  (color) => color != null,
                )) {
                  coloredChunks++;
                }
                return false;
              case DiffWire.done:
                if (!sawChangedText) {
                  throw StateError('Worker lost the last changed source line');
                }
                completed++;
                return true;
              case DiffWire.err:
                throw StateError('Worker failed: ${event[DiffWire.message]}');
              default:
                throw StateError('Unknown worker event: $event');
            }
          },
        )
        .timeout(const Duration(seconds: 30));
  }

  final rssBefore = ProcessInfo.currentRss;
  final cold = Stopwatch()..start();
  try {
    await compute();
    cold.stop();
    // Warm each worker before the measured burst. This is deliberately not
    // a Flutter first-frame or first-PR measurement; cold startup is separate.
    await Future.wait(List.generate(count, (_) => compute()));
    final rssWarm = ProcessInfo.currentRss;
    final gaps = <int>[];
    final burst = Stopwatch()..start();
    var lastTick = 0;
    final heartbeat = Timer.periodic(const Duration(milliseconds: 4), (_) {
      final now = burst.elapsedMicroseconds;
      gaps.add(now - lastTick);
      lastTick = now;
    });
    try {
      await Future.wait(List.generate(files, (_) => compute()));
    } finally {
      burst.stop();
      heartbeat.cancel();
    }
    if (completed != 1 + count + files || coloredChunks < completed) {
      throw StateError('Incomplete or uncolored worker results');
    }
    gaps.sort();
    int? percentile(double p) =>
        gaps.isEmpty ? null : gaps[((gaps.length - 1) * p).round()];
    stdout.writeln(
      jsonEncode({
        'scope': 'production diff worker; no Flutter rendering, RPC or agents',
        'workers': count,
        'files': files,
        'changed_rows_per_file': changes * 2,
        'cold_us': cold.elapsedMicroseconds,
        'burst_us': burst.elapsedMicroseconds,
        'rss_before_bytes': rssBefore,
        'rss_warm_bytes': rssWarm,
        'rss_after_bytes': ProcessInfo.currentRss,
        'heartbeat_requested_us': 4000,
        'heartbeat_samples': gaps.length,
        'heartbeat_gap_p50_us': percentile(0.5),
        'heartbeat_gap_p95_us': percentile(0.95),
        'heartbeat_gap_max_us': gaps.lastOrNull,
        'completed': completed,
      }),
    );
  } finally {
    await manager.stop();
  }
}

// Throwaway benchmark: cost of parsing a large PR's patches synchronously.
// Mirrors the unified viewer's eager-parse path (parseUnifiedDiff per file).
// ignore_for_file: avoid_print
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';

void main() {
  // ~52 files x ~256 added lines ≈ 13.3k lines, shaped like the recorded PR.
  final patches = List.generate(52, (f) {
    final b = StringBuffer('@@ -1,3 +1,259 @@\n');
    b.writeln(' import { inject, injectable } from "inversify";');
    b.writeln(' import type { IDatabase } from "#/lib/database";');
    for (var i = 0; i < 256; i++) {
      b.writeln(
        '+  const alert_$f$i = await repo.getByKey("metric_$i", { eq, count,'
        ' isNull }); // handles frequency window $i',
      );
    }
    b.writeln(' export const done = true;');
    return b.toString();
  });

  // Warmup for the JIT, then measure.
  for (var round = 0; round < 6; round++) {
    final sw = Stopwatch()..start();
    var lines = 0;
    for (final p in patches) {
      lines += parseUnifiedDiff(p).length;
    }
    sw.stop();
    print('round $round: ${sw.elapsedMilliseconds} ms for $lines lines');
  }
}

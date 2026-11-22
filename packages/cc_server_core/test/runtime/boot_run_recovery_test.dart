import 'dart:async';

import 'package:cc_server_core/src/runtime/boot_run_recovery.dart';
import 'package:test/test.dart';

void main() {
  test('nothing after the reap starts before the reap finished', () async {
    final order = <String>[];
    final reapGate = Completer<void>();

    final recovery = recoverRunsAtBoot(
      reapOrphans: (
        name: 'reap',
        run: () async {
          order.add('reap started');
          await reapGate.future;
          order.add('reap finished');
        },
      ),
      afterReap: [
        (name: 'pipelines', run: () async => order.add('pipelines')),
        (name: 'goals', run: () async => order.add('goals')),
      ],
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(order, ['reap started']);

    reapGate.complete();
    await recovery;

    expect(order.take(2), ['reap started', 'reap finished']);
    expect(order.skip(2), unorderedEquals(['pipelines', 'goals']));
  });

  test('a failed reap still lets recovery run, and one failed step stops '
      'no other', () async {
    final ran = <String>[];

    await recoverRunsAtBoot(
      reapOrphans: (name: 'reap', run: () async => throw StateError('db')),
      afterReap: [
        (name: 'pipelines', run: () async => throw StateError('stuck')),
        (name: 'goals', run: () async => ran.add('goals')),
      ],
    );

    expect(ran, ['goals']);
  });
}

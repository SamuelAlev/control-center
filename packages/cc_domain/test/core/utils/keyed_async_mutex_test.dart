import 'dart:async';

import 'package:cc_domain/core/utils/keyed_async_mutex.dart';
import 'package:test/test.dart';

void main() {
  test('serializes one key in FIFO order and frees it afterwards', () async {
    final mutex = KeyedAsyncMutex();
    final order = <String>[];
    final gate = Completer<void>();
    final first = mutex.run('k', () async {
      order.add('first:start');
      await gate.future;
      order.add('first:end');
    });
    final second = mutex.run('k', () async => order.add('second'));
    await Future<void>.delayed(Duration.zero);
    expect(order, ['first:start']);
    expect(mutex.isLocked('k'), isTrue);
    gate.complete();
    await Future.wait([first, second]);
    expect(order, ['first:start', 'first:end', 'second']);
    expect(mutex.isLocked('k'), isFalse);
  });

  test('different keys do not wait on each other', () async {
    final mutex = KeyedAsyncMutex();
    final gate = Completer<void>();
    final held = mutex.run('a', () => gate.future);
    expect(await mutex.run('b', () async => 42), 42);
    gate.complete();
    await held;
  });

  test('a throwing action still releases the key', () async {
    final mutex = KeyedAsyncMutex();
    await expectLater(
      mutex.run<void>('k', () async => throw StateError('boom')),
      throwsStateError,
    );
    expect(await mutex.run('k', () async => 'next'), 'next');
    expect(mutex.isLocked('k'), isFalse);
  });
}

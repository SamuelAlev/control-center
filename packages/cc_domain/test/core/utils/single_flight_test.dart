import 'dart:async';

import 'package:cc_domain/core/utils/single_flight.dart';
import 'package:test/test.dart';

void main() {
  test('concurrent callers share one flight', () async {
    final flights = SingleFlight<String, int>();
    var calls = 0;
    final gate = Completer<void>();
    Future<int> body() async {
      calls++;
      await gate.future;
      return 7;
    }

    final a = flights.run('k', body);
    final b = flights.run('k', body);
    expect(flights.isRunning('k'), isTrue);
    gate.complete();
    expect(await a, 7);
    expect(await b, 7);
    expect(calls, 1);
    expect(flights.isRunning('k'), isFalse);
  });

  test('a settled flight is forgotten so the next run loads again', () async {
    final flights = SingleFlight<String, int>();
    var calls = 0;
    await flights.run('k', () async => ++calls);
    await flights.run('k', () async => ++calls);
    expect(calls, 2);
  });

  test('a failing flight releases the key and surfaces the error', () async {
    final flights = SingleFlight<String, int>();
    await expectLater(
      flights.run('k', () async => throw StateError('x')),
      throwsStateError,
    );
    expect(flights.isRunning('k'), isFalse);
    expect(await flights.run('k', () async => 1), 1);
  });

  test('invalidate during a flight wins: no commit, next run is fresh', () async {
    final flights = SingleFlight<String, int>();
    final gate = Completer<void>();
    final committed = <int>[];
    final stale = flights.run('k', () async {
      await gate.future;
      return 1;
    }, commit: committed.add);
    flights.invalidate('k');
    final fresh = flights.run('k', () async => 2, commit: committed.add);
    gate.complete();
    expect(await stale, 1);
    expect(await fresh, 2);
    expect(committed, [2]);
  });

  test('keys never wait on each other', () async {
    final flights = SingleFlight<String, int>();
    final gate = Completer<void>();
    final slow = flights.run('a', () async {
      await gate.future;
      return 1;
    });
    expect(await flights.run('b', () async => 2), 2);
    gate.complete();
    expect(await slow, 1);
  });
}

import 'package:control_center/core/server/server_startup_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ValueNotifier<ServerStartupStatus?> status;
  late StartupReporter reporter;

  setUp(() {
    status = ValueNotifier(null);
    reporter = StartupReporter(status);
  });

  test('track reports the first phase, then ready', () async {
    final seen = <ServerStartupPhase?>[];
    status.addListener(() => seen.add(status.value?.phase));

    await reporter.track(ServerStartupPhase.starting, () async {
      reporter.advance(ServerStartupPhase.connecting);
      return 1;
    });

    expect(seen, [
      ServerStartupPhase.starting,
      ServerStartupPhase.connecting,
      ServerStartupPhase.ready,
    ]);
  });

  test('track reports the original error once and rethrows it', () async {
    final failure = StateError('boom');
    await expectLater(
      reporter.track(ServerStartupPhase.connecting, () async => throw failure),
      throwsA(same(failure)),
    );
    expect(status.value?.phase, ServerStartupPhase.failed);
    expect(status.value?.error, same(failure));
  });

  test('a lease stops writing once anything else reports', () {
    final lease = reporter.lease(ServerStartupPhase.starting);
    expect(lease.holds, isTrue);

    reporter.advance(ServerStartupPhase.connecting); // a remote switch
    lease.report(ServerStartupPhase.ready);

    expect(status.value?.phase, ServerStartupPhase.connecting);
    expect(lease.holds, isFalse);
    // Released for good: a later report is still a no-op.
    reporter.clear();
    lease.report(ServerStartupPhase.failed);
    expect(status.value, isNull);
  });

  test('a ready report releases the lease', () {
    final lease = reporter.lease(ServerStartupPhase.starting)
      ..report(ServerStartupPhase.ready);
    expect(status.value?.phase, ServerStartupPhase.ready);
    lease.report(ServerStartupPhase.failed);
    expect(status.value?.phase, ServerStartupPhase.ready);
  });
}

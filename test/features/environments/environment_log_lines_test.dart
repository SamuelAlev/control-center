import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'environment_test_support.dart';

void main() {
  test('a replayed tail is not shown twice', () async {
    final repository = FakeEnvironmentRepository()
      ..logLines = const [
        (line: 'one', seq: 1),
        (line: 'two', seq: 2),
        // A reconnect replays from the tail.
        (line: 'two', seq: 2),
        (line: 'three', seq: 3),
        (line: 'unnumbered', seq: null),
      ];
    final container = ProviderContainer(
      overrides: [environmentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    const key = (workspaceId: kWorkspace, spaceId: kSpace, target: 'stack');
    final subscription = container.listen(
      environmentLogLinesProvider(key),
      (_, _) {},
    );
    addTearDown(subscription.close);
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(subscription.read().value, ['one', 'two', 'three', 'unnumbered']);
    expect(repository.calls, ['watchLogs:stack']);
  });
}

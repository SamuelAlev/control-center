import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_server_core/src/pr_review/pr_space_provisioning.dart';
import 'package:test/test.dart';

/// The two reads the wait makes: one row, and the workspace's space stream.
class _Spaces implements MessagingRepository {
  Space? row;
  // Closed by the tear-down `_spaces()` registers.
  // ignore: close_sinks
  final StreamController<List<Space>> changes = StreamController.broadcast();

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async => row;

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Space _space(SpaceProvisioningStatus status) => Space(
  id: 's1',
  name: 'PR #7',
  workspaceId: 'ws',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  provisioningStatus: status,
);

_Spaces _spaces() {
  final spaces = _Spaces();
  addTearDown(spaces.changes.close);
  return spaces;
}

Future<void> _wait(_Spaces spaces, {Duration? timeout}) =>
    awaitPrSpaceProvisioning(
      messaging: spaces,
      workspaceId: 'ws',
      spaceId: 's1',
      prNumber: 7,
      timeout: timeout ?? const Duration(seconds: 5),
    );

void main() {
  test('a ready space returns at once', () async {
    final spaces = _spaces()..row = _space(SpaceProvisioningStatus.ready);
    await _wait(spaces);
  });

  test('a missing space is an error, not ready', () async {
    final spaces = _spaces();
    await expectLater(_wait(spaces), throwsStateError);
  });

  test('waits on the space stream until the checkout lands', () async {
    final spaces = _spaces()
      ..row = _space(SpaceProvisioningStatus.provisioning);
    var done = false;
    final wait = _wait(spaces).then((_) => done = true);
    await Future<void>.delayed(Duration.zero);
    spaces.changes.add([_space(SpaceProvisioningStatus.provisioning)]);
    await Future<void>.delayed(Duration.zero);
    expect(done, isFalse);
    spaces.changes.add([_space(SpaceProvisioningStatus.ready)]);
    await wait;
    expect(done, isTrue);
  });

  test('a failed checkout throws', () async {
    final spaces = _spaces()
      ..row = _space(SpaceProvisioningStatus.provisioning);
    final wait = _wait(spaces);
    await Future<void>.delayed(Duration.zero);
    spaces.changes.add([_space(SpaceProvisioningStatus.failed)]);
    await expectLater(wait, throwsStateError);
  });

  test('a space deleted mid-wait throws', () async {
    final spaces = _spaces()
      ..row = _space(SpaceProvisioningStatus.provisioning);
    final wait = _wait(spaces);
    await Future<void>.delayed(Duration.zero);
    spaces.changes.add(const []);
    await expectLater(wait, throwsStateError);
  });

  test('a checkout that never lands times out', () async {
    final spaces = _spaces()
      ..row = _space(SpaceProvisioningStatus.provisioning);
    await expectLater(
      _wait(spaces, timeout: const Duration(milliseconds: 20)),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
}

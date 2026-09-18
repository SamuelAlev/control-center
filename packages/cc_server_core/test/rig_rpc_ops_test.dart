import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/rig_rpc_ops.dart';
import 'package:test/test.dart';

void main() {
  const owner = 'owner';
  RepoOpContext context(String userId, Object? action) => RepoOpContext(
    args: {'action': action},
    workspaceId: null,
    deviceId: 'device',
    userId: userId,
  );

  void requireOwner(RepoOpContext context) {
    if (context.userId != owner) {
      throw StateError('owner required');
    }
  }

  test('declares global server-owner authority and both setup effects', () {
    final op = buildRigInstallBackendSetupOp(
      rigs: _RecordingRigPort(),
      requireServerAdmin: requireOwner,
    );
    expect(op.name, 'rig.installBackendSetup');
    expect(op.workspaceScoped, isFalse);
    expect(op.serverAuthority, ServerAuthority.serverOwner);
    expect(op.actionClasses, {
      ActionClass.networkEgress,
      ActionClass.packageInstall,
    });
    expect(op.requiredArgs, ['action']);
  });

  test('rejects a non-owner before delegating', () async {
    final rigs = _RecordingRigPort();
    final op = buildRigInstallBackendSetupOp(
      rigs: rigs,
      requireServerAdmin: requireOwner,
    );
    await expectLater(
      op.handler(context('member', 'ios-automation')),
      throwsStateError,
    );
    expect(rigs.installed, isEmpty);
  });

  test('validates the stable action wire and delegates it once', () async {
    final rigs = _RecordingRigPort();
    final op = buildRigInstallBackendSetupOp(
      rigs: rigs,
      requireServerAdmin: requireOwner,
    );
    expect(
      await op.handler(context(owner, 'ios-automation')),
      {'ok': true},
    );
    expect(rigs.installed, [RigBackendSetupAction.iosAutomation]);
    await expectLater(
      op.handler(context(owner, 'future-action')),
      throwsA(isA<Exception>()),
    );
  });
}

class _RecordingRigPort implements RigPort {
  final List<RigBackendSetupAction> installed = [];

  @override
  Future<void> installBackendSetup(RigBackendSetupAction action) async {
    installed.add(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

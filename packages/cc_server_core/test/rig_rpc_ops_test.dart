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

  test('declares global server-owner authority and both setup effects', () {
    final op = buildRigInstallBackendSetupOp(rigs: _RecordingRigPort());
    expect(op.name, 'rig.installBackendSetup');
    expect(op.workspaceScoped, isFalse);
    expect(op.serverAuthority, ServerAuthority.serverOwner);
    expect(op.actionClasses, {
      ActionClass.networkEgress,
      ActionClass.packageInstall,
    });
    expect(op.requiredArgs, ['action']);
  });

  test('the dispatcher refuses a non-owner before delegating', () async {
    final rigs = _RecordingRigPort();
    final dispatcher = RepoOpDispatcher(
      registry: RepoOpRegistry([buildRigInstallBackendSetupOp(rigs: rigs)]),
      resolveServerOwner: (userId) async => userId == owner,
    );
    final response = await dispatcher.call(
      id: 1,
      params: {
        'op': 'rig.installBackendSetup',
        'args': {'action': 'ios-automation'},
      },
      deviceId: 'device',
      userId: 'member',
      sessionCapability: SessionCapability.fullClient,
    );
    final error = response['error'] as Map;
    expect((error['data'] as Map)['kind'], 'server_owner_required');
    expect(rigs.installed, isEmpty);
  });

  test('validates the stable action wire and delegates it once', () async {
    final rigs = _RecordingRigPort();
    final op = buildRigInstallBackendSetupOp(rigs: rigs);
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

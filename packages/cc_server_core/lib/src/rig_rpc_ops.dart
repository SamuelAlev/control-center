import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';

/// Builds the global, owner-only pinned backend setup operation.
RepoOp buildRigInstallBackendSetupOp({
  required RigPort rigs,
  required void Function(RepoOpContext context) requireServerAdmin,
}) => RepoOp(
  name: 'rig.installBackendSetup',
  serverAuthority: ServerAuthority.serverOwner,
  kind: RepoOpKind.mutate,
  workspaceScoped: false,
  requiredArgs: const ['action'],
  actionClasses: const {
    ActionClass.networkEgress,
    ActionClass.packageInstall,
  },
  handler: (context) async {
    requireServerAdmin(context);
    final raw = context.args['action'];
    final action = raw is String ? RigBackendSetupAction.fromWire(raw) : null;
    if (action == null) {
      throw const ValidationException(
        'Missing or invalid argument: action (expected ios-automation)',
      );
    }
    await rigs.installBackendSetup(action);
    return const {'ok': true};
  },
);

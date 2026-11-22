import 'package:cc_domain/cc_domain.dart' show RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/code_mode/code_mode_rpc_ops.dart'
    show kCodeModeWorkspaceSettingKeys;

/// The workspace-scoped mirror of `prefs.*`: an opaque key/value space for
/// configuration two members of a workspace must agree on (branch naming,
/// agent/model defaults, default sandbox capabilities, data-sharing policy).
/// Previously these lived in device-local preferences, so two members — or
/// one member on two machines — disagreed about workspace policy.
///
/// Reads sit at `member` rather than the derived `guest` floor because the
/// set describes the workspace's security posture. Writes carry an EXPLICIT
/// admin floor: `kind: mutate` alone would derive `member` and any member
/// could then rewrite policy for everyone. Code mode's keys are not written
/// here: they go through `codeMode.setWorkspaceSetting`, which checks them.
///
/// Spread from `buildRemoteRpcCatalog` so the catalog freeze does not grow.
List<RepoOp> buildWorkspaceSettingsOps(
  WorkspaceSettingsRepository workspaceSettingsRepository,
) => [
  RepoOp(
    name: 'workspace_settings.getAll',
    kind: RepoOpKind.read,
    minRole: WorkspaceRole.member,
    handler: (ctx) async => {
      'settings': await workspaceSettingsRepository.getAll(ctx.workspaceId!),
    },
  ),
  RepoOp(
    name: 'workspace_settings.set',
    kind: RepoOpKind.mutate,
    minRole: WorkspaceRole.admin,
    requiredArgs: ['key'],
    handler: (ctx) async {
      final key = ctx.args['key'] as String;
      // Code mode's keys are checked before they are stored, which this
      // raw store cannot do: they go through `codeMode.setWorkspaceSetting`.
      if (kCodeModeWorkspaceSettingKeys.contains(key)) {
        throw ValidationException(
          '$key is written with codeMode.setWorkspaceSetting.',
          code: 'code_mode_setting_reserved',
        );
      }
      // Always the SESSION workspace — a client can never seed a setting
      // into a foreign workspace (isolation invariant).
      await workspaceSettingsRepository.set(
        ctx.workspaceId!,
        key,
        ctx.args['value'] as String?,
      );
      return {'ok': true};
    },
  ),
];

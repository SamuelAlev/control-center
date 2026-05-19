import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Workspace-scoped settings over RPC — the store for configuration two
/// members of a workspace must agree on.
///
/// Deliberately NOT mirrored into local preferences the way per-user settings
/// are. These are server-authoritative: read live so an admin's change reaches
/// every member without a reload and written through an admin-gated op.
final workspaceSettingsRepositoryProvider =
    Provider<WorkspaceSettingsRepository>(
      (ref) => RemoteWorkspaceSettingsRepository(ref.watch(rpcClientProvider)),
    );

/// The active workspace's settings, live. Empty while no workspace is active.
final workspaceSettingsProvider = StreamProvider<Map<String, String>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const {});
  }
  return ref.watch(workspaceSettingsRepositoryProvider).watchAll(workspaceId);
});

/// One workspace setting by key, or null while unset or still loading.
///
/// Reads through [workspaceSettingsProvider] rather than issuing its own call,
/// so N settings on one page cost one subscription.
final workspaceSettingProvider = Provider.family<String?, String>(
  (ref, key) => ref.watch(workspaceSettingsProvider).value?[key],
);

/// Writes one setting to the active workspace.
///
/// Server-gated on the admin role; a member's attempt is denied there even if
/// the calling UI forgot to hide the control.
Future<void> setWorkspaceSetting(
  WidgetRef ref,
  String key,
  String? value,
) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  await ref
      .read(workspaceSettingsRepositoryProvider)
      .set(workspaceId, key, value);
}

/// The workspace's branch-name template, falling back to the built-in default.
///
/// Workspace-scoped because it names branches in repositories every member
/// shares: two people must not generate differently-shaped branches for the
/// same kind of work. It was previously a device-local preference that, on top
/// of that, never reached the server-side code which actually creates the
/// branch — so it did nothing at all.
final workspaceBranchTemplateProvider = Provider<String?>(
  (ref) => ref.watch(workspaceSettingProvider(branchTemplateSettingKey)),
);

/// The `workspace_settings` key holding the branch-name template.
const String branchTemplateSettingKey = 'branch_template';

/// The `workspace_settings` key holding the workspace's custom meeting-note
/// templates (JSON array; the built-in presets are code, not data).
const String meetingTemplatesSettingKey = 'meeting_templates';

/// The `workspace_settings` key holding the id of the active meeting-note
/// template. Absent means the built-in default.
const String activeMeetingTemplateSettingKey = 'meeting_note_template';

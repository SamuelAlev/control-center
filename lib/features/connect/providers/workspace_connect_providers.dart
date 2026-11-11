import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/features/connect/domain/repositories/workspace_connect_repository.dart';
import 'package:cc_domain/features/connect/domain/value_objects/workspace_connect_status.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart'
    show invalidateForgeState;
import 'package:control_center/features/forge/providers/workspace_github_providers.dart';
import 'package:control_center/features/settings/providers/workspace_provider_apps_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

/// One workspace's Control Center Connect choice and health, or null on a
/// demo server (which has no Connect at all).
///
/// Every member may read it; the admin-only fields (install id, pending pins)
/// are simply absent for the rest. Errors surface as errors: a card that
/// could not read the choice must say so, not show a default.
final workspaceConnectStatusProvider =
    AsyncNotifierProvider.family<
      WorkspaceConnectStatusNotifier,
      WorkspaceConnectStatus?,
      String
    >(WorkspaceConnectStatusNotifier.new);

/// Reads and changes one workspace's Connect choice.
///
/// A mutation publishes the status the server returns, rather than a re-read
/// that may race it, and then drops everything that cached the old lane.
class WorkspaceConnectStatusNotifier
    extends AsyncNotifier<WorkspaceConnectStatus?> {
  /// Creates the notifier for [workspaceId].
  WorkspaceConnectStatusNotifier(this.workspaceId);

  /// The workspace whose choice this is.
  final String workspaceId;

  WorkspaceConnectRepository get _repo =>
      ref.read(workspaceConnectRepositoryProvider);

  @override
  Future<WorkspaceConnectStatus?> build() async {
    if (ref.watch(isDemoServerProvider)) {
      return null;
    }
    return ref.watch(workspaceConnectRepositoryProvider).status(workspaceId);
  }

  /// Switches the workspace to [mode] ([url] for a custom Connect).
  Future<WorkspaceConnectStatus> set(
    WorkspaceConnectMode mode, {
    String? url,
  }) => _apply(() => _repo.set(workspaceId, mode, url: url));

  /// Forces a configuration refresh for the workspace's Connect.
  Future<WorkspaceConnectStatus> test() =>
      _apply(() => _repo.test(workspaceId));

  /// Accepts the workspace's custom Connect's new signing pins.
  Future<WorkspaceConnectStatus> confirmPins() =>
      _apply(() => _repo.confirmPins(workspaceId));

  Future<WorkspaceConnectStatus> _apply(
    Future<WorkspaceConnectStatus> Function() op,
  ) async {
    final status = await op();
    state = AsyncData(status);
    invalidateWorkspaceLaneState(ref.invalidate, workspaceId);
    return status;
  }
}

/// Drops every client view that depends on which apps [workspaceId] runs on.
///
/// A choice change moves every person grant to another app, so who is signed
/// in to which forge, the sign-in lanes, the workspace's own-app forms, the
/// GitHub App installations, the calendar accounts and the chat bridges all
/// re-read. [invalidateForgeState] is the forge half, never a partial copy.
void invalidateWorkspaceLaneState(
  void Function(ProviderOrFamily) invalidate,
  String workspaceId,
) {
  invalidateForgeState(invalidate);
  invalidate(workspaceGitHubStatusProvider);
  invalidate(githubInstallationsProvider(workspaceId));
  invalidate(workspaceProviderAppsProvider);
  invalidate(googleAccountsProvider);
  invalidate(chatProvidersProvider);
}

/// Whose apps a workspace uses, for gating the own-app forms.
///
/// The Connect status is the authority (a mutation publishes it at once);
/// until it arrives, or where it cannot be read, the workspace entity's own
/// copy stands in.
final workspaceConnectModeProvider =
    Provider.family<WorkspaceConnectMode, String>((ref, workspaceId) {
      final status = ref.watch(workspaceConnectStatusProvider(workspaceId));
      if (status.value case final status?) {
        return status.mode;
      }
      final workspaces = ref.watch(workspacesProvider).value ?? const [];
      for (final workspace in workspaces) {
        if (workspace.id == workspaceId) {
          return workspace.connectMode;
        }
      }
      return WorkspaceConnectMode.inherit;
    });

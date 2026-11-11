import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/features/connect/domain/value_objects/workspace_connect_status.dart';

/// One workspace's Control Center Connect choice (`workspaceConnect.*`).
///
/// **Workspace invariant:** every call names its workspace. Reading the status
/// needs a member; every other call needs a workspace admin, and the server
/// refuses anyone else.
abstract interface class WorkspaceConnectRepository {
  /// The workspace's choice, what it resolves to and how it is doing.
  Future<WorkspaceConnectStatus> status(String workspaceId);

  /// Switches the workspace to [mode]; [url] names a custom Connect and is
  /// ignored otherwise. Returns the resulting status.
  Future<WorkspaceConnectStatus> set(
    String workspaceId,
    WorkspaceConnectMode mode, {
    String? url,
  });

  /// Forces a configuration refresh for the workspace's Connect.
  Future<WorkspaceConnectStatus> test(String workspaceId);

  /// Accepts the workspace's custom Connect's new signing pins.
  Future<WorkspaceConnectStatus> confirmPins(String workspaceId);
}

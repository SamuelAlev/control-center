import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unwraps the active workspace id, or throws.
///
/// Server-side, a workspace id selects which database file a read or write lands
/// in, so every workspace-scoped repository method requires one. On the client
/// there is exactly one authoritative source for it: the `:workspaceId` in the
/// current route, which `workspaceUrlSyncProvider` pushes into
/// [activeWorkspaceIdProvider]. That is the value threaded through here — not a
/// "current workspace" the client invented, but the one the URL names.
///
/// Throws when there is none. That only happens on the pre-context surfaces
/// (splash, onboarding, the workspace picker), which have no workspace-scoped
/// data to show — so reaching here without one is a routing bug and failing
/// loudly beats reading some other workspace's rows.
String _require(String? id) {
  if (id == null || id.isEmpty) {
    throw StateError(
      'No active workspace: workspace-scoped data was read outside a '
      '/workspaces/:workspaceId route',
    );
  }
  return id;
}

/// Reads the workspace a provider's workspace-scoped calls belong to.
extension ActiveWorkspaceScope on Ref {
  /// The active workspace id.
  ///
  /// Watched, so a provider rebuilds when the route moves to another workspace
  /// rather than continuing to serve the previous one's data.
  String requireWorkspaceId() => _require(watch(activeWorkspaceIdProvider));
}

/// The widget-tree counterpart of [ActiveWorkspaceScope], for `ConsumerWidget`
/// and `ConsumerState` callbacks that hold a [WidgetRef] rather than a [Ref].
extension ActiveWorkspaceWidgetScope on WidgetRef {
  /// The active workspace id.
  ///
  /// Read rather than watched: these calls sit in event handlers, where watching
  /// is not allowed and the value only has to be right when the handler runs.
  String requireWorkspaceId() => _require(read(activeWorkspaceIdProvider));
}

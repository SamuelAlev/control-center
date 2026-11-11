import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Re-provides the ambient [MediaProxyScope] for the active workspace, so a
/// private forge image (a PR body screenshot, a private avatar) is fetched
/// with the viewer's own sign-in in effect there, never a global one.
///
/// Without an ambient scope (no live connection) it adds nothing.
class WorkspaceMediaProxyScope extends ConsumerWidget {
  /// Creates a [WorkspaceMediaProxyScope].
  const WorkspaceMediaProxyScope({required this.child, super.key});

  /// The subtree that resolves media for the active workspace.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = MediaProxyScope.configOf(context);
    if (config == null) {
      return child;
    }
    return MediaProxyScope(
      config: config.forWorkspace(ref.watch(activeWorkspaceIdProvider)),
      child: child,
    );
  }
}

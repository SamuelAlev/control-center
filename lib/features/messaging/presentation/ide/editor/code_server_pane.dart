import 'package:control_center/features/messaging/presentation/ide/editor/code_server_window_pool.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_window_view.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';

/// Embedded code-server (VS Code in the browser) editor tab.
///
/// Where [CodeServerWindowPool.sharesWindows], the tab shows its worktree's
/// shared window from [pool] while it is the selected tab and holds nothing
/// while hidden (the window moves to whichever tab needs it). Elsewhere it
/// keeps a window of its own.
class CodeServerPane extends StatelessWidget {
  /// Creates a [CodeServerPane].
  const CodeServerPane({
    super.key,
    required this.spaceId,
    this.repoId,
    this.path,
    this.line,
    required this.tab,
    required this.pool,
  });

  /// The conversation whose isolated worktree code-server should open.
  final String spaceId;

  /// The repo whose worktree to open (null lets the server pick the first).
  final String? repoId;

  /// Optional file to open inside code-server.
  final String? path;

  /// Optional 1-based line to reveal in [path] (best-effort).
  final int? line;

  /// The tab this pane renders (the pool's ownership key).
  final EditorTab tab;

  /// The layout's window pool.
  final CodeServerWindowPool pool;

  @override
  Widget build(BuildContext context) {
    if (!CodeServerWindowPool.sharesWindows) {
      return CodeServerWindowView(
        request: CodeServerSessionRequest(
          spaceId: spaceId,
          repoId: repoId,
          path: path,
          line: line,
        ),
      );
    }
    return ListenableBuilder(
      listenable: pool,
      builder: (context, _) {
        final window = pool.windowOf(tab);
        if (window == null) {
          // Hidden, or shown before the pool caught up with the layout (a
          // restore, a PR worktree that just finished provisioning).
          pool.requestReconcile();
          return const CodeServerPreparing();
        }
        return codeServerWindowSlot(pool, window);
      },
    );
  }
}

/// Keeps a [CodeServerWindowPool]'s parked windows mounted, offstage, so a
/// switch back to their worktree reuses the running editor. Place one beside
/// the editor layout the pool follows.
class CodeServerWindowParking extends StatelessWidget {
  /// Creates a [CodeServerWindowParking].
  const CodeServerWindowParking({super.key, required this.pool});

  /// The pool whose parked windows to hold.
  final CodeServerWindowPool pool;

  @override
  Widget build(BuildContext context) {
    if (!CodeServerWindowPool.sharesWindows) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: pool,
      builder: (context, _) => Offstage(
        child: Stack(
          children: [
            for (final window in pool.parked)
              Positioned.fill(child: codeServerWindowSlot(pool, window)),
          ],
        ),
      ),
    );
  }
}

/// [window]'s view under its [CodeServerWindow.key], so the same element (and
/// platform view) moves between a pane and the parking slot.
@visibleForTesting
Widget codeServerWindowSlot(
  CodeServerWindowPool pool,
  CodeServerWindow window,
) => KeyedSubtree(
  key: window.key,
  child: CodeServerWindowView(
    request: window.request,
    onBooting: () => pool.windowBooting(window),
    onBridgeWindow: (id) => pool.bridgeReady(window, id),
  ),
);

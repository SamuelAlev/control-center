import 'package:flutter/widgets.dart';

/// Makes "open this run's activity" reachable from inside a transcript cell.
///
/// Tool renderers are pure `(BuildContext, ToolSegment) → Widget`, so a cell has
/// no callback of its own. Rather than widen every renderer's signature, the host
/// that knows how to open a tab installs this scope above the transcript and the
/// one cell that needs it (the `task` / subagent spawn) reads it through
/// `context`.
class RunActivityOpenerScope extends InheritedWidget {
  /// Creates a [RunActivityOpenerScope].
  const RunActivityOpenerScope({
    super.key,
    required this.workspaceId,
    required this.channelId,
    required this.openRun,
    required super.child,
  });

  /// The workspace the surrounding transcript belongs to.
  final String workspaceId;

  /// The conversation the surrounding transcript belongs to — scopes the
  /// tool-call → child-run lookup.
  final String channelId;

  /// Opens (or refocuses) the activity tab for `runId`.
  final void Function({required String runId, required String label}) openRun;

  /// The nearest scope, or null when the host installed none (then a cell simply
  /// stays non-interactive, as it was before).
  static RunActivityOpenerScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RunActivityOpenerScope>();

  @override
  bool updateShouldNotify(RunActivityOpenerScope oldWidget) =>
      oldWidget.workspaceId != workspaceId ||
      oldWidget.channelId != channelId ||
      oldWidget.openRun != openRun;
}

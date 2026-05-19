import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A read-mirror entry for one live terminal session in a conversation:
/// the session identity plus its current shell title (OSC 0/2 or the
/// server-polled foreground process). The title lets the General pane's
/// TERMINALS section show `claude` / `pnpm dev` instead of a generic
/// "Terminals" label.
class TerminalMirror {
  /// Creates a [TerminalMirror].
  const TerminalMirror({required this.session, this.title = ''});

  /// The terminal session identity (space, workspace, agent binding).
  final TerminalSession session;

  /// The shell's current title ('' = none yet).
  final String title;

  /// Convenience for the session id.
  String get sessionId => session.sessionId;
}

/// A read mirror of the live terminal sessions for one conversation.
///
/// Terminal lifecycle stays owned by the IDE layout (`_terminalSessions`); the
/// layout writes through to this provider whenever that map OR a shell title
/// changes, so the General pane's TERMINALS section can list them with their
/// live names without reaching into the layout's private state.
class SpaceTerminalsNotifier extends Notifier<List<TerminalMirror>> {
  /// Creates a [SpaceTerminalsNotifier] for [spaceId].
  SpaceTerminalsNotifier(this.spaceId);

  /// The conversation whose terminals this tracks.
  final String spaceId;

  @override
  List<TerminalMirror> build() => const [];

  /// Replaces the tracked sessions for this conversation.
  void set(List<TerminalMirror> sessions) => state = sessions;
}

/// Live terminal sessions for a conversation (space id), maintained by the
/// IDE layout.
final spaceTerminalsProvider =
    NotifierProvider.family<
      SpaceTerminalsNotifier,
      List<TerminalMirror>,
      String
    >(SpaceTerminalsNotifier.new);

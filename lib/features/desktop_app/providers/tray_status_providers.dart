import 'package:cc_rpc/cc_rpc.dart' show ServerConnectionPhase;
import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server connection, as the tray reports it.
enum TrayConnection {
  /// A live, healthy path.
  online,

  /// Connecting for the first time, or re-resolving a dropped path.
  connecting,

  /// Down until the operator acts (closed, rejected, identity mismatch).
  offline,
}

/// A space in which agents wait on the operator's answer.
@immutable
class TrayAttentionSpace {
  /// Creates a [TrayAttentionSpace].
  const TrayAttentionSpace({
    required this.spaceId,
    required this.name,
    required this.openQuestions,
  });

  /// The space.
  final String spaceId;

  /// Its display name; empty while the space list is still loading.
  final String name;

  /// How many agent questions there await an answer.
  final int openQuestions;

  @override
  bool operator ==(Object other) =>
      other is TrayAttentionSpace &&
      other.spaceId == spaceId &&
      other.name == name &&
      other.openQuestions == openQuestions;

  @override
  int get hashCode => Object.hash(spaceId, name, openQuestions);
}

/// Everything the tray icon and its menu say, for the active workspace.
///
/// Compared by value: the inputs re-emit on every message and run-output
/// stamp, and only a change of what the tray shows may reach the platform.
@immutable
class TrayStatus {
  /// Creates a [TrayStatus].
  const TrayStatus({
    required this.connection,
    this.workspaceId,
    this.attention = const [],
    this.approvals = 0,
    this.workingSpaces = 0,
  });

  /// The connection state.
  final TrayConnection connection;

  /// The workspace this describes, null before one is active.
  final String? workspaceId;

  /// Spaces with unanswered agent questions, most questions first.
  final List<TrayAttentionSpace> attention;

  /// Agent actions blocked on the operator's approval (host-wide).
  final int approvals;

  /// Visible spaces with an agent run in flight.
  final int workingSpaces;

  /// Unanswered questions across [attention].
  int get questions =>
      attention.fold(0, (sum, space) => sum + space.openQuestions);

  /// Everything waiting on the operator.
  int get needsYou => questions + approvals;

  /// The glyph variant this status calls for.
  TrayIconTone get tone => switch (connection) {
    TrayConnection.offline => TrayIconTone.offline,
    _ when needsYou > 0 => TrayIconTone.attention,
    _ => TrayIconTone.normal,
  };

  @override
  bool operator ==(Object other) =>
      other is TrayStatus &&
      other.connection == connection &&
      other.workspaceId == workspaceId &&
      listEquals(other.attention, attention) &&
      other.approvals == approvals &&
      other.workingSpaces == workingSpaces;

  @override
  int get hashCode => Object.hash(
    connection,
    workspaceId,
    Object.hashAll(attention),
    approvals,
    workingSpaces,
  );
}

/// Maps a connection phase onto [TrayConnection]; null (no supervisor, as in
/// tests) reads as online.
TrayConnection trayConnectionOf(ServerConnectionPhase? phase) =>
    switch (phase) {
      null || ServerConnectionPhase.connected => TrayConnection.online,
      ServerConnectionPhase.connecting ||
      ServerConnectionPhase.reconnecting => TrayConnection.connecting,
      _ => TrayConnection.offline,
    };

/// The connection, for the tray.
final trayConnectionProvider = Provider<TrayConnection>(
  (ref) => trayConnectionOf(
    ref.watch(serverConnectionStatusProvider.select((s) => s.value?.phase)),
  ),
);

/// Spaces of `workspaceId` with unanswered agent questions.
///
/// From the one workspace-wide activity subscription the sidebar already
/// holds, so the tray costs no per-space stream for it. Includes spaces the
/// sidebar hides (a pipeline run's): a question there still waits.
final trayAttentionSpacesProvider =
    Provider.family<List<TrayAttentionSpace>, String>((ref, workspaceId) {
      final activity =
          ref.watch(workspaceSpaceActivityProvider(workspaceId)).value ??
          const {};
      final waiting = [
        for (final entry in activity.values)
          if (entry.openQuestionCount > 0) entry,
      ];
      if (waiting.isEmpty) {
        return const [];
      }
      final spaces =
          ref.watch(workspaceSpacesProvider(workspaceId)).value ?? const [];
      final names = {for (final space in spaces) space.id: space.name};
      final result =
          [
            for (final entry in waiting)
              TrayAttentionSpace(
                spaceId: entry.spaceId,
                name: names[entry.spaceId] ?? '',
                openQuestions: entry.openQuestionCount,
              ),
          ]..sort((a, b) {
            final byCount = b.openQuestions.compareTo(a.openQuestions);
            return byCount != 0 ? byCount : a.name.compareTo(b.name);
          });
      return List.unmodifiable(result);
    });

/// How many of `workspaceId`'s visible spaces have an agent working.
///
/// One status watch per visible space: the same watches the sidebar keeps,
/// so with the main window open these share its subscriptions.
final trayWorkingSpaceCountProvider = Provider.family<int, String>((
  ref,
  workspaceId,
) {
  var working = 0;
  for (final space in ref.watch(workspaceVisibleSpacesProvider(workspaceId))) {
    if (ref.watch(spaceStatusProvider(space.id)) == SpaceStatus.running) {
      working++;
    }
  }
  return working;
});

/// The tray's whole status for the active workspace.
final trayStatusProvider = Provider<TrayStatus>((ref) {
  final connection = ref.watch(trayConnectionProvider);
  final approvals = ref.watch(
    pendingConfirmationsProvider.select((p) => p.value?.length ?? 0),
  );
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return TrayStatus(connection: connection, approvals: approvals);
  }
  return TrayStatus(
    connection: connection,
    workspaceId: workspaceId,
    attention: ref.watch(trayAttentionSpacesProvider(workspaceId)),
    approvals: approvals,
    workingSpaces: ref.watch(trayWorkingSpaceCountProvider(workspaceId)),
  );
});

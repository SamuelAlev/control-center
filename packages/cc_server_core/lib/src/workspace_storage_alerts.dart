import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';

/// Tells the server owner when a workspace's database turns read-only.
///
/// The database manager finds the damage (a failed `quick_check` on open)
/// and calls [report] once per process per workspace. The notice goes to the
/// server-global database, because the damaged file is the one place it
/// cannot be stored, and is raised at most once per workspace until a
/// restore closes it ([WorkspaceRestored]), so a server that restarts with
/// the same damaged file does not notify again. Workspace members see the
/// state as `storage_state` on the workspace summary; the finding itself is
/// for the owner alone.
class WorkspaceStorageAlerts {
  /// Creates the alerts over [_notices]. The log sink receives one line per
  /// newly raised notice.
  WorkspaceStorageAlerts(this._notices, {this._log, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ServerNoticeRepository _notices;
  final void Function(String message)? _log;
  final DateTime Function() _now;
  StreamSubscription<WorkspaceRestored>? _restored;
  final _changes = StreamController<String>.broadcast();

  /// The id of each workspace whose storage state just changed: it turned
  /// read-only, or a restore made it writable again.
  ///
  /// The state is not a column of the workspace's row, so the workspace
  /// list does not move when it flips; whoever renders `storage_state`
  /// renders again on this.
  Stream<String> get changes => _changes.stream;

  /// Records that [workspaceId]'s database failed its integrity check with
  /// SQLite's [finding]. Returns whether this call raised a new notice.
  Future<bool> report(String workspaceId, String finding) async {
    final bool raised;
    try {
      raised = await _notices.raise(
        ServerNotice(
          kind: ServerNoticeKind.workspaceReadOnly,
          subject: workspaceId,
          detail: finding,
          createdAt: _now(),
        ),
      );
    } finally {
      // Members are told whether or not the owner's notice could be stored.
      _signal(workspaceId);
    }
    if (raised) {
      _log?.call(
        'workspace $workspaceId is read-only: its database failed an '
        'integrity check ($finding); restore it from a snapshot',
      );
    }
    return raised;
  }

  /// Closes a workspace's notice when it is restored. Call once.
  void listen(DomainEventBus bus) {
    _restored ??= bus.on<WorkspaceRestored>().listen((event) {
      _signal(event.workspaceId);
      unawaited(
        _notices.resolve(ServerNoticeKind.workspaceReadOnly, event.workspaceId),
      );
    });
  }

  void _signal(String workspaceId) {
    if (!_changes.isClosed) {
      _changes.add(workspaceId);
    }
  }

  /// Stops listening for restores and ends [changes].
  Future<void> dispose() async {
    await _restored?.cancel();
    _restored = null;
    await _changes.close();
  }
}

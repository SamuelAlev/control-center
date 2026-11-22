import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart'
    show CrossWorkspaceQueries, WorkspaceDatabase, WorkspaceDatabaseManager;

/// Finishes the code executions a restart ended (one workspace).
///
/// A script runs only inside the server process that admitted it, so a
/// record still `running` when a server starts belonged to a process that
/// died with it. Such a record is finished the way an orphaned run is: with
/// the closest terminal status (`sandbox_error`), the fixed error kind
/// `server_stopped` and the time from its start to now as its duration. Its
/// call rows stay as they were appended.
///
/// Every running record is finished, whatever its start time says (a clock
/// that stepped back must not leave one running). The server admits no
/// script of a workspace until this has succeeded there
/// ([OrphanedExecutionSweeps]), so it never finishes a live one.
Future<int> sweepOrphanedExecutionsIn(WorkspaceDatabase db) =>
    db.codeModeDao.finishAllRunning(
      nowMs: DateTime.now().millisecondsSinceEpoch,
      status: CodeExecutionStatus.sandboxError.wire,
      errorKind: CodeExecutionErrorKind.serverStopped,
    );

/// The boot sweep of code execution records, and what admission waits for:
/// no script of a workspace is admitted until a sweep of that workspace has
/// succeeded in this process.
///
/// [sweepAll] sweeps every workspace once, at boot. A workspace it did not
/// sweep (its sweep threw, it was skipped as read-only, or it was added
/// later) is swept on the first admission in it, one sweep at a time per
/// workspace; while that fails, each attempt retries it and each script is
/// refused with a reason the server owner can act on, logged once until a
/// sweep of that workspace succeeds. A workspace's scripts are admitted
/// only after its sweep, so a sweep never finishes a live record of this
/// process.
class OrphanedExecutionSweeps {
  /// Creates the sweeps over every workspace's database; `sweepIn` sweeps
  /// one workspace (tests make it fail).
  OrphanedExecutionSweeps({
    required this._crossWorkspace,
    required this._workspaceDbs,
    this._sweepIn = sweepOrphanedExecutionsIn,
  });

  final CrossWorkspaceQueries _crossWorkspace;
  final WorkspaceDatabaseManager _workspaceDbs;
  final Future<int> Function(WorkspaceDatabase db) _sweepIn;
  final Completer<void> _booted = Completer<void>();
  final Set<String> _swept = {};
  final Map<String, Future<String?>> _sweeping = {};
  final Set<String> _refusing = {};
  bool _started = false;
  void Function(String line) _announce = CcHostLog.info;

  /// Why a script of a workspace whose sweep keeps failing is refused.
  static const String refusal =
      'the records of scripts a previous server process left running in '
      'this workspace could not be closed, so no script runs in it until '
      'they are. The server owner finds why in the server log '
      '(orphaned-execution sweep); the next script retries.';

  /// Sweeps every workspace once, then lets admission go on; later calls do
  /// nothing. When it closed records it gives [announce] one line saying how
  /// many, in how many workspaces; nothing when there were none.
  ///
  /// CROSS-WORKSPACE BY DESIGN: a boot reconciler, like the orphaned-wait
  /// sweep. Each workspace's rows are written in that workspace's own
  /// database.
  Future<void> sweepAll({required void Function(String line) announce}) async {
    if (_started) {
      return;
    }
    _started = true;
    _announce = announce;
    var finished = 0;
    var workspaces = 0;
    try {
      await _crossWorkspace.forEachWorkspace(
        (db) async {
          final closed = await _sweepIn(db);
          _swept.add(db.workspaceId);
          if (closed > 0) {
            finished += closed;
            workspaces++;
          }
        },
        onError: (workspaceId, error) => CcHostLog.warning(
          'orphaned-execution sweep failed for workspace $workspaceId: '
          '$error; its scripts wait for a sweep that succeeds',
        ),
        backgroundWriter: 'orphaned-execution sweep',
      );
    } on Object catch (e, st) {
      CcHostLog.error('orphaned-execution sweep failed: $e', e, st);
    } finally {
      _booted.complete();
    }
    if (finished > 0) {
      announce(
        'cc_server: closed $finished code mode script record(s) a previous '
        'server process left running, in $workspaces workspace(s) '
        '(sandbox_error/server_stopped)',
      );
    }
  }

  /// Whether scripts of [workspaceId] may be admitted: null once its sweep
  /// has succeeded, else [refusal]. Waits for [sweepAll] first; the caller
  /// bounds the wait.
  Future<String?> admit(String workspaceId) async {
    await _booted.future;
    if (_swept.contains(workspaceId)) {
      return null;
    }
    // The callback returns nothing: whenComplete would wait for a future
    // it returned, and the removed entry is this very future.
    return _sweeping[workspaceId] ??= _sweepOne(workspaceId).whenComplete(() {
      _sweeping.remove(workspaceId);
    });
  }

  Future<String?> _sweepOne(String workspaceId) async {
    try {
      final finished = await _sweepIn(_workspaceDbs.of(workspaceId));
      _swept.add(workspaceId);
      _refusing.remove(workspaceId);
      if (finished > 0) {
        _announce(
          'cc_server: closed $finished code mode script record(s) a previous '
          'server process left running, in workspace $workspaceId, before '
          'its first script (sandbox_error/server_stopped)',
        );
      }
      return null;
    } on Object catch (e) {
      if (_refusing.add(workspaceId)) {
        CcHostLog.warning(
          'orphaned-execution sweep failed again for workspace '
          '$workspaceId: $e; its scripts are refused (audit_unavailable) '
          'until a sweep succeeds',
        );
      }
      return refusal;
    }
  }
}

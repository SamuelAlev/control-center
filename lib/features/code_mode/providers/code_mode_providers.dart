import 'package:cc_domain/cc_domain.dart' show CodeModeStatusDto;
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/code_mode/providers/running_script_watch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the server runs scripts, its caps and the limits a script in a
/// workspace runs under, as the server reports it (`codeMode.status`), by
/// workspace id.
///
/// Errors surface as errors: a settings card that could not read the status
/// must say so rather than show code mode as unavailable.
final codeModeStatusProvider = FutureProvider.autoDispose
    .family<CodeModeStatusDto, String>(
      (ref, workspaceId) =>
          ref.watch(codeModeRepositoryProvider).status(workspaceId),
    );

/// The writes behind the code mode settings of one workspace.
///
/// Every write is `codeMode.setWorkspaceSetting` (the generic workspace
/// settings write refuses its key) and re-reads the status afterwards.
final codeModeSettingsControllerProvider =
    Provider.family<CodeModeSettingsController, String>(
      CodeModeSettingsController.new,
    );

/// Changes one workspace's code mode limits. Needs a workspace admin; the
/// server refuses anyone else.
class CodeModeSettingsController {
  /// Creates the controller for [workspaceId].
  CodeModeSettingsController(this._ref, this.workspaceId);

  final Ref _ref;

  /// The workspace these writes go to.
  final String workspaceId;

  /// Stores [overrides] (limit key to value, only those that differ from the
  /// defaults), or clears them back to the defaults when empty.
  Future<void> setLimits(Map<String, int> overrides) async {
    await _ref
        .read(codeModeRepositoryProvider)
        .setWorkspaceLimits(workspaceId, overrides.isEmpty ? null : overrides);
    _ref.invalidate(codeModeStatusProvider);
  }
}

/// One execution to open: its workspace and its opaque id.
typedef CodeExecutionKey = ({String workspaceId, String executionId});

/// One execution with its source, output and nested calls, or null when the
/// workspace has none with that id.
///
/// A record in a space the caller may not read is refused by the server; the
/// refusal is this provider's error, for the page to word by its kind.
///
/// While the script is still running the record is read again each time its
/// run's transcript shows it move on ([watchRunningScript]), so the page
/// fills in its calls and then its outcome without being reopened. The
/// previous record stays on screen while the next is read.
final codeExecutionDetailProvider = FutureProvider.autoDispose
    .family<CodeExecutionDetail?, CodeExecutionKey>((ref, key) async {
      final detail = await ref
          .watch(codeModeRepositoryProvider)
          .getExecution(key.workspaceId, key.executionId);
      final execution = detail?.execution;
      if (execution != null &&
          execution.status == CodeExecutionStatus.running) {
        watchRunningScript(
          ref,
          workspaceId: key.workspaceId,
          runId: execution.runId,
          toolCallId: execution.toolCallId,
          onProgress: ref.invalidateSelf,
        );
      }
      return detail;
    });

/// A `repl` call to find the record of: the call's id, when its row says it
/// started, and the run or the conversation it was made in (at least one).
typedef CodeExecutionCallKey = ({
  String workspaceId,
  String? runId,
  String? conversationId,
  String toolCallId,
  DateTime startedAt,
});

/// The id of the record the `repl` call [key] left, or null when none is
/// found: one `codeMode.listExecutions` request, asked when the person
/// presses "Open record" and never while a transcript renders.
///
/// The row knows its call id and the run or conversation around it, not the
/// record's id (the server may have suffixed it). Call ids repeat (local
/// models reuse `call_0`), so the query is narrowed to the call id within that
/// run (else that conversation) and, among several matches, the record whose
/// start is nearest the row's own start is the row's. A record starts when
/// the host admits the script, moments after the row; only records that
/// started within [_matchWindow] of the row's start, on either side, are
/// read, so neither a long run's later repeats nor its earlier ones can crowd
/// the row's own record out of the one page. No further page is read.
///
/// [listExecutions] is the repository's read (`codeModeRepositoryProvider`).
Future<String?> findCodeExecutionForCall(
  Future<CodeExecutionPage> Function(String workspaceId, CodeExecutionQuery)
  listExecutions,
  CodeExecutionCallKey key,
) async {
  if (key.runId == null && key.conversationId == null) {
    return null;
  }
  final page = await listExecutions(
    key.workspaceId,
    CodeExecutionQuery(
      limit: CodeExecutionQuery.maxLimit,
      runId: key.runId,
      conversationId: key.runId == null ? key.conversationId : null,
      toolCallId: key.toolCallId,
      since: key.startedAt.subtract(_matchWindow),
      until: key.startedAt.add(_matchWindow),
    ),
  );
  CodeExecution? nearest;
  Duration? nearestGap;
  for (final execution in page.items) {
    if (execution.toolCallId != key.toolCallId) {
      continue;
    }
    final gap = execution.startedAt.difference(key.startedAt).abs();
    if (nearestGap == null || gap < nearestGap) {
      nearest = execution;
      nearestGap = gap;
    }
  }
  return nearest?.id;
}

/// How long before or after its row's start a script's record may start and
/// still be read as the row's: generous, because the row's clock and the host's may
/// differ (a fleet worker), and the nearest start decides among matches.
const Duration _matchWindow = Duration(minutes: 10);

/// Whether the record a key names exists and the caller may read it: the
/// gate on an "open record" link from an approval or a question a script
/// raised. The record is written when the host admits the script, so a
/// script waiting on the answer already has one; a Python `eval` cell never
/// does, and its origin names no execution to ask about.
final codeExecutionResolvesProvider = FutureProvider.autoDispose
    .family<bool, CodeExecutionKey>((ref, key) async {
      // Asked directly rather than through the detail provider, so a refusal
      // answers false at once instead of waiting out that provider's retries.
      final repo = ref.watch(codeModeRepositoryProvider);
      try {
        return await repo.getExecution(key.workspaceId, key.executionId) !=
            null;
      } on Object {
        return false;
      }
    });

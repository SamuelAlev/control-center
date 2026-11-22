import 'package:cc_domain/features/messaging/domain/ports/conversation_transcript_port.dart';
import 'package:cc_harness/context.dart'
    show ToolOutputEntry, ToolOutputReadResult;

/// What one run's scripts read of the run's past (`history`, `outputs`,
/// `loadOutput`) and where they keep large values (`keep`).
///
/// The surface binds one to each run, from the run itself: the workspace,
/// the conversation, the run, the output store's scope and the person the
/// run acts for are never taken from a script's arguments. A main run reads
/// its conversation's transcript and the outputs stored for its
/// conversation and agent; a subagent reads its own run only (its turns and
/// the outputs it stored itself), never its parent's.
///
/// Every method answers for the bound run or throws [ScriptPastRefusal]
/// with a sentence the script is told. The host bounds what a script and a
/// run read in total ([usage]) and what one call returns.
abstract interface class ScriptPastPort {
  /// At most [limit] rows of the run's transcript from [start] (null for
  /// the first, or a page's `next_start`), oldest first, as
  /// [ConversationTranscriptPort.page] (or `pageRun` for a subagent).
  Future<TranscriptPage> history({
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  });

  /// More of one row [history] returned cut, from [offset]; null when the
  /// row is not in the run's transcript or [offset] is past its end.
  Future<TranscriptSlice?> historyRow({
    required String rowId,
    required int offset,
  });

  /// The outputs the run may read, newest first ([ToolOutputEntry]).
  Future<List<ToolOutputEntry>> outputs();

  /// At most [limit] characters of output [handle] from [offset], when it
  /// is one the run may read: a handle of another scope, or (for a
  /// subagent) of another run, is not found.
  Future<ToolOutputReadResult> readOutput(
    String handle, {
    required int offset,
    required int limit,
  });

  /// Stores [content] under [handle] (minted by the host) with [label] for
  /// the run's later scripts. False when the store declined it.
  Future<bool> keep({
    required String handle,
    required String label,
    required String content,
  });

  /// Why the run has no outputs to read and nowhere to keep a value (it
  /// has no output store), in a sentence for the script; null when it has
  /// one. `keep()` asks it before handing out a handle, so a value is never
  /// promised that could not be saved.
  String? get noOutputs;

  /// What every script of the run has read and kept so far.
  ScriptPastUsage get usage;
}

/// Why a read of the run's past is refused, in a sentence for the script.
class ScriptPastRefusal implements Exception {
  /// Creates a refusal.
  const ScriptPastRefusal(this.message);

  /// What the script is told.
  final String message;

  @override
  String toString() => message;
}

/// What one run's scripts have read of its past and kept, counted by the
/// host against `CodeModeLimits.maxPastReadBytesPerRun`,
/// `maxKeepsPerRun` and `maxKeptBytesPerRun`.
class ScriptPastUsage {
  /// UTF-8 bytes of text the run's past reads returned.
  int readBytes = 0;

  /// Values the run's scripts kept (committed).
  int keeps = 0;

  /// UTF-8 bytes the run's scripts kept (committed).
  int keptBytes = 0;
}

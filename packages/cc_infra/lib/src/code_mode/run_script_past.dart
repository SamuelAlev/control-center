import 'dart:collection';

import 'package:cc_domain/features/code_mode/domain/ports/script_past_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/conversation_transcript_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/transcript_store.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/messaging/conversation_transcript_reader.dart';

/// The spaces of a workspace the run calling from `callerConversationId` may
/// not read (the server's `AgentSpaceVisibility.hiddenFor`, the rule
/// `get_messages` applies).
typedef ScriptHiddenSpaces =
    Future<Set<String>> Function({
      required String workspaceId,
      required String? callerConversationId,
    });

/// What the server gives every run's [ScriptPastPort]: the transcripts and
/// the space rule. The dispatch session binds one port to each run with
/// [forRun] or [forSubagent], from the run itself.
class ScriptPastSources {
  /// Creates the sources over a transcript reader.
  ScriptPastSources({required this.transcripts, required this.hiddenSpaces});

  /// The sources over the server's stored transcripts.
  factory ScriptPastSources.over(
    TranscriptStore store,
    ScriptHiddenSpaces hiddenSpaces,
  ) => ScriptPastSources(
    transcripts: ConversationTranscriptReader(store),
    hiddenSpaces: hiddenSpaces,
  );

  /// Conversation and run transcripts.
  final ConversationTranscriptPort transcripts;

  /// The space rule.
  final ScriptHiddenSpaces hiddenSpaces;

  /// The port of a main run: its conversation's transcript and the outputs
  /// [store] holds for its conversation and agent ([scope]).
  ScriptPastPort forRun({
    required String workspaceId,
    required String? conversationId,
    required String? spaceId,
    required ToolOutputStore? store,
    required ToolOutputScope? scope,
  }) => RunScriptPast(
    sources: this,
    workspaceId: workspaceId,
    conversationId: conversationId,
    spaceId: spaceId,
    subagentRunId: null,
    store: store,
    scope: scope,
    ledger: null,
    noOutputs: RunScriptPast.noOutputStore,
  );

  /// The port of a run on the MCP endpoint (Claude Code, ACP), bound from its
  /// attested scope: its conversation's transcript. That endpoint keeps no
  /// tool outputs of the run (the agent keeps its own), so outputs(),
  /// loadOutput() and keep() refuse with [RunScriptPast.noOutputStoreMcp]. A
  /// subagent there is the agent's own and calls under its parent run's
  /// scope, so it reads what that run reads; a run whose conversation slot
  /// holds its own dispatch id passes a null [conversationId] and reads
  /// nothing.
  ScriptPastPort forMcpRun({
    required String workspaceId,
    required String? conversationId,
    required String? spaceId,
  }) => RunScriptPast(
    sources: this,
    workspaceId: workspaceId,
    conversationId: conversationId,
    spaceId: spaceId,
    subagentRunId: null,
    store: null,
    scope: null,
    ledger: null,
    noOutputs: RunScriptPast.noOutputStoreMcp,
  );

  /// The port of subagent run [runId]: its own transcript, and only the
  /// outputs its own run stored ([ledger]), though they share its parent's
  /// store scope.
  ScriptPastPort forSubagent({
    required String workspaceId,
    required String runId,
    required String? conversationId,
    required String? spaceId,
    required ToolOutputStore? store,
    required ToolOutputScope? scope,
    required RunOutputLedger ledger,
  }) => RunScriptPast(
    sources: this,
    workspaceId: workspaceId,
    conversationId: conversationId,
    spaceId: spaceId,
    subagentRunId: runId,
    store: store,
    scope: scope,
    ledger: ledger,
    noOutputs: RunScriptPast.noOutputStore,
  );
}

/// The handles one run stored, so a subagent (whose outputs share its
/// parent's store scope) reads only its own: [over] records every handle a
/// write through it was given.
class RunOutputLedger {
  final Set<String> _handles = {};

  /// Whether this run stored [handle].
  bool contains(String handle) => _handles.contains(handle);

  /// Records [handle] as this run's.
  void add(String handle) => _handles.add(handle);

  /// [store] with every successful write recorded here; null for null.
  ToolOutputStore? over(ToolOutputStore? store) =>
      store == null ? null : _LedgeredStore(store, this);

  /// [sink] (a `repl` result's full-output sink) with the handle of every
  /// output it stores recorded here; null for null.
  Future<ToolOutputReference?> Function(String text)? recording(
    Future<ToolOutputReference?> Function(String text)? sink,
  ) => sink == null
      ? null
      : (text) async {
          final reference = await sink(text);
          if (reference != null) {
            add(reference.handle);
          }
          return reference;
        };
}

class _LedgeredStore implements ToolOutputStore {
  _LedgeredStore(this._inner, this._ledger);

  final ToolOutputStore _inner;
  final RunOutputLedger _ledger;

  @override
  Future<ToolOutputReference?> put(ToolOutputWrite write) async {
    final reference = await _inner.put(write);
    if (reference != null) {
      _ledger.add(reference.handle);
    }
    return reference;
  }

  @override
  Future<ToolOutputReadResult> read(
    ToolOutputScope scope,
    String handle, {
    int offsetChars = 0,
    int limitChars = kToolOutputReadDefaultChars,
  }) => _inner.read(
    scope,
    handle,
    offsetChars: offsetChars,
    limitChars: limitChars,
  );

  @override
  Future<List<ToolOutputEntry>> list(ToolOutputScope scope) =>
      _inner.list(scope);

  @override
  Future<void> clearScope(ToolOutputScope scope) => _inner.clearScope(scope);

  @override
  Future<void> clearConversation(ToolOutputScope scope) =>
      _inner.clearConversation(scope);
}

/// One run's [ScriptPastPort]. Everything it reads is named by the
/// constructor, which the dispatch session fills from the run: the
/// workspace, the conversation, the space, the subagent run, the output
/// scope. A script's arguments only choose a page within that.
class RunScriptPast implements ScriptPastPort {
  /// Creates the port of one run.
  RunScriptPast({
    required this._sources,
    required this._workspaceId,
    required String? conversationId,
    required String? spaceId,
    required String? subagentRunId,
    required this._store,
    required this._scope,
    required this._ledger,
    required this._noOutputs,
  }) : _conversationId = _real(conversationId),
       _spaceId = _real(spaceId),
       _subagentRunId = _real(subagentRunId);

  final ScriptPastSources _sources;
  final String _workspaceId;
  final String? _conversationId;
  final String? _spaceId;
  final String? _subagentRunId;
  final ToolOutputStore? _store;
  final ToolOutputScope? _scope;
  final RunOutputLedger? _ledger;
  final String _noOutputs;

  @override
  final ScriptPastUsage usage = ScriptPastUsage();

  static String? _real(String? id) => id == null || id.isEmpty ? null : id;

  /// Why the run may not read its space's conversation (the person it acts
  /// for cannot read the space), as `get_messages` refuses it.
  static const String hiddenSpace =
      'The person this run acts for cannot read this space: it reviews a '
      'pull request or exposes a repository they cannot read, so its '
      'transcript and outputs are not readable here.';

  /// Why outputs(), loadOutput() and keep() refuse in a run with no output
  /// store.
  static const String noOutputStore =
      'This run keeps no tool outputs, so outputs(), loadOutput() and '
      'keep() have nothing to read or write.';

  /// [noOutputStore] on the MCP endpoint, which stores no tool output of
  /// the run.
  static const String noOutputStoreMcp =
      'Control Center keeps no tool outputs of this run (its agent keeps '
      'its own), so outputs(), loadOutput() and keep() have nothing to read '
      'or write here. Return what you need from this script, keep a small '
      'value for a later script with store() (not in a read-only run), and '
      'read this conversation with history().';

  Future<void> _requireSpace() async {
    final space = _spaceId;
    if (space == null) {
      return;
    }
    final hidden = await _sources.hiddenSpaces(
      workspaceId: _workspaceId,
      callerConversationId: _conversationId,
    );
    if (hidden.contains(space)) {
      throw const ScriptPastRefusal(hiddenSpace);
    }
  }

  @override
  Future<TranscriptPage> history({
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  }) async {
    await _requireSpace();
    final run = _subagentRunId;
    if (run != null) {
      return _sources.transcripts.pageRun(
        workspaceId: _workspaceId,
        runId: run,
        start: start,
        limit: limit,
        roles: roles,
        tools: tools,
      );
    }
    return _sources.transcripts.page(
      workspaceId: _workspaceId,
      conversationId: _conversation(),
      start: start,
      limit: limit,
      roles: roles,
      tools: tools,
    );
  }

  @override
  Future<TranscriptSlice?> historyRow({
    required String rowId,
    required int offset,
  }) async {
    await _requireSpace();
    final run = _subagentRunId;
    if (run != null) {
      return _sources.transcripts.sliceRun(
        workspaceId: _workspaceId,
        runId: run,
        rowId: rowId,
        offset: offset,
      );
    }
    return _sources.transcripts.slice(
      workspaceId: _workspaceId,
      conversationId: _conversation(),
      rowId: rowId,
      offset: offset,
    );
  }

  String _conversation() =>
      _conversationId ??
      (throw const ScriptPastRefusal(
        'This run has no conversation, so history() has no transcript to '
        'read.',
      ));

  @override
  String? get noOutputs {
    final scope = _scope;
    return _store == null ||
            scope == null ||
            invalidToolOutputScope(scope) != null
        ? _noOutputs
        : null;
  }

  ({ToolOutputStore store, ToolOutputScope scope}) _outputs() {
    final store = _store;
    final scope = _scope;
    if (store == null ||
        scope == null ||
        invalidToolOutputScope(scope) != null) {
      throw ScriptPastRefusal(_noOutputs);
    }
    return (store: store, scope: scope);
  }

  @override
  Future<List<ToolOutputEntry>> outputs() async {
    await _requireSpace();
    final o = _outputs();
    final ledger = _ledger;
    return [
      for (final e in await o.store.list(o.scope))
        if (ledger == null || ledger.contains(e.handle)) e,
    ];
  }

  @override
  Future<ToolOutputReadResult> readOutput(
    String handle, {
    required int offset,
    required int limit,
  }) async {
    await _requireSpace();
    final o = _outputs();
    final ledger = _ledger;
    if (ledger != null && !ledger.contains(handle)) {
      // Another run's handle, though the scope is shared: unknown here.
      return ToolOutputReadResult.notFound(handle);
    }
    return o.store.read(
      o.scope,
      handle,
      offsetChars: offset,
      limitChars: limit,
    );
  }

  @override
  Future<bool> keep({
    required String handle,
    required String label,
    required String content,
  }) async {
    final o = _outputs();
    final reference = await o.store.put(
      ToolOutputWrite(
        scope: o.scope,
        toolName: 'keep',
        content: content,
        handle: handle,
        label: label,
      ),
    );
    if (reference == null) {
      return false;
    }
    _ledger?.add(reference.handle);
    return true;
  }
}

/// The ports of the runs on the MCP endpoint, one per run-log id, so a
/// run's per-run read bounds ([ScriptPastUsage]) hold across its scripts:
/// each `repl` call there is a new script of the same run. A run's port is
/// dropped when the run settles ([drop]); at most [maxRuns] are held, the
/// least recently used going first, so a run whose settle never arrives (a
/// crash) cannot hold one for good.
class McpRunScriptPasts {
  /// Creates the ports of `sources`.
  McpRunScriptPasts(this._sources);

  /// The most runs held.
  static const int maxRuns = 1024;

  final ScriptPastSources _sources;
  final LinkedHashMap<String, ScriptPastPort> _runs = LinkedHashMap();

  /// How many runs are held.
  int get length => _runs.length;

  /// The port of run [runLogId], bound from its attested scope
  /// ([ScriptPastSources.forMcpRun]) on its first script and reused by its
  /// later ones. A run's grant names one workspace, conversation and space,
  /// so the first binding is the run's for its life.
  ScriptPastPort forRun({
    required String runLogId,
    required String workspaceId,
    required String? conversationId,
    required String? spaceId,
  }) {
    final port =
        _runs.remove(runLogId) ??
        _sources.forMcpRun(
          workspaceId: workspaceId,
          conversationId: conversationId,
          spaceId: spaceId,
        );
    _runs[runLogId] = port;
    while (_runs.length > maxRuns) {
      _runs.remove(_runs.keys.first);
    }
    return port;
  }

  /// Forgets run [runLogId], which settled.
  void drop(String runLogId) => _runs.remove(runLogId);
}

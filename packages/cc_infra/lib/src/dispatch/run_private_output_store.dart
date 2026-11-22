import 'package:cc_harness/context.dart';

/// The store a run's tool outputs go to: [store] itself, or for a
/// [readOnly] run a [RunPrivateOutputStore] of run [runId] over it.
ToolOutputStore? runOutputStore(
  ToolOutputStore? store, {
  required bool readOnly,
  required String runId,
}) => store != null && readOnly
    ? RunPrivateOutputStore(store, runId: runId)
    : store;

/// The tool-output store of a read-only run: it writes under scopes of the
/// run's own, so nothing the run stores reaches the scope the worker's runs
/// read, and it reads its own scope and then the worker's.
///
/// A read-only run (a goal's reviewer, an improvement review) shares its
/// worker's conversation and agent. Without this its over-budget `repl`
/// results and the outputs its loop cut would land in the worker's scope,
/// where the worker's `outputs()` lists them and `loadOutput` reads them.
/// Every scope passed through here keeps its workspace and conversation and
/// gets the agent id `<agent>#ro:<runId>` ([privateScope]):
///
/// - writes ([put]), [clearScope], [clearConversation] and [retire] touch
///   only that private scope;
/// - [read] looks in the private scope first and then in the scope it was
///   given (the worker's), so the handle `history()` shows for a worker's
///   cut output loads through `loadOutput` and `read_output`: a read-only
///   run may read;
/// - [list] returns both, newest first, as `outputs()` promises the outputs
///   "this conversation's runs stored".
///
/// The worker never reads the private scope. [retire] drops every scope the
/// run wrote; the dispatch session calls it when the run ends. A store only
/// ever drops entries through `clearScope`, and once the run has ended
/// nothing can name them: the worker reads its own scope, and a later
/// read-only run gets scopes of its own run.
class RunPrivateOutputStore implements ToolOutputStore {
  /// Creates the store of run [runId] over `inner`.
  RunPrivateOutputStore(this._inner, {required this.runId});

  final ToolOutputStore _inner;

  /// The run whose scopes these are.
  final String runId;

  final Set<ToolOutputScope> _written = {};

  /// [scope] as this run's own.
  ToolOutputScope privateScope(ToolOutputScope scope) => ToolOutputScope(
    workspaceId: scope.workspaceId,
    conversationId: scope.conversationId,
    agentId: '${scope.agentId ?? ''}#ro:$runId',
  );

  @override
  Future<ToolOutputReference?> put(ToolOutputWrite write) {
    final scope = privateScope(write.scope);
    _written.add(scope);
    return _inner.put(
      ToolOutputWrite(
        scope: scope,
        toolName: write.toolName,
        content: write.content,
        isError: write.isError,
        toolUseId: write.toolUseId,
        handle: write.handle,
        label: write.label,
      ),
    );
  }

  @override
  Future<ToolOutputReadResult> read(
    ToolOutputScope scope,
    String handle, {
    int offsetChars = 0,
    int limitChars = kToolOutputReadDefaultChars,
  }) async {
    final own = await _inner.read(
      privateScope(scope),
      handle,
      offsetChars: offsetChars,
      limitChars: limitChars,
    );
    // Not the run's own (never written there, or another scope's): the
    // worker's scope, which a read-only run may read.
    if (own.status != ToolOutputReadStatus.notFound &&
        own.status != ToolOutputReadStatus.denied) {
      return own;
    }
    return _inner.read(
      scope,
      handle,
      offsetChars: offsetChars,
      limitChars: limitChars,
    );
  }

  @override
  Future<List<ToolOutputEntry>> list(ToolOutputScope scope) async =>
      [...await _inner.list(privateScope(scope)), ...await _inner.list(scope)]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> clearScope(ToolOutputScope scope) =>
      _inner.clearScope(privateScope(scope));

  /// Clears this run's own scopes of [scope]'s conversation, never the
  /// worker's.
  @override
  Future<void> clearConversation(ToolOutputScope scope) async {
    for (final written in _written.toList()) {
      if (written.workspaceId == scope.workspaceId &&
          written.conversationId == scope.conversationId) {
        await _inner.clearScope(written);
        _written.remove(written);
      }
    }
  }

  /// Drops everything the run stored. Never throws.
  Future<void> retire() async {
    for (final scope in _written.toList()) {
      try {
        await _inner.clearScope(scope);
      } on Object {
        // A store reports its own failures; a scope it could not clear
        // stays unreachable (no one reads it).
      }
      _written.remove(scope);
    }
  }
}

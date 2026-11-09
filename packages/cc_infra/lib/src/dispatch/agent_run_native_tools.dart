part of 'agent_run_gateway.dart';

/// What one of Claude Code's own file or web tools is about to do, in the
/// action policy's terms.
class _NativeToolAction {
  const _NativeToolAction(this.summary, this.request);

  /// Reads a hook's `tool_name` and `tool_input`. Null when the tool is not one
  /// the policy governs, or its input does not say what it would touch.
  static _NativeToolAction? of(
    Object? toolName,
    Map<dynamic, dynamic> input,
    AgentRunGrant grant,
  ) {
    switch (toolName) {
      case 'Write' || 'Edit' || 'MultiEdit':
        return _write(input['file_path'], grant);
      case 'NotebookEdit':
        return _write(input['notebook_path'], grant);
      case 'WebFetch':
        final url = input['url'];
        if (url is! String || url.trim().isEmpty) {
          return null;
        }
        final host = Uri.tryParse(url)?.host ?? '';
        return _NativeToolAction(
          'web fetch: $url',
          ActionRequest(
            classes: const {ActionClass.networkEgress},
            hosts: [if (host.isNotEmpty) host],
          ),
        );
      case 'WebSearch':
        final query = input['query'];
        if (query is! String || query.trim().isEmpty) {
          return null;
        }
        return _NativeToolAction(
          'web search: $query',
          const ActionRequest(classes: {ActionClass.networkEgress}),
        );
    }
    return null;
  }

  /// A write is only a policy question when it leaves the run's own ground.
  /// Inside it nothing is declared, as for the harness's own write tools.
  static _NativeToolAction? _write(Object? raw, AgentRunGrant grant) {
    if (raw is! String || raw.trim().isEmpty) {
      return null;
    }
    final root = grant.worktreeRoot;
    final target = _resolved(raw, relativeTo: root);
    // Both sides resolved: the overlay reaches its worktrees through a
    // `repos` symlink, so a write there lands in a shared root, not under
    // [root] — which is why those roots are the run's own ground too.
    final owned = [
      ?root,
      ...grant.sharedWorktreeRoots,
      ...grant.runnerStateDirs,
    ].map(_resolved);
    final inside = owned.any((dir) => p.isWithin(dir, target));
    return _NativeToolAction(
      'write: $target',
      ActionRequest(
        classes: {if (!inside) ActionClass.fileWriteOutsideWorktree},
        paths: [target],
      ),
    );
  }

  /// [path] with `..` and symlinks gone, so neither can walk a write out of
  /// its directory. A file about to be created resolves through its deepest
  /// ancestor that exists.
  static String _resolved(String path, {String? relativeTo}) {
    var existing = p.normalize(
      p.isAbsolute(path) ? path : p.join(relativeTo ?? '', path),
    );
    final missing = <String>[];
    while (true) {
      try {
        return p.joinAll([
          File(existing).resolveSymbolicLinksSync(),
          ...missing.reversed,
        ]);
      } on FileSystemException {
        final parent = p.dirname(existing);
        if (parent == existing) {
          return p.joinAll([existing, ...missing.reversed]);
        }
        missing.add(p.basename(existing));
        existing = parent;
      }
    }
  }

  /// How the action reads in an approval and the audit trail.
  final String summary;

  /// What the policy can match on.
  final ActionRequest request;
}

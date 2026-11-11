part of 'dispatch_session.dart';

/// Which repositories this run works on, and which of its space's worktrees
/// it may change ([ReadOnlyWorktrees]). Resolved once when the run starts,
/// from the server's own records and grants, and read from there by the
/// gateway lease, the sandbox spec, the harness file tools, ACP's `fs/*` and
/// the gateway's Claude Code hook.
extension _DispatchSessionRepoGrants on DispatchSession {
  /// The forge repositories this run works on.
  ///
  /// In a space they are the space's checkouts as the server recorded them
  /// ([SandboxDispatchDeps.spaceRepos]): a checkout's `origin` is the agent's
  /// to rewrite, and the directory the run starts in is no checkout at all,
  /// so git there would answer for whatever repository happens to enclose
  /// the data directory. Anywhere else it is the checkout the run starts in.
  /// A lookup that fails leaves the run with none.
  Future<List<ForgeRemote>> _resolveRunRepos() async {
    if (!_layout.isOverlay) {
      try {
        final info = await deps.repoInspector?.inspect(agentDirHostPath);
        return [
          if (info != null)
            (forge: info.forge, owner: info.owner, name: info.repoName),
        ];
      } on Object {
        // Not a git worktree, or no origin on a supported forge.
        return const [];
      }
    }
    final lookup = deps.spaceRepos;
    final ws = workspaceId;
    final space = spaceId;
    if (lookup == null ||
        ws == null ||
        ws.isEmpty ||
        space == null ||
        space.isEmpty) {
      return const [];
    }
    try {
      return await lookup(ws, space);
    } on Object catch (e) {
      CcInfraLog.warning(
        'dispatch $dispatchId: the space\'s repositories are unavailable, so '
        'this run reads no forge: $e',
      );
      return const [];
    }
  }

  /// Resolves, once, the worktrees read-only for this run.
  ///
  /// Asked for the person the run acts for ([requestedByUserId]; the server
  /// resolves the accountable human for a run nobody asked for). A failed
  /// lookup, or a run in a space it cannot name, makes every worktree
  /// read-only.
  Future<List<String>> _resolveReadOnlyWorktrees() async {
    final known = _readOnlyWorktreeDirs;
    if (known != null) {
      return known;
    }
    final reposDir = _reposDir;
    final lookup = deps.writableWorktrees;
    if (reposDir == null || lookup == null) {
      return _readOnlyWorktreeDirs = const [];
    }
    List<String>? writable;
    final ws = workspaceId;
    final space = spaceId;
    if (ws != null && ws.isNotEmpty && space != null && space.isNotEmpty) {
      try {
        writable = await lookup(ws, space, requestedByUserId);
      } on Object catch (e) {
        CcInfraLog.warning(
          'dispatch $dispatchId: repository grants unavailable, every '
          'worktree is read-only for this run: $e',
        );
      }
    }
    return _readOnlyWorktreeDirs = List.unmodifiable(
      ReadOnlyWorktrees.of(reposDir, writable),
    );
  }

  /// The worktrees read-only for this run, as resolved when it started.
  List<String> get _readOnlyWorktrees => _readOnlyWorktreeDirs ?? const [];

  /// [_readOnlyWorktrees] as the harness file tools' read-only roots.
  List<ReadOnlyRoot> get _readOnlyRoots => [
    for (final worktree in _readOnlyWorktrees) ReadOnlyWorktrees.root(worktree),
  ];

  /// The read-only worktrees as bind mounts, listed after the space's
  /// writable `repos/` so each one stays read-only inside it.
  List<SandboxBindMount> get _readOnlyWorktreeMounts => [
    for (final dir in _readOnlyWorktrees)
      SandboxBindMount(hostPath: dir, guestPath: dir, readOnly: true),
  ];

  /// Extra workspace roots for the in-process harness file tools: the shared
  /// conversation worktrees dir (`<convRoot>/repos`) and the conversation's
  /// materialized attachments, when this session's cwd is a per-agent overlay.
  /// Without the first, the tools refuse the worktrees' real paths — the
  /// overlay only reaches them through its `repos` symlink, whose target is
  /// lexically outside the cwd. Without the second, the paths this run's own
  /// prompt names are unreadable to the tools that were given them. Derived
  /// from the directory layout (mirrors [_bindMounts]), never from the
  /// agent-writable symlink itself.
  List<String> _workspaceSharedRoots() => [
    ?_layout.reposDir,
    ?_layout.attachmentsDir,
  ];

  /// The space's shared worktree dir, or null when this session's cwd is not a
  /// per-agent overlay (the fallback path, where there are no worktrees).
  String? get _reposDir => _layout.reposDir;
}

/// The one forge [repos] are on, or null when there is none or several: a
/// run's commits carry one identity.
ForgeHost? _forgeOf(List<ForgeRemote> repos) {
  final forges = {for (final repo in repos) repo.forge};
  return forges.length == 1 ? forges.single : null;
}

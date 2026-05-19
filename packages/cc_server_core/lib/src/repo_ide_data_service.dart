import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/session_diff_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;

/// Options for [RepoIdeDataService.searchContent], mirroring VS Code's search
/// controls. Defaults (`caseSensitive: false`, `regex: false`, `wholeWord:
/// false`, empty globs) reproduce the original case-insensitive literal
/// behaviour, so an older client that omits the option map gets the legacy
/// semantics.
class SearchContentOptions {
  /// Creates [SearchContentOptions]. All flags default to the legacy
  /// (case-insensitive, literal, no-glob) behaviour.
  const SearchContentOptions({
    this.caseSensitive = false,
    this.regex = false,
    this.wholeWord = false,
    this.include = const [],
    this.exclude = const [],
  });

  /// Case-sensitive matching. When false (default) `git grep` runs with `-i`.
  final bool caseSensitive;

  /// Treat `query` as a regex. When false (default) `git grep` runs with `-F`
  /// (fixed-string); when true the `-F` is dropped.
  final bool regex;

  /// Whole-word matching. Adds `git grep`'s `-w`.
  final bool wholeWord;

  /// Comma/space-separated include pathspecs (matched as path globs after
  /// `git grep`'s `--`). Empty (default) → no include filter.
  final List<String> include;

  /// Comma/space-separated exclude pathspecs (each forwarded as `:!glob`).
  /// Empty (default) → no exclude filter.
  final List<String> exclude;
}

/// Result of writing a draft into a conversation worktree.
class WorktreeWriteResult {
  /// Creates a successful write result for [repoId] at [path].
  const WorktreeWriteResult({required this.repoId, required this.path});

  /// The repo whose worktree the file landed in.
  final String repoId;

  /// The repo-relative path actually written (normalized, confined).
  final String path;
}

/// Result of reverting one or more working-tree files in a conversation
/// worktree to HEAD. [reverted] counts files restored; [skipped] lists paths
/// that could not be reverted (untracked/new files — `git checkout-index` is a
/// no-op on them).
class WorktreeRevertResult {
  /// Creates a revert result with [reverted] files restored and [skipped] paths.
  const WorktreeRevertResult({
    required this.repoId,
    required this.reverted,
    required this.skipped,
  });

  /// The repo whose worktree was reverted.
  final String repoId;

  /// Number of files restored to HEAD.
  final int reverted;

  /// Paths that were not reverted (untracked files).
  final List<String> skipped;
}

/// Server-side data source for the messaging IDE's repo views — the Explorer
/// file tree, the Source Control working-tree diffs and the file viewer —
/// served over the `repos.*` and `conversation.changes` RPC ops.
///
/// Every client tier is thin: neither the desktop (thin + bundled `cc_server`)
/// nor the web/remote client owns the checkouts or a `git` binary, so all of
/// this runs on the SERVER, which owns both the linked-repo working trees and
/// the per-conversation copy-on-write worktrees. Wiring these four fetchers is
/// what makes the IDE identical across desktop and web.
///
/// Workspace isolation: every method is scoped to `workspaceId`. The
/// workspace→repo link ([WorkspaceRepository.isRepoLinkedToWorkspace] / the
/// linked-repo list) and the workspace-scoped worktree registry
/// ([IsolatedRepoRepository.forChannel]) are the isolation boundary — a repo (or
/// worktree) that does not belong to the caller's workspace is simply not found,
/// so a session cannot read another workspace's repos.
class RepoIdeDataService {
  /// Creates a [RepoIdeDataService].
  ///
  /// [fileSearch] is REQUIRED: the server injects its shared [FffFileSearch] so
  /// the Explorer shares fff's per-root scan caches with the harness tools. It
  /// used to default to [DartFileSearch], which quietly turned a missing
  /// `libfff_c` into a slow pure-Dart walk — exactly the degrade the native
  /// preflight now refuses to boot on. Tests pass [DartFileSearch] explicitly.
  ///
  /// [diff] defaults to the pure-Dart `git`-shelling adapter and is injectable
  /// for tests.
  RepoIdeDataService({
    required RepoRepository repoRepository,
    required WorkspaceRepository workspaceRepository,
    required IsolatedRepoRepository isolatedRepoRepository,
    required FileSearch fileSearch,
    SessionDiffPort? diff,
    Future<String?> Function()? githubToken,
  }) : _repos = repoRepository,
       _workspaces = workspaceRepository,
       _isolated = isolatedRepoRepository,
       _diff = diff ?? const ProcessSessionDiffAdapter(),
       _fileSearch = fileSearch,
       _githubToken = githubToken;

  final RepoRepository _repos;
  final WorkspaceRepository _workspaces;
  final IsolatedRepoRepository _isolated;
  final SessionDiffPort _diff;
  final FileSearch _fileSearch;
  final Future<String?> Function()? _githubToken;

  /// Reads no more than this many bytes when sniffing a file for a NUL byte.
  static const _binarySniffBytes = 8000;

  /// Cap on fuzzy-search results for a non-empty query.
  static const _searchLimit = 200;

  /// Cap on the unfiltered tree (empty query → the full file set). Generous
  /// enough for large repos; a pathological monorepo past this is truncated
  /// rather than blowing up the payload.
  static const _treeLimit = 100000;

  /// Bounds for content search so a broad query can't blow up the payload.
  static const _contentMaxMatches = 2000; // total matching lines across repos
  static const _contentMaxPerFile = 50; // matching lines kept per file
  static const _contentMaxLineChars = 400; // each matching line truncated to

  /// Cap on the number of pathspecs (`include`/`exclude` globs) we forward to
  /// `git grep` — a defensive bound so a huge glob list can't overflow argv.
  static const _contentMaxPathspecs = 256;

  /// Caps a single `worktree.writeFile` payload (4 MB) so a client can't stream
  /// unbounded bytes into a conversation worktree.
  static const _writeMaxBytes = 4 * 1024 * 1024;

  /// Working-tree diff (vs HEAD, incl. untracked) for a single repo, backing
  /// the Source Control panel's per-repo section.
  ///
  /// When [channelId] is given (the PR workbench + the IDE Source Control panel
  /// are both per-conversation), the diff runs STRICTLY against the
  /// conversation's ISOLATED CoW worktree for [repoId] — the tree the
  /// conversation's agents/code-server/quick-editor edit — resolved through the
  /// worktree registry (the isolation boundary). It does NOT fall back to the
  /// original linked checkout when that worktree is missing: a fallback there
  /// would surface the ORIGINAL repo's working-tree changes, which the
  /// conversation's writes never touch, so the diff would silently disagree
  /// with what a commit would stage (the write ops resolve the same worktree
  /// and no-op when it's absent). An unresolved worktree (provisioning still in
  /// flight / failed) therefore returns empty — the client gates on the
  /// channel's provisioning status and shows a "preparing"/"failed" state.
  ///
  /// Only when [channelId] is null (the IDE panel's documented no-conversation
  /// case) does it diff the linked checkout directly. Returns empty when the
  /// repo is not linked to [workspaceId] (a foreign repo is simply not found —
  /// no cross-workspace leak) or its checkout no longer exists on disk.
  Future<List<PrFile>> repoChanges(
    String workspaceId,
    String repoId, {
    String? channelId,
  }) async {
    if (channelId != null) {
      final worktree = await _worktreeFor(workspaceId, channelId, repoId);
      if (worktree == null) {
        return const [];
      }
      return _diff.changedFiles(worktree.path, 'HEAD');
    }
    final repo = await _linkedRepo(workspaceId, repoId);
    if (repo == null) {
      return const [];
    }
    return _diff.changedFiles(repo.path, 'HEAD');
  }

  /// The worktree's changes split into staged (index vs HEAD) and unstaged
  /// (worktree vs index + untracked) buckets — the VS Code Source Control model.
  /// Same workspace/channel scoping as [repoChanges]; empty buckets when the
  /// channel has no worktree for [repoId].
  Future<({List<PrFile> staged, List<PrFile> unstaged})> repoChangesGrouped(
    String workspaceId,
    String repoId, {
    String? channelId,
  }) async {
    if (channelId != null) {
      final worktree = await _worktreeFor(workspaceId, channelId, repoId);
      if (worktree == null) {
        return (staged: const <PrFile>[], unstaged: const <PrFile>[]);
      }
      return _diff.groupedChanges(worktree.path);
    }
    final repo = await _linkedRepo(workspaceId, repoId);
    if (repo == null) {
      return (staged: const <PrFile>[], unstaged: const <PrFile>[]);
    }
    return _diff.groupedChanges(repo.path);
  }

  /// Stages [paths] (empty ⇒ all changes) into the git index of the
  /// conversation's isolated worktree for [repoId] via `git add`. Paths are
  /// confined to the worktree root. Returns false when the channel has no
  /// worktree for [repoId].
  Future<bool> stageFiles(
    String workspaceId,
    String channelId,
    String repoId,
    List<String> paths,
  ) async {
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return false;
    }
    final root = p.normalize(worktree.path);
    final ProcessResult res;
    if (paths.isEmpty) {
      res = await Process.run('git', ['add', '-A'], workingDirectory: root);
    } else {
      final safe = _confinePaths(root, paths);
      if (safe.isEmpty) {
        return true;
      }
      res = await Process.run('git', [
        'add',
        '--',
        ...safe,
      ], workingDirectory: root);
    }
    return res.exitCode == 0;
  }

  /// Unstages [paths] (empty ⇒ all) from the git index of the conversation's
  /// isolated worktree for [repoId] via `git reset HEAD`. The working-tree
  /// content is untouched — only the index entry reverts. Returns false when the
  /// channel has no worktree for [repoId].
  Future<bool> unstageFiles(
    String workspaceId,
    String channelId,
    String repoId,
    List<String> paths,
  ) async {
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return false;
    }
    final root = p.normalize(worktree.path);
    final ProcessResult res;
    if (paths.isEmpty) {
      res = await Process.run('git', [
        'reset',
        '-q',
        'HEAD',
      ], workingDirectory: root);
    } else {
      final safe = _confinePaths(root, paths);
      if (safe.isEmpty) {
        return true;
      }
      res = await Process.run('git', [
        'reset',
        '-q',
        'HEAD',
        '--',
        ...safe,
      ], workingDirectory: root);
    }
    return res.exitCode == 0;
  }

  /// Repo-relative, worktree-confined subset of [paths] (drops traversals and
  /// absolute escapes). Shared by stage/unstage/revert/commit.
  List<String> _confinePaths(String root, List<String> paths) {
    final safe = <String>[];
    for (final path in paths) {
      final resolved = p.normalize(p.join(root, path));
      if (resolved == root || !p.isWithin(root, resolved)) {
        continue;
      }
      safe.add(p.relative(resolved, from: root));
    }
    return safe;
  }

  /// Reads a UTF-8 text file from a linked repo checkout, backing the IDE file
  /// viewer. Rejects traversal outside the repo root and non-linked repos (both
  /// → empty text). Binary files resolve to `(content: '', binary: true)` so the
  /// viewer can show a "binary file" placeholder instead of garbled text.
  Future<({String content, bool binary})> readFile(
    String workspaceId,
    String repoId,
    String path,
  ) async {
    final repo = await _linkedRepo(workspaceId, repoId);
    if (repo == null) {
      return (content: '', binary: false);
    }
    final root = p.normalize(repo.path);
    final resolved = p.normalize(p.join(root, path));
    // Confine to the repo root — reject `..` traversal and absolute escapes.
    if (resolved != root && !p.isWithin(root, resolved)) {
      return (content: '', binary: false);
    }
    final file = File(resolved);
    if (!file.existsSync()) {
      return (content: '', binary: false);
    }
    final bytes = await file.readAsBytes();
    if (_looksBinary(bytes)) {
      return (content: '', binary: true);
    }
    try {
      return (content: utf8.decode(bytes), binary: false);
    } on FormatException {
      // Not valid UTF-8 → treat as binary rather than emit replacement chars.
      return (content: '', binary: true);
    }
  }

  /// Fuzzy file search across a workspace's linked repo roots, backing the
  /// Explorer. An empty [query] yields the full entry tree (for the collapsible
  /// per-repo tree); a non-empty query yields a scored fuzzy list. Each hit
  /// carries the owning `repoId` (matched by its search root) so the client can
  /// group/open per repo.
  ///
  /// Returns raw wire maps (the [FileSearchHit] fields plus `repoId`) rather
  /// than the cc_natives type, keeping the wire contract free of that dependency
  /// — the client rebuilds `FileSearchHit` from the map.
  Future<List<Map<String, dynamic>>> searchFiles(
    String workspaceId,
    String query,
  ) async {
    final repos = await _linkedRepos(workspaceId);
    final rootToRepoId = <String, String>{};
    final roots = <String>[];
    for (final repo in repos) {
      final root = p.normalize(repo.path);
      // Skip repos whose checkout is missing so a broken link can't abort the
      // whole search — the rest of the workspace's repos still list.
      if (!Directory(root).existsSync()) {
        continue;
      }
      rootToRepoId[root] = repo.id;
      roots.add(root);
    }
    if (roots.isEmpty) {
      return const [];
    }
    final trimmed = query.trim();
    // Route both the tree and typed search through `search` so fff's native
    // scan powers both: an empty query returns the full file set (the client
    // infers directories from path segments), a non-empty query a scored
    // subset. `DartFileSearch` (tests) matches that empty-query contract, so the
    // same code path holds for both implementations.
    final hits = await _fileSearch
        .search(
          roots: roots,
          query: trimmed,
          limit: trimmed.isEmpty ? _treeLimit : _searchLimit,
        )
        .first;
    return [
      for (final hit in hits)
        {
          'absolutePath': hit.absolutePath,
          'relativePath': hit.relativePath,
          'rootPath': hit.rootPath,
          'isDirectory': hit.isDirectory,
          'score': hit.score,
          'repoId': rootToRepoId[p.normalize(hit.rootPath)] ?? '',
        },
    ];
  }

  /// Literal, case-insensitive content search across a workspace's linked repo
  /// roots, backing the Explorer's "Content" mode. Runs `git grep` on each repo
  /// (tracked + untracked, skipping binary + ignored files) so it's fast and
  /// respects `.gitignore`.
  ///
  /// Returns raw wire maps grouped per file — `{repoId, relativePath, matches:
  /// [{line, text}]}` — bounded by [_contentMaxMatches] / [_contentMaxPerFile]
  /// and with each line truncated to [_contentMaxLineChars]. Match ranges are
  /// computed client-side from `text` + the query (so highlighting stays a
  /// presentation concern). An empty query yields nothing.
  ///
  /// [options] toggles case-sensitivity, regex, whole-word and include/exclude
  /// pathspecs. Defaults reproduce the legacy case-insensitive literal search.
  Future<List<Map<String, dynamic>>> searchContent(
    String workspaceId,
    String query, {
    SearchContentOptions options = const SearchContentOptions(),
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final repos = await _linkedRepos(workspaceId);
    final out = <Map<String, dynamic>>[];
    var total = 0;
    // Build the `git grep` argv once — it is identical across repos.
    final grepArgs = _buildGrepArgs(trimmed, options);
    for (final repo in repos) {
      if (total >= _contentMaxMatches) {
        break;
      }
      final grouped = await _grepRoot(
        p.normalize(repo.path),
        repo.id,
        grepArgs,
        _contentMaxMatches - total,
      );
      for (final group in grouped) {
        out.add(group);
        total += (group['matches'] as List).length;
      }
    }
    return out;
  }

  /// Literal/regex content search across a conversation's ISOLATED CoW worktree
  /// for [repoId] (e.g. the PR-head tree), backing the PR workbench sidebar's
  /// "search in files" mode. Resolves the worktree through the workspace-scoped
  /// registry ([_worktreeFor]); a foreign/unprovisioned channel is simply not
  /// found (empty) and it NEVER falls back to the linked checkout — searching
  /// the original repo would surface files that aren't part of the PR's tree.
  /// Runs the same `git grep` (tracked + untracked) as [searchContent], so the
  /// user's uncommitted local edits and new files match too.
  ///
  /// Returns raw wire maps grouped per file — `{repoId, relativePath, matches:
  /// [{line, text}]}` — with the same bounds/truncation as [searchContent].
  Future<List<Map<String, dynamic>>> searchContentInWorktree(
    String workspaceId,
    String channelId,
    String repoId,
    String query, {
    SearchContentOptions options = const SearchContentOptions(),
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return const [];
    }
    return _grepRoot(
      p.normalize(worktree.path),
      repoId,
      _buildGrepArgs(trimmed, options),
      _contentMaxMatches,
    );
  }

  /// Fuzzy file search across ONE conversation's isolated CoW worktree (e.g.
  /// the PR-head tree), backing the PR workbench sidebar's file finder.
  /// Resolves the worktree through the workspace-scoped registry
  /// ([_worktreeFor]); a foreign/unprovisioned channel is simply not found
  /// (empty). Unlike [searchFiles] it NEVER falls back to the linked checkout —
  /// the finder lists the same tree the conversation edits (so untracked files
  /// created in the worktree list too).
  ///
  /// An empty [query] yields the full entry tree (capped at [_treeLimit]); a
  /// non-empty query a scored fuzzy subset (capped at [_searchLimit]). Every hit
  /// carries [repoId] so the client can attribute/open it. Returns raw wire maps
  /// (the [FileSearchHit] fields plus `repoId`), keeping the wire contract free
  /// of the cc_natives type — the client rebuilds `FileSearchHit`.
  Future<List<Map<String, dynamic>>> searchFilesInWorktree(
    String workspaceId,
    String channelId,
    String repoId,
    String query,
  ) async {
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return const [];
    }
    final root = p.normalize(worktree.path);
    if (!Directory(root).existsSync()) {
      return const [];
    }
    final trimmed = query.trim();
    final hits = await _fileSearch
        .search(
          roots: [root],
          query: trimmed,
          limit: trimmed.isEmpty ? _treeLimit : _searchLimit,
        )
        .first;
    return [
      for (final hit in hits)
        {
          'absolutePath': hit.absolutePath,
          'relativePath': hit.relativePath,
          'rootPath': hit.rootPath,
          'isDirectory': hit.isDirectory,
          'score': hit.score,
          'repoId': repoId,
        },
    ];
  }

  /// Runs the prebuilt `git grep` [grepArgs] in [root] and groups the output
  /// per file (`{repoId, relativePath, matches: [{line, text}]}`), attributing
  /// each group to [repoId]. Bounded by [remaining] total matching lines and
  /// [_contentMaxPerFile] per file; each line is truncated to
  /// [_contentMaxLineChars]. Returns empty when [root] is missing, `git grep`
  /// errors, or [remaining] is already exhausted — a broken checkout can't abort
  /// a multi-repo search.
  Future<List<Map<String, dynamic>>> _grepRoot(
    String root,
    String repoId,
    List<String> grepArgs,
    int remaining,
  ) async {
    if (remaining <= 0 || !Directory(root).existsSync()) {
      return const [];
    }
    // exit 0 = matches, 1 = no matches; anything else is a real error.
    final result = await Process.run('git', grepArgs, workingDirectory: root);
    if (result.exitCode != 0 && result.exitCode != 1) {
      return const [];
    }
    final byFile = <String, List<Map<String, dynamic>>>{};
    final order = <String>[];
    var added = 0;
    for (final line in (result.stdout as String).split('\n')) {
      if (line.isEmpty) {
        continue;
      }
      // `git grep -n` emits `<path>:<lineno>:<text>` (paths with colons are
      // pathological; split on the first two colons only).
      final firstColon = line.indexOf(':');
      if (firstColon <= 0) {
        continue;
      }
      final secondColon = line.indexOf(':', firstColon + 1);
      if (secondColon < 0) {
        continue;
      }
      final path = line.substring(0, firstColon);
      final lineNo = int.tryParse(line.substring(firstColon + 1, secondColon));
      if (lineNo == null) {
        continue;
      }
      var text = line.substring(secondColon + 1);
      if (text.length > _contentMaxLineChars) {
        text = text.substring(0, _contentMaxLineChars);
      }
      final matches = byFile.putIfAbsent(path, () {
        order.add(path);
        return [];
      });
      if (matches.length >= _contentMaxPerFile) {
        continue;
      }
      matches.add({'line': lineNo, 'text': text});
      added++;
      if (added >= remaining) {
        break;
      }
    }
    return [
      for (final path in order)
        {'repoId': repoId, 'relativePath': path, 'matches': byFile[path]},
    ];
  }

  /// Builds the `git grep` argv for [query] under [options].
  ///
  /// Legacy defaults (`caseSensitive: false`, `regex: false`) emit
  /// `-i -F`. Whole-word adds `-w`; regex replaces `-F` with `-E` (extended
  /// regex — git grep's default BRE doesn't recognise `\d` etc.). Include/
  /// exclude globs become pathspecs after `--`: a default pathspec already
  /// treats `*` as a wildcard across the whole path (so `*skip.dart` matches
  /// `lib/skip.dart`) and excludes are prefixed with `:(exclude)`. The argv is
  /// bounded by [_contentMaxPathspecs] defensively.
  static List<String> _buildGrepArgs(
    String query,
    SearchContentOptions options,
  ) {
    final args = <String>[
      'grep',
      '-n',
      '-I',
      '--untracked',
      '--no-color',
      if (!options.caseSensitive) '-i',
      if (options.regex) '-E' else '-F',
      if (options.wholeWord) '-w',
      '-e',
      query,
    ];
    final pathspecs = <String>[];
    var count = 0;
    for (final raw in options.include) {
      if (count >= _contentMaxPathspecs) {
        break;
      }
      final glob = raw.trim();
      if (glob.isEmpty) {
        continue;
      }
      pathspecs.add(glob);
      count++;
    }
    for (final raw in options.exclude) {
      if (count >= _contentMaxPathspecs) {
        break;
      }
      final glob = raw.trim();
      if (glob.isEmpty) {
        continue;
      }
      pathspecs.add(':(exclude)$glob');
      count++;
    }
    if (pathspecs.isNotEmpty) {
      args
        ..add('--')
        ..addAll(pathspecs);
    }
    return args;
  }

  /// Adapter that satisfies the RPC fetcher typedef: parses a raw options map
  /// (from the wire) into [SearchContentOptions] and delegates to
  /// [searchContent]. Unknown keys are ignored; missing keys fall back to the
  /// legacy defaults.
  Future<List<Map<String, dynamic>>> searchContentWithOptions(
    String workspaceId,
    String query, {
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    return searchContent(
      workspaceId,
      query,
      options: _parseSearchOptions(options),
    );
  }

  /// Adapter for the `worktree.searchContent` RPC fetcher: parses the raw wire
  /// options map and delegates to [searchContentInWorktree].
  Future<List<Map<String, dynamic>>> searchWorktreeContentWithOptions(
    String workspaceId,
    String channelId,
    String repoId,
    String query, {
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    return searchContentInWorktree(
      workspaceId,
      channelId,
      repoId,
      query,
      options: _parseSearchOptions(options),
    );
  }

  /// Parses the wire `options` map into [SearchContentOptions]. Tolerates a
  /// missing map and wrong-typed values (each falls back to the default).
  static SearchContentOptions _parseSearchOptions(
    Map<String, Object?> options,
  ) {
    bool boolOpt(String key) {
      final v = options[key];
      return v is bool ? v : false;
    }

    List<String> listOpt(String key) {
      final v = options[key];
      if (v is List) {
        return v.whereType<String>().where((s) => s.isNotEmpty).toList();
      }
      if (v is String && v.isNotEmpty) {
        // Accept a single comma/space-separated glob string for ergonomics.
        return v
            .split(RegExp(r'[,\s]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return const [];
    }

    return SearchContentOptions(
      caseSensitive: boolOpt('case_sensitive'),
      regex: boolOpt('regex'),
      wholeWord: boolOpt('whole_word'),
      include: listOpt('include'),
      exclude: listOpt('exclude'),
    );
  }

  /// Writes a draft file into the conversation's isolated copy-on-write
  /// worktree. Backs the IDE's "untitled" draft save (⌘S). The worktree is
  /// resolved through [IsolatedRepoRepository.forChannel] (the worktree
  /// isolation boundary), so a channel the caller's workspace does not own is
  /// simply not found — no cross-workspace leak. The [path] is confined to the
  /// worktree root (rejecting `..`/absolute escapes) and the payload is capped
  /// at [_writeMaxBytes]. Returns the resolved path, or null when the channel
  /// has no worktree for [repoId] / the path escapes / the payload is too big.
  Future<WorktreeWriteResult?> writeFile(
    String workspaceId,
    String channelId,
    String repoId,
    String path,
    String content,
  ) async {
    final bytes = utf8.encode(content);
    if (bytes.length > _writeMaxBytes) {
      return null;
    }
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final normalized = p.normalize(p.join(root, path));
    if (normalized != root && !p.isWithin(root, normalized)) {
      return null;
    }
    final file = File(normalized);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return WorktreeWriteResult(
      repoId: repoId,
      path: p.relative(normalized, from: root),
    );
  }

  /// Reverts one or more working-tree files in the conversation's isolated
  /// worktree to HEAD via `git checkout-index -f` (matches the snapshot-restore
  /// path in `ProcessGitSnapshotAdapter`). Tracked modified/deleted files are
  /// restored; untracked/new files are skipped (`checkout-index` cannot remove
  /// them — the client surfaces them as `skipped`). Paths outside the worktree
  /// root are rejected. Returns null when the channel has no worktree for
  /// [repoId].
  Future<WorktreeRevertResult?> revertFiles(
    String workspaceId,
    String channelId,
    String repoId,
    List<String> paths,
  ) async {
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final safe = <String>[];
    for (final path in paths) {
      final resolved = p.normalize(p.join(root, path));
      if (resolved == root || !p.isWithin(root, resolved)) {
        continue;
      }
      // Repo-relative form for the pathspec argv.
      safe.add(p.relative(resolved, from: root));
    }
    if (safe.isEmpty) {
      return WorktreeRevertResult(
        repoId: repoId,
        reverted: 0,
        skipped: const [],
      );
    }
    var reverted = 0;
    final skipped = <String>[];
    for (final rel in safe) {
      final absolute = p.join(root, rel);
      // `ls-files --error-unmatch` exits non-zero for untracked files: those
      // can't be reverted by checkout-index (they have no index entry) and are
      // reported back so the client can show "untracked file".
      final tracked = await Process.run('git', [
        'ls-files',
        '--error-unmatch',
        '--',
        rel,
      ], workingDirectory: root);
      if (tracked.exitCode != 0) {
        skipped.add(rel);
        continue;
      }
      final restore = await Process.run('git', [
        'checkout-index',
        '-f',
        '--',
        rel,
      ], workingDirectory: root);
      if (restore.exitCode == 0) {
        reverted++;
        // checkout-index restores content but does not remove a file that was
        // deleted in the working tree only if it's already gone — make sure
        // the restored file actually exists on disk.
        if (!File(absolute).existsSync()) {
          // The file was deleted in the working tree; checkout-index writes it
          // back from the index. If for some reason it didn't, count as skip.
          skipped.add(rel);
          reverted--;
        }
      } else {
        skipped.add(rel);
      }
    }
    return WorktreeRevertResult(
      repoId: repoId,
      reverted: reverted,
      skipped: skipped,
    );
  }

  /// Reads a file from the conversation's isolated worktree (path-confined to
  /// the worktree root). Returns null when the channel has no worktree for
  /// [repoId] (foreign / unprovisioned); `(content:'', binary:true)` for binary
  /// or non-UTF-8 files. Symmetric to [writeFile] — the PR/IDE file viewer reads
  /// the PR-head tree through this, not the linked-repo checkout.
  Future<({String content, bool binary})?> readFileFromWorktree(
    String workspaceId,
    String channelId,
    String repoId,
    String path,
  ) async {
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final resolved = p.normalize(p.join(root, path));
    if (resolved != root && !p.isWithin(root, resolved)) {
      return null;
    }
    final file = File(resolved);
    if (!file.existsSync()) {
      return (content: '', binary: false);
    }
    final bytes = await file.readAsBytes();
    if (_looksBinary(bytes)) {
      return (content: '', binary: true);
    }
    try {
      return (content: utf8.decode(bytes), binary: false);
    } on FormatException {
      return (content: '', binary: true);
    }
  }

  /// Stages, commits and (optionally) pushes changes in the conversation's
  /// isolated worktree for [repoId]. [paths] scopes the stage (empty ⇒ all
  /// changes). When [push] is true the local branch is pushed to
  /// `refs/heads/[pushBranch]` on `origin` using the GitHub token via
  /// `GIT_CONFIG_PARAMETERS` (never argv, so invisible to `ps`). The commit is
  /// authored by [authorName]/[authorEmail] when supplied (the acting human),
  /// else Control Center. Returns a result map; `pushed` is false with a
  /// verbatim `error` when the push is rejected (e.g. non-fast-forward).
  ///
  /// [amend] rewrites the previous commit (`git commit --amend`) instead of
  /// creating a new one — keeping its message when [message] is empty and
  /// lease-force-pushing when [push] is also set (history was rewritten).
  /// [sync] integrates the remote branch (fetch + rebase) before pushing so a
  /// diverged branch still fast-forwards; a rebase conflict aborts and returns
  /// the git error verbatim.
  Future<Map<String, dynamic>?> commitAndPush({
    required String workspaceId,
    required String channelId,
    required String repoId,
    required String message,
    List<String> paths = const [],
    bool push = true,
    bool amend = false,
    bool sync = false,
    String? pushBranch,
    String? authorName,
    String? authorEmail,
  }) async {
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    // Confine any explicit paths to the worktree.
    final safePaths = <String>[];
    for (final path in paths) {
      final resolved = p.normalize(p.join(root, path));
      if (resolved == root || !p.isWithin(root, resolved)) {
        continue;
      }
      safePaths.add(p.relative(resolved, from: root));
    }
    const baseEnv = {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_NOSYSTEM': '1',
    };
    Future<ProcessResult> git(List<String> args, {Map<String, String>? env}) =>
        Process.run(
          'git',
          args,
          workingDirectory: root,
          environment: {...baseEnv, ...?env},
        );

    // Stage the explicit paths (if any). With real staging the client stages via
    // `repos.stage` and commits with NO paths — we then commit the index AS-IS
    // (crucially, no `git add -A`, which would sweep in unstaged changes). Legacy
    // callers that pass explicit paths still get them staged here first.
    if (safePaths.isNotEmpty) {
      final add = await git(['add', '--', ...safePaths]);
      if (add.exitCode != 0) {
        return {
          'committed': false,
          'pushed': false,
          'error': add.stderr.toString(),
        };
      }
    }
    // Anything staged? An amend may only rewrite the previous commit's message
    // (no staged changes), so the guard applies to fresh commits only.
    if (!amend) {
      final staged = await git(['diff', '--cached', '--name-only']);
      if ((staged.stdout as String).trim().isEmpty) {
        return {
          'committed': false,
          'pushed': false,
          'error': 'nothing to commit',
        };
      }
    }
    // Commit with a per-invocation identity (never touches global git config).
    final name = (authorName?.trim().isNotEmpty ?? false)
        ? authorName!.trim()
        : 'Control Center';
    final email = (authorEmail?.trim().isNotEmpty ?? false)
        ? authorEmail!.trim()
        : 'control-center@localhost';
    // `--amend` rewrites HEAD; with an empty message we keep the prior one
    // (`--no-edit`), otherwise the supplied message replaces it.
    final keepMessage = amend && message.trim().isEmpty;
    final commit = await git([
      '-c',
      'user.name=$name',
      '-c',
      'user.email=$email',
      'commit',
      if (amend) '--amend',
      if (keepMessage) '--no-edit' else ...['-m', message],
    ]);
    if (commit.exitCode != 0) {
      return {
        'committed': false,
        'pushed': false,
        'error': commit.stderr.toString(),
      };
    }
    var headSha = ((await git(['rev-parse', 'HEAD'])).stdout as String).trim();
    if (!push) {
      return {'committed': true, 'pushed': false, 'headSha': headSha};
    }
    // Push to the PR head branch on origin, token via env (not argv).
    final branch = (pushBranch?.trim().isNotEmpty ?? false)
        ? pushBranch!.trim()
        : worktree.branch;
    final token = await _githubToken?.call();
    var env = <String, String>{};
    if (token != null && token.isNotEmpty) {
      final b64 = base64Encode(utf8.encode('x-access-token:$token'));
      env = {
        'GIT_CONFIG_PARAMETERS':
            "'http.https://github.com/.extraHeader=Authorization: Basic $b64'",
      };
    }
    // "Commit & sync": integrate any remote commits before pushing so the push
    // fast-forwards (VS Code's Sync = pull --rebase then push). A missing remote
    // branch (first push) or a failed fetch just falls through to the push; a
    // rebase CONFLICT aborts and surfaces git's message verbatim.
    if (sync) {
      final fetch = await git(['fetch', 'origin', branch], env: env);
      if (fetch.exitCode == 0) {
        final rebase = await git(['rebase', 'FETCH_HEAD']);
        if (rebase.exitCode != 0) {
          await git(['rebase', '--abort']);
          return {
            'committed': true,
            'pushed': false,
            'headSha': headSha,
            'error': (rebase.stderr as String).trim(),
          };
        }
        headSha = ((await git(['rev-parse', 'HEAD'])).stdout as String).trim();
      }
    }
    // An amended commit rewrites history, so its push leases-force; a fresh
    // commit (or a rebased sync) fast-forwards.
    final pushRes = await git([
      'push',
      if (amend) '--force-with-lease',
      'origin',
      'HEAD:refs/heads/$branch',
    ], env: env);
    if (pushRes.exitCode != 0) {
      return {
        'committed': true,
        'pushed': false,
        'headSha': headSha,
        'error': pushRes.stderr.toString(),
      };
    }
    return {'committed': true, 'pushed': true, 'headSha': headSha};
  }

  /// Publishes the conversation worktree's branch to `origin` — a push and
  /// nothing else.
  ///
  /// A conversation worktree is created with a local
  /// `git checkout -b conv/<id>` (or the ticket branch template) and is never
  /// given an upstream, so its commits exist only inside the copy-on-write copy.
  /// GitHub cannot open a pull request from a ref it has never seen and the
  /// compose screen's branch pickers read `refs/heads/*` off the remote — so
  /// until the branch is published, "create pull request" from a chat is a dead
  /// end.
  ///
  /// Deliberately push-only: it never stages, commits, amends, or rebases, so it
  /// cannot rewrite local history or sweep up work the user has not committed.
  /// Uncommitted changes simply are not published — the client reports how many
  /// were left behind rather than quietly committing them. The token travels via
  /// `GIT_CONFIG_PARAMETERS`, never argv.
  ///
  /// Returns null when the channel owns no worktree for [repoId]. Otherwise a map
  /// with `branch`, `headSha`, `pushed`, `uncommitted` (count of dirty paths),
  /// and a verbatim `error` when the push was rejected.
  Future<Map<String, dynamic>?> publishBranch({
    required String workspaceId,
    required String channelId,
    required String repoId,
    String? branchOverride,
  }) async {
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    const baseEnv = {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_NOSYSTEM': '1',
    };
    Future<ProcessResult> git(List<String> args, {Map<String, String>? env}) =>
        Process.run(
          'git',
          args,
          workingDirectory: root,
          environment: {...baseEnv, ...?env},
        );

    final branch = (branchOverride?.trim().isNotEmpty ?? false)
        ? branchOverride!.trim()
        : worktree.branch.trim();
    if (branch.isEmpty) {
      return {
        'pushed': false,
        'error': 'the worktree has no branch to publish',
      };
    }
    final headSha = ((await git(['rev-parse', 'HEAD'])).stdout as String)
        .trim();
    // Report (never silently include) work the push leaves behind.
    final dirty = await git(['status', '--porcelain']);
    final uncommitted = (dirty.stdout as String)
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;

    final token = await _githubToken?.call();
    var env = <String, String>{};
    if (token != null && token.isNotEmpty) {
      final b64 = base64Encode(utf8.encode('x-access-token:$token'));
      env = {
        'GIT_CONFIG_PARAMETERS':
            "'http.https://github.com/.extraHeader=Authorization: Basic $b64'",
      };
    }
    // No lease-force: publishing must never overwrite someone else's commits on
    // a branch that already exists. A rejected push surfaces git's own message,
    // which is the actionable thing (diverged / protected / no permission).
    final pushRes = await git([
      'push',
      'origin',
      'HEAD:refs/heads/$branch',
    ], env: env);
    if (pushRes.exitCode != 0) {
      return {
        'branch': branch,
        'headSha': headSha,
        'pushed': false,
        'uncommitted': uncommitted,
        'error': pushRes.stderr.toString().trim(),
      };
    }
    return {
      'branch': branch,
      'headSha': headSha,
      'pushed': true,
      'uncommitted': uncommitted,
    };
  }

  /// Re-syncs the conversation worktree for [repoId] to the current PR head.
  ///
  /// A PR-review worktree is checked out at the PR head **when it is
  /// provisioned** and never moves after that — so commits pushed to the PR
  /// later don't show up. This re-fetches [headRef] (e.g. `refs/pull/42/head`)
  /// and, when the worktree is CLEAN, hard-resets it to those commits ([branch]
  /// recreated at `FETCH_HEAD`) then scrubs untracked cruft (`git clean -ffdx`),
  /// so the review tree tracks the latest PR commits.
  ///
  /// When the worktree is DIRTY it no-ops and returns `{dirty: true}` — it never
  /// clobbers uncommitted edits; the client asks the user to commit/discard
  /// first. Returns null when the channel has no worktree for [repoId]; a map
  /// with `ok:false` + `error` on fetch/checkout failure.
  Future<Map<String, dynamic>?> syncToPrHead(
    String workspaceId,
    String channelId,
    String repoId, {
    required String headRef,
    required String branch,
  }) async {
    final worktree = await _worktreeFor(workspaceId, channelId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    Future<ProcessResult> git(List<String> args, {Map<String, String>? env}) =>
        Process.run('git', args, workingDirectory: root, environment: env);

    // Never clobber uncommitted work — bail out and let the client warn.
    final status = await git(['status', '--porcelain']);
    if (status.exitCode == 0 && (status.stdout as String).trim().isNotEmpty) {
      return {'ok': true, 'synced': false, 'dirty': true};
    }

    final repo = await _linkedRepo(workspaceId, repoId);
    if (repo == null || !repo.hasForgeRemote) {
      return {'ok': false, 'error': 'no GitHub remote for repo'};
    }
    // Fetching a PR head-ref needs auth — bail (never hit the network) without a
    // token. The token rides in the git auth header env (never argv, so
    // invisible to `ps`), mirroring commitAndPush / the rift isolation adapter.
    final token = await _githubToken?.call();
    if (token == null || token.isEmpty) {
      return {'ok': false, 'error': 'GitHub authentication required'};
    }
    final cleanUrl =
        'https://github.com/${repo.remoteOwner}/${repo.remoteName}.git';
    final b64 = base64Encode(utf8.encode('x-access-token:$token'));
    final fetchEnv = {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_PARAMETERS':
          "'http.https://github.com/.extraHeader=Authorization: Basic $b64'",
    };

    final fetch = await git([
      '-c',
      'credential.helper=',
      'fetch',
      '--no-tags',
      '--force',
      cleanUrl,
      headRef,
    ], env: fetchEnv);
    if (fetch.exitCode != 0) {
      return {'ok': false, 'error': (fetch.stderr as String).trim()};
    }
    // `-B` (re)creates [branch] at FETCH_HEAD even if it's the current branch,
    // guaranteeing the working tree matches the PR head.
    final checkout = await git([
      'checkout',
      '--force',
      '-B',
      branch,
      'FETCH_HEAD',
    ]);
    if (checkout.exitCode != 0) {
      return {'ok': false, 'error': (checkout.stderr as String).trim()};
    }
    await git(['clean', '-ffdx']);
    final headSha = ((await git(['rev-parse', 'HEAD'])).stdout as String)
        .trim();
    return {'ok': true, 'synced': true, 'headSha': headSha};
  }

  /// Resolves the (workspace-owned) isolated worktree for one conversation +
  /// repo, or null when none exists / the channel isn't owned by the workspace.
  Future<IsolatedRepo?> _worktreeFor(
    String workspaceId,
    String channelId,
    String repoId,
  ) async {
    final worktrees = await _isolated.forChannel(workspaceId, channelId);
    for (final w in worktrees) {
      if (w.repoId == repoId) {
        return w;
      }
    }
    return null;
  }

  /// Aggregate working-tree diff (vs HEAD, incl. untracked) across a
  /// conversation's isolated copy-on-write worktrees, backing the conversation
  /// changes view. Workspace-scoped via the registry lookup: only worktrees the
  /// caller's workspace owns are diffed.
  Future<List<PrFile>> conversationChanges(
    String workspaceId,
    String channelId,
  ) async {
    final worktrees = await _isolated.forChannel(workspaceId, channelId);
    final files = <PrFile>[];
    for (final worktree in worktrees) {
      files.addAll(await _diff.changedFiles(worktree.path, 'HEAD'));
    }
    return files;
  }

  Future<List<Repo>> _linkedRepos(String workspaceId) =>
      _workspaces.watchReposForWorkspace(workspaceId).first;

  Future<Repo?> _linkedRepo(String workspaceId, String repoId) async {
    if (!await _workspaces.isRepoLinkedToWorkspace(workspaceId, repoId)) {
      return null;
    }
    return _repos.getById(workspaceId, repoId);
  }

  static bool _looksBinary(List<int> bytes) {
    final limit = bytes.length < _binarySniffBytes
        ? bytes.length
        : _binarySniffBytes;
    for (var i = 0; i < limit; i++) {
      if (bytes[i] == 0) {
        return true;
      }
    }
    return false;
  }
}

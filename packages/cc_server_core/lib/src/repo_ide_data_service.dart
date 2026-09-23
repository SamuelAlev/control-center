import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/session_diff_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
// Narrow on purpose: this service needs exactly one cc_infra type. The
// package-wide barrel would drag the whole dispatch/chat/infra surface into
// every compile of this file (and everything that tests it).
// ignore: implementation_imports
import 'package:cc_infra/src/git/process_session_diff_adapter.dart';
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
    this.paths = const [],
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

  /// Exact repo-relative files to grep (a JSON list, never a split string).
  ///
  /// When non-empty these replace [include] as the include pathspecs, so a
  /// PR-scoped search cannot leak into the rest of the tree. [include] then
  /// filters this list (git-style globs) rather than OR-ing onto the whole
  /// tree. Empty (default) → whole-tree grep, optionally narrowed by
  /// [include].
  final List<String> paths;
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

/// Head commit of an open pull request for [branch] in [repoId], from the
/// local open-PR snapshot. Null when this branch has no open pull request.
///
/// Must not hit the network: [RepoIdeDataService.repoChangesGrouped] runs on
/// the source-control poll, every few seconds.
typedef PublishedBranchHead =
    Future<String?> Function({
      required String workspaceId,
      required String repoId,
      required String branch,
    });

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

/// Server-side data for the messaging IDE (Explorer, Source Control, file viewer) over `repos.*` /
/// `conversation.changes`. Clients are thin; the server owns checkouts and CoW worktrees.
///
/// Every method requires `workspaceId`; unlinked repos/worktrees are not found (no cross-workspace leak).
class RepoIdeDataService {
  /// Creates a [RepoIdeDataService].
  ///
  /// [_fileSearch] is REQUIRED: the server injects its shared [FffFileSearch] so
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
    required this._fileSearch,
    SessionDiffPort? diff,
    this._githubToken,
    this._publishedBranchHead,
  }) : _repos = repoRepository,
       _workspaces = workspaceRepository,
       _isolated = isolatedRepoRepository,
       _diff = diff ?? const ProcessSessionDiffAdapter();

  final RepoRepository _repos;
  final WorkspaceRepository _workspaces;
  final IsolatedRepoRepository _isolated;
  final SessionDiffPort _diff;
  final FileSearch _fileSearch;

  /// Resolves the GitHub credential a network-touching git command rides.
  /// [_githubToken]'s `actingUserId` names the human whose click drove the
  /// operation, so their push is authored on GitHub as THEM (per-actor lane);
  /// omitted, it resolves the server chain (app → owner → environment), which
  /// is only right for work with no human behind it. `workspaceId` selects
  /// that workspace's GitHub overlay rather than another workspace's token.
  final Future<String?> Function({String? actingUserId, String? workspaceId})?
  _githubToken;

  /// Open pull request head for a branch this checkout has never fetched.
  /// Null leaves publication entirely to local git refs.
  final PublishedBranchHead? _publishedBranchHead;

  /// Reads no more than this many bytes when sniffing a file for a NUL byte.
  static const _binarySniffBytes = 8000;

  /// Cap on fuzzy-search results per request. Requests page through the ranked
  /// list with [searchFiles]'s `offset`, so this bounds a single response, not
  /// the reachable set.
  static const _searchLimit = 200;

  /// Default page size for the Explorer's per-directory listing. Bounds one
  /// `repos.listDirectory` response; the client keeps pulling cursor pages
  /// until the directory is exhausted, so nothing is truncated.
  static const _dirListingPageSize = 500;

  /// Resolved directory listings, keyed by absolute directory path and held
  /// while the directory's mtime is unchanged (see [_resolvedEntries]).
  /// Insertion order IS recency order: a hit reinserts, and the trim drops
  /// from the front.
  final _dirListings =
      <
        String,
        ({
          List<Map<String, dynamic>> entries,
          DateTime mtime,
          DateTime storedAt,
        })
      >{};

  /// How long a listing may be served on an unchanged mtime. Bounds the one
  /// change mtime cannot report: an ignore rule that reclassifies entries the
  /// directory itself never saw touched.
  static const _dirCacheTtl = Duration(seconds: 60);

  /// Directories held at once, and the largest listing worth holding.
  static const _dirCacheMax = 512;
  static const _dirCacheMaxEntries = 4000;

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

  /// Working-tree diff vs HEAD (incl. untracked) for Source Control.
  ///
  /// With [spaceId]: only the conversation's CoW worktree — never fall back to the linked checkout
  /// (that would disagree with what commit stages). Missing worktree → empty. Without [spaceId]: linked checkout.
  /// Unlinked repo → empty.
  Future<List<PrFile>> repoChanges(
    String workspaceId,
    String repoId, {
    String? spaceId,
  }) async {
    if (spaceId != null) {
      final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
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
  /// Same workspace/space scoping as [repoChanges]; empty buckets when the
  /// space has no worktree for [repoId].
  ///
  /// Also reports how the branch sits against its upstream (local refs only,
  /// no fetch): ahead is commits to push, behind is commits to pull. A branch
  /// with no tracking ref and no `origin/<branch>` is still published when an
  /// open pull request names it — the head commit from that snapshot stands
  /// in for the missing remote-tracking ref, so a pull request opened outside
  /// this worktree is not offered as "Publish branch". With neither, ahead is
  /// commits the remote default does not contain, so a local conversation
  /// commit is still visible.
  Future<
    ({
      List<PrFile> staged,
      List<PrFile> unstaged,
      bool hasUpstream,
      int ahead,
      int behind,
      int aheadOfBase,
    })
  >
  repoChangesGrouped(
    String workspaceId,
    String repoId, {
    String? spaceId,
  }) async {
    Future<
      ({
        List<PrFile> staged,
        List<PrFile> unstaged,
        bool hasUpstream,
        int ahead,
        int behind,
        int aheadOfBase,
      })
    >
    pack(String root) async {
      final grouped = await _diff.groupedChanges(root);
      final published = _publishedBranchHead;
      final sync = await _branchSync(
        p.normalize(root),
        publishedHeadSha: published == null
            ? null
            : (branch) => published(
                workspaceId: workspaceId,
                repoId: repoId,
                branch: branch,
              ),
      );
      return (
        staged: grouped.staged,
        unstaged: grouped.unstaged,
        hasUpstream: sync.hasUpstream,
        ahead: sync.ahead,
        behind: sync.behind,
        aheadOfBase: sync.aheadOfBase,
      );
    }

    if (spaceId != null) {
      final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
      if (worktree == null) {
        return _emptyGrouped();
      }
      return pack(worktree.path);
    }
    final repo = await _linkedRepo(workspaceId, repoId);
    if (repo == null) {
      return _emptyGrouped();
    }
    return pack(repo.path);
  }

  ({
    List<PrFile> staged,
    List<PrFile> unstaged,
    bool hasUpstream,
    int ahead,
    int behind,
    int aheadOfBase,
  })
  _emptyGrouped() => (
    staged: const <PrFile>[],
    unstaged: const <PrFile>[],
    hasUpstream: false,
    ahead: 0,
    behind: 0,
    aheadOfBase: 0,
  );

  /// Ahead/behind from local refs. No network: the poll that reads this runs
  /// every few seconds, and a fetch belongs on [syncBranch].
  ///
  /// `ahead`/`behind` are against the tracking branch. With no tracking config
  /// but an `origin/<branch>` ref (a push that never ran `-u`), they are
  /// against that ref, so commits already on the remote are not counted as
  /// unpushed. A pull request opened outside this checkout leaves no such
  /// ref; [publishedHeadSha] supplies that branch's head from the open-PR
  /// snapshot and the comparison stays local. Only a branch neither git nor
  /// that snapshot has falls back to commits the default branch does not
  /// contain. `aheadOfBase` is always against the default branch and skips
  /// that branch itself, so a published feature branch still counts as a
  /// pull request after it is in sync with upstream.
  Future<({bool hasUpstream, int ahead, int behind, int aheadOfBase})>
  _branchSync(
    String root, {
    Future<String?> Function(String branch)? publishedHeadSha,
  }) async {
    const env = {'GIT_TERMINAL_PROMPT': '0', 'GIT_ASKPASS': 'echo'};
    Future<ProcessResult> git(List<String> args) =>
        Process.run('git', args, workingDirectory: root, environment: env);

    final headBranch =
        ((await git(['rev-parse', '--abbrev-ref', 'HEAD'])).stdout as String)
            .trim();
    final bases = <String>[
      'origin/HEAD',
      'origin/main',
      'origin/master',
      if (headBranch != 'main') 'main',
      if (headBranch != 'master') 'master',
    ];
    int? unpushed;
    int? aheadOfBase;
    for (final base in bases) {
      final abbrev = await git(['rev-parse', '--abbrev-ref', base]);
      if (abbrev.exitCode != 0) {
        continue;
      }
      final name = (abbrev.stdout as String).trim();
      if (name.isEmpty) {
        continue;
      }
      final n = await git(['rev-list', '--count', '$base..HEAD']);
      if (n.exitCode != 0) {
        continue;
      }
      final count = int.tryParse((n.stdout as String).trim()) ?? 0;
      unpushed ??= count;
      final short = name.startsWith('origin/')
          ? name.substring('origin/'.length)
          : name;
      if (short != headBranch) {
        aheadOfBase ??= count;
      }
      if (aheadOfBase != null) {
        break;
      }
    }

    final upstream = await git([
      'rev-parse',
      '--abbrev-ref',
      '--symbolic-full-name',
      '@{upstream}',
    ]);
    if (upstream.exitCode == 0 &&
        (upstream.stdout as String).trim().isNotEmpty) {
      final counts = await git([
        'rev-list',
        '--left-right',
        '--count',
        'HEAD...@{upstream}',
      ]);
      final parts = (counts.stdout as String).trim().split(RegExp(r'\s+'));
      if (counts.exitCode == 0 && parts.length >= 2) {
        return (
          hasUpstream: true,
          ahead: int.tryParse(parts[0]) ?? 0,
          behind: int.tryParse(parts[1]) ?? 0,
          aheadOfBase: aheadOfBase ?? 0,
        );
      }
      return (
        hasUpstream: true,
        ahead: 0,
        behind: 0,
        aheadOfBase: aheadOfBase ?? 0,
      );
    }

    // A publish that did not set tracking still updates
    // refs/remotes/origin/<branch>. Comparing to the default branch would
    // report those pushed commits as outgoing.
    if (headBranch.isNotEmpty && headBranch != 'HEAD') {
      final remoteBranch = 'origin/$headBranch';
      final remote = await git([
        'rev-parse',
        '--verify',
        '--quiet',
        remoteBranch,
      ]);
      if (remote.exitCode == 0) {
        final counts = await git([
          'rev-list',
          '--left-right',
          '--count',
          'HEAD...$remoteBranch',
        ]);
        final parts = (counts.stdout as String).trim().split(RegExp(r'\s+'));
        if (counts.exitCode == 0 && parts.length >= 2) {
          return (
            hasUpstream: true,
            ahead: int.tryParse(parts[0]) ?? 0,
            behind: int.tryParse(parts[1]) ?? 0,
            aheadOfBase: aheadOfBase ?? 0,
          );
        }
      }
    }

    // A pull request opened from another checkout (or the forge UI) publishes
    // the branch without writing `refs/remotes/origin/<branch>` here. The
    // snapshot head is that remote tip. Counting against the default branch
    // would report those commits as still needing a first push.
    if (publishedHeadSha != null &&
        headBranch.isNotEmpty &&
        headBranch != 'HEAD') {
      final raw = (await publishedHeadSha(headBranch))?.trim() ?? '';
      if (_isCommitSha(raw)) {
        final exists = await git(['cat-file', '-e', '$raw^{commit}']);
        if (exists.exitCode == 0) {
          final counts = await git([
            'rev-list',
            '--left-right',
            '--count',
            'HEAD...$raw',
          ]);
          final parts = (counts.stdout as String).trim().split(RegExp(r'\s+'));
          if (counts.exitCode == 0 && parts.length >= 2) {
            return (
              hasUpstream: true,
              ahead: int.tryParse(parts[0]) ?? 0,
              behind: int.tryParse(parts[1]) ?? 0,
              aheadOfBase: aheadOfBase ?? 0,
            );
          }
        } else {
          // The forge moved and this checkout has not fetched that commit.
          // Still published: Sync fetches it. Publish would claim the branch
          // had never left the machine.
          return (
            hasUpstream: true,
            ahead: 0,
            behind: 1,
            aheadOfBase: aheadOfBase ?? 0,
          );
        }
      }
    }

    return (
      hasUpstream: false,
      ahead: unpushed ?? 0,
      behind: 0,
      aheadOfBase: aheadOfBase ?? 0,
    );
  }

  static final RegExp _commitSha = RegExp(r'^[0-9a-fA-F]{7,64}$');

  static bool _isCommitSha(String sha) => _commitSha.hasMatch(sha);

  /// Stages [paths] (empty ⇒ all changes) into the git index of the
  /// conversation's isolated worktree for [repoId] via `git add`. Paths are
  /// confined to the worktree root. Returns false when the space has no
  /// worktree for [repoId].
  Future<bool> stageFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  ) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
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
  /// space has no worktree for [repoId].
  Future<bool> unstageFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  ) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
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
      // POSIX-canonical: these strings become git PATHSPECS and client-facing
      // ids; Windows separators are neither.
      final rel = p.relative(resolved, from: root);
      safe.add(Platform.isWindows ? rel.replaceAll('\\', '/') : rel);
    }
    return safe;
  }

  /// Reads a UTF-8 text file from a repo checkout, backing the IDE file
  /// viewer. Rejects traversal outside the repo root and non-linked repos (both
  /// → empty text). Binary files resolve to `(content: '', binary: true)` so the
  /// viewer can show a "binary file" placeholder instead of garbled text.
  ///
  /// [spaceId] scopes the read to that conversation's ISOLATED CoW worktree —
  /// the tree its agents/code-server edit, and the one the Explorer lists — with
  /// no fallback to the linked checkout (see [repoChanges] for why: a fallback
  /// would show a file whose contents the conversation never wrote).
  Future<({String content, bool binary})> readFile(
    String workspaceId,
    String repoId,
    String path, {
    String? spaceId,
  }) async {
    final repoRoot = await _readRoot(workspaceId, repoId, spaceId);
    if (repoRoot == null) {
      return (content: '', binary: false);
    }
    final root = p.normalize(repoRoot);
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

  /// Fuzzy file search across a workspace's repo roots, backing the
  /// Explorer's flat results list and the composer's `@` mentions. Pages
  /// through the ranked list: [offset] skips the first N ranked hits and
  /// [limit] bounds the returned page (the caller pages until satisfied, so
  /// the cap bounds a response, never the reachable set). Each hit carries
  /// the owning `repoId` (matched by its search root) so the client can
  /// group/open per repo.
  ///
  /// [spaceId] scopes the search to the conversation's isolated CoW worktrees
  /// (see [_readRoots]) — the same repos, and the same uncommitted/untracked
  /// files, the Explorer's tree shows.
  ///
  /// Returns raw wire maps (the [FileSearchHit] fields plus `repoId`) rather
  /// than the cc_natives type, keeping the wire contract free of that dependency
  /// — the client rebuilds `FileSearchHit` from the map.
  Future<List<Map<String, dynamic>>> searchFiles(
    String workspaceId,
    String query, {
    int offset = 0,
    int? limit,
    String? spaceId,
  }) async {
    final rootToRepoId = <String, String>{};
    final roots = <String>[];
    for (final entry in await _readRoots(workspaceId, spaceId)) {
      rootToRepoId[entry.root] = entry.repoId;
      roots.add(entry.root);
    }
    if (roots.isEmpty) {
      return const [];
    }
    final trimmed = query.trim();
    final page = (limit ?? _searchLimit).clamp(1, _searchLimit);
    final hits = await _fileSearch
        .search(
          roots: roots,
          query: trimmed,
          limit: page,
          offset: offset < 0 ? 0 : offset,
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

  /// One directory level for the Explorer (lazy tree), cursor-paginated (`has_more`, snake_case — not `hasMore`).
  ///
  /// Uses the conversation CoW worktree when [spaceId] is set. Hides ignore-matched children and `.git`.
  /// Unlinked repo → empty page. Client owns dirs-first sorting/icons.
  Future<Map<String, dynamic>> listDirectory(
    String workspaceId,
    String repoId, {
    String path = '',
    String cursor = '',
    int? limit,
    String? spaceId,
  }) async {
    final repoRoot = await _readRoot(workspaceId, repoId, spaceId);
    if (repoRoot == null) {
      return const {'entries': <Map<String, dynamic>>[], 'has_more': false};
    }
    final root = p.normalize(repoRoot);
    final dir = p.normalize(p.join(root, path));
    // Confine to the repo root — reject `..` traversal and absolute escapes
    // (same rule as [readFile]). A file (not a dir) at `path` lists nothing.
    if ((dir != root && !p.isWithin(root, dir)) ||
        !Directory(dir).existsSync()) {
      return const {'entries': <Map<String, dynamic>>[], 'has_more': false};
    }
    final entries = await _resolvedEntries(root, dir);
    var page = entries;
    if (cursor.isNotEmpty) {
      page = entries
          .where((e) => (e['relativePath'] as String).compareTo(cursor) > 0)
          .toList();
    }
    final pageSize = (limit ?? _dirListingPageSize).clamp(1, 1000);
    final hasMore = page.length > pageSize;
    return {
      'entries': page.take(pageSize).toList(growable: false),
      'has_more': hasMore,
    };
  }

  /// One directory's children: ignore-filtered and in path order (the order
  /// the cursor pages through), served from [_dirListings] when the directory
  /// has not changed.
  ///
  /// Producing this is the expensive half of a listing — a full `readdir` plus
  /// a `git check-ignore` PROCESS — and it was paid per RESPONSE, so a
  /// directory of 3000 entries spawned git six times to hand back six pages of
  /// the same walk, and every return to the Explorer tab did it again for
  /// every folder on screen. The cache is keyed on the directory's own mtime,
  /// which the filesystem bumps whenever an entry is added, removed or
  /// renamed — exactly the set of changes a listing can show. It cannot see an
  /// edit to a `.gitignore` (which reclassifies entries without touching the
  /// directory), so validity is additionally capped at [_dirCacheTtl] rather
  /// than left to mtime alone.
  Future<List<Map<String, dynamic>>> _resolvedEntries(
    String root,
    String dir,
  ) async {
    final mtime = FileStat.statSync(dir).modified;
    final now = DateTime.now();
    final cached = _dirListings[dir];
    if (cached != null &&
        cached.mtime == mtime &&
        now.difference(cached.storedAt) < _dirCacheTtl) {
      // Reinsert: the map's key order is its recency order (see the trim).
      _dirListings
        ..remove(dir)
        ..[dir] = cached;
      return cached.entries;
    }

    final entries = <Map<String, dynamic>>[];
    await for (final entity in Directory(
      dir,
    ).list(recursive: false, followLinks: false)) {
      final name = p.basename(entity.path);
      // Never surface the git database itself, whatever ignore rules say.
      if (name == '.git') {
        continue;
      }
      // Links are listed as files: resolving them would need a per-entry stat
      // and a cycle story, and the tree opens files by path anyway.
      entries.add({
        'relativePath': _posixRelative(entity.path, root),
        'isDirectory': entity is Directory,
      });
    }
    await _dropIgnored(root, entries);
    entries.sort((a, b) {
      final byPath = (a['relativePath'] as String).compareTo(
        b['relativePath'] as String,
      );
      return byPath;
    });

    final resolved = List<Map<String, dynamic>>.unmodifiable(entries);
    // A directory big enough to matter as a cache entry is also the one a
    // reader is least likely to come back to; skip it rather than let one
    // pathological folder own the budget.
    if (resolved.length <= _dirCacheMaxEntries) {
      _dirListings
        ..remove(dir)
        ..[dir] = (entries: resolved, mtime: mtime, storedAt: now);
      while (_dirListings.length > _dirCacheMax) {
        _dirListings.remove(_dirListings.keys.first);
      }
    }
    return resolved;
  }

  /// Removes entries whose repo-relative paths `git` considers ignored, in
  /// place. One batched `git check-ignore --stdin -z` invocation for the whole
  /// directory (NUL-framed, so a pathological filename cannot corrupt the
  /// batch): exit 0 means some paths matched (printed on stdout), 1 means none
  /// matched, anything else (not a repo, git missing) keeps everything —
  /// matching how a non-git folder lists in full.
  Future<void> _dropIgnored(
    String root,
    List<Map<String, dynamic>> entries,
  ) async {
    if (entries.isEmpty) {
      return;
    }
    final process = await Process.start('git', const [
      'check-ignore',
      '--stdin',
      '-z',
    ], workingDirectory: root);
    final batch = StringBuffer();
    for (final entry in entries) {
      batch
        ..write(entry['relativePath'] as String)
        ..write('\u0000');
    }
    try {
      process.stdin.write(batch.toString());
    } catch (_) {
      // The process died early (not a repo); its exit code says so below.
    }
    // dart:io reports a broken pipe on the awaited close, not on the write,
    // so the close needs the same tolerance: git exiting 128 ("not a repo")
    // before reading stdin must keep the listing, not kill the request.
    try {
      await process.stdin.close();
    } catch (_) {}
    final output = await process.stdout.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0 && exitCode != 1) {
      return;
    }
    final ignored = output.split('\u0000').where((l) => l.isNotEmpty).toSet();
    if (ignored.isEmpty) {
      return;
    }
    entries.removeWhere((e) => ignored.contains(e['relativePath']));
  }

  /// Repo-relative, `/`-separated path (Windows-safe), matching the
  /// `FileSearchHit.relativePath` form the rest of this service emits.
  static String _posixRelative(String path, String root) {
    final relative = p.relative(path, from: root);
    return Platform.isWindows ? relative.replaceAll('\\', '/') : relative;
  }

  /// Literal, case-insensitive content search across a workspace's repo roots
  /// (the conversation's isolated CoW worktrees when [spaceId] is given),
  /// backing the Explorer's "Content" mode. Runs `git grep` on each repo
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
    String? spaceId,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final roots = await _readRoots(workspaceId, spaceId);
    final out = <Map<String, dynamic>>[];
    var total = 0;
    for (final entry in roots) {
      if (total >= _contentMaxMatches) {
        break;
      }
      final grouped = await _grepRootWithOptions(
        entry.root,
        entry.repoId,
        trimmed,
        options,
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
  /// registry ([_worktreeFor]); a foreign/unprovisioned space is simply not
  /// found (empty) and it NEVER falls back to the linked checkout — searching
  /// the original repo would surface files that aren't part of the PR's tree.
  /// Runs the same `git grep` (tracked + untracked) as [searchContent], so the
  /// user's uncommitted local edits and new files match too.
  ///
  /// Returns raw wire maps grouped per file — `{repoId, relativePath, matches:
  /// [{line, text}]}` — with the same bounds/truncation as [searchContent].
  Future<List<Map<String, dynamic>>> searchContentInWorktree(
    String workspaceId,
    String spaceId,
    String repoId,
    String query, {
    SearchContentOptions options = const SearchContentOptions(),
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return const [];
    }
    return _grepRootWithOptions(
      p.normalize(worktree.path),
      repoId,
      trimmed,
      options,
      _contentMaxMatches,
    );
  }

  /// Fuzzy file search across ONE conversation's isolated CoW worktree (e.g.
  /// the PR-head tree), backing the PR workbench sidebar's file finder.
  /// Resolves the worktree through the workspace-scoped registry
  /// ([_worktreeFor]); a foreign/unprovisioned space is simply not found
  /// (empty). Unlike [searchFiles] it NEVER falls back to the linked checkout —
  /// the finder lists the same tree the conversation edits (so untracked files
  /// created in the worktree list too).
  ///
  /// Pages through the ranked list exactly like [searchFiles] ([offset] +
  /// [limit] bound a response, never the reachable set). Every hit carries
  /// [repoId] so the client can attribute/open it. Returns raw wire maps
  /// (the [FileSearchHit] fields plus `repoId`), keeping the wire contract free
  /// of the cc_natives type — the client rebuilds `FileSearchHit`.
  Future<List<Map<String, dynamic>>> searchFilesInWorktree(
    String workspaceId,
    String spaceId,
    String repoId,
    String query, {
    int offset = 0,
    int? limit,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return const [];
    }
    final root = p.normalize(worktree.path);
    if (!Directory(root).existsSync()) {
      return const [];
    }
    final trimmed = query.trim();
    final page = (limit ?? _searchLimit).clamp(1, _searchLimit);
    final hits = await _fileSearch
        .search(
          roots: [root],
          query: trimmed,
          limit: page,
          offset: offset < 0 ? 0 : offset,
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

  /// Resolves [options] into one or more `git grep` invocations against [root].
  ///
  /// When [SearchContentOptions.paths] is non-empty the search is restricted
  /// to those files: missing/deleted paths are dropped (so a deleted PR file
  /// cannot 128-exit the whole grep) and an empty remainder returns nothing
  /// rather than widening to the whole tree. Explicit paths are batched in
  /// chunks of [_contentMaxPathspecs] so a large PR does not overflow argv.
  Future<List<Map<String, dynamic>>> _grepRootWithOptions(
    String root,
    String repoId,
    String query,
    SearchContentOptions options,
    int remaining,
  ) async {
    if (remaining <= 0 || !Directory(root).existsSync()) {
      return const [];
    }
    final restricted = options.paths.isNotEmpty;
    var includes = _includePathspecs(options);
    if (restricted) {
      includes = [for (final rel in includes) ?_existingWorktreeRel(root, rel)];
      if (includes.isEmpty) {
        return const [];
      }
    }
    final excludeCount = options.exclude
        .where((raw) => raw.trim().isNotEmpty)
        .length;
    final chunkSize = excludeCount >= _contentMaxPathspecs
        ? 1
        : _contentMaxPathspecs - excludeCount;
    if (includes.isEmpty) {
      return _grepRoot(root, repoId, _buildGrepArgs(query, options), remaining);
    }
    final out = <Map<String, dynamic>>[];
    var total = 0;
    for (var i = 0; i < includes.length; i += chunkSize) {
      if (total >= remaining) {
        break;
      }
      final end = i + chunkSize > includes.length
          ? includes.length
          : i + chunkSize;
      final grouped = await _grepRoot(
        root,
        repoId,
        _buildGrepArgs(
          query,
          options,
          includeOverride: includes.sublist(i, end),
        ),
        remaining - total,
      );
      for (final group in grouped) {
        out.add(group);
        total += (group['matches'] as List).length;
      }
    }
    return out;
  }

  /// Include pathspecs for a grep: exact [SearchContentOptions.paths]
  /// (optionally filtered by [SearchContentOptions.include] globs) or, when
  /// paths is empty, the include globs themselves.
  static List<String> _includePathspecs(SearchContentOptions options) {
    if (options.paths.isEmpty) {
      return [
        for (final raw in options.include)
          if (raw.trim().isNotEmpty) raw.trim(),
      ];
    }
    final paths = [
      for (final raw in options.paths)
        if (raw.trim().isNotEmpty) raw.trim(),
    ];
    final globs = [
      for (final raw in options.include)
        if (raw.trim().isNotEmpty) raw.trim(),
    ];
    if (globs.isEmpty) {
      return paths;
    }
    return [
      for (final path in paths)
        if (globs.any((glob) => _pathspecMatches(path, glob))) path,
    ];
  }

  /// Git's default pathspec glob: `*` matches across `/`, `?` is one character.
  static bool _pathspecMatches(String path, String glob) {
    final buf = StringBuffer('^');
    for (var i = 0; i < glob.length; i++) {
      final c = glob[i];
      switch (c) {
        case '*':
          buf.write('.*');
        case '?':
          buf.write('.');
        default:
          buf.write(RegExp.escape(c));
      }
    }
    buf.write(r'$');
    return RegExp(buf.toString(), caseSensitive: false).hasMatch(path);
  }

  /// Repo-relative POSIX path if [raw] names a file inside [root], else null.
  /// Rejects `..` / absolute escapes so a client-supplied path cannot leave
  /// the worktree. Missing files (deleted PR paths) return null.
  static String? _existingWorktreeRel(String root, String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final joined = p.normalize(p.join(root, trimmed));
    if (joined == root || !p.isWithin(root, joined)) {
      return null;
    }
    if (!File(joined).existsSync()) {
      return null;
    }
    final rel = p.relative(joined, from: root);
    return Platform.isWindows ? rel.replaceAll('\\', '/') : rel;
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
  /// bounded by [_contentMaxPathspecs] defensively, except when
  /// [includeOverride] is a pre-batched chunk of exact paths (already sized).
  static List<String> _buildGrepArgs(
    String query,
    SearchContentOptions options, {
    List<String>? includeOverride,
  }) {
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
    final includes =
        includeOverride ??
        [
          for (final raw in options.include)
            if (raw.trim().isNotEmpty) raw.trim(),
        ];
    final pathspecs = <String>[];
    var count = 0;
    final includeCap = includeOverride != null
        ? includes.length
        : _contentMaxPathspecs;
    for (final glob in includes) {
      if (count >= includeCap) {
        break;
      }
      pathspecs.add(glob);
      count++;
    }
    for (final raw in options.exclude) {
      if (includeOverride == null && count >= _contentMaxPathspecs) {
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
    String? spaceId,
  }) {
    return searchContent(
      workspaceId,
      query,
      options: _parseSearchOptions(options),
      spaceId: spaceId,
    );
  }

  /// Adapter for the `worktree.searchContent` RPC fetcher: parses the raw wire
  /// options map and delegates to [searchContentInWorktree].
  Future<List<Map<String, dynamic>>> searchWorktreeContentWithOptions(
    String workspaceId,
    String spaceId,
    String repoId,
    String query, {
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    return searchContentInWorktree(
      workspaceId,
      spaceId,
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

    // Exact file paths must stay a JSON list — comma-splitting would break
    // paths with spaces and would OR a joined blob as one glob.
    List<String> pathsOpt() {
      final v = options['paths'];
      if (v is List) {
        return v.whereType<String>().where((s) => s.isNotEmpty).toList();
      }
      return const [];
    }

    return SearchContentOptions(
      caseSensitive: boolOpt('case_sensitive'),
      regex: boolOpt('regex'),
      wholeWord: boolOpt('whole_word'),
      include: listOpt('include'),
      exclude: listOpt('exclude'),
      paths: pathsOpt(),
    );
  }

  /// Writes a draft file into the conversation's isolated copy-on-write
  /// worktree. Backs the IDE's "untitled" draft save (⌘S). The worktree is
  /// resolved through [IsolatedRepoRepository.forSpace] (the worktree
  /// isolation boundary), so a space the caller's workspace does not own is
  /// simply not found — no cross-workspace leak. The [path] is confined to the
  /// worktree root (rejecting `..`/absolute escapes) and the payload is capped
  /// at [_writeMaxBytes]. Returns the resolved path, or null when the space
  /// has no worktree for [repoId] / the path escapes / the payload is too big.
  Future<WorktreeWriteResult?> writeFile(
    String workspaceId,
    String spaceId,
    String repoId,
    String path,
    String content,
  ) async {
    final bytes = utf8.encode(content);
    if (bytes.length > _writeMaxBytes) {
      return null;
    }
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
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
    // POSIX-canonical like every other wire-facing relative path in this
    // service (the file-search hits already are): the client compares them
    // as strings.
    final rel = p.relative(normalized, from: root);
    return WorktreeWriteResult(
      repoId: repoId,
      path: Platform.isWindows ? rel.replaceAll('\\', '/') : rel,
    );
  }

  /// Reverts one or more working-tree files in the conversation's isolated
  /// worktree to HEAD via `git checkout-index -f` (matches the snapshot-restore
  /// path in `ProcessGitSnapshotAdapter`). Tracked modified/deleted files are
  /// restored; untracked/new files are skipped (`checkout-index` cannot remove
  /// them — the client surfaces them as `skipped`). Paths outside the worktree
  /// root are rejected. Returns null when the space has no worktree for
  /// [repoId].
  Future<WorktreeRevertResult?> revertFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  ) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
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
  /// the worktree root). Returns null when the space has no worktree for
  /// [repoId] (foreign / unprovisioned); `(content:'', binary:true)` for binary
  /// or non-UTF-8 files. Symmetric to [writeFile] — the PR/IDE file viewer reads
  /// the PR-head tree through this, not the linked-repo checkout.
  Future<({String content, bool binary})?> readFileFromWorktree(
    String workspaceId,
    String spaceId,
    String repoId,
    String path,
  ) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
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

  /// Stage/commit/(optional) push in the conversation worktree. Token via `GIT_CONFIG_PARAMETERS` (not argv).
  /// Push authenticates as [actingUserId]; commit authored by [authorName]/[authorEmail] or Control Center.
  /// [amend] rewrites HEAD; [sync] fetch+rebase before push (conflict returns git error).
  Future<Map<String, dynamic>?> commitAndPush({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String message,
    List<String> paths = const [],
    bool push = true,
    bool amend = false,
    bool sync = false,
    String? pushBranch,
    String? authorName,
    String? authorEmail,
    String? actingUserId,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
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
    // Push to the PR head branch on origin, token via env (not argv), on the
    // ACTING USER's credential so GitHub attributes the push to them.
    final branch = (pushBranch?.trim().isNotEmpty ?? false)
        ? pushBranch!.trim()
        : worktree.branch;
    final token = await _githubToken?.call(
      actingUserId: actingUserId,
      workspaceId: workspaceId,
    );
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
      // `credential.helper=` pins auth to the header env: with no token the
      // fetch fails loudly instead of borrowing whatever account the host's
      // keychain helper happens to hold.
      final fetch = await git([
        '-c',
        'credential.helper=',
        'fetch',
        'origin',
        branch,
      ], env: env);
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
    // commit (or a rebased sync) fast-forwards. `credential.helper=` keeps the
    // host's keychain out of it — the header env is the only credential.
    final pushRes = await git([
      '-c',
      'credential.helper=',
      'push',
      // Track the remote branch so the next status read can show ahead/behind
      // instead of offering Publish again for a branch that already exists.
      '-u',
      if (amend) '--force-with-lease',
      'origin',
      'HEAD:refs/heads/$branch',
    ], env: env);
    if (pushRes.exitCode != 0) {
      final reason = _pushRefusalText(pushRes);
      return {
        'committed': true,
        'pushed': false,
        'headSha': headSha,
        'error': ?reason,
      };
    }
    return {'committed': true, 'pushed': true, 'headSha': headSha};
  }

  /// Push-only publish of the conversation worktree branch to `origin` (needed before forge PR creation).
  /// Never stages/commits/amends/rebases; token via `GIT_CONFIG_PARAMETERS`. Null if no worktree.
  Future<Map<String, dynamic>?> publishBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? branchOverride,
    String? actingUserId,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
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

    // The ACTING USER's credential, so publishing the branch is attributed on
    // GitHub to the human who clicked, not to the server's App.
    final token = await _githubToken?.call(
      actingUserId: actingUserId,
      workspaceId: workspaceId,
    );
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
    // `credential.helper=` keeps the host's keychain out of it.
    final pushRes = await git([
      '-c',
      'credential.helper=',
      'push',
      '-u',
      'origin',
      'HEAD:refs/heads/$branch',
    ], env: env);
    if (pushRes.exitCode != 0) {
      final reason = _pushRefusalText(pushRes);
      return {
        'branch': branch,
        'headSha': headSha,
        'pushed': false,
        'uncommitted': uncommitted,
        'error': ?reason,
      };
    }
    return {
      'branch': branch,
      'headSha': headSha,
      'pushed': true,
      'uncommitted': uncommitted,
    };
  }

  /// VS Code's Sync for the conversation worktree: fetch the branch, rebase when
  /// the remote has commits this side does not, then push when this side is
  /// ahead or the branch has never been published. Never commits.
  ///
  /// A dirty tree that still needs the rebase is refused (`dirty: true`) so
  /// uncommitted edits are not clobbered. A rebase conflict aborts and returns
  /// git's message. A rejected push — branch protection, a pre-push or
  /// pre-receive hook, a non-fast-forward — returns `pushRefused: true` with
  /// the hook or remote's own text, and does not report the sync as done. A
  /// pull that already landed stays landed. Null when the space has no
  /// worktree for [repoId].
  Future<Map<String, dynamic>?> syncBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? actingUserId,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    const baseEnv = {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_NOSYSTEM': '1',
      // A conflicted rebase must not open an editor; we abort and report.
      'GIT_EDITOR': 'true',
    };
    Future<ProcessResult> git(List<String> args, {Map<String, String>? env}) =>
        Process.run(
          'git',
          args,
          workingDirectory: root,
          environment: {...baseEnv, ...?env},
        );

    var branch = worktree.branch.trim();
    if (branch.isEmpty) {
      branch =
          ((await git(['rev-parse', '--abbrev-ref', 'HEAD'])).stdout as String)
              .trim();
    }
    if (branch.isEmpty || branch == 'HEAD') {
      return {
        'pulled': false,
        'pushed': false,
        'dirty': false,
        'error': 'the worktree has no branch to sync',
      };
    }

    final token = await _githubToken?.call(
      actingUserId: actingUserId,
      workspaceId: workspaceId,
    );
    var env = <String, String>{};
    if (token != null && token.isNotEmpty) {
      final b64 = base64Encode(utf8.encode('x-access-token:$token'));
      env = {
        'GIT_CONFIG_PARAMETERS':
            "'http.https://github.com/.extraHeader=Authorization: Basic $b64'",
      };
    }

    // A missing remote branch (first publish) fails the fetch; the push below
    // creates it. Any other fetch failure falls through to the push, which
    // reports the network error if it is real.
    final fetch = await git([
      '-c',
      'credential.helper=',
      'fetch',
      'origin',
      branch,
    ], env: env);
    final fetched = fetch.exitCode == 0;
    var pulled = false;
    if (fetched) {
      final behindRes = await git(['rev-list', '--count', 'HEAD..FETCH_HEAD']);
      final behind = behindRes.exitCode == 0
          ? int.tryParse((behindRes.stdout as String).trim()) ?? 0
          : 0;
      if (behind > 0) {
        final status = await git(['status', '--porcelain', '-z']);
        final dirtyNames = status.exitCode == 0
            ? _porcelainPaths(status.stdout as String)
            : const <String>{};
        final dirty = dirtyNames.isNotEmpty;
        if (await _pullWouldConflict(git, dirtyNames)) {
          // Leave the worktree untouched. The client asks whether a person
          // or an agent should resolve it.
          return {
            'pulled': false,
            'pushed': false,
            'dirty': dirty,
            'conflict': true,
          };
        }
        if (dirty) {
          return {'pulled': false, 'pushed': false, 'dirty': true};
        }
        final rebase = await git(['rebase', 'FETCH_HEAD']);
        if (rebase.exitCode != 0) {
          await git(['rebase', '--abort']);
          final err = (rebase.stderr as String).trim();
          final conflict =
              err.contains('CONFLICT') || err.contains('could not apply');
          return {
            'pulled': false,
            'pushed': false,
            'dirty': false,
            'conflict': conflict,
            'error': conflict ? null : err,
          };
        }
        pulled = true;
      }
    }

    final aheadRes = fetched
        ? await git(['rev-list', '--count', 'FETCH_HEAD..HEAD'])
        : null;
    final ahead = aheadRes == null || aheadRes.exitCode != 0
        ? (fetched ? 0 : 1)
        : int.tryParse((aheadRes.stdout as String).trim()) ?? 0;
    if (fetched && ahead == 0) {
      return {'pulled': pulled, 'pushed': false, 'dirty': false};
    }
    final pushRes = await git([
      '-c',
      'credential.helper=',
      'push',
      '-u',
      'origin',
      'HEAD:refs/heads/$branch',
    ], env: env);
    if (pushRes.exitCode != 0) {
      // The pull, when there was one, already landed. Say so separately from
      // the refusal so a protected branch does not look like a failed fetch.
      return {
        'pulled': pulled,
        'pushed': false,
        'dirty': false,
        'pushRefused': true,
        'error': ?_pushRefusalText(pushRes),
      };
    }
    return {'pulled': pulled, 'pushed': true, 'dirty': false};
  }

  /// Local branches, remote-tracking refs and tags in the conversation
  /// worktree, newest commit first. No network: a fetch belongs on
  /// [syncBranch]. Null when the space has no worktree for [repoId].
  Future<Map<String, dynamic>?> listBranches({
    required String workspaceId,
    required String spaceId,
    required String repoId,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final head =
        ((await _git(root, ['rev-parse', '--abbrev-ref', 'HEAD'])).stdout
                as String)
            .trim();
    final listed = await _git(root, const [
      'for-each-ref',
      '--count=400',
      '--sort=-committerdate',
      '--format=%(refname)\x1f%(objectname:short)\x1f%(committerdate:unix)\x1f%(subject)',
      'refs/heads',
      'refs/remotes',
      'refs/tags',
    ]);
    final refs = <Map<String, Object?>>[];
    if (listed.exitCode == 0) {
      for (final line in (listed.stdout as String).split('\n')) {
        if (line.isEmpty) {
          continue;
        }
        final parts = line.split('\x1f');
        if (parts.length < 4) {
          continue;
        }
        final refname = parts[0];
        if (refname == 'refs/remotes/origin/HEAD') {
          continue;
        }
        final parsed = _parseRefName(refname);
        if (parsed == null) {
          continue;
        }
        final (kind, name, localName) = parsed;
        refs.add({
          'name': name,
          'kind': kind,
          'sha': parts[1],
          'committedAt': int.tryParse(parts[2]) ?? 0,
          'subject': parts.sublist(3).join('\x1f'),
          'current': kind == 'branch' && name == head,
          'localName': localName,
        });
      }
    }
    return {'current': head, 'detached': head == 'HEAD', 'refs': refs};
  }

  /// Checks [branch] out in the conversation worktree, or creates it.
  ///
  /// Stays inside the isolated copy: local refs and remote-tracking refs
  /// already in the worktree, never a fetch and never a write into the
  /// source checkout. A dirty tree is left for git to accept or refuse —
  /// creating a branch at HEAD keeps uncommitted work, switching to another
  /// commit does not overwrite files.
  ///
  /// On success the isolated-repo row's branch is updated to the checked-out
  /// name, because commit and push publish that stored name. A detached
  /// checkout stores an empty branch so a later push cannot invent
  /// `refs/heads/HEAD`. If recording the row fails, the checkout is rolled
  /// back. Null when the space has no worktree for [repoId].
  Future<Map<String, dynamic>?> checkoutBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? branch,
    String? startPoint,
    bool create = false,
    bool detach = false,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final previous =
        ((await _git(root, ['rev-parse', '--abbrev-ref', 'HEAD'])).stdout
                as String)
            .trim();
    final previousSha =
        ((await _git(root, ['rev-parse', 'HEAD'])).stdout as String).trim();

    if (detach) {
      final start = (startPoint?.trim().isNotEmpty ?? false)
          ? startPoint!.trim()
          : 'HEAD';
      if (!_isRefToken(start)) {
        return {'ok': false, 'error': 'invalid start point'};
      }
      final verified = await _verifyCommit(root, start);
      if (!verified) {
        return {'ok': false, 'error': 'unknown start point'};
      }
      final res = await _git(root, ['switch', '--detach', start]);
      if (res.exitCode != 0) {
        return _checkoutFailure(res);
      }
      final recorded = await _recordBranch(
        root,
        worktree,
        branch: '',
        previous: previous,
        previousSha: previousSha,
      );
      if (recorded != null) {
        return recorded;
      }
      return {'ok': true, 'branch': '', 'detached': true, 'dirty': false};
    }

    final name = branch?.trim() ?? '';
    if (!_isRefToken(name)) {
      return {'ok': false, 'error': 'invalid branch name'};
    }
    final format = await _git(root, ['check-ref-format', '--branch', name]);
    if (format.exitCode != 0) {
      return {'ok': false, 'error': 'invalid branch name'};
    }
    final start = startPoint?.trim() ?? '';
    if (start.isNotEmpty && !_isRefToken(start)) {
      return {'ok': false, 'error': 'invalid start point'};
    }

    final ProcessResult res;
    if (create) {
      final atHead = start.isEmpty || start == 'HEAD' || start == previous;
      if (atHead) {
        res = await _git(root, ['switch', '-c', name]);
      } else {
        if (!await _verifyCommit(root, start)) {
          return {'ok': false, 'error': 'unknown start point'};
        }
        final remote = await _git(root, [
          'show-ref',
          '--verify',
          '--quiet',
          'refs/remotes/$start',
        ]);
        res = remote.exitCode == 0
            ? await _git(root, ['switch', '--track', '-c', name, start])
            : await _git(root, ['switch', '-c', name, start]);
      }
    } else {
      final local = await _git(root, [
        'show-ref',
        '--verify',
        '--quiet',
        'refs/heads/$name',
      ]);
      if (local.exitCode == 0) {
        res = await _git(root, ['switch', '--', name]);
      } else {
        final remote = await _git(root, [
          'show-ref',
          '--verify',
          '--quiet',
          'refs/remotes/origin/$name',
        ]);
        if (remote.exitCode != 0) {
          return {'ok': false, 'error': 'no such branch'};
        }
        res = await _git(root, [
          'switch',
          '--track',
          '-c',
          name,
          'origin/$name',
        ]);
      }
    }
    if (res.exitCode != 0) {
      return _checkoutFailure(res);
    }
    final checked =
        ((await _git(root, ['rev-parse', '--abbrev-ref', 'HEAD'])).stdout
                as String)
            .trim();
    final recorded = await _recordBranch(
      root,
      worktree,
      branch: checked == 'HEAD' ? '' : checked,
      previous: previous,
      previousSha: previousSha,
      created: create ? name : null,
    );
    if (recorded != null) {
      return recorded;
    }
    return {
      'ok': true,
      'branch': checked == 'HEAD' ? '' : checked,
      'detached': checked == 'HEAD',
      'dirty': false,
    };
  }

  /// Writes [branch] onto the isolated-repo row. On failure, checks the
  /// previous commit back out (and deletes [created]) so the disk and the
  /// row cannot disagree about what a later push would publish.
  Future<Map<String, dynamic>?> _recordBranch(
    String root,
    IsolatedRepo worktree, {
    required String branch,
    required String previous,
    required String previousSha,
    String? created,
  }) async {
    try {
      await _isolated.upsert(worktree.copyWith(branch: branch));
    } on Object {
      if (previous == 'HEAD') {
        await _git(root, ['switch', '--detach', previousSha]);
      } else if (previous.isNotEmpty) {
        await _git(root, ['switch', '--', previous]);
      }
      if (created != null && created.isNotEmpty) {
        await _git(root, ['branch', '-D', created]);
      }
      return {'ok': false, 'error': 'could not record the checked-out branch'};
    }
    return null;
  }

  Future<bool> _verifyCommit(String root, String start) async {
    final verified = await _git(root, [
      'rev-parse',
      '--verify',
      '--end-of-options',
      '$start^{commit}',
    ]);
    return verified.exitCode == 0;
  }

  Map<String, dynamic> _checkoutFailure(ProcessResult res) {
    final err = (res.stderr as String).trim();
    final dirty =
        err.contains('local changes') ||
        err.contains('would be overwritten') ||
        err.contains('overwritten by checkout') ||
        err.contains('Please commit your changes');
    return {'ok': false, 'dirty': dirty, 'error': dirty ? null : err};
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
  /// first. Returns null when the space has no worktree for [repoId]; a map
  /// with `ok:false` + `error` on fetch/checkout failure.
  Future<Map<String, dynamic>?> syncToPrHead(
    String workspaceId,
    String spaceId,
    String repoId, {
    required String headRef,
    required String branch,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
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
    final token = await _githubToken?.call(workspaceId: workspaceId);
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
  /// repo, or null when none exists / the space isn't owned by the workspace.
  /// The filesystem root ONE repo read should run against: the conversation's
  /// isolated CoW worktree when [spaceId] is given, else the linked checkout.
  ///
  /// Null when there is nothing to read — a repo not linked to the workspace, or
  /// a space that owns no worktree for it. There is deliberately no fallback
  /// from the second case to the first: the conversation's writes never touch
  /// the linked checkout, so serving it would show a tree that disagrees with
  /// what the operator (and every agent) is actually editing.
  Future<String?> _readRoot(
    String workspaceId,
    String repoId,
    String? spaceId,
  ) async {
    if (spaceId != null) {
      return (await _worktreeFor(workspaceId, spaceId, repoId))?.path;
    }
    return (await _linkedRepo(workspaceId, repoId))?.path;
  }

  /// The roots a WORKSPACE-WIDE repo read should run across, paired with the
  /// repo id each one belongs to: the conversation's isolated CoW worktrees
  /// when [spaceId] is given (so the Explorer's search sees exactly the repos
  /// its tree lists), else every linked checkout.
  ///
  /// Roots that no longer exist on disk are skipped rather than fatal, so one
  /// broken checkout cannot abort the whole search.
  Future<List<({String root, String repoId})>> _readRoots(
    String workspaceId,
    String? spaceId,
  ) async {
    final candidates = <({String root, String repoId})>[];
    if (spaceId != null) {
      for (final w in await _isolated.forSpace(workspaceId, spaceId)) {
        candidates.add((root: p.normalize(w.path), repoId: w.repoId));
      }
    } else {
      for (final repo in await _linkedRepos(workspaceId)) {
        candidates.add((root: p.normalize(repo.path), repoId: repo.id));
      }
    }
    return [
      for (final c in candidates)
        if (Directory(c.root).existsSync()) c,
    ];
  }

  Future<ProcessResult> _git(String root, List<String> args) => Process.run(
    'git',
    args,
    workingDirectory: root,
    environment: const {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_NOSYSTEM': '1',
    },
  );

  Future<IsolatedRepo?> _worktreeFor(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    final worktrees = await _isolated.forSpace(workspaceId, spaceId);
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
    String spaceId,
  ) async {
    final worktrees = await _isolated.forSpace(workspaceId, spaceId);
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

/// The part of a rejected `git push` a person can act on: the hook's own
/// text and git's rejection. Progress and the `To <url>` echo are dropped.
/// Null when git said nothing — the push is still refused.
String? _pushRefusalText(ProcessResult result) {
  final lines = <String>[];
  void take(Object? raw) {
    for (final line in raw.toString().split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || _isPushNoise(trimmed)) {
        continue;
      }
      lines.add(trimmed);
    }
  }

  // stderr is git's rejection. A pre-push hook often explains itself on stdout.
  take(result.stderr);
  take(result.stdout);
  if (lines.isEmpty) {
    return null;
  }
  const cap = 8;
  final picked = lines.length <= cap
      ? lines
      : lines.sublist(lines.length - cap);
  return picked.join('\n');
}

bool _isPushNoise(String line) {
  if (line.startsWith('To ') || line.startsWith('to ')) {
    return true;
  }
  const prefixes = [
    'Enumerating objects',
    'Counting objects',
    'Compressing objects',
    'Writing objects',
    'Total ',
    'Delta compression',
    'remote: Resolving deltas',
  ];
  for (final prefix in prefixes) {
    if (line.startsWith(prefix) || line.startsWith('remote: $prefix')) {
      return true;
    }
  }
  return false;
}

/// True when rebasing onto `FETCH_HEAD` would conflict: uncommitted paths the
/// incoming commits also touch, or a clean merge-tree that still conflicts.
/// A dirty tree with no overlap is not a conflict — the caller refuses it as
/// dirty so a rebase cannot clobber it. `merge-tree` exit 1 is the conflict
/// signal; any other failure is "could not tell", and the rebase reports it.
Future<bool> _pullWouldConflict(
  Future<ProcessResult> Function(List<String> args, {Map<String, String>? env})
  git,
  Set<String> dirtyNames,
) async {
  if (dirtyNames.isNotEmpty) {
    final incoming = await git([
      'diff',
      '--name-only',
      '-z',
      'HEAD',
      'FETCH_HEAD',
    ]);
    if (incoming.exitCode == 0 &&
        dirtyNames.any(_nulPaths(incoming.stdout as String).contains)) {
      return true;
    }
  }
  final merge = await git([
    'merge-tree',
    '--write-tree',
    '--name-only',
    'HEAD',
    'FETCH_HEAD',
  ]);
  return merge.exitCode == 1;
}

/// Paths from `git status --porcelain -z`. A rename's original path is skipped;
/// the name in the worktree is the one a checkout would overwrite.
Set<String> _porcelainPaths(String raw) {
  final names = <String>{};
  final parts = raw.split('\x00');
  for (var i = 0; i < parts.length; i++) {
    final entry = parts[i];
    if (entry.length < 4) {
      continue;
    }
    names.add(entry.substring(3));
    final xy = entry.substring(0, 2);
    if (xy.contains('R') || xy.contains('C')) {
      i++;
    }
  }
  return names;
}

Set<String> _nulPaths(String raw) => {
  for (final part in raw.split('\x00'))
    if (part.isNotEmpty) part,
};

/// A branch, remote-tracking ref or tag name that cannot be an option and
/// cannot escape the ref namespace. `git check-ref-format` still runs on
/// branch names; this only keeps a caller-supplied token out of argv flags.
bool _isRefToken(String name) {
  if (name.isEmpty || name.length > 250) {
    return false;
  }
  if (name.startsWith('-') || name.startsWith('.') || name.startsWith('/')) {
    return false;
  }
  if (name.endsWith('/') || name.endsWith('.') || name.endsWith('.lock')) {
    return false;
  }
  if (name.contains('..') || name.contains('//') || name.contains('@{')) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9._/@+-]+$').hasMatch(name);
}

/// `(kind, name, localName)` for a `for-each-ref` refname, or null.
(String, String, String)? _parseRefName(String refname) {
  const heads = 'refs/heads/';
  const remotes = 'refs/remotes/';
  const tags = 'refs/tags/';
  if (refname.startsWith(heads)) {
    final name = refname.substring(heads.length);
    if (name.isEmpty) {
      return null;
    }
    return ('branch', name, name);
  }
  if (refname.startsWith(remotes)) {
    final name = refname.substring(remotes.length);
    final slash = name.indexOf('/');
    if (name.isEmpty || slash <= 0 || slash == name.length - 1) {
      return null;
    }
    return ('remote', name, name.substring(slash + 1));
  }
  if (refname.startsWith(tags)) {
    final name = refname.substring(tags.length);
    if (name.isEmpty) {
      return null;
    }
    return ('tag', name, name);
  }
  return null;
}

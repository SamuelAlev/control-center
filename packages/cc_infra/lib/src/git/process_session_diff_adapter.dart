import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/session_diff_port.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_domain/features/pr_review/domain/services/scm_path_order.dart';
import 'package:cc_infra/src/git/git_diff_z_parser.dart';
import 'package:cc_infra/src/git/working_tree_capture.dart';
import 'package:cc_natives/cc_natives.dart' show IsolatedGit, RigWorktreeGuard;
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// A [SessionDiffPort] that shells out to `git` to compute what changed in a
/// worktree since a snapshot ref.
///
/// Mirrors the local-git PR diff source: `--name-status -z` for status/rename
/// info, `--numstat -z` for +/- counts, then a full `git diff` whose output is
/// sliced per-file by `extractAllFilePatches`. When `headRef` is omitted the
/// base ref is diffed against the live working tree, which is what "review what
/// this session changed before I commit" wants.
///
/// Every list comes back in VS Code's Source Control order ([compareScmPaths]),
/// with untracked files mixed in rather than appended, so the panel and the
/// review pane list the same files in the same order.
///
/// Both reads start from one `git status --porcelain=v2` snapshot
/// ([_statusSnapshot]). It refreshes the index's stat cache, says whether
/// anything changed at all, lists the untracked files, and fingerprints
/// everything a diff of the tree depends on. The Source Control panel polls
/// [groupedChanges] every few seconds; an unchanged fingerprint answers from
/// the last result instead of re-running every diff.
class ProcessSessionDiffAdapter implements SessionDiffPort {
  /// Creates a [ProcessSessionDiffAdapter].
  const ProcessSessionDiffAdapter();

  /// The fast working-tree diff hands each untracked file to its own
  /// `git diff --no-index`. Past this many, one whole-tree capture is cheaper.
  static const _untrackedFastLimit = 24;

  @override
  Future<List<PrFile>> changedFiles(
    String worktreePath,
    String baseRef, {
    String? headRef,
  }) async {
    if (headRef == null && baseRef == 'HEAD') {
      return _workingTreeChanges(worktreePath);
    }
    if (!await _isWorktree(worktreePath)) {
      return const [];
    }
    return _capturedChanges(worktreePath, baseRef, headRef: headRef);
  }

  /// HEAD against the live working tree, untracked files included: what the
  /// review pane shows.
  ///
  /// Tracked changes come from `git diff HEAD`, which reads the real index's
  /// stat cache (refreshed by the status snapshot, exactly as `git status`
  /// trusts it) and untracked files are diffed one by one. No whole-tree
  /// capture, so nothing is hashed that did not change and the read does not
  /// queue behind a checkpoint capture of the same worktree.
  ///
  /// Two shapes still take the capture: a deleted tracked path next to
  /// untracked files (a move without `git mv`, or `git rm --cached`, which
  /// only a tree-to-tree diff pairs up as a rename or as no change), and more
  /// untracked files than [_untrackedFastLimit].
  Future<List<PrFile>> _workingTreeChanges(String worktreePath) async {
    final snapshot = await _statusSnapshot(worktreePath);
    if (snapshot == null) {
      return const [];
    }
    final key = _memoKey(worktreePath);
    final remembered = _workingTreeMemo.lookup(key, snapshot.fingerprint);
    if (remembered != null) {
      return remembered;
    }
    final List<PrFile> files;
    if (snapshot.clean) {
      files = const [];
    } else if (snapshot.headOid == null ||
        (snapshot.untracked.isNotEmpty &&
            (snapshot.hasTrackedDeletion ||
                snapshot.untracked.length > _untrackedFastLimit))) {
      files = await _capturedChanges(worktreePath, 'HEAD');
    } else {
      final (tracked, untracked) = await (
        _filesForDiff(worktreePath, const ['HEAD']),
        _untrackedFiles(worktreePath, snapshot.untracked),
      ).wait;
      files = _scmOrdered([...tracked, ...untracked]);
    }
    _workingTreeMemo.store(key, snapshot.fingerprint, files);
    return files;
  }

  /// [baseRef] against [headRef], or against a capture of the working tree
  /// when [headRef] is omitted.
  Future<List<PrFile>> _capturedChanges(
    String worktreePath,
    String baseRef, {
    String? headRef,
  }) async {
    // Diff two trees so brand-new (untracked) files show up — a plain
    // `git diff <tree>` ignores untracked files. When no head ref is given we
    // snapshot the working tree and diff against that.
    final head = headRef ?? await captureWorkingTree(worktreePath);
    if (head == null) {
      return const [];
    }
    return _scmOrdered(await _filesForDiff(worktreePath, [baseRef, head]));
  }

  @override
  Future<({List<PrFile> staged, List<PrFile> unstaged})> groupedChanges(
    String worktreePath,
  ) async {
    const empty = (staged: <PrFile>[], unstaged: <PrFile>[]);
    // The snapshot also syncs the index's stat cache, so a CoW copy's fresh
    // mtimes don't make unchanged files read as modified in the diffs below.
    final snapshot = await _statusSnapshot(worktreePath);
    if (snapshot == null) {
      return empty;
    }
    final key = _memoKey(worktreePath);
    final remembered = _groupedMemo.lookup(key, snapshot.fingerprint);
    if (remembered != null) {
      return remembered;
    }
    if (snapshot.clean) {
      _groupedMemo.store(key, snapshot.fingerprint, empty);
      return empty;
    }

    // Staged = index vs HEAD; unstaged (tracked) = working tree vs index.
    // Read-only once the snapshot's refresh has landed, so they run side by
    // side.
    final (staged, unstagedTracked, untracked) = await (
      _filesForDiff(worktreePath, const ['--cached', 'HEAD']),
      _filesForDiff(worktreePath, const []),
      _untrackedFiles(worktreePath, snapshot.untracked),
    ).wait;
    final grouped = (
      staged: _scmOrdered(staged),
      unstaged: _scmOrdered([...unstagedTracked, ...untracked]),
    );
    _groupedMemo.store(key, snapshot.fingerprint, grouped);
    return grouped;
  }

  /// One `git status --porcelain=v2` of [worktreePath], or null when it is
  /// not a git worktree.
  ///
  /// Status refreshes the index's stat cache and writes it back when it can
  /// take the lock, as `git status` always does. The fingerprint covers
  /// everything the diffs of this tree read: HEAD, every changed path with its
  /// index blob (so a re-staged hunk counts) and, for each listed path, its
  /// size, mtime and ctime on disk (so an edit to an already-modified file
  /// counts). A path status does not list matches HEAD and the index, so it
  /// contributes nothing to any diff.
  Future<_StatusSnapshot?> _statusSnapshot(String worktreePath) async {
    if (!Directory(worktreePath).existsSync()) {
      return null;
    }
    final res = await _run([
      'status',
      '--porcelain=v2',
      '-z',
      '--branch',
      '--untracked-files=all',
    ], worktreePath);
    if (res.exitCode != 0) {
      return null;
    }
    final parsed = parseGitStatusV2Z(res.stdout);
    final stats = await Future.wait([
      for (final path in parsed.paths)
        FileStat.stat(p.join(worktreePath, path)),
    ]);
    final fingerprint = StringBuffer(res.stdout);
    for (var i = 0; i < stats.length; i++) {
      final s = stats[i];
      fingerprint
        ..write('\x00')
        ..write(parsed.paths[i])
        ..write('|${s.type}|${s.size}')
        ..write('|${s.modified.microsecondsSinceEpoch}')
        ..write('|${s.changed.microsecondsSinceEpoch}');
    }
    return _StatusSnapshot(
      headOid: parsed.headOid,
      untracked: parsed.untracked,
      hasTrackedDeletion: parsed.hasTrackedDeletion,
      clean: parsed.paths.isEmpty,
      fingerprint: sha1.convert(utf8.encode(fingerprint.toString())).toString(),
    );
  }

  static String _memoKey(String worktreePath) =>
      p.normalize(p.absolute(worktreePath));

  /// Runs the name-status / numstat / full-diff triple for the given `git diff`
  /// [diffArgs] and assembles [PrFile]s (status + counts + patch).
  Future<List<PrFile>> _filesForDiff(
    String worktreePath,
    List<String> diffArgs,
  ) async {
    // quotePath=false keeps non-ASCII paths raw in the `diff --git` headers so
    // they match the verbatim `-z` paths — otherwise the per-file patch lookup
    // misses and the file renders with an empty body.
    final (nameStatus, numstat, full) = await (
      _run(['diff', '--name-status', '-z', ...diffArgs], worktreePath),
      _run(['diff', '--numstat', '-z', ...diffArgs], worktreePath),
      _run([
        '-c',
        'core.quotePath=false',
        'diff',
        '--no-color',
        ...diffArgs,
      ], worktreePath),
    ).wait;
    if (nameStatus.exitCode != 0 || numstat.exitCode != 0) {
      return const [];
    }
    final statusMap = parseGitNameStatusZ(nameStatus.stdout);
    final files = parseGitNumstatZ(numstat.stdout, statusMap);
    if (files.isEmpty) {
      return const [];
    }
    final patches = full.exitCode == 0
        ? extractAllFilePatches(full.stdout)
        : const <String, String>{};
    return [
      for (final f in files)
        PrFile(
          filename: f.filename,
          status: f.status,
          additions: f.additions,
          deletions: f.deletions,
          patch: patches[f.filename] ?? '',
          previousFilename: f.previousFilename,
        ),
    ];
  }

  /// The untracked files [names] (from the status snapshot), each as an added
  /// [PrFile] with a whole-file patch (via `git diff --no-index` against
  /// `/dev/null`).
  Future<List<PrFile>> _untrackedFiles(
    String worktreePath,
    List<String> names,
  ) async {
    final out = <PrFile>[];
    // A few at a time: an agent can leave hundreds of new files.
    for (var i = 0; i < names.length; i += _untrackedBatch) {
      out.addAll(
        await Future.wait(
          names
              .skip(i)
              .take(_untrackedBatch)
              .map((name) => _untrackedFile(worktreePath, name)),
        ),
      );
    }
    return out;
  }

  static const _untrackedBatch = 8;

  Future<PrFile> _untrackedFile(String worktreePath, String name) async {
    // --no-index exits 1 when the files differ (always, for a new file) — that
    // is expected, so read stdout regardless of the exit code.
    final diff = await _run([
      '-c',
      'core.quotePath=false',
      'diff',
      '--no-color',
      '--no-index',
      '--',
      '/dev/null',
      name,
    ], worktreePath);
    final patch = extractAllFilePatches(diff.stdout)[name] ?? diff.stdout;
    // Count added lines from the patch (lines starting with '+' that aren't
    // the '+++' file header).
    final additions = patch
        .split('\n')
        .where((l) => l.startsWith('+') && !l.startsWith('+++'))
        .length;
    return PrFile(
      filename: name,
      status: PrFileStatus.added,
      additions: additions,
      deletions: 0,
      patch: patch,
    );
  }

  List<PrFile> _scmOrdered(List<PrFile> files) =>
      [...files]..sort((a, b) => compareScmPaths(a.filename, b.filename));

  Future<bool> _isWorktree(String path) async {
    if (!Directory(path).existsSync()) {
      return false;
    }
    final result = await _run(['rev-parse', '--is-inside-work-tree'], path);
    return result.exitCode == 0 && result.stdout.trim() == 'true';
  }

  Future<({int exitCode, String stdout, String stderr})> _run(
    List<String> args,
    String workdir, {
    Map<String, String>? env,
  }) async {
    final result = await IsolatedGit.run(
      RigWorktreeGuard.gitArgs(args, workingDirectory: workdir),
      workingDirectory: workdir,
      environment: env,
    );
    return (
      exitCode: result.exitCode,
      stdout: result.stdout as String,
      stderr: result.stderr as String,
    );
  }
}

/// What one `git status --porcelain=v2` said about a worktree.
class _StatusSnapshot {
  const _StatusSnapshot({
    required this.headOid,
    required this.untracked,
    required this.hasTrackedDeletion,
    required this.clean,
    required this.fingerprint,
  });

  /// HEAD's commit, or null before the first commit.
  final String? headOid;

  /// Untracked, non-ignored files, as `git ls-files --others
  /// --exclude-standard` lists them.
  final List<String> untracked;

  /// Whether a tracked path is deleted in the index or the working tree.
  final bool hasTrackedDeletion;

  /// Nothing staged, modified or untracked.
  final bool clean;

  final String fingerprint;
}

/// `git status --porcelain=v2 -z --branch` output, parsed.
///
/// `paths` lists every path an entry names (a rename's source too), in
/// output order; `untracked` the `?` entries.
@visibleForTesting
({
  String? headOid,
  List<String> paths,
  List<String> untracked,
  bool hasTrackedDeletion,
})
parseGitStatusV2Z(String output) {
  String? headOid;
  final paths = <String>[];
  final untracked = <String>[];
  var deletion = false;
  final fields = output.split('\x00');
  for (var i = 0; i < fields.length; i++) {
    final entry = fields[i];
    if (entry.isEmpty) {
      continue;
    }
    switch (entry[0]) {
      case '#':
        const oidHeader = '# branch.oid ';
        if (entry.startsWith(oidHeader)) {
          final oid = entry.substring(oidHeader.length).trim();
          headOid = oid == '(initial)' ? null : oid;
        }
      case '?':
        final path = entry.substring(2);
        paths.add(path);
        untracked.add(path);
      case '1':
        // 1 XY sub mH mI mW hH hI path
        final parts = entry.split(' ');
        if (parts.length >= 9) {
          deletion = deletion || parts[1].contains('D');
          paths.add(parts.sublist(8).join(' '));
        }
      case '2':
        // 2 XY sub mH mI mW hH hI Xscore path, then the source path as its
        // own NUL-terminated field.
        final parts = entry.split(' ');
        if (parts.length >= 10) {
          deletion = deletion || parts[1].contains('D');
          paths.add(parts.sublist(9).join(' '));
        }
        if (i + 1 < fields.length && fields[i + 1].isNotEmpty) {
          paths.add(fields[++i]);
        }
      case 'u':
        // u XY sub m1 m2 m3 mW h1 h2 h3 path
        final parts = entry.split(' ');
        if (parts.length >= 11) {
          deletion = deletion || parts[1].contains('D');
          paths.add(parts.sublist(10).join(' '));
        }
    }
  }
  return (
    headOid: headOid,
    paths: paths,
    untracked: untracked,
    hasTrackedDeletion: deletion,
  );
}

/// The last result per worktree, valid while its status fingerprint holds.
///
/// Process-wide like the capture queue in `working_tree_capture.dart`: every
/// client polling one worktree shares it. A hit needs the exact fingerprint,
/// so a stale entry is never served, only recomputed. Bounded, least recently
/// used first out.
class _FingerprintMemo<T> {
  _FingerprintMemo(this._capacity);

  final int _capacity;
  final _entries = <String, ({String fingerprint, T value})>{};

  T? lookup(String key, String fingerprint) {
    final entry = _entries.remove(key);
    if (entry == null) {
      return null;
    }
    _entries[key] = entry;
    return entry.fingerprint == fingerprint ? entry.value : null;
  }

  void store(String key, String fingerprint, T value) {
    _entries
      ..remove(key)
      ..[key] = (fingerprint: fingerprint, value: value);
    while (_entries.length > _capacity) {
      _entries.remove(_entries.keys.first);
    }
  }
}

final _groupedMemo =
    _FingerprintMemo<({List<PrFile> staged, List<PrFile> unstaged})>(32);
final _workingTreeMemo = _FingerprintMemo<List<PrFile>>(32);

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// A cheap fingerprint of a checkout's state, used by the code indexer's
/// boot-time short-circuit: when a checkout's fingerprint matches the one
/// recorded at its last successful index, the whole run (file-state read,
/// walk, hash, prune, reference resolution) is skipped.
class RepoStateFingerprint {
  /// Creates a [RepoStateFingerprint].
  const RepoStateFingerprint({
    required this.headSha,
    required this.digest,
    required this.dirtyCount,
  });

  /// `git rev-parse HEAD`. Empty string on an unborn branch (a repo with no
  /// commits yet).
  final String headSha;

  /// SHA-256 over the HEAD sha, the raw `git status --porcelain -z -uall`
  /// output and a `path|mtime|size` stat fold of every dirty path. The stat
  /// fold is the correctness fix for porcelain's blind spot: a second edit to
  /// an already-dirty file leaves the porcelain output byte-identical.
  final String digest;

  /// Number of dirty (modified/untracked/staged) entries git reported.
  final int dirtyCount;
}

/// Probes a checkout's git state to produce a [RepoStateFingerprint].
///
/// Deliberately git-driven: `git status` stats files through git's own index
/// and stat cache, which is far faster than a Dart tree walk and it reads
/// the same index `git ls-files` enumeration uses — so the fingerprint is
/// consistent with what the walker would see, by construction.
///
/// Returns `null` (= caller must NOT skip; run the real walk) whenever the
/// state cannot be fingerprinted conservatively: not a git work tree, git
/// unavailable, or a dirty set too large to stat cheaply.
class RepoStateProbe {
  /// Creates a [RepoStateProbe].
  const RepoStateProbe({this.maxDirtyEntries = 5000});

  /// Above this many dirty entries the probe gives up and returns `null` —
  /// at that point stat-ing them all approaches the cost of the real walk the
  /// probe exists to avoid.
  final int maxDirtyEntries;

  /// Fingerprints the checkout at [repoPath], or returns `null` when no
  /// conservative fingerprint is possible.
  Future<RepoStateFingerprint?> probe(String repoPath) async {
    final head = await _git(repoPath, const ['rev-parse', 'HEAD']);
    // `rev-parse HEAD` fails on an unborn branch even inside a valid work
    // tree; distinguish that from "not a repo" so a fresh `git init` checkout
    // still fingerprints (as an empty head + status digest).
    String headSha;
    if (head == null) {
      final inTree = await _git(repoPath, const [
        'rev-parse',
        '--is-inside-work-tree',
      ]);
      if (inTree?.trim() != 'true') {
        return null;
      }
      headSha = '';
    } else {
      headSha = head.trim();
    }

    // `-uall` is required: without it an untracked directory collapses to a
    // single `dir/` entry and new files created inside it never move the
    // digest.
    final status = await _git(repoPath, const [
      'status',
      '--porcelain',
      '-z',
      '--untracked-files=all',
      '--ignore-submodules=none',
    ]);
    if (status == null) {
      return null;
    }

    final entries = status
        .split('\u0000')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (entries.length > maxDirtyEntries) {
      return null;
    }

    // Fold a stat of every dirty path into the digest, on a WORKER isolate.
    //
    // Porcelain `-z` emits `XY path` records; a rename (`R`/`C` in X) emits
    // the destination in the record and the SOURCE as the following
    // NUL-separated field, with no status prefix. Treating every field as a
    // path (prefixed fields stripped of their 3-char `XY ` header) covers
    // both.
    //
    // Off-isolate because this runs on cc_server's main isolate on EVERY
    // index run — including every watcher-event run — and folds up to
    // `maxDirtyEntries` (5,000) synchronous stats in a loop. Microseconds each
    // on a warm APFS volume; a slow or networked home directory turns the same
    // loop into a visible event-loop stall.
    final (statFold, statPaths) = await Isolate.run(
      () => _statFold(repoPath, entries),
    );
    final digest = sha256
        .convert(utf8.encode('$headSha\u0000$status\u0000$statFold'))
        .toString();
    return RepoStateFingerprint(
      headSha: headSha,
      digest: digest,
      dirtyCount: statPaths,
    );
  }

  /// The path component of a porcelain `-z` field: strips the 3-char `XY `
  /// status prefix when present; a bare field (a rename's source path) is
  /// returned as-is.
  static String _pathOf(String entry) {
    if (entry.length > 3 && entry[2] == ' ') {
      return entry.substring(3);
    }
    return entry;
  }

  /// Stats every dirty path and folds the result into a digest input.
  /// Runs inside a worker isolate — see the call site.
  static (String, int) _statFold(String repoPath, List<String> entries) {
    final statFold = StringBuffer();
    var statPaths = 0;
    for (final entry in entries) {
      final path = _pathOf(entry);
      if (path.isEmpty) {
        continue;
      }
      statPaths++;
      final abs = p.normalize(p.join(repoPath, p.joinAll(path.split('/'))));
      try {
        final stat = File(abs).statSync();
        if (stat.type == FileSystemEntityType.notFound) {
          statFold.writeln('$path|missing');
        } else {
          statFold.writeln(
            '$path|${stat.modified.microsecondsSinceEpoch}|${stat.size}',
          );
        }
      } on FileSystemException {
        statFold.writeln('$path|unreadable');
      }
    }
    return (statFold.toString(), statPaths);
  }

  /// Runs git with [args] in [repoPath]; stdout on success, null on any
  /// failure (missing binary, non-zero exit).
  static Future<String?> _git(String repoPath, List<String> args) async {
    ProcessResult result;
    try {
      result = await Process.run('git', args, workingDirectory: repoPath);
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) {
      return null;
    }
    return result.stdout as String;
  }
}

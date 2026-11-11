part of 'repo_ide_data_service.dart';

/// The part of a rejected `git push` a person can act on: the remote's own
/// text (its hooks speak as `remote: …`) and git's rejection. Progress and the `To <url>` echo are dropped.
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

  // stderr carries git's rejection and the remote's messages; stdout is
  // read too, in case git wrote anything there.
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

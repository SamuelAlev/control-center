part of 'repo_ide_data_service.dart';

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

/// A failed checkout as the IDE reports it: `dirty` when git refused to
/// overwrite local changes, else git's own message.
Map<String, dynamic> _checkoutFailure(ProcessResult res) {
  final err = (res.stderr as String).trim();
  final dirty =
      err.contains('local changes') ||
      err.contains('would be overwritten') ||
      err.contains('overwritten by checkout') ||
      err.contains('Please commit your changes');
  return {'ok': false, 'dirty': dirty, 'error': dirty ? null : err};
}

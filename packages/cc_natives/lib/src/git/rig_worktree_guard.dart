import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// A worktree's git metadata changed while a rig had it mounted.
///
/// Thrown instead of running git: a stack nobody reviewed may have planted
/// `core.fsmonitor`, a filter driver, `diff.external`, `core.sshCommand` or a
/// hook, and the host's own git would run it. A person has to look first.
class RigWorktreeTampered implements Exception {
  /// Creates a [RigWorktreeTampered].
  const RigWorktreeTampered(this.worktree);

  /// The worktree whose metadata changed.
  final String worktree;

  /// A sentence fit for a person.
  String get message =>
      'The git metadata of $worktree changed while an environment rig had it '
      'mounted, so Control Center will not run git there. Inspect '
      '.git/config and .git/hooks, then release the worktree.';

  @override
  String toString() => 'RigWorktreeTampered: $message';
}

/// Keeps the host's own git from running what a rig planted in a worktree.
///
/// A worktree is quarantined before a rig mounts it, with a fingerprint of
/// everything in its git metadata that can make git run a program. Every git
/// invocation CC makes in it then gets `core.fsmonitor` and `core.hooksPath`
/// switched off, and is refused outright if the fingerprint has changed:
/// `-c` cannot neutralize a filter driver or an `include.path`, the
/// fingerprint catches them.
///
/// The quarantine lives in two places. A marker inside the git directory is
/// visible from every isolate and survives restarts; the rig mounts that
/// directory read-only, so it cannot remove it. The registry, persisted at
/// [storePath], holds even if a marker were removed.
// A namespace over process-wide state that every git call site consults.
// ignore: avoid_classes_with_only_static_members
abstract final class RigWorktreeGuard {
  /// The marker's name inside the git directory.
  static const String markerName = 'cc-rig-quarantine';

  /// Where the registry persists, or null to keep it in memory. Set once by
  /// the host at boot.
  static String? storePath;

  static Map<String, String>? _registry;

  /// The flags every guarded invocation gets.
  static const List<String> hardening = [
    '-c',
    'core.fsmonitor=false',
    '-c',
    'core.hooksPath=/dev/null',
  ];

  static Map<String, String> _entries() {
    final loaded = _registry;
    if (loaded != null) {
      return loaded;
    }
    final store = storePath;
    final entries = <String, String>{};
    if (store != null && File(store).existsSync()) {
      try {
        final decoded = jsonDecode(File(store).readAsStringSync());
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.value is String) {
              entries['${entry.key}'] = entry.value as String;
            }
          }
        }
      } on FormatException {
        // A damaged store must not free anything: markers still guard.
      }
    }
    return _registry = entries;
  }

  static void _persist() {
    final store = storePath;
    if (store == null) {
      return;
    }
    final file = File(store);
    file.parent.createSync(recursive: true);
    final temp = File('$store.tmp')..writeAsStringSync(jsonEncode(_entries()));
    temp.renameSync(file.path);
  }

  /// The directory `.git` names in [worktree]: itself, or where a pointer file
  /// leads. Null when there is no git metadata.
  static String? gitDirOf(String worktree) {
    final dotGit = p.join(worktree, '.git');
    if (FileSystemEntity.isDirectorySync(dotGit)) {
      return dotGit;
    }
    if (!FileSystemEntity.isFileSync(dotGit)) {
      return null;
    }
    final line = File(dotGit).readAsStringSync().trim();
    if (!line.startsWith('gitdir:')) {
      return null;
    }
    final target = line.substring('gitdir:'.length).trim();
    return p.normalize(
      p.isAbsolute(target) ? target : p.join(worktree, target),
    );
  }

  /// A hash of everything in [worktree]'s git metadata that can make git run
  /// a program, or redirect it to metadata that does.
  static String fingerprintOf(String worktree) {
    final digest = AccumulatorSink<Digest>();
    final sink = sha256.startChunkedConversion(digest);
    void add(String label, File file) {
      sink.add(utf8.encode('$label\u0000'));
      if (file.existsSync()) {
        sink.add(file.readAsBytesSync());
      }
      sink.add(const [0]);
    }

    add('.git', File(p.join(worktree, '.git')));
    final gitDir = gitDirOf(worktree);
    if (gitDir != null) {
      final dirs = {gitDir};
      final common = File(p.join(gitDir, 'commondir'));
      if (common.existsSync()) {
        final target = common.readAsStringSync().trim();
        dirs.add(
          p.normalize(p.isAbsolute(target) ? target : p.join(gitDir, target)),
        );
      }
      for (final dir in dirs.toList()..sort()) {
        for (final name in const [
          'config',
          'config.worktree',
          'commondir',
          'gitdir',
          'info/attributes',
        ]) {
          add('$dir/$name', File(p.join(dir, name)));
        }
        final hooks = Directory(p.join(dir, 'hooks'));
        if (hooks.existsSync()) {
          final files =
              hooks
                  .listSync(recursive: true, followLinks: false)
                  .whereType<File>()
                  .toList()
                ..sort((a, b) => a.path.compareTo(b.path));
          for (final hook in files) {
            add(hook.path, hook);
          }
        }
      }
    }
    sink.close();
    return digest.events.single.toString();
  }

  /// Quarantines [worktree] before a rig mounts it. Idempotent: an existing
  /// quarantine keeps its original fingerprint, which is the trusted one.
  static void quarantine(String worktree) {
    final root = p.normalize(p.absolute(worktree));
    final entries = _entries();
    final existing = entries[root] ?? _readMarker(root);
    final fingerprint = existing ?? fingerprintOf(root);
    entries[root] = fingerprint;
    _persist();
    final gitDir = gitDirOf(root);
    if (gitDir != null) {
      File(p.join(gitDir, markerName)).writeAsStringSync(fingerprint);
    }
  }

  /// Lifts the quarantine when the metadata is as it was. Returns false, and
  /// keeps it, when something changed: that worktree needs a person.
  static bool release(String worktree) {
    final root = p.normalize(p.absolute(worktree));
    final trusted = _entries()[root] ?? _readMarker(root);
    if (trusted == null) {
      return true;
    }
    if (fingerprintOf(root) != trusted) {
      return false;
    }
    _entries().remove(root);
    _persist();
    final gitDir = gitDirOf(root);
    if (gitDir != null) {
      final marker = File(p.join(gitDir, markerName));
      if (marker.existsSync()) {
        marker.deleteSync();
      }
    }
    return true;
  }

  /// Lifts the quarantine after a person has looked, whatever changed.
  static void forceRelease(String worktree) {
    final root = p.normalize(p.absolute(worktree));
    _entries().remove(root);
    _persist();
    final gitDir = gitDirOf(root);
    final marker = gitDir == null ? null : File(p.join(gitDir, markerName));
    if (marker != null && marker.existsSync()) {
      marker.deleteSync();
    }
  }

  static String? _readMarker(String root) {
    final gitDir = gitDirOf(root);
    if (gitDir == null) {
      return null;
    }
    final marker = File(p.join(gitDir, markerName));
    return marker.existsSync() ? marker.readAsStringSync().trim() : null;
  }

  /// The quarantined worktree [path] lies in, and its trusted fingerprint.
  static (String, String)? _quarantineFor(String path) {
    final target = p.normalize(p.absolute(path));
    for (final entry in _entries().entries) {
      if (target == entry.key || p.isWithin(entry.key, target)) {
        return (entry.key, entry.value);
      }
    }
    // Another isolate, or a registry that did not persist: walk up to the
    // worktree and read its marker.
    for (var dir = target; ; dir = p.dirname(dir)) {
      final marker = _readMarker(dir);
      if (marker != null) {
        return (dir, marker);
      }
      if (p.dirname(dir) == dir) {
        return null;
      }
    }
  }

  /// [args] for a git invocation in [workingDirectory] (or wherever `-C`
  /// points), hardened when that is a quarantined worktree.
  ///
  /// Throws [RigWorktreeTampered] when the worktree's metadata changed.
  static List<String> gitArgs(List<String> args, {String? workingDirectory}) {
    final at = args.indexOf('-C');
    final path = at >= 0 && at + 1 < args.length
        ? p.join(workingDirectory ?? Directory.current.path, args[at + 1])
        : workingDirectory ?? Directory.current.path;
    final quarantine = _quarantineFor(path);
    if (quarantine == null) {
      return args;
    }
    final (root, trusted) = quarantine;
    if (fingerprintOf(root) != trusted) {
      throw RigWorktreeTampered(root);
    }
    return [...hardening, ...args];
  }

  /// Forgets the in-memory registry, as a fresh isolate sees it.
  static void debugReset() => _registry = null;
}

/// Collects a chunked hash's result.
class AccumulatorSink<T> implements Sink<T> {
  /// Every value added.
  final List<T> events = [];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}

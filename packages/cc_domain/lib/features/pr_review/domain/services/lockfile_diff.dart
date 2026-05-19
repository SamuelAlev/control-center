// Offline dependency-change extraction for the PR Review Hub's "Dependencies"
// panel: given the base and head bytes of a lockfile, say what a human actually
// needs to know — what arrived, what left, and what moved version.
//
// Everything here is a hand-rolled parser on purpose. `cc_domain` is the shared
// kernel, so it carries no `yaml` (or any other) infrastructure dependency, and
// a lockfile is machine-generated: its shape is far narrower than the format it
// nominally belongs to. The two formats that are NOT safely narrow (pnpm, yarn)
// say so through `bestEffort` rather than pretending to precision they cannot
// deliver.
//
// Null-on-malformed / empty-on-malformed throughout, the same discipline as
// `CohortInsights`: a lockfile written by a tool version we do not know yields
// "no dependencies read", never a half-parsed lie that would show a phantom
// upgrade on a review page.

import 'dart:convert';

/// Which package ecosystem a lockfile belongs to.
enum LockfileEcosystem {
  /// Dart / Flutter — `pubspec.lock`.
  pub,

  /// npm — `package-lock.json`.
  npm,

  /// pnpm — `pnpm-lock.yaml`.
  pnpm,

  /// Yarn classic (v1) — `yarn.lock`.
  yarn;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a stored name, or null when it names no known ecosystem.
  ///
  /// Unlike an enum default this returns null, because a diff whose ecosystem
  /// is unreadable is not a diff of some other ecosystem — it is unusable.
  static LockfileEcosystem? fromName(String? name) {
    if (name == null) {
      return null;
    }
    for (final value in LockfileEcosystem.values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }

  /// Detects the ecosystem from a repo-relative path's BASENAME, or null.
  ///
  /// Only the basename is consulted: a lockfile is identified by its filename
  /// wherever it sits in a monorepo, and a directory happening to be named
  /// `yarn.lock/` is not one.
  static LockfileEcosystem? detect(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final basename = normalized.substring(normalized.lastIndexOf('/') + 1);
    return switch (basename) {
      'pubspec.lock' => pub,
      'package-lock.json' => npm,
      'pnpm-lock.yaml' => pnpm,
      'yarn.lock' => yarn,
      _ => null,
    };
  }
}

/// A dependency whose version changed.
class DependencyUpgrade {
  /// Creates a [DependencyUpgrade].
  const DependencyUpgrade({
    required this.name,
    required this.from,
    required this.to,
  });

  /// Package name, scope included (`@scope/foo`).
  final String name;

  /// Version recorded in the base revision.
  final String from;

  /// Version recorded in the head revision.
  final String to;

  /// Whether the leading numeric component increased (or either side is
  /// unparseable and the strings differ) — a best-effort major-bump signal.
  ///
  /// Deliberately biased toward flagging: a git ref or a path dependency has no
  /// major to compare, and "this changed and we cannot tell how much" is the
  /// case a reviewer most wants pulled forward.
  bool get majorBump {
    if (from == to) {
      return false;
    }
    final before = _leadingMajor(from);
    final after = _leadingMajor(to);
    if (before == null || after == null) {
      return true;
    }
    return after > before;
  }

  /// Builds from JSON, or null when the shape is unusable.
  static DependencyUpgrade? fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final from = json['from'];
    final to = json['to'];
    if (name is! String || from is! String || to is! String) {
      return null;
    }
    return DependencyUpgrade(name: name, from: from, to: to);
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {'name': name, 'from': from, 'to': to};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyUpgrade &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(name, from, to);

  @override
  String toString() => 'DependencyUpgrade($name: $from -> $to)';
}

/// The computed difference between two lockfile revisions.
class DependencyDiff {
  /// Creates a [DependencyDiff].
  const DependencyDiff({
    required this.ecosystem,
    this.added = const {},
    this.removed = const {},
    this.upgraded = const [],
    this.bestEffort = false,
  });

  /// Which lockfile format this diff was read from.
  final LockfileEcosystem ecosystem;

  /// Dependencies present in head but not base, `name -> version`.
  final Map<String, String> added;

  /// Dependencies present in base but not head, `name -> version`.
  final Map<String, String> removed;

  /// Dependencies present in both at different versions, sorted by name.
  final List<DependencyUpgrade> upgraded;

  /// True when the parser could not fully guarantee the extraction (pnpm/yarn
  /// hand-rolled formats). The UI labels this rather than implying precision.
  final bool bestEffort;

  /// Whether nothing changed (or nothing could be read).
  bool get isEmpty => added.isEmpty && removed.isEmpty && upgraded.isEmpty;

  /// added + removed + upgraded count.
  int get churn => added.length + removed.length + upgraded.length;

  /// Builds from JSON, or null when the shape is unusable.
  ///
  /// An unknown [ecosystem] is fatal: the panel's labelling and the
  /// [bestEffort] caveat both hang off it, so a diff without one is dropped
  /// rather than shown under a guessed format.
  static DependencyDiff? fromJson(Map<String, dynamic> json) {
    final rawEcosystem = json['ecosystem'];
    // Type-tested rather than cast: a blob whose `ecosystem` is a number is
    // exactly the malformed case this returns null for, so it must not throw
    // on the way to saying so.
    final ecosystem = LockfileEcosystem.fromName(
      rawEcosystem is String ? rawEcosystem : null,
    );
    if (ecosystem == null) {
      return null;
    }
    final upgraded = <DependencyUpgrade>[];
    final rawUpgraded = json['upgraded'];
    if (rawUpgraded is List) {
      for (final raw in rawUpgraded) {
        if (raw is! Map) {
          continue;
        }
        final parsed = DependencyUpgrade.fromJson(raw.cast<String, dynamic>());
        if (parsed != null) {
          upgraded.add(parsed);
        }
      }
    }
    return DependencyDiff(
      ecosystem: ecosystem,
      added: _stringMap(json['added']),
      removed: _stringMap(json['removed']),
      upgraded: upgraded,
      bestEffort: json['bestEffort'] == true,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'ecosystem': ecosystem.wireName,
    if (added.isNotEmpty) 'added': added,
    if (removed.isNotEmpty) 'removed': removed,
    if (upgraded.isNotEmpty)
      'upgraded': upgraded.map((u) => u.toJson()).toList(),
    if (bestEffort) 'bestEffort': true,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyDiff &&
          runtimeType == other.runtimeType &&
          ecosystem == other.ecosystem &&
          _mapEquals(added, other.added) &&
          _mapEquals(removed, other.removed) &&
          _listEquals(upgraded, other.upgraded) &&
          bestEffort == other.bestEffort;

  @override
  int get hashCode => Object.hash(
    ecosystem,
    Object.hashAllUnordered(
      added.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      removed.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAll(upgraded),
    bestEffort,
  );
}

/// Reads lockfiles and diffs two revisions of one.
class LockfileDiffer {
  /// Creates a [LockfileDiffer].
  const LockfileDiffer();

  /// Parses one lockfile's contents into `name -> version`. Returns an empty
  /// map when the content is unparseable — never throws.
  Map<String, String> parseVersions(
    LockfileEcosystem ecosystem,
    String content,
  ) {
    if (content.trim().isEmpty) {
      return const {};
    }
    return switch (ecosystem) {
      LockfileEcosystem.pub => _parsePub(content),
      LockfileEcosystem.npm => _parseNpm(content),
      LockfileEcosystem.pnpm => _parsePnpm(content),
      LockfileEcosystem.yarn => _parseYarn(content),
    };
  }

  /// Diffs base vs head. Returns null when [filePath] is not a known lockfile.
  DependencyDiff? diff({
    required String filePath,
    required String baseContent,
    required String headContent,
  }) {
    final ecosystem = LockfileEcosystem.detect(filePath);
    if (ecosystem == null) {
      return null;
    }
    final base = parseVersions(ecosystem, baseContent);
    final head = parseVersions(ecosystem, headContent);

    final added = <String, String>{};
    final removed = <String, String>{};
    final upgraded = <DependencyUpgrade>[];

    // Sorted once here so every collection below is deterministic by
    // construction; a review panel that reorders between two identical reads
    // reads as churn that did not happen.
    final names = <String>{...base.keys, ...head.keys}.toList()..sort();
    for (final name in names) {
      final before = base[name];
      final after = head[name];
      if (before == null && after != null) {
        added[name] = after;
      } else if (before != null && after == null) {
        removed[name] = before;
      } else if (before != null && after != null && before != after) {
        upgraded.add(DependencyUpgrade(name: name, from: before, to: after));
      }
    }

    // OSV.dev batch query is the future online extension.
    return DependencyDiff(
      ecosystem: ecosystem,
      added: added,
      removed: removed,
      upgraded: upgraded,
      bestEffort: _isBestEffort(ecosystem),
    );
  }
}

/// Whether an ecosystem's parser can only promise a best-effort read.
bool _isBestEffort(LockfileEcosystem ecosystem) => switch (ecosystem) {
  LockfileEcosystem.pub => false,
  LockfileEcosystem.npm => false,
  LockfileEcosystem.pnpm => true,
  LockfileEcosystem.yarn => true,
};

// --- pubspec.lock -----------------------------------------------------------

/// Reads `packages:` entries out of a `pubspec.lock`.
Map<String, String> _parsePub(String content) {
  final versions = <String, String>{};
  var inPackages = false;
  String? current;

  for (final line in _lines(content)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final indent = _indentOf(line);
    if (indent == 0) {
      // Any top-level key closes the block. Without this, `sdks:`' `dart:` and
      // `flutter:` children would be reported as two new dependencies on every
      // SDK bump.
      inPackages = trimmed == 'packages:';
      current = null;
      continue;
    }
    if (!inPackages) {
      continue;
    }
    if (indent == 2 && trimmed.endsWith(':')) {
      current = _unquote(trimmed.substring(0, trimmed.length - 1).trim());
      continue;
    }
    // Exactly one level below the package name: the `description:` sub-map sits
    // deeper and must not be mined for keys.
    if (indent == 4 && current != null && trimmed.startsWith('version:')) {
      final value = _unquote(trimmed.substring('version:'.length).trim());
      if (value.isNotEmpty && current.isNotEmpty) {
        versions[current] = value;
      }
    }
  }
  return versions;
}

// --- package-lock.json ------------------------------------------------------

/// Reads a `package-lock.json` (lockfileVersion 2/3 first, then v1).
Map<String, String> _parseNpm(String content) {
  final decoded = _tryDecodeJson(content);
  if (decoded is! Map) {
    return const {};
  }
  final packages = decoded['packages'];
  if (packages is Map) {
    return _npmFromPackages(packages);
  }
  final dependencies = decoded['dependencies'];
  if (dependencies is Map) {
    return _npmFromDependencies(dependencies);
  }
  return const {};
}

/// The lockfileVersion 2/3 shape: install paths keyed to resolved metadata.
Map<String, String> _npmFromPackages(Map<Object?, Object?> packages) {
  const marker = 'node_modules/';
  final versions = <String, String>{};
  final depths = <String, int>{};

  for (final entry in packages.entries) {
    final path = entry.key;
    if (path is! String) {
      continue;
    }
    final cut = path.lastIndexOf(marker);
    if (cut < 0) {
      // The `""` root key and workspace paths describe the project itself.
      continue;
    }
    final name = path.substring(cut + marker.length);
    if (name.isEmpty) {
      continue;
    }
    final value = entry.value;
    if (value is! Map) {
      continue;
    }
    final version = value['version'];
    if (version is! String || version.isEmpty) {
      continue;
    }
    // `node_modules/a/node_modules/b` is a SECOND copy of `b` nested for a
    // conflicting peer. The shallowest copy is the one most of the tree
    // resolves to, so it wins — and picking by depth rather than by JSON order
    // keeps the result stable however the file was written.
    final depth = marker.allMatches(path).length;
    final known = depths[name];
    if (known != null && known <= depth) {
      continue;
    }
    depths[name] = depth;
    versions[name] = version;
  }
  return versions;
}

/// The lockfileVersion 1 shape: a `dependencies` map keyed by package name.
Map<String, String> _npmFromDependencies(Map<Object?, Object?> dependencies) {
  final versions = <String, String>{};
  for (final entry in dependencies.entries) {
    final name = entry.key;
    if (name is! String || name.isEmpty) {
      continue;
    }
    final value = entry.value;
    if (value is! Map) {
      continue;
    }
    final version = value['version'];
    if (version is! String || version.isEmpty) {
      continue;
    }
    versions[name] = version;
  }
  return versions;
}

/// Decodes JSON, or null when the bytes are not JSON at all.
Object? _tryDecodeJson(String content) {
  try {
    return jsonDecode(content);
  } on FormatException {
    return null;
  }
}

// --- pnpm-lock.yaml ---------------------------------------------------------

/// Reads package/snapshot keys out of a `pnpm-lock.yaml`.
///
/// Best-effort by construction: pnpm has changed its key grammar across major
/// lockfile versions, so this recognizes every shape it has shipped and lets a
/// key it cannot split fall through silently.
Map<String, String> _parsePnpm(String content) {
  final versions = <String, String>{};
  for (final line in _lines(content)) {
    // Top-level keys (`packages:`, `settings:`, `importers:`) are sections, and
    // an indented key is the only thing that can be a package.
    if (_indentOf(line) == 0) {
      continue;
    }
    var key = line.trim();
    if (key.startsWith('#') || !key.endsWith(':')) {
      continue;
    }
    key = _unquote(key.substring(0, key.length - 1).trim());
    // pnpm appends the resolved peer set as `(react@18.2.0)`. It belongs to the
    // identity of the snapshot, not to the version a reviewer reads.
    final peer = key.indexOf('(');
    if (peer > 0) {
      key = key.substring(0, peer);
    }
    if (key.startsWith('/')) {
      key = key.substring(1);
    }
    final split = _splitNameAndVersion(key);
    if (split != null) {
      versions[split.$1] = split.$2;
    }
  }
  return versions;
}

/// Splits a pnpm key into `(name, version)`, or null when it is not one.
(String, String)? _splitNameAndVersion(String key) {
  if (key.isEmpty) {
    return null;
  }
  // `foo@1.2.3` / `@scope/foo@1.2.3`: the LAST `@` separates, and a leading one
  // is the scope sigil rather than a separator.
  final at = key.lastIndexOf('@');
  if (at > 0) {
    final name = key.substring(0, at);
    final version = key.substring(at + 1);
    if (name.isNotEmpty && _looksLikeVersion(version)) {
      return (name, version);
    }
  }
  // The older form separates with `/`: `foo/1.2.3`, `@scope/foo/1.2.3`.
  final slash = key.lastIndexOf('/');
  if (slash > 0) {
    final name = key.substring(0, slash);
    final version = key.substring(slash + 1);
    if (name.isNotEmpty && _looksLikeVersion(version)) {
      return (name, version);
    }
  }
  return null;
}

// --- yarn.lock (classic v1) -------------------------------------------------

/// Reads entry headers and their `version` lines out of a classic `yarn.lock`.
///
/// Best-effort by construction: the format is a bespoke YAML dialect, and one
/// header may carry several requested ranges that all resolved to the same
/// install.
Map<String, String> _parseYarn(String content) {
  final versions = <String, String>{};
  var pending = const <String>[];

  for (final line in _lines(content)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    if (_indentOf(line) == 0) {
      pending = const [];
      // `__metadata:` is a Yarn Berry block, not a package; reading it would
      // report the lockfile's own schema number as a dependency version.
      if (trimmed.startsWith('#') ||
          trimmed.startsWith('__') ||
          !trimmed.endsWith(':')) {
        continue;
      }
      pending = _yarnNames(trimmed.substring(0, trimmed.length - 1));
      continue;
    }
    if (pending.isEmpty || !trimmed.startsWith('version')) {
      continue;
    }
    var rest = trimmed.substring('version'.length).trim();
    if (rest.startsWith(':')) {
      rest = rest.substring(1).trim();
    }
    final version = _unquote(rest);
    if (version.isEmpty) {
      continue;
    }
    for (final name in pending) {
      versions[name] = version;
    }
    // Consumed: only the first `version` line of a block is the install's.
    pending = const [];
  }
  return versions;
}

/// Extracts the distinct package names from one yarn entry header.
List<String> _yarnNames(String header) {
  final names = <String>[];
  for (final raw in header.split(',')) {
    final spec = _unquote(raw.trim());
    if (spec.isEmpty) {
      continue;
    }
    // Strip the requested range at the LAST `@`; `at == 0` is a bare scope
    // sigil, which means the spec carries no range at all.
    final at = spec.lastIndexOf('@');
    final name = at > 0 ? spec.substring(0, at) : spec;
    if (name.isNotEmpty && !names.contains(name)) {
      names.add(name);
    }
  }
  return names;
}

// --- shared scanning helpers ------------------------------------------------

/// Splits [content] into lines with any trailing `\r` removed.
Iterable<String> _lines(String content) sync* {
  for (final raw in content.split('\n')) {
    yield raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
  }
}

/// Counts the leading spaces of [line].
int _indentOf(String line) {
  var index = 0;
  while (index < line.length && line.codeUnitAt(index) == 0x20) {
    index++;
  }
  return index;
}

/// Removes one matching pair of surrounding quotes, if present.
String _unquote(String value) {
  if (value.length >= 2) {
    final first = value[0];
    if ((first == '"' || first == "'") && value[value.length - 1] == first) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}

/// Whether [value] opens with a digit — the cheap test that keeps structural
/// keys (`resolution:`, `dependencies:`) out of the package tables.
bool _looksLikeVersion(String value) =>
    value.isNotEmpty && _isDigit(value.codeUnitAt(0));

/// Whether [unit] is an ASCII digit.
bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;

/// The leading numeric component of [version], or null when there is none.
int? _leadingMajor(String version) {
  const decorations = ' vV=^~><';
  var index = 0;
  while (index < version.length && decorations.contains(version[index])) {
    index++;
  }
  final start = index;
  while (index < version.length && _isDigit(version.codeUnitAt(index))) {
    index++;
  }
  if (index == start) {
    return null;
  }
  return int.tryParse(version.substring(start, index));
}

/// Reads a JSON value as a `String -> String` map, dropping unusable entries.
Map<String, String> _stringMap(Object? raw) {
  if (raw is! Map) {
    return const {};
  }
  final result = <String, String>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is String && value is String) {
      result[key] = value;
    }
  }
  return result;
}

/// Order-insensitive map equality.
bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

/// Ordered list equality.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

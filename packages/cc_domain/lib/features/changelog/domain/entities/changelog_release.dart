/// The kind of change a changelog entry reports.
enum ChangelogChangeType {
  /// A new capability.
  added,

  /// A change to something that already existed.
  improved,

  /// A bug fix.
  fixed,

  /// A tag this build does not know yet, published by a newer website.
  other,
}

/// The entries of one [ChangelogChangeType] within a release.
final class ChangelogChangeGroup {
  /// Creates a group; [items] must not be empty.
  ChangelogChangeGroup({required this.type, required List<String> items})
    : items = List.unmodifiable(items) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
  }

  /// What the entries report.
  final ChangelogChangeType type;

  /// The entries, in published order.
  final List<String> items;

  @override
  bool operator ==(Object other) =>
      other is ChangelogChangeGroup &&
      other.type == type &&
      _sameItems(other.items, items);

  @override
  int get hashCode => Object.hash(type, Object.hashAll(items));
}

/// One published release, as the website's changelog lists it.
final class ChangelogRelease {
  /// Creates a release; [version] must not be empty.
  ChangelogRelease({
    required this.version,
    required this.dateLabel,
    required this.title,
    required this.lead,
    required List<ChangelogChangeGroup> groups,
    this.releasedOn,
    this.note,
  }) : groups = List.unmodifiable(groups) {
    if (version.isEmpty) {
      throw ArgumentError.value(version, 'version', 'must not be empty');
    }
  }

  /// The version without its `v` prefix, comparable to the build version.
  final String version;

  /// The date as published, shown when [releasedOn] could not be read.
  final String dateLabel;

  /// The release date, or null when [dateLabel] has an unknown format.
  final DateTime? releasedOn;

  /// The release's headline.
  final String title;

  /// The summary paragraph.
  final String lead;

  /// Caveats published with the release.
  final String? note;

  /// The changes, grouped by type in published order.
  final List<ChangelogChangeGroup> groups;

  /// Parses the website's `/changelog.md`, newest release first. Text outside
  /// a release heading is ignored; an unreadable document yields no releases.
  static List<ChangelogRelease> parseMarkdown(String source) {
    final releases = <ChangelogRelease>[];
    _ReleaseDraft? draft;
    for (final raw in source.split('\n')) {
      final line = raw.trim();
      if (line.startsWith('## ')) {
        if (draft != null) {
          releases.add(draft.build());
        }
        draft = _ReleaseDraft.fromHeading(line.substring(3));
      } else if (line.isNotEmpty) {
        draft?.addLine(line);
      }
    }
    if (draft != null) {
      releases.add(draft.build());
    }
    return releases;
  }

  @override
  bool operator ==(Object other) =>
      other is ChangelogRelease &&
      other.version == version &&
      other.dateLabel == dateLabel &&
      other.releasedOn == releasedOn &&
      other.title == title &&
      other.lead == lead &&
      other.note == note &&
      _sameItems(other.groups, groups);

  @override
  int get hashCode => Object.hash(
    version,
    dateLabel,
    releasedOn,
    title,
    lead,
    note,
    Object.hashAll(groups),
  );
}

class _ReleaseDraft {
  _ReleaseDraft(this.version, this.dateLabel, this.title);

  /// Reads `v0.0.11 — Oct 27, 2026 — Title`; the title may hold a dash too.
  /// Null for a heading that names no release.
  static _ReleaseDraft? fromHeading(String heading) {
    final parts = heading.split(' — ');
    final version = parts.first.trim().replaceFirst(RegExp('^v'), '');
    if (parts.length < 2 || version.isEmpty) {
      return null;
    }
    return _ReleaseDraft(
      version,
      parts[1].trim(),
      _decodeEntities(parts.skip(2).join(' — ').trim()),
    );
  }

  static final RegExp _item = RegExp(r'^- \[([a-z]+)\]\s+(.+)$');
  static const String _notePrefix = 'Notes: ';

  final String version;
  final String dateLabel;
  final String title;
  final List<String> _lead = [];
  final Map<ChangelogChangeType, List<String>> _items = {};
  String? _note;

  void addLine(String line) {
    final item = _item.firstMatch(line);
    if (item != null) {
      final type = switch (item[1]) {
        'new' => ChangelogChangeType.added,
        'improved' => ChangelogChangeType.improved,
        'fixed' => ChangelogChangeType.fixed,
        _ => ChangelogChangeType.other,
      };
      (_items[type] ??= []).add(_decodeEntities(item[2]!));
    } else if (line.startsWith(_notePrefix)) {
      _note = _decodeEntities(line.substring(_notePrefix.length));
    } else {
      _lead.add(_decodeEntities(line));
    }
  }

  ChangelogRelease build() => ChangelogRelease(
    version: version,
    dateLabel: dateLabel,
    releasedOn: _parseDate(dateLabel),
    title: title,
    lead: _lead.join(' '),
    note: _note,
    groups: [
      for (final MapEntry(:key, :value) in _items.entries)
        ChangelogChangeGroup(type: key, items: value),
    ],
  );
}

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Reads the website's `Oct 27, 2026` format.
DateTime? _parseDate(String label) {
  final match = RegExp(r'^([A-Z][a-z]{2}) (\d{1,2}), (\d{4})$').firstMatch(label);
  if (match == null) {
    return null;
  }
  final month = _months.indexOf(match[1]!);
  if (month < 0) {
    return null;
  }
  return DateTime(int.parse(match[3]!), month + 1, int.parse(match[2]!));
}

const Map<String, String> _entities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'rsquo': '’',
  'lsquo': '‘',
  'ldquo': '“',
  'rdquo': '”',
  'mdash': '—',
  'ndash': '–',
  'hellip': '…',
  'rarr': '→',
};

/// The website strips tags from its Markdown but leaves entities in place.
String _decodeEntities(String text) => text.replaceAllMapped(
  RegExp(r'&(#\d+|[a-z]+);'),
  (match) {
    final name = match[1]!;
    if (name.startsWith('#')) {
      final code = int.tryParse(name.substring(1));
      return code == null || code > 0x10FFFF
          ? match[0]!
          : String.fromCharCode(code);
    }
    return _entities[name] ?? match[0]!;
  },
);

bool _sameItems<T>(List<T> a, List<T> b) {
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

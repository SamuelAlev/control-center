import 'package:collection/collection.dart';

/// The structured part of a delegated task's brief (plan section 10,
/// "Briefs"): what "done" means, the constraints the delegate works under and
/// the references it starts from.
///
/// `delegate_task` renders it into the ticket's description under fixed
/// headings, after the free text ([render]), and stores it in the ticket's
/// metadata under [metadataKey] ([toMetadata]), so a completion notice can
/// echo what "done" meant without parsing prose ([fromMetadata]).
class DelegationBrief {
  /// Creates a brief. Throws [ArgumentError] when a limit is broken: more
  /// than [maxDoneMeans] items or one longer than [maxDoneMeansChars], a
  /// blank item, [constraints] longer than [maxConstraintsChars], more than
  /// [maxReferences] references or one longer than [maxReferenceChars].
  ///
  /// Items and references are trimmed and their line breaks folded to
  /// spaces (each is one line of a list); [constraints] is trimmed and an
  /// empty one is none.
  factory DelegationBrief({
    List<String> doneMeans = const [],
    String? constraints,
    List<String> references = const [],
  }) {
    final items = [for (final item in doneMeans) _oneLine(item)];
    final refs = [for (final ref in references) _oneLine(ref)];
    final rules = constraints?.trim();
    if (items.length > maxDoneMeans) {
      throw ArgumentError(
        'done_means has ${items.length} items; at most $maxDoneMeans.',
      );
    }
    for (final (index, item) in items.indexed) {
      if (item.isEmpty) {
        throw ArgumentError('done_means item ${index + 1} is empty.');
      }
      if (item.length > maxDoneMeansChars) {
        throw ArgumentError(
          'done_means item ${index + 1} is ${item.length} characters; at '
          'most $maxDoneMeansChars.',
        );
      }
    }
    if (rules != null && rules.length > maxConstraintsChars) {
      throw ArgumentError(
        'constraints is ${rules.length} characters; at most '
        '$maxConstraintsChars.',
      );
    }
    if (refs.length > maxReferences) {
      throw ArgumentError(
        'references has ${refs.length} items; at most $maxReferences.',
      );
    }
    for (final (index, ref) in refs.indexed) {
      if (ref.isEmpty) {
        throw ArgumentError('references item ${index + 1} is empty.');
      }
      if (ref.length > maxReferenceChars) {
        throw ArgumentError(
          'references item ${index + 1} is ${ref.length} characters; at '
          'most $maxReferenceChars.',
        );
      }
    }
    return DelegationBrief._(
      doneMeans: List.unmodifiable(items),
      constraints: (rules == null || rules.isEmpty) ? null : rules,
      references: List.unmodifiable(refs),
    );
  }

  const DelegationBrief._({
    required this.doneMeans,
    required this.constraints,
    required this.references,
  });

  /// The brief stored in a ticket's [metadata] by [toMetadata], or null when
  /// the ticket has none (or one this version cannot read).
  static DelegationBrief? fromMetadata(Map<String, dynamic> metadata) {
    final raw = metadata[metadataKey];
    if (raw is! Map) {
      return null;
    }
    List<String>? strings(Object? value) => value == null
        ? const []
        : value is List && value.every((e) => e is String)
        ? value.cast<String>()
        : null;
    final done = strings(raw['done_means']);
    final refs = strings(raw['references']);
    final rules = raw['constraints'];
    if (done == null || refs == null || (rules != null && rules is! String)) {
      return null;
    }
    try {
      return DelegationBrief(
        doneMeans: done,
        constraints: rules as String?,
        references: refs,
      );
    } on ArgumentError {
      return null;
    }
  }

  /// The most "done means" items.
  static const int maxDoneMeans = 12;

  /// The most characters of one "done means" item.
  static const int maxDoneMeansChars = 300;

  /// The most characters of the constraints.
  static const int maxConstraintsChars = 2000;

  /// The most references.
  static const int maxReferences = 20;

  /// The most characters of one reference (a path, a ticket id, a pull
  /// request link).
  static const int maxReferenceChars = 500;

  /// The ticket metadata key the brief is stored under.
  static const String metadataKey = 'brief';

  /// The heading of the numbered acceptance list.
  static const String doneMeansHeading = '## Done means';

  /// The heading of the constraints.
  static const String constraintsHeading = '## Constraints';

  /// The heading of the reference list.
  static const String referencesHeading = '## References';

  /// What the delegate's work must achieve, one checkable statement each.
  final List<String> doneMeans;

  /// What the delegate must not do or must stay within, or null.
  final String? constraints;

  /// Paths, ticket ids and pull request links the delegate starts from.
  final List<String> references;

  /// Whether nothing was given.
  bool get isEmpty =>
      doneMeans.isEmpty && constraints == null && references.isEmpty;

  /// The ticket description: [freeText] (when given) followed by each
  /// non-empty section under its heading. Null when both are empty.
  String? render(String? freeText) {
    final parts = <String>[
      if (freeText != null && freeText.trim().isNotEmpty) freeText.trim(),
      if (doneMeans.isNotEmpty)
        [
          doneMeansHeading,
          for (final (i, item) in doneMeans.indexed) '${i + 1}. $item',
        ].join('\n'),
      if (constraints != null) '$constraintsHeading\n$constraints',
      if (references.isNotEmpty)
        [referencesHeading, for (final ref in references) '- $ref'].join('\n'),
    ];
    return parts.isEmpty ? null : parts.join('\n\n');
  }

  /// The JSON stored under [metadataKey]: only the parts given.
  Map<String, dynamic> toMetadata() => {
    if (doneMeans.isNotEmpty) 'done_means': doneMeans,
    'constraints': ?constraints,
    if (references.isNotEmpty) 'references': references,
  };

  static String _oneLine(String text) =>
      text.trim().replaceAll(RegExp(r'\s*[\r\n]+\s*'), ' ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DelegationBrief &&
          const ListEquality<String>().equals(doneMeans, other.doneMeans) &&
          constraints == other.constraints &&
          const ListEquality<String>().equals(references, other.references);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(doneMeans),
    constraints,
    Object.hashAll(references),
  );
}

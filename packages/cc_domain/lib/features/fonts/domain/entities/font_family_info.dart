import 'package:meta/meta.dart';

/// A selectable font family, as catalogued by the host.
///
/// This is metadata only — enough to list, search, and preview a family in the
/// picker, and enough for the host to resolve one variant to a file. It carries
/// no URL: clients ask the host for bytes by `(id, weight, style, subset)` and
/// the host owns where those bytes come from (see the fonts proxy route), so a
/// client never learns or dials an upstream CDN.
@immutable
class FontFamilyInfo {
  /// Creates a [FontFamilyInfo].
  const FontFamilyInfo({
    required this.id,
    required this.family,
    required this.category,
    required this.weights,
    required this.styles,
    required this.subsets,
    required this.defSubset,
    this.variable = false,
  }) : assert(id != '', 'id must not be empty'),
       assert(family != '', 'family must not be empty'),
       assert(weights.length != 0, 'a family offers at least one weight'),
       assert(styles.length != 0, 'a family offers at least one style');

  /// Catalog identifier, used to address the family's files (e.g. `inter`).
  /// Stable and lowercase-hyphenated; distinct from the display [family].
  final String id;

  /// Display name, as shown in the picker and persisted in preferences
  /// (e.g. `Inter`). This is also the font-family name the app registers with.
  final String family;

  /// Coarse classification (`sans-serif`, `serif`, `monospace`, `display`,
  /// `handwriting`), used to group and filter the picker.
  final String category;

  /// Offered numeric weights (100–900), ascending.
  final List<int> weights;

  /// Offered styles — `normal` and/or `italic`.
  final List<String> styles;

  /// Offered unicode subsets (`latin`, `latin-ext`, `cyrillic`, …).
  final List<String> subsets;

  /// The family's default subset, used when a request names one it lacks.
  final String defSubset;

  /// Whether the family ships as a variable font. Informational: variants are
  /// always resolved to a static instance, which is what Flutter's font loader
  /// can register.
  final bool variable;

  /// Whether this family is monospaced — the code-font surfaces filter on it.
  bool get isMonospace => category == 'monospace';

  /// The offered weight closest to [weight] (ties resolve to the heavier one).
  /// Every family offers at least one weight, so this never returns null.
  int nearestWeight(int weight) => weights.reduce(
    (a, b) => (a - weight).abs() <= (b - weight).abs() ? a : b,
  );

  /// Whether [style] is offered.
  bool hasStyle(String style) => styles.contains(style);

  /// [subset] when offered, else [defSubset].
  String resolveSubset(String subset) =>
      subsets.contains(subset) ? subset : defSubset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontFamilyInfo &&
          id == other.id &&
          family == other.family &&
          category == other.category &&
          defSubset == other.defSubset &&
          variable == other.variable &&
          _sameList(weights, other.weights) &&
          _sameList(styles, other.styles) &&
          _sameList(subsets, other.subsets);

  @override
  int get hashCode => Object.hash(
    id,
    family,
    category,
    defSubset,
    variable,
    Object.hashAll(weights),
    Object.hashAll(styles),
    Object.hashAll(subsets),
  );

  static bool _sameList<T>(List<T> a, List<T> b) {
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
}

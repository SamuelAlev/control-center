final RegExp _stackSlug = RegExp(r'^[a-z0-9](?:[a-z0-9._-]{0,39})?$');

/// Turns a human part name into a branch slug, or null when it cannot be a
/// single path segment.
///
/// Lowercases, folds spaces and underscores into `-`, and rejects anything
/// that is not a short ref segment: empty, `..`, a leading dash, or a trailing
/// dot. The result is appended to the bottom branch, so it is never a free
/// git ref.
String? normalizeStackSlug(String raw) {
  var slug = raw.trim().toLowerCase();
  slug = slug.replaceAll(RegExp(r'[\s_]+'), '-');
  slug = slug.replaceAll(RegExp(r'-{2,}'), '-');
  slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.contains('..') || slug.endsWith('.')) {
    return null;
  }
  if (!_stackSlug.hasMatch(slug)) {
    return null;
  }
  return slug;
}

/// The branch name of a layer above [bottom].
///
/// Git stores a branch as a file under `refs/heads`, so `refs/heads/<bottom>`
/// and `refs/heads/<bottom>/<slug>` cannot both exist. A double hyphen keeps
/// the part grouped on the bottom name without that conflict. Slugs never
/// contain `--`.
String stackLayerBranch(String bottom, String slug) => '$bottom--$slug';

/// The part's name: the slug after [bottom], otherwise the last path segment.
String stackLayerLabel(String branch, {String? bottom}) {
  final prefix = bottom == null ? null : '$bottom--';
  if (prefix != null &&
      branch.startsWith(prefix) &&
      branch.length > prefix.length) {
    return branch.substring(prefix.length);
  }
  final slash = branch.lastIndexOf('/');
  if (slash < 0 || slash == branch.length - 1) {
    return branch;
  }
  return branch.substring(slash + 1);
}

/// Head-branch names whose open pull requests belong to one checkout.
///
/// The checked-out branch, plus every recorded stack layer, so a part that is
/// not checked out still matches. Order is the checked-out branch first, then
/// the stack bottom to top, with duplicates dropped.
List<String> pullRequestHeadBranches({
  required String checkedOut,
  required Iterable<String> stackBranches,
}) {
  final seen = <String>{};
  final names = <String>[];
  void add(String raw) {
    final name = raw.trim();
    if (name.isEmpty || !seen.add(name)) {
      return;
    }
    names.add(name);
  }

  add(checkedOut);
  for (final branch in stackBranches) {
    add(branch);
  }
  return names;
}

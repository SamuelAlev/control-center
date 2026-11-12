/// The names clients give the two editor layouts they persist through the
/// `cache.read` / `cache.write` ops.
///
/// An editor layout (panes, tabs, sizes and the tab each pane last showed) is
/// one person's arrangement, so the server stores it per caller, in the
/// workspace's `editor_layouts` table ([EditorLayoutSurface] names its row):
/// it is that person's state, not a refetchable cache row, and nothing prunes
/// it. The ops reach no other kind.
abstract final class EditorLayoutCacheKinds {
  /// The messaging IDE layout of one space; the key is the space id.
  static const String space = 'editor_layout_v1';

  /// The PR workbench layout of one PR; the key is `owner/repo#number`.
  static const String pullRequest = 'pr_editor_layout_v1';

  /// Every kind a client may read or write through the `cache.*` ops.
  static const Set<String> all = {space, pullRequest};
}

/// What an editor layout arranges.
enum EditorLayoutSurface {
  /// The messaging IDE of one space; the target is the space id.
  space('space', EditorLayoutCacheKinds.space),

  /// The PR workbench of one pull request; the target is `owner/repo#number`.
  pullRequest('pull_request', EditorLayoutCacheKinds.pullRequest);

  const EditorLayoutSurface(this.wire, this.clientKind);

  /// The value stored in `editor_layouts.surface`.
  final String wire;

  /// The kind name clients send for this surface.
  final String clientKind;

  /// The surface a client's [kind] names, or null for any other kind.
  static EditorLayoutSurface? ofClientKind(String kind) {
    for (final surface in values) {
      if (surface.clientKind == kind) {
        return surface;
      }
    }
    return null;
  }
}

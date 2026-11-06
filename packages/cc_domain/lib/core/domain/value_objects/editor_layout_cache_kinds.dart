/// Cache kinds clients persist editor layouts under.
///
/// An editor layout (panes, tabs, sizes and the tab each pane last showed) is
/// one person's arrangement, so the server stores every row of these kinds per
/// caller, and the `cache.*` RPC ops reach no other kind: the same `caches`
/// table also holds server-owned state (PR payloads, collaboration and policy
/// rows) that clients must neither read nor write.
abstract final class EditorLayoutCacheKinds {
  /// The messaging IDE layout of one space; the cache key is the space id.
  static const String space = 'editor_layout_v1';

  /// The PR workbench layout of one PR; the cache key is `owner/repo#number`.
  static const String pullRequest = 'pr_editor_layout_v1';

  /// Every kind a client may read or write through the `cache.*` ops.
  static const Set<String> all = {space, pullRequest};
}

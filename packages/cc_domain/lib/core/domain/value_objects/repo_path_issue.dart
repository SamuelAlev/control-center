/// Why the server keeps listing a linked repository but does not serve its
/// checkout (the IDE, provisioning, environments, terminals, the code index)
/// until it is linked again.
///
/// Wire: the `path_issue` code on each repository a repository watch or
/// `repos.get` sends; the same codes are a refused link's `data.kind`. Not on
/// the `Repo` entity: it is the server's verdict on the stored path, not part
/// of the link.
enum RepoPathIssue {
  /// The folder is outside the workspace's storage: only the server's owner
  /// may confirm that the server uses it.
  hostPath('repo_path.host_path'),

  /// Nothing exists at the path on the server anymore.
  missing('repo_path.missing'),

  /// The path is inside the server's own data directory.
  dataDir('repo_path.data_dir'),

  /// The path is the workspace's storage root itself.
  workspaceRoot('repo_path.workspace_root');

  const RepoPathIssue(this.wire);

  /// The wire code.
  final String wire;

  /// The issue [wire] names, or null for none (or a code this client does
  /// not know, which it then does not claim to explain).
  static RepoPathIssue? fromWire(Object? wire) {
    for (final issue in values) {
      if (issue.wire == wire) {
        return issue;
      }
    }
    return null;
  }
}

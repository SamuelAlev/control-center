import 'package:drift/drift.dart';

@TableIndex(name: 'idx_channel_repos_channelId', columns: {#channelId})
/// Many-to-many join between channels and the repos a channel provisions
/// worktrees for.
///
/// A row `(workspaceId, channelId, repoId)` declares that the channel's
/// conversation workspace should check out that repo. When a channel has NO
/// rows, the provisioner falls back to every repo linked to the workspace
/// (back-compat with channels created before per-channel selection existed);
/// PR-workbench channels ignore this table entirely and always provision
/// exactly the PR's repo.
///
/// `workspaceId` is carried (not just derivable via the channel) so reads scope
/// to the workspace directly — workspace isolation is a hard invariant.
class ChannelReposTable extends Table {
  /// Workspace the channel and repo belong to.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// Channel side of the link.
  TextColumn get channelId => text().customConstraint(
    'NOT NULL REFERENCES channels (id) ON DELETE CASCADE',
  )();

  /// Repo side of the link.
  TextColumn get repoId => text().customConstraint(
    'NOT NULL REFERENCES repos (id) ON DELETE CASCADE',
  )();

  /// When the link was created (drives ordering).
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'channel_repos';

  @override
  Set<Column> get primaryKey => {channelId, repoId};
}

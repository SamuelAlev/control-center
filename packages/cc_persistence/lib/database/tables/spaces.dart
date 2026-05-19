import 'package:drift/drift.dart';

@TableIndex(name: 'idx_spaces_workspaceId', columns: {#workspaceId})
/// Drift table definition for messaging spaces (DMs and group spaces).
class SpacesTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// Name.
  TextColumn get name => text()();

  /// Workspace id.
  TextColumn get workspaceId => text().nullable()();

  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Updated at.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Conversation mode. Stored as the `name` of the `Mode` enum
  /// (`chat`, `review`, `plan`). Defaults to `chat` for legacy rows.
  TextColumn get mode => text().withDefault(const Constant('chat'))();

  /// Owning pipeline run when this conversation was spawned by a pipeline
  /// step. Non-null ⇒ pipeline-managed: hidden from the sidebar, surfaced only
  /// from the pipeline run / step detail. Null for user-facing conversations.
  TextColumn get pipelineRunId => text().nullable()();

  /// Provisioning state of the conversation workspace. `provisioning` while
  /// the background worktree + overlay + `.mcp.json` setup runs, `ready` once
  /// dispatch is unblocked, `failed` when provisioning needs a retry. Existing
  /// rows default to `ready` (migration backfills the column).
  TextColumn get provisioningStatus =>
      text().withDefault(const Constant('ready'))();

  /// Granular in-flight provisioning step (`SpaceProvisioningStep`
  /// JSON: cloning repo X / setting up agent Y), surfaced live in the
  /// "preparing workspace" UI. Non-null only while [provisioningStatus] is
  /// `provisioning`; cleared by the status write when it leaves that state.
  TextColumn get provisioningStep => text().nullable()();

  /// Kind discriminator (PRD 22 §1): `topic` (human-created),
  /// `agentPeer` (an agent↔agent peer space — sectioned separately in the
  /// sidebar, muted-by-default, GC'd by its own retention policy), `system`,
  /// or `pr` (minted by `pr.ensureSpace` for a PR's chat/terminal/file
  /// surfaces — sidebar-hidden until it has messages).
  TextColumn get kind => text().withDefault(const Constant('topic'))();

  /// Whether the space EXPLICITLY provisions no repo worktrees (created with
  /// every repo deselected). Needed because "no rows in `space_repos`" already
  /// means "all workspace repos" (the pre-selection back-compat default), so
  /// an empty selection is otherwise inexpressible. When true, the provisioner
  /// checks out nothing and `space_repos` holds no rows for the space.
  BoolColumn get noRepos => boolean().withDefault(const Constant(false))();

  /// Soft-archive timestamp. Non-null ⇒ archived: hidden from the sidebar,
  /// the space-activity feed and agent-facing space lists, restorable from
  /// the archived-spaces dialog. Archiving deletes nothing — messages,
  /// participants and worktrees all survive.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  String get tableName => 'spaces';

  @override
  Set<Column> get primaryKey => {id};
}

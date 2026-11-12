import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:drift/drift.dart';

/// Drift table definition for messaging spaces (DMs and group spaces).
@TableIndex(name: 'idx_spaces_pipelineRunId', columns: {#pipelineRunId})
class SpacesTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// Name.
  TextColumn get name => text()();

  /// Owning workspace: the one this file holds.
  TextColumn get workspaceId => text()();

  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Updated at.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Conversation mode. Stored as the `name` of the `Mode` enum
  /// (`chat`, `review`, `plan`, `orchestrate`). Defaults to `chat`.
  TextColumn get mode => text()
      .check(
        // ignore: recursive_getters
        mode.isIn(SpacesStoredValues.spaceMode),
      )
      .withDefault(const Constant('chat'))();

  /// Owning pipeline run when this conversation was spawned by a pipeline
  /// step. Non-null ⇒ pipeline-managed: hidden from the sidebar, surfaced only
  /// from the pipeline run / step detail. Null for user-facing conversations.
  ///
  /// `ON DELETE CASCADE`: a pipeline-managed space is reachable only from its
  /// run, so it goes with the run instead of surfacing in the sidebar as an
  /// unowned conversation.
  TextColumn get pipelineRunId => text().nullable().references(
    PipelineRunsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Provisioning state of the conversation workspace. `provisioning` while
  /// the background worktree + overlay + `.mcp.json` setup runs, `ready` once
  /// dispatch is unblocked, `failed` when provisioning needs a retry,
  /// `cancelled` when the person stopped it.
  TextColumn get provisioningStatus => text()
      .check(
        // ignore: recursive_getters
        provisioningStatus.isIn(SpacesStoredValues.spaceProvisioningStatus),
      )
      .withDefault(const Constant('ready'))();

  /// Granular in-flight provisioning step (`SpaceProvisioningStep`
  /// JSON: cloning repo X / setting up agent Y), surfaced live in the
  /// "preparing workspace" UI. Non-null only while [provisioningStatus] is
  /// `provisioning`; cleared by the status write when it leaves that state.
  TextColumn get provisioningStep => text().nullable().check(
    // ignore: recursive_getters
    isJsonObject(provisioningStep),
  )();

  /// Kind discriminator (PRD 22 §1): `topic` (human-created),
  /// `agentPeer` (an agent↔agent peer space — sectioned separately in the
  /// sidebar, muted-by-default, GC'd by its own retention policy), `system`,
  /// `pr` (minted by `pr.ensureSpace` for a PR's chat/terminal/file
  /// surfaces — sidebar-hidden until it has messages), or `slack` (bridged
  /// from an external chat thread).
  TextColumn get kind => text()
      .check(
        // ignore: recursive_getters
        kind.isIn(SpacesStoredValues.spaceKind),
      )
      .withDefault(const Constant('topic'))();

  /// Whether the space EXPLICITLY provisions no repo worktrees (created with
  /// every repo deselected). Needed because "no rows in `space_repos`" already
  /// means "all workspace repos" (the default selection), so
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

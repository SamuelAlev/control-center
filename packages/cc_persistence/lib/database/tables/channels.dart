import 'package:drift/drift.dart';

@TableIndex(name: 'idx_channels_workspaceId', columns: {#workspaceId})
/// Drift table definition for messaging channels (DMs and group channels).
class ChannelsTable extends Table {
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

  /// Granular in-flight provisioning step (`ChannelProvisioningStep`
  /// JSON: cloning repo X / setting up agent Y), surfaced live in the
  /// "preparing workspace" UI. Non-null only while [provisioningStatus] is
  /// `provisioning`; cleared by the status write when it leaves that state.
  TextColumn get provisioningStep => text().nullable()();

  /// Origin discriminator (PRD 22 §1): `user` (a human-facing conversation),
  /// `agentDm` (an agent↔agent peer channel — sectioned separately in the
  /// sidebar, muted-by-default, GC'd by its own retention policy), `system`,
  /// or `prWorkbench` (minted by `pr.ensureChannel` for a PR's chat/terminal/
  /// file surfaces — sidebar-hidden until it has messages).
  /// Existing rows default to `user`.
  TextColumn get origin => text().withDefault(const Constant('user'))();

  @override
  String get tableName => 'channels';

  @override
  Set<Column> get primaryKey => {id};
}

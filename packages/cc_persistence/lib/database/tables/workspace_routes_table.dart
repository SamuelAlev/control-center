import 'package:drift/drift.dart';

/// Global routing index: an opaque key → the workspace that owns it.
///
/// **CROSS-WORKSPACE BY DESIGN** — this table lives in `global.db` and is the
/// one sanctioned way to answer "which workspace does this belong to?" *before*
/// a workspace is known.
///
/// The database is split into `global.db` + one file per workspace, so a lookup
/// needs its workspace id to pick a file. Almost every call site already has
/// one (the RPC session binds it). The exceptions are pre-auth entry points
/// that receive nothing but a secret or an opaque id:
///
///  * an invite code hash arriving from an unauthenticated redeemer,
///  * a webhook token on an inbound HTTP request,
///  * a deep link naming a pipeline run / space / ticket with no workspace.
///
/// Those resolve here. Writes are strict and fail loudly: the route row is
/// written by the same server-side operation that creates the entity (entity
/// first, then route) and a lookup miss is simply "not found" — there is no
/// scan fallback that could quietly paper over a missing route.
class WorkspaceRoutesTable extends Table {
  /// The kind of key being routed — see [WorkspaceRouteKind].
  TextColumn get kind => text()();

  /// The key itself: a hash for secrets, the raw id for opaque ids. Never a
  /// plaintext secret.
  TextColumn get keyHash => text()();

  /// The workspace that owns the keyed entity.
  TextColumn get workspaceId => text()();

  /// When the route was recorded.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'workspace_routes';

  @override
  Set<Column> get primaryKey => {kind, keyHash};
}

/// The closed set of [WorkspaceRoutesTable.kind] values.
///
/// Closed on purpose: every new kind is a new pre-auth entry point and deserves
/// a deliberate decision, so the set is an enum rather than free-form strings.
enum WorkspaceRouteKind {
  /// A hashed workspace invite code (`workspace_invites.code_hash`).
  inviteCode('invite_code'),

  /// A pipeline trigger's webhook token.
  webhookToken('webhook_token'),

  /// A pipeline run id (deep links, worker callbacks).
  pipelineRun('pipeline_run'),

  /// A space id (deep links, notification taps).
  space('space'),

  /// A ticket's `provider:external_key` pair (inbound provider webhooks).
  ticketExternalKey('ticket_external_key'),

  /// An isolated-repo checkout id (teardown by space/ticket id).
  isolatedRepo('isolated_repo');

  const WorkspaceRouteKind(this.wireName);

  /// The value stored in [WorkspaceRoutesTable.kind].
  final String wireName;
}

import 'package:drift/drift.dart';

/// Opaque key → owning workspace (pre-auth routing).
///
/// CROSS-WORKSPACE BY DESIGN — lives in `global.db`. Used when only a secret
/// or opaque id is known (invite hash, webhook token, deep link). Written with
/// the entity (entity first, then route); miss is not-found (no scan fallback).
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

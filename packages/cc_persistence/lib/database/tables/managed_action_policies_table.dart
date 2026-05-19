import 'package:drift/drift.dart';

/// CROSS-WORKSPACE BY DESIGN: the MANAGED (install-wide) action-policy tier.
///
/// Lives in `global.db` because it is the operator's clamp over EVERY
/// workspace on the install — "no workspace on this server may auto-approve
/// `git push`", "nothing here exceeds act-with-approval". Rules here are
/// merged into resolution as `mostRestrictive(workspaceChain, managed)`: the
/// managed tier can only TIGHTEN what a workspace decided, never loosen it,
/// so it is not a scope in the first-match chain (a head-of-chain `allow`
/// would let the install override a workspace's own deny — the opposite of
/// what a managed tier is for).
///
/// A `CC_SERVER_MANAGED_POLICY` file outranks these rows entirely (same
/// precedence rule as `server_settings`), so an operator can pin a policy
/// that no admin UI can flip.
class ManagedActionPoliciesTable extends Table {
  @override
  String get tableName => 'managed_action_policies';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// The ActionClass wire name this rule governs (null when a
  /// [commandPrefix] rule instead). Exactly one of the two is set.
  TextColumn get actionClass => text().nullable()();

  /// A command prefix this rule governs (null when an [actionClass] rule).
  TextColumn get commandPrefix => text().nullable()();

  /// The decision: `allow` / `prompt` / `deny`. (`allow` is stored but can
  /// only ever confirm — the merge is most-restrictive.)
  TextColumn get decision => text().withDefault(const Constant('prompt'))();

  /// Enforcement level: `advisory` / `soft` / `hard` (null = `hard`).
  TextColumn get enforcement => text().nullable()();

  /// Optional argument constraint JSON (`ActionConstraint` wire shape).
  TextColumn get constraintJson => text().nullable()();

  /// The user who last wrote the rule (the server owner).
  TextColumn get updatedBy => text().nullable()();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {actionClass, commandPrefix},
  ];
}

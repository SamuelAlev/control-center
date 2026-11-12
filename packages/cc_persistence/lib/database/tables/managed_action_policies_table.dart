import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/users_table.dart';
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
///
/// One rule per subject: an action class, or a command prefix.
@TableIndex.sql(
  'CREATE UNIQUE INDEX uq_managed_action_policies_class '
  'ON managed_action_policies (action_class) WHERE action_class IS NOT NULL',
)
@TableIndex.sql(
  'CREATE UNIQUE INDEX uq_managed_action_policies_command '
  'ON managed_action_policies (command_prefix) '
  'WHERE command_prefix IS NOT NULL',
)
@TableIndex(
  name: 'idx_managed_action_policies_updated_by',
  columns: {#updatedBy},
)
class ManagedActionPoliciesTable extends Table {
  @override
  String get tableName => 'managed_action_policies';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// The ActionClass wire name this rule governs (null when a
  /// [commandPrefix] rule instead). Exactly one of the two is set.
  TextColumn get actionClass =>
      text().nullable()
      // ignore: recursive_getters
      .check(actionClass.isIn(PlatformStoredValues.actionClass))();

  /// A command prefix this rule governs (null when an [actionClass] rule).
  TextColumn get commandPrefix => text().nullable()();

  /// The decision: `allow` / `prompt` / `deny`. (`allow` is stored but can
  /// only ever confirm — the merge is most-restrictive.) An `ActionDecision`
  /// wire name.
  TextColumn get decision => text()
      // ignore: recursive_getters
      .check(decision.isIn(PlatformStoredValues.actionDecision))
      .withDefault(const Constant('prompt'))();

  /// Enforcement level: an `EnforcementLevel` wire name (null = `hard`).
  TextColumn get enforcement =>
      text().nullable()
      // ignore: recursive_getters
      .check(enforcement.isIn(PlatformStoredValues.enforcementLevel))();

  /// Optional argument constraint (`ActionConstraint` wire shape): a JSON
  /// object.
  TextColumn get constraintJson =>
      // ignore: recursive_getters
      text().nullable().check(isJsonObject(constraintJson))();

  /// The user who last wrote the rule (the server owner). History: cleared
  /// if the user row goes.
  TextColumn get updatedBy => text().nullable().references(
    UsersTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  /// A rule names exactly one subject.
  @override
  List<String> get customConstraints => [
    'CHECK ((action_class IS NULL) <> (command_prefix IS NULL))',
  ];
}

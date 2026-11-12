import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/users_table.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

/// Paired remote-control device metadata (PSK never stored here — only [pskRef]).
///
/// Global across workspaces: a device belongs to one [userId] (device registry
/// and principal binding); [landingWorkspaceId] is only where it landed when
/// it was paired, never a grant.
@TableIndex(name: 'idx_paired_devices_user', columns: {#userId})
@TableIndex(
  name: 'idx_paired_devices_landing_workspace',
  columns: {#landingWorkspaceId},
)
class PairedDevicesTable extends Table {
  /// Unique device id (generated at pairing).
  TextColumn get id => text()();

  /// The user this device authenticates as; the device goes with them.
  TextColumn get userId =>
      text().references(UsersTable, #id, onDelete: KeyAction.cascade)();

  /// The workspace active at pairing time (seed for the session binding), or
  /// null when it was paired outside one (the local desktop, a web sign-in).
  /// History, not ownership: cleared if the workspace row ever goes.
  TextColumn get landingWorkspaceId => text().nullable().references(
    WorkspacesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// User-editable label (e.g. "iPhone").
  TextColumn get label => text()();

  /// Platform string reported by the phone ("ios", "android", "web").
  TextColumn get platform => text().withDefault(const Constant('web'))();

  /// Secure-store key referencing this device's PSK
  /// (`paired_device_psk_<id>`).
  TextColumn get pskRef => text()();

  /// Pinned remote DTLS fingerprint (TOFU on first connect).
  TextColumn get remoteFingerprint => text().nullable()();

  /// Pairing status: a [PlatformStoredValues.pairedDeviceStatus] value.
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(PlatformStoredValues.pairedDeviceStatus))
      .withDefault(const Constant('pendingConfirm'))();

  /// When the device was paired.
  DateTimeColumn get pairedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the device last connected.
  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  /// When this credential becomes invalid and the desktop must fail it closed.
  ///
  /// Two-phase: for a `pendingConfirm` device it is the short pairing-offer
  /// window (the QR's ~5 min) — if the user never confirms in time, the offer is
  /// purged. Once confirmed (`active`) it is reset to an absolute credential
  /// lifetime, after which the phone must re-pair. The desktop checks this in
  /// both connect gates so a leaked link is time-boxed rather than a permanent
  /// backdoor. Null means "no expiry" (legacy rows upgraded before this column).
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  String get tableName => 'paired_devices';

  @override
  Set<Column> get primaryKey => {id};
}

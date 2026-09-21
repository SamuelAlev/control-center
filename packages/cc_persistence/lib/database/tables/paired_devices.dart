import 'package:drift/drift.dart';

/// Paired remote-control device metadata (PSK never stored here — only [pskRef]).
///
/// Global across workspaces: [workspaceId] is pairing-time only, not a cascade
/// FK. Each device belongs to one [userId] (device registry + principal binding).
class PairedDevicesTable extends Table {
  /// Unique device id (generated at pairing).
  TextColumn get id => text()();

  /// The user this device authenticates as. Nullable in SQL only until the
  /// identity bootstrap backfills legacy rows to the owner; required in code.
  TextColumn get userId => text().nullable()();

  /// Workspace active at pairing time (seed for the session binding).
  TextColumn get workspaceId => text().nullable()();

  /// User-editable label (e.g. "iPhone").
  TextColumn get label => text()();

  /// Platform string reported by the phone ("ios", "android", "web").
  TextColumn get platform => text().withDefault(const Constant('web'))();

  /// Secure-store key referencing this device's PSK
  /// (`paired_device_psk_<id>`).
  TextColumn get pskRef => text()();

  /// Pinned remote DTLS fingerprint (TOFU on first connect).
  TextColumn get remoteFingerprint => text().nullable()();

  /// Pairing status: `pendingConfirm`, `active`, or `revoked`.
  TextColumn get status =>
      text().withDefault(const Constant('pendingConfirm'))();

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

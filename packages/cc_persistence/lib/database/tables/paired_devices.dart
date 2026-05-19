import 'package:drift/drift.dart';

/// Drift table definition for paired remote-control devices (phones).
///
/// Stores **metadata only**: the device id, label, platform, the secure-store
/// key reference for its PSK ([pskRef]), the pinned remote DTLS fingerprint
/// ([remoteFingerprint]), and its [status]. The PSK itself is **never** stored
/// here — it lives in the platform secure store keyed by [pskRef] (see
/// `PairedDeviceSecretsRepository`), mirroring the calendar/MCP "secrets in
/// keychain, metadata in Drift" precedent.
///
/// Devices are **global** (they span every workspace — the phone has a
/// workspace switcher), so [workspaceId] is the workspace active at pairing
/// time, used only to seed the session binding. It is deliberately *not* a
/// cascade-delete foreign key: deleting a workspace must not revoke a paired
/// device.
class PairedDevicesTable extends Table {
  /// Unique device id (generated at pairing).
  TextColumn get id => text()();

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
  DateTimeColumn get pairedAt =>
      dateTime().withDefault(currentDateAndTime)();

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

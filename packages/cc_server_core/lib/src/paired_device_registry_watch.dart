import 'dart:async';
import 'dart:convert';

import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart';

/// Republishes `paired_devices` rows written by ANOTHER process, so a running
/// server picks up `cc_server pair` without being restarted.
///
/// Drift's `.watch()` streams are driven by in-process table-update
/// notifications: they fire for writes made through THIS connection and are
/// blind to a second process writing the same SQLite file. `cc_server pair` is
/// exactly that second process, which left two consumers stale until the next
/// boot:
///
///  * `RemoteRelayHost`, whose admission-hash set is rebuilt from
///    `devicesDao.watchAll()` — an unpublished hash means the broker never
///    admits the new device, so a remote client cannot even reach the auth
///    handshake.
///  * `pairing.watchOwn`, the device list every client renders — a device that
///    exists on disk but is absent from the UI.
///
/// One poll covers both: read the registry, and when it differs from the last
/// snapshot call `notifyUpdates` so every existing stream on the table re-runs
/// its query. Nothing subscribes to this class directly — it feeds the
/// notification lane those streams already use.
///
/// On-demand reads need none of this: `getById` / `getAll` go to disk, which is
/// why direct WebSocket auth only ever needed the PSK cache fixed (see
/// `FileSecretsStore`).
class PairedDeviceRegistryWatch {
  /// Watches [global]'s device registry, polling every [interval].
  PairedDeviceRegistryWatch({
    required GlobalDatabase global,
    this.interval = const Duration(seconds: 10),
  }) : _global = global;

  final GlobalDatabase _global;

  /// How often the registry is re-read. Short enough that pairing a device from
  /// the CLI and connecting it reads as immediate; the query is a scan of a
  /// table that holds one row per device.
  final Duration interval;

  Timer? _timer;
  String? _snapshot;
  bool _inFlight = false;

  /// Takes the initial snapshot (so the first tick cannot fire a spurious
  /// notification) and starts polling. Idempotent.
  Future<void> start() async {
    if (_timer != null) {
      return;
    }
    await _poll();
    _timer = Timer.periodic(interval, (_) => unawaited(_poll()));
  }

  /// Re-reads the registry now and notifies if it changed. Safe to call at any
  /// time — a caller that knows a pairing just happened need not wait a tick.
  Future<void> refresh() => _poll();

  /// Stops polling. The timer outlives a "stopped" server otherwise, which the
  /// desktop (which embeds `CcServer`) pays for across a server switch.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    // A slow read must not stack ticks on top of one another.
    if (_inFlight) {
      return;
    }
    _inFlight = true;
    try {
      final next = _fingerprint(await _global.pairedDeviceDao.getAll());
      if (next == _snapshot) {
        return;
      }
      final first = _snapshot == null;
      _snapshot = next;
      if (first) {
        return;
      }
      _global.notifyUpdates({
        TableUpdate.onTable(_global.pairedDevicesTable, kind: UpdateKind.update),
      });
    } on Object catch (e) {
      CcHostLog.warning('cc_server: paired-device registry poll failed: $e');
    } finally {
      _inFlight = false;
    }
  }

  /// A digest of everything a consumer of this table reacts to.
  ///
  /// JSON rather than a delimiter join because a label is free text: any
  /// separator a user can type into one is a separator two different
  /// registries can collide on.
  ///
  /// `lastSeenAt` is deliberately excluded — it is written by THIS process on
  /// every authentication, which drift already notifies for, so including it
  /// would make the poll re-emit the whole device list after each connect.
  String _fingerprint(List<PairedDevicesTableData> devices) {
    final rows = [
      for (final d in devices)
        <String?>[
          d.id,
          d.status,
          d.userId,
          d.workspaceId,
          d.label,
          d.platform,
          d.expiresAt?.microsecondsSinceEpoch.toString(),
        ],
    ]..sort((a, b) => a.first!.compareTo(b.first!));
    return jsonEncode(rows);
  }
}

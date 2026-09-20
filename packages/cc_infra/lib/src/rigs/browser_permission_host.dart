import 'dart:async';

import 'package:cc_infra/src/rigs/browser_permission_probe.dart';

/// The three engine clients install the same interceptor and surface its
/// asks here. The driver owns the ledger; the clients only carry the wire.
mixin BrowserPermissionHost {
  /// Broadcast of in-page permission asks. Survives a missed listener: a
  /// probe with nobody watching is still a prompt the human should see on
  /// the next toolbar poll of the ledger, once the driver has recorded it.
  final StreamController<BrowserPermissionProbe> permissionProbeController =
      StreamController<BrowserPermissionProbe>.broadcast();

  /// Live permission asks from the page.
  Stream<BrowserPermissionProbe> get permissionProbes =>
      permissionProbeController.stream;

  /// Publishes [probe] unless this host is already closed.
  void emitPermissionProbe(BrowserPermissionProbe probe) {
    if (!permissionProbeController.isClosed) {
      permissionProbeController.add(probe);
    }
  }

  /// Wraps the prompting APIs in the current page and every future one.
  Future<void> installPermissionInterceptor();

  /// Completes the parked page promise for [probe].
  Future<void> resolvePermissionProbe(
    BrowserPermissionProbe probe, {
    required bool allow,
  });

  /// Tears the probe lane down. Safe to call twice.
  void closePermissionHost() {
    if (!permissionProbeController.isClosed) {
      permissionProbeController.close();
    }
  }
}

/// [client] if it is a [BrowserPermissionHost], otherwise null.
BrowserPermissionHost? asBrowserPermissionHost(Object client) =>
    client is BrowserPermissionHost ? client : null;

/// Combined zero-config discovery of `cc_server` instances (VM).
///
/// Runs three complementary discoverers together:
///  * this machine: direct loopback probe (`loopback_discovery.dart`) — a
///    loopback-bound server is invisible to the other two;
///  * LAN: mDNS/DNS-SD browse of `_ccserver._tcp.local`
///    (`lan_discovery.dart`);
///  * tailnet: Tailscale peer enumeration + `/healthz` probing
///    (`tailscale_discovery.dart`) — mDNS cannot cross a tailnet.
///
/// Web-safe counterpart: `server_discovery_web.dart` (a browser can join
/// neither multicast groups nor the tailscale CLI, so discovery is a
/// desktop-only affordance).
library;

import 'dart:async';

import 'package:control_center/core/server/lan_discovery.dart';
import 'package:control_center/core/server/loopback_discovery.dart';
import 'package:control_center/core/server/tailscale_discovery.dart';

export 'lan_discovery.dart' show DiscoveredServer, DiscoverySource;

/// One-call discovery across every network the desktop can see.
class ServerDiscovery {
  /// Creates a discoverer. Each [discover]/[watch] call re-runs both
  /// underlying scans; no state is kept between calls. [lan]/[tailnet] are
  /// injectable so tests can substitute fakes (the real ones need multicast
  /// and the `tailscale` CLI).
  const ServerDiscovery({
    this.local = const LoopbackServerDiscovery(),
    this.lan = const LanServerDiscovery(),
    this.tailnet = const TailscaleServerDiscovery(),
  });

  /// The same-machine (loopback probe) discoverer.
  final LoopbackServerDiscovery local;

  /// The LAN (mDNS) discoverer.
  final LanServerDiscovery lan;

  /// The tailnet (Tailscale peer probe) discoverer.
  final TailscaleServerDiscovery tailnet;

  /// Looks up every reachable `cc_server`, LAN and tailnet results merged
  /// (LAN wins on duplicates). Never throws — each underlying discoverer
  /// degrades to "found nothing" on its own failure mode.
  Future<List<DiscoveredServer>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    List<DiscoveredServer> last = const [];
    await for (final snapshot in watch(timeout: timeout)) {
      last = snapshot;
    }
    return last;
  }

  /// The incremental counterpart of [discover]: yields the merged snapshot
  /// as soon as the LAN browse lands and again as each tailnet probe chunk
  /// resolves, so a dialog can paint results immediately instead of blocking
  /// on the slowest peer (a large tailnet is seconds of probing). Completes
  /// when both sources are done; never emits an error.
  Stream<List<DiscoveredServer>> watch({
    Duration timeout = const Duration(seconds: 3),
  }) {
    final controller = StreamController<List<DiscoveredServer>>();
    // De-duped by serverId; LAN overwrites local/tailnet on collision
    // regardless of arrival order (the LAN advertisement carries the
    // authoritative port/TLS metadata).
    final found = <String, DiscoveredServer>{};
    var sourcesRunning = 3;

    void emit() {
      // Skip empty snapshots — the dialog's "nothing found" state is driven
      // by the stream completing, not by empty emissions.
      if (!controller.isClosed && found.isNotEmpty) {
        controller.add(found.values.toList(growable: false));
      }
    }

    void sourceDone() {
      sourcesRunning--;
      if (sourcesRunning == 0 && !controller.isClosed) {
        controller.close();
      }
    }

    unawaited(() async {
      try {
        // Milliseconds-fast and entitlement-free: usually the first
        // snapshot the dialog paints.
        final localResults = await local.discover();
        for (final server in localResults) {
          found.putIfAbsent(server.serverId, () => server);
        }
        emit();
      } catch (_) {
        // Loopback probing is best-effort — the other branches still run.
      } finally {
        sourceDone();
      }
    }());

    unawaited(() async {
      try {
        final lanResults = await lan.discover(timeout: timeout);
        for (final server in lanResults) {
          found[server.serverId] = server;
        }
        emit();
      } catch (_) {
        // LAN discovery is best-effort — the tailnet branch still reports.
      } finally {
        sourceDone();
      }
    }());

    final tailnetSub = tailnet.discoverStream().listen(
      (chunk) {
        for (final server in chunk) {
          found.putIfAbsent(server.serverId, () => server);
        }
        emit();
      },
      onError: (_) {},
      onDone: sourceDone,
      cancelOnError: false,
    );
    // A cancelled subscription (e.g. the dialog closed mid-scan) stops the
    // tailnet probing too, instead of chunking on for seconds into a dead
    // controller.
    controller.onCancel = tailnetSub.cancel;

    return controller.stream;
  }
}

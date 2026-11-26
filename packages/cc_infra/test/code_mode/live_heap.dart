// The live heap of this isolate, for tests that bound what code holds.
//
// The figure is the VM's own count of live objects (the VM service's heap
// usage after a full collection), not resident memory: resident memory
// belongs to the whole process, moves with paging and with when the
// collector returns pages, and on CI read anywhere from 90 MiB below zero to
// 95 MiB above for the same held objects.
import 'dart:developer';
import 'dart:isolate';

import 'package:vm_service/vm_service.dart' show VmService;
import 'package:vm_service/vm_service_io.dart';

/// Reads the live heap of the current isolate over the VM service.
class LiveHeap {
  LiveHeap._(this._service, this._isolateId);

  final VmService _service;
  final String _isolateId;

  /// How many collections in a row must fail to lower the reading before it
  /// is taken as settled.
  static const int _settled = 3;

  /// The most collections one reading takes.
  static const int _maxCollections = 20;

  /// Between collections, for the sweeper to finish.
  static const Duration _settle = Duration(milliseconds: 50);

  /// Starts the VM service and connects to it. Throws a [StateError] when
  /// the service does not start.
  static Future<LiveHeap> connect() async {
    final info = await Service.controlWebServer(
      enable: true,
      silenceOutput: true,
    );
    final uri = info.serverWebSocketUri;
    final isolateId = Service.getIsolateId(Isolate.current);
    if (uri == null || isolateId == null) {
      throw StateError('the VM service did not start');
    }
    return LiveHeap._(await vmServiceConnectUri(uri.toString()), isolateId);
  }

  /// Live bytes after a full collection: what the isolate holds, whatever
  /// the allocator has kept or given back.
  ///
  /// The least reading, taken until [_settled] collections in a row no longer
  /// lower it (at most [_maxCollections]). What is reachable does not change
  /// between readings, so a higher one counted garbage a collection had not
  /// yet swept: one reading on Windows counted a second copy of every decoded
  /// string, and on a loaded Windows runner three readings 50 ms apart still
  /// counted two (a 256 KiB ASCII string read as 859 KiB), so a fixed number
  /// of readings is not enough.
  Future<int> bytes() async {
    int? least;
    var unchanged = 0;
    for (var i = 0; i < _maxCollections && unchanged < _settled; i++) {
      if (i > 0) {
        await Future<void>.delayed(_settle);
      }
      final profile = await _service.getAllocationProfile(_isolateId, gc: true);
      final usage = profile.memoryUsage!.heapUsage!;
      if (least == null || usage < least) {
        least = usage;
        unchanged = 0;
      } else {
        unchanged++;
      }
    }
    return least!;
  }

  /// Disconnects and stops the VM service, which would otherwise keep the
  /// process alive.
  Future<void> close() async {
    await _service.dispose();
    await Service.controlWebServer(enable: false);
  }
}

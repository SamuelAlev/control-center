// The live heap of this isolate, for tests that bound what code holds.
//
// The figure is the VM's own count of live objects (the VM service's heap
// usage after a full collection), not resident memory: resident memory
// belongs to the whole process, moves with paging and with when the
// collector returns pages, and on CI read anywhere from 90 MiB below zero to
// 95 MiB above for the same held objects.
import 'dart:developer';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:vm_service/vm_service.dart' show VmService;
import 'package:vm_service/vm_service_io.dart';

/// Reads the live heap of the current isolate over the VM service.
class LiveHeap {
  LiveHeap._(this._service, this._isolateId);

  final VmService _service;
  final String _isolateId;

  /// How many collections one reading takes.
  static const int _collections = 3;

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
  /// The least of [_collections] readings. What is reachable does not change
  /// between them, so a higher reading counted garbage a collection had not
  /// yet swept: one reading on Windows counted a second copy of every decoded
  /// string.
  Future<int> bytes() async {
    int? least;
    for (var i = 0; i < _collections; i++) {
      if (i > 0) {
        await Future<void>.delayed(_settle);
      }
      final profile = await _service.getAllocationProfile(_isolateId, gc: true);
      final usage = profile.memoryUsage!.heapUsage!;
      least = least == null ? usage : math.min(least, usage);
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

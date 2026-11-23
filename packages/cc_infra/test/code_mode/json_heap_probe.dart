// Prints `<bytes> <heap> <weight>` for one JSON shape: its UTF-8 bytes, the
// heap one decoded copy takes, and its JsonShape.weight. Run by
// json_weight_test.dart, one process per shape.
//
// The heap is the VM's own count of live objects (the VM service's heap
// usage after a full collection) over 16 kept copies, not resident memory:
// on a loaded machine resident memory moves with paging and with when the
// collector returns pages, and read below zero or above the decode.
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:vm_service/vm_service_io.dart';

const _size = 256 * 1024;

/// [unit] repeated, comma separated, inside `{"a":[…]}`, to about [_size]
/// bytes; `#` in [unit] becomes the index.
String _array(String unit) {
  final b = StringBuffer('{"a":[');
  var i = 0;
  while (b.length + unit.length + 12 < _size) {
    if (i > 0) {
      b.write(',');
    }
    b.write(unit.replaceAll('#', '${i++}'));
  }
  b.write(']}');
  return b.toString();
}

String _wide() {
  final b = StringBuffer('{"a":{');
  var i = 0;
  while (b.length + 20 < _size) {
    if (i > 0) {
      b.write(',');
    }
    b.write('"k${i++}":0');
  }
  b.write('}}');
  return b.toString();
}

final Map<String, String Function()> _shapes = {
  'empty objects': () => _array('{}'),
  'one-member objects': () => _array('{"a":0}'),
  'distinct keys': () => _array('{"k#":0}'),
  'objects of arrays': () => _array('{"a":[]}'),
  'nested arrays': () => _array('[[[]]]'),
  'nested objects': () => _array('{"a":{"b":{}}}'),
  'empty arrays': () => _array('[]'),
  'wide object': _wide,
  'small integers': () => _array('0'),
  'distinct integers': () => _array('#'),
  'doubles': () => _array('1.5'),
  'distinct doubles': () => _array('#.5'),
  'nulls': () => _array('null'),
  'short strings': () => _array('"a"'),
  'distinct strings': () => _array('"#"'),
  'one ASCII string': () => '{"s":"${'a' * _size}"}',
  'one string past Latin-1': () => '{"s":"一${'a' * _size}"}',
};

/// The shapes the probe knows.
Iterable<String> get jsonHeapProbeShapes => _shapes.keys;

Future<void> main(List<String> args) async {
  final bytes = Uint8List.fromList(utf8.encode(_shapes[args.single]!()));
  final weight = scanJsonFrame(bytes).shape.weight;
  final info = await Service.controlWebServer(
    enable: true,
    silenceOutput: true,
  );
  final uri = info.serverWebSocketUri;
  final isolateId = Service.getIsolateId(Isolate.current);
  if (uri == null || isolateId == null) {
    stderr.writeln('the VM service did not start');
    exit(2);
  }
  final service = await vmServiceConnectUri(uri.toString());
  // Live bytes after a full collection: what the isolate holds, whatever the
  // allocator has kept or given back.
  Future<int> live() async {
    final profile = await service.getAllocationProfile(isolateId, gc: true);
    return profile.memoryUsage!.heapUsage!;
  }

  const copies = 16;
  final kept = <Object?>[];
  final base = await live();
  for (var i = 0; i < copies; i++) {
    kept.add(utf8JsonDecoder.convert(bytes));
  }
  final heap = (await live() - base) ~/ copies;
  // The copies stay reachable until the measurement is taken.
  if (kept.length != copies) {
    exit(1);
  }
  await service.dispose();
  // A running VM service would keep the process alive.
  await Service.controlWebServer(enable: false);
  stdout.writeln('${bytes.length} $heap $weight');
}

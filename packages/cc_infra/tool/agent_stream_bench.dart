// Measures GuestAgentClient.openStream throughput against a live agent port.
//   dart run tool/agent_stream_bench.dart <port> <token>
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_infra/cc_infra.dart';

Future<void> main(List<String> args) async {
  final client = GuestAgentClient(port: int.parse(args[0]), token: args[1]);
  final stream = await client.openStream(
    RigWatchRequest(size: RigDisplaySize(960, 600), fps: 24),
  );
  var bytes = 0;
  var frames = 0;
  final sub = stream.listen((chunk) {
    bytes += chunk.length;
    for (var i = 0; i + 1 < chunk.length; i++) {
      if (chunk[i] == 0xFF && chunk[i + 1] == 0xD8) {
        frames++;
      }
    }
  });
  await Future<void>.delayed(const Duration(seconds: 5));
  await sub.cancel();
  client.close();
  stdout.writeln('dart client: $bytes bytes, $frames frames in 5s '
      '(~${(frames / 5).toStringAsFixed(1)} fps)');
  exit(0);
}

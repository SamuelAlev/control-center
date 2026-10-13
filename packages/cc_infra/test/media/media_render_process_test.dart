import 'dart:async';
import 'dart:io';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/media/media_render_process.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late File child;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('media-process-test-');
    child = File('${root.path}/child.dart');
    await child.writeAsString('''
import 'dart:async';
import 'dart:io';
Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    final socket = await Socket.connect('127.0.0.1', int.parse(args.single));
    socket.add([1]);
    await socket.flush();
  }
  Timer.periodic(const Duration(seconds: 1), (_) {});
}
''');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('deadline kills and reaps a decoder that never finishes', () async {
    final operation = MediaRenderProcess(timeout: const Duration(seconds: 1));
    final work = operation.run(
      executable: Platform.resolvedExecutable,
      arguments: [child.path],
      maxOutputBytes: 1024,
    );
    try {
      await expectLater(
        operation.guard(work),
        throwsA(isA<TimeoutException>()),
      );
      await expectLater(
        work.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw StateError('The timed-out decoder was not reaped.');
          },
        ),
        throwsA(isA<TimeoutException>()),
      );
    } finally {
      operation.dispose();
    }
  });

  test('abandonment kills and reaps an already running decoder', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final connected = server.first;
    final abandoned = Completer<void>();
    final operation = MediaRenderProcess(
      timeout: const Duration(seconds: 30),
      abandoned: [abandoned.future],
    );
    final work = operation.run(
      executable: Platform.resolvedExecutable,
      arguments: [child.path, '${server.port}'],
      maxOutputBytes: 1024,
    );
    final stopped = expectLater(
      operation.guard(work),
      throwsA(isA<CancelledException>()),
    );
    Socket? socket;
    try {
      socket = await connected.timeout(const Duration(seconds: 20));
      await socket.first.timeout(const Duration(seconds: 5));
      abandoned.complete();
      await stopped;
      await expectLater(
        work.timeout(const Duration(seconds: 5)),
        throwsA(isA<CancelledException>()),
      );
    } finally {
      operation.dispose();
      socket?.destroy();
      await server.close();
    }
  });
}

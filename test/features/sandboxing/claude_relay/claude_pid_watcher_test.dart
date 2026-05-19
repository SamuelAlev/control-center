import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/sandboxing/claude_pid_watcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempHome;
  late File pidFile;
  const pid = 4242;

  setUp(() {
    tempHome = Directory.systemTemp.createTempSync('claude_relay_pid_test_');
    final sessionsDir = Directory(p.join(tempHome.path, '.claude', 'sessions'))
      ..createSync(recursive: true);
    pidFile = File(p.join(sessionsDir.path, '$pid.json'));
  });

  tearDown(() {
    if (tempHome.existsSync()) {
      tempHome.deleteSync(recursive: true);
    }
  });

  void writeStatus(String status) {
    pidFile.writeAsStringSync(jsonEncode({
      'pid': pid,
      'sessionId': 'sess-abc123',
      'cwd': '/tmp/work',
      'kind': 'agent',
      'status': status,
    }));
  }

  test('reports status changes and exposes the session id', () async {
    writeStatus('busy');
    final seen = <String>[];
    final done = Completer<void>();
    final watcher = ClaudePidWatcher(
      pid,
      (status, waitingFor, data) {
        seen.add(status);
        if (status == 'idle') {
          done.complete();
        }
      },
      homeDir: tempHome.path,
      pollInterval: const Duration(milliseconds: 10),
    )..start();

    addTearDown(watcher.stop);

    // Flip to idle shortly after the watcher starts polling.
    Timer(const Duration(milliseconds: 40), () => writeStatus('idle'));

    await done.future.timeout(const Duration(seconds: 2));
    expect(seen, contains('busy'));
    expect(seen, contains('idle'));
    expect(watcher.getSessionId(), 'sess-abc123');
  });

  test('returns null session id when no file exists', () {
    final watcher = ClaudePidWatcher(999999, (_, _, _) {},
        homeDir: tempHome.path);
    expect(watcher.getSessionId(), isNull);
  });

  test('rejects unsafe session ids used as filenames', () {
    pidFile.writeAsStringSync(jsonEncode({
      'pid': pid,
      'sessionId': '../escape',
      'cwd': '/tmp',
      'kind': 'agent',
      'status': 'idle',
    }));
    final watcher =
        ClaudePidWatcher(pid, (_, _, _) {}, homeDir: tempHome.path);
    expect(watcher.getSessionId(), isNull);
  });
}

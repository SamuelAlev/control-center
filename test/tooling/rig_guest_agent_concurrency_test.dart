import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('last viewer detach cannot kill an interleaved reconnect', () async {
    final lines = File('scripts/rigs/build_image.sh').readAsLinesSync();
    final start = lines.indexWhere((line) => line.trim() == '_streams = {}');
    final end = lines.indexWhere(
      (line) => line.trim() == '_microphone_lock = threading.Lock()',
      start + 1,
    );
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));

    final source = lines
        .sublist(start, end)
        .map((line) => line.length >= 6 ? line.substring(6) : '')
        .join('\n');
    final encoded = base64Encode(utf8.encode(source));
    final harness =
        '''
import base64
import os
import queue
import threading
import time

class FakeStdout:
    def read1(self, _count):
        return b""

class FakeProc:
    def __init__(self):
        self.stdout = FakeStdout()
        self.killed = False
    def kill(self):
        self.killed = True
    def wait(self, timeout=None):
        return 0

class FakeSubprocess:
    PIPE = object()
    def Popen(self, *args, **kwargs):
        return FakeProc()

subprocess = FakeSubprocess()
def scale_filter(*_args):
    return "null"

real_start = threading.Thread.start
threading.Thread.start = lambda self: None
exec(base64.b64decode("$encoded"), globals())

first, first_inbox = subscribe_mjpeg(1280, 800, 60, 3, 1280, 800)
interleave = threading.Event()

class InterleavingLock:
    def __init__(self):
        self._lock = threading.Lock()
    def __enter__(self):
        self._lock.acquire()
        return self
    def __exit__(self, *_args):
        self._lock.release()
        interleave.set()
        time.sleep(0.05)

first.lock = InterleavingLock()
detach = threading.Thread(target=first.unsubscribe, args=(first_inbox,))
real_start(detach)
assert interleave.wait(1), "detach never reached the interleave point"
second, _ = subscribe_mjpeg(1280, 800, 60, 3, 1280, 800)
detach.join(1)
assert not detach.is_alive(), "detach did not finish"
assert second is not first, "reconnect attached to the departing producer"
assert first.proc.killed, "departing producer was not stopped"
assert not second.proc.killed, "departing viewer killed the reconnect's producer"
threading.Thread.start = real_start
''';

    final result = await Process.run('python3', ['-c', harness]);
    expect(
      result.exitCode,
      0,
      reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
  });

  test('replaced microphone session ignores delayed chunks and end', () async {
    final lines = File('scripts/rigs/build_image.sh').readAsLinesSync();
    final start = lines.indexWhere(
      (line) => line.trim() == '_microphone_lock = threading.Lock()',
    );
    final end = lines.indexWhere(
      (line) =>
          line.trim() == 'class Handler(http.server.BaseHTTPRequestHandler):',
      start + 1,
    );
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));

    final source = lines
        .sublist(start, end)
        .map((line) => line.length >= 6 ? line.substring(6) : '')
        .join('\n');
    final encoded = base64Encode(utf8.encode(source));
    final harness =
        '''
import base64
import threading
import time

class FakeStdin:
    def __init__(self):
        self.writes = []
        self.closed = False
    def write(self, value):
        self.writes.append(value)
    def flush(self):
        pass
    def close(self):
        self.closed = True

class FakeProc:
    def __init__(self):
        self.stdin = FakeStdin()
        self.killed = False
    def poll(self):
        return None if not self.killed else 0
    def kill(self):
        self.killed = True
    def wait(self, timeout=None):
        return 0

class FakeSubprocess:
    PIPE = object()
    def __init__(self):
        self.processes = []
    def Popen(self, *args, **kwargs):
        proc = FakeProc()
        self.processes.append(proc)
        return proc

subprocess = FakeSubprocess()
real_start = threading.Thread.start
threading.Thread.start = lambda self: None
exec(base64.b64decode("$encoded"), globals())

feed_microphone(b"", 16000, 1, "old", start=True)
feed_microphone(b"old-first", 16000, 1, "old")
old_proc = subprocess.processes[-1]

feed_microphone(b"", 16000, 1, "new", start=True)
feed_microphone(b"new-first", 16000, 1, "new")
new_proc = subprocess.processes[-1]
assert old_proc.killed, "replacement did not stop the old playback process"

feed_microphone(b"old-late", 16000, 1, "old")
feed_microphone(b"", 16000, 1, "old", end=True)
assert not new_proc.killed, "old teardown killed the replacement session"
assert new_proc.stdin.writes == [b"new-first"], "old PCM reached replacement"

feed_microphone(b"", 16000, 1, "new", end=True)
assert new_proc.killed, "active session end did not stop playback"
feed_microphone(b"new-late", 16000, 1, "new")
assert len(subprocess.processes) == 2, "late PCM restarted a closed session"
threading.Thread.start = real_start
''';

    final result = await Process.run('python3', ['-c', harness]);
    expect(
      result.exitCode,
      0,
      reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
  });

  test('cloud-init rendering does not execute guest documentation', () async {
    final lines = File('scripts/rigs/build_image.sh').readAsLinesSync();
    final start = lines.indexWhere(
      (line) => line.contains('cat > "\$WORK_DIR/user-data" <<CLOUDINIT'),
    );
    final end = lines.indexWhere(
      (line) => line.trim() == 'CLOUDINIT',
      start + 1,
    );
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final commonPackages = lines.firstWhere(
      (line) => line.startsWith('COMMON_PACKAGES='),
    );
    final renderScript = [
      commonPackages,
      ...lines.sublist(start, end + 1),
    ].join('\n');

    final workDir = await Directory.systemTemp.createTemp(
      'cc-rig-cloud-init-test-',
    );
    addTearDown(() => workDir.delete(recursive: true));
    final result = await Process.run(
      'bash',
      ['-c', renderScript],
      environment: {
        'WORK_DIR': workDir.path,
        'EXTRA_PACKAGES': '',
        'WALLPAPER': '',
        'QEMU_HTTP_PROXY_ADDR': '10.0.2.100:3128',
        'QEMU_SOCKS_PROXY_ADDR': '10.0.2.101:1080',
        'SURFACE_UNITS': 'cc-x11.service',
        'EXTRA_RUNCMD': '',
        'IMAGE_ID': 'test-image',
      },
    );

    expect(
      result.exitCode,
      0,
      reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
    expect(result.stderr, isEmpty);
    final rendered = await File('${workDir.path}/user-data').readAsString();
    final cloudInit = loadYaml(rendered);
    expect(cloudInit, isA<YamlMap>());
    final document = cloudInit as YamlMap;
    final packages = document['packages'];
    expect(packages, isA<YamlList>());
    expect(packages as YamlList, contains('iputils-ping'));
    final writeFiles = document['write_files'];
    expect(writeFiles, isA<YamlList>());
    for (final entry in writeFiles as YamlList) {
      expect(entry, isA<YamlMap>());
    }
    final seedService = (writeFiles as YamlList)
        .whereType<YamlMap>()
        .singleWhere((entry) => entry['path'] == '/usr/local/bin/cc-rig-seed');
    final seedScript = seedService['content'];
    expect(seedScript, isA<String>());
    expect(seedScript, contains('.unrestricted_network == true'));
    expect(seedScript, contains("sed -i '/^\\("));
    expect(seedScript, contains('unset http_proxy https_proxy'));
    final netplan = writeFiles
        .whereType<YamlMap>()
        .singleWhere((entry) => entry['path'] == '/etc/netplan/60-cc-rig.yaml');
    expect(netplan['content'], contains('renderer: NetworkManager'));
    expect(netplan['content'], contains('name: "en*"'));
    expect(netplan['content'], contains('dhcp4: true'));
    final cloudNetwork = writeFiles.whereType<YamlMap>().singleWhere(
      (entry) =>
          entry['path'] == '/etc/cloud/cloud.cfg.d/99-cc-rig-network.cfg',
    );
    expect(cloudNetwork['content'], contains('config: disabled'));
    final runCommands = document['runcmd'];
    expect(runCommands, isA<YamlList>());
    expect(runCommands, isNotEmpty);
    for (final command in runCommands as YamlList) {
      expect(command, anyOf(isA<String>(), isA<YamlList>()));
    }
    expect(runCommands, contains('rm -f /etc/netplan/50-cloud-init.yaml'));
    expect(runCommands, contains('netplan generate'));
    expect(runCommands, contains('systemctl enable NetworkManager.service'));
    expect(rendered, contains('ccout is the'));
    expect(rendered, contains('ccin is'));
    expect(rendered, contains('EnvironmentFile=-/etc/environment'));
    expect(rendered, contains('pulseaudio --start --exit-idle-time=-1'));
    expect(
      rendered,
      contains('Environment=PULSE_SERVER=unix:/run/user/1000/pulse/native'),
    );
  });
}

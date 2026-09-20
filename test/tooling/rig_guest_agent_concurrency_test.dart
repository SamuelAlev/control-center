import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Joins a `NAME="a b \` / `c"` assignment so a continued COMMON_PACKAGES
/// list still renders as one shell statement.
String readContinuedAssignment(List<String> lines, String name) {
  final start = lines.indexWhere((line) => line.startsWith('$name='));
  if (start < 0) {
    throw StateError('no $name= assignment');
  }
  final buf = StringBuffer();
  for (var i = start; i < lines.length; i++) {
    var line = lines[i];
    final cont = line.endsWith(r'\');
    if (cont) {
      line = line.substring(0, line.length - 1).trimRight();
    }
    if (buf.isEmpty) {
      buf.write(line);
    } else {
      buf
        ..write(' ')
        ..write(line.trimLeft());
    }
    if (!cont) {
      break;
    }
  }
  return buf.toString();
}

List<String> packagesInAssignment(String assignment) {
  final eq = assignment.indexOf('=');
  final value = assignment.substring(eq + 1).replaceAll('"', '').trim();
  return value.split(RegExp(r'\s+')).where((pkg) => pkg.isNotEmpty).toList();
}

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
    final commonPackages = readContinuedAssignment(lines, 'COMMON_PACKAGES');
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
      workingDirectory: workDir.path,
      environment: {
        'WORK_DIR': workDir.path,
        'EXTRA_PACKAGES': '',
        'WALLPAPER': '',
        'QEMU_HTTP_PROXY_ADDR': '10.0.2.100:3128',
        'QEMU_SOCKS_PROXY_ADDR': '10.0.2.101:1080',
        'SURFACE_UNITS': 'cc-x11.service',
        'EXTRA_RUNCMD': '',
        'IMAGE_ID': 'test-image',
        'FIREFOX_URL': 'https://example.invalid/firefox.tar.xz',
        'FIREFOX_SHA256': 'deadbeef',
        'CHROMIUM_URL': 'https://example.invalid/chrome.zip',
        'CHROMIUM_SHA256': 'cafebabe',
      },
    );

    expect(
      result.exitCode,
      0,
      reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
    expect(result.stderr, isEmpty);
    for (final name in [
      '{display:',
      '{ok:',
      '{protocol:',
      '{text,',
      'PCM16',
      'MP3,',
      'concatenated',
      'a',
    ]) {
      expect(
        File('${workDir.path}/$name').existsSync(),
        isFalse,
        reason:
            'cloud-init body was executed as shell and redirected into $name',
      );
    }
    final rendered = await File('${workDir.path}/user-data').readAsString();
    final cloudInit = loadYaml(rendered);
    expect(cloudInit, isA<YamlMap>());
    final document = cloudInit as YamlMap;
    final packages = document['packages'] as YamlList;
    expect(packages, contains('iputils-ping'));
    expect(packages, contains('gcc'));
    expect(packages, contains('python3'));
    expect(packages, contains('cmake'));
    final writeFiles = document['write_files'] as YamlList;
    for (final entry in writeFiles) {
      expect(entry, isA<YamlMap>());
    }
    final seedService = writeFiles.whereType<YamlMap>().singleWhere(
      (entry) => entry['path'] == '/usr/local/bin/cc-rig-seed',
    );
    final seedScript = seedService['content'];
    expect(seedScript, isA<String>());
    expect(seedScript, contains('.unrestricted_network == true'));
    expect(seedScript, contains("sed -i '/^\\("));
    expect(seedScript, contains('unset http_proxy https_proxy'));
    final netplan = writeFiles.whereType<YamlMap>().singleWhere(
      (entry) => entry['path'] == '/etc/netplan/60-cc-rig.yaml',
    );
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
    final extraPackages = lines.firstWhere(
      (line) => line.startsWith('EXTRA_PACKAGES='),
    );
    expect(extraPackages, isNot(contains('chromium-browser')));
    expect(extraPackages, contains('libnss3'));
    expect(extraPackages, contains('epiphany-browser'));
    expect(
      packages,
      contains('unzip'),
      reason:
          'Chromium is a zip; runcmd extracts it, so unzip must be in the '
          'apt list (it lives in COMMON_PACKAGES with the rest of the CLI '
          'baseline).',
    );
    final firefox = writeFiles.whereType<YamlMap>().singleWhere(
      (entry) => entry['path'] == '/usr/local/bin/cc-firefox',
    );
    expect(firefox['content'], contains('/opt/firefox/firefox'));
    expect(firefox['content'], contains('MOZ_DISABLE_CONTENT_SANDBOX'));
    final chromium = writeFiles.whereType<YamlMap>().singleWhere(
      (entry) => entry['path'] == '/usr/local/bin/cc-chromium',
    );
    expect(chromium['content'], contains('/opt/chromium/chrome'));
    expect(chromium['content'], contains('--no-sandbox'));
    expect(chromium['content'], contains('--enable-unsafe-swiftshader'));
    expect(chromium['content'], contains('VK_ICD_FILENAMES'));
    expect(chromium['content'], contains('--ozone-platform='));
    expect(chromium['content'], contains('--no-first-run'));
    expect(chromium['content'], contains('--no-default-browser-check'));
    expect(rendered, contains('DontCheckDefaultBrowser'));
    expect(rendered, contains('OverrideFirstRunPage'));
    expect(rendered, contains('SkipTermsOfUse'));
    expect(rendered, contains('DefaultBrowserSettingEnabled'));
    expect(rendered, contains('/etc/opt/chrome_for_testing/policies/managed'));
    expect(rendered, contains('skip_first_run_ui'));
    expect(rendered, contains('ask-for-default=false'));
    final webkit = writeFiles.whereType<YamlMap>().singleWhere(
      (entry) => entry['path'] == '/usr/local/bin/cc-webkit',
    );
    expect(webkit['content'], contains('epiphany'));
    expect(webkit['content'], contains('WEBKIT_DISABLE_SANDBOX'));
    final browser = writeFiles.whereType<YamlMap>().singleWhere(
      (entry) => entry['path'] == '/usr/local/bin/cc-web-browser',
    );
    expect(browser['content'], contains('/usr/local/bin/cc-firefox'));
    expect(browser['content'], isNot(contains('/snap/bin/chromium')));
    expect(rendered, contains('WebBrowser=cc-web-browser'));
    expect(rendered, contains('Name=Chromium'));
    expect(rendered, contains('Name=Firefox'));
    expect(rendered, contains('Name=WebKit'));
    expect(rendered, contains('export MOZ_WEBRENDER=0'));
    expect(rendered, contains('/mnt/ccbrowsers/firefox.txz'));
    expect(rendered, contains('/mnt/ccbrowsers/chrome.zip'));
    expect(rendered, contains('/dev/disk/by-label/CCBROWSERS'));
    expect(rendered, contains("\$nrconf{restart} = 'l';"));
    expect(rendered, isNot(contains('/mnt/cidata/firefox')));
    expect(rendered, isNot(contains('firefox.tar.xz')));
    expect(rendered, contains('test -x /opt/firefox/firefox'));
    expect(rendered, contains('test -x /opt/chromium/chrome'));
    expect(rendered, contains('CC_RIG_BUILD_FAIL browsers'));
    final source = File('scripts/rigs/build_image.sh').readAsStringSync();
    expect(source, contains('BROWSERS_ISO'));
    expect(source, contains(r'make_iso "$BROWSERS_DIR" CCBROWSERS'));
    expect(
      source,
      contains('-drive "file=\$BROWSERS_ISO,if=virtio,format=raw,readonly=on"'),
    );
    expect(rendered, isNot(contains('CHROMIUM_FLAGS')));
    expect(
      runCommands,
      contains(
        "sh -c 'update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/cc-web-browser 200'",
      ),
    );
    for (final command in runCommands.whereType<String>()) {
      if (!command.contains("sh -c '")) {
        continue;
      }
      expect(
        command.startsWith("sh -c '") && command.endsWith("'"),
        isTrue,
        reason:
            'cloud-init runcmd uses set -e; an unclosed sh -c quote '
            'aborts cloud-final before poweroff: $command',
      );
    }
    final proxyCmd = runCommands.whereType<String>().singleWhere(
      (command) => command.contains('>> /etc/environment'),
    );
    expect(proxyCmd.startsWith("sh -c '"), isTrue);
    expect(proxyCmd.endsWith("'"), isTrue);
  });

  test('the desktop image ships the same CLI toolset as the terminal', () {
    // A Computer tab and a terminal tab should not disagree about what "a
    // basic toolchain" means. Desktop-only extras (openssh-server,
    // python3-pil) sit on top; every package the exec guest warms must
    // also be in the qcow2.
    final shellLines = File('scripts/rigs/build_image.sh').readAsLinesSync();
    final desktop = packagesInAssignment(
      readContinuedAssignment(shellLines, 'COMMON_PACKAGES'),
    );
    final dart = File(
      'packages/cc_infra/lib/src/rigs/smolvm_enclosure_backend.dart',
    ).readAsStringSync();
    final start = dart.indexOf('const List<String> kSmolvmExecPackages = [');
    expect(start, greaterThanOrEqualTo(0));
    final open = dart.indexOf('[', start);
    final close = dart.indexOf('];', open);
    final execPackages = [
      for (final match in RegExp(
        "'([^']+)'",
      ).allMatches(dart.substring(open + 1, close)))
        match.group(1)!,
    ];
    expect(execPackages, isNotEmpty);
    for (final pkg in execPackages) {
      expect(
        desktop,
        contains(pkg),
        reason:
            'The desktop image is missing $pkg which the terminal warms. '
            'Keep COMMON_PACKAGES in lockstep with kSmolvmExecPackages.',
      );
    }
    expect(desktop, contains('openssh-server'));
    expect(desktop, contains('python3-pil'));
  });
}

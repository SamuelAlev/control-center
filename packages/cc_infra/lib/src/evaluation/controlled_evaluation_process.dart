import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
import 'package:path/path.dart' as p;

typedef _PythonRuntime = ({
  String executable,
  String prefix,
  String searchPath,
});

/// A fail-closed process boundary for untrusted evaluation fixtures and code.
/// Provider HTTP is made by the trusted host harness, never from this guest.
class ControlledEvaluationProcess implements HarnessCommandRunner {
  /// Confines each command to a disposable root and private home.
  ControlledEvaluationProcess({
    required this.root,
    required this.home,
    List<String> readOnlyRoots = const [],
    this.cancellation,
    this.commandGuard,
  }) : readOnlyRoots = [
         for (final path in readOnlyRoots)
           Directory(path).resolveSymbolicLinksSync(),
       ];

  /// Mutable task fixture; its directory itself cannot be replaced by a guest.
  final String root;

  /// Per-attempt scratch directory, never the server's actual home.
  final String home;

  /// Immutable skill packages readable by the guest.
  final List<String> readOnlyRoots;

  /// Campaign cancellation also stops the active process group.
  final CancellationToken? cancellation;

  /// Host action-policy check; a reason denies before the process starts.
  final Future<String?> Function(String command)? commandGuard;

  // Resolve Apple's launcher before entering containment; Xcode and the
  // standalone Command Line Tools install their runtimes in different roots.
  static _PythonRuntime? _cachedRuntime;
  static bool _runtimeDiscovered = false;
  static Directory? _runtimeBin;
  static _PythonRuntime? get _pythonRuntime {
    if (!_runtimeDiscovered) {
      _runtimeDiscovered = true;
      _cachedRuntime = _discoverPythonRuntime();
    }
    return _cachedRuntime;
  }

  /// Releases the read-only interpreter alias after all campaign jobs stop.
  static Future<void> disposeRuntime() async {
    final directory = _runtimeBin;
    _runtimeBin = null;
    _cachedRuntime = null;
    _runtimeDiscovered = false;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  static _PythonRuntime? _discoverPythonRuntime() {
    try {
      final result = Process.runSync(
        '/usr/bin/python3',
        [
          '-I',
          '-S',
          '-c',
          'import json,os,sys; print(json.dumps([os.path.realpath(sys.executable),'
              'os.path.realpath(sys.base_prefix)]))',
        ],
        environment: const {'PATH': '/usr/bin:/bin'},
        includeParentEnvironment: false,
      );
      if (result.exitCode != 0) {
        return null;
      }
      final paths = jsonDecode(result.stdout as String) as List<dynamic>;
      var executable = paths[0] as String;
      final prefix = paths[1] as String;
      if (prefix == '/' ||
          !p.isWithin(prefix, executable) ||
          !File(executable).existsSync()) {
        return null;
      }
      var searchPath = p.dirname(executable);
      if (Platform.isMacOS) {
        // The bin/python3 launcher uses posix_spawn. Execute the actual
        // interpreter so guest posix_spawn can remain denied.
        executable = p.join(
          prefix,
          'Resources',
          'Python.app',
          'Contents',
          'MacOS',
          'Python',
        );
        if (!File(executable).existsSync()) {
          return null;
        }
        final directory = Directory.systemTemp.createTempSync(
          'cc-eval-python-',
        );
        _runtimeBin = directory;
        Link(p.join(directory.path, 'python3')).createSync(executable);
        searchPath = directory.resolveSymbolicLinksSync();
      }
      return (executable: executable, prefix: prefix, searchPath: searchPath);
    } on Object {
      return null;
    }
  }

  /// Unsupported platforms are rejected before creating attempts or model calls.
  static String? capabilityReason() {
    if (Platform.isMacOS) {
      if (!File('/usr/bin/sandbox-exec').existsSync()) {
        return 'sandbox-exec is unavailable';
      }
    } else if (Platform.isLinux) {
      if (!File('/usr/bin/bwrap').existsSync()) {
        return 'bubblewrap is unavailable';
      }
    } else {
      return 'No strict skill evaluation sandbox on ${Platform.operatingSystem}';
    }
    if (!File('/bin/bash').existsSync()) {
      return 'bash is unavailable';
    }
    if (_pythonRuntime == null) {
      return 'the contained python3 runtime is unavailable';
    }
    return null;
  }

  /// Probe actual containment and runtime availability without a candidate,
  /// corpus, provider credential, or model charge.
  static Future<String?> probeCapability() async {
    final unavailable = capabilityReason();
    if (unavailable != null) {
      return unavailable;
    }
    final trial = await Directory.systemTemp.createTemp('cc-eval-probe-');
    ServerSocket? sink;
    StreamSubscription<Socket>? connections;
    try {
      final guest = await Directory(p.join(trial.path, 'work')).create();
      final home = await Directory(p.join(trial.path, 'home')).create();
      final canary = File(p.join(trial.path, 'host-canary'));
      await canary.writeAsString('cc-eval-uncaptured-host-secret');
      // A reachable local listener distinguishes enforced denial from an
      // offline machine or an unavailable external test endpoint.
      sink = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final hostConnected = Completer<void>();
      var acceptedConnections = 0;
      connections = sink.listen((socket) {
        acceptedConnections++;
        socket.destroy();
        if (!hostConnected.isCompleted) {
          hostConnected.complete();
        }
      });
      final control = await Socket.connect(
        sink.address,
        sink.port,
        timeout: const Duration(seconds: 2),
      );
      control.destroy();
      await hostConnected.future.timeout(const Duration(seconds: 2));
      final runner = ControlledEvaluationProcess(
        root: guest.path,
        home: home.path,
      );
      final result = await runner.execute('/usr/bin/python3', [
        '-I',
        '-S',
        '-c',
        '''import os, pathlib, resource, socket, sys
failures = []
try:
    pathlib.Path(sys.argv[1]).read_bytes()
    failures.append('host-read')
except OSError:
    pass
try:
    sock = socket.socket()
    sock.settimeout(1)
    sock.connect(('127.0.0.1', int(sys.argv[2])))
    failures.append('network')
except OSError:
    pass
if sys.platform == 'darwin':
    for name, operation in [
        ('setsid', lambda: os.setsid()),
        ('setpgid', lambda: os.setpgid(0, 0)),
        ('spawn', lambda: os.posix_spawn('/bin/bash', ['bash', '-c', 'exit 0'], {}, setpgroup=0)),
    ]:
        try:
            operation()
            failures.append(name)
        except OSError:
            pass
for kind, maximum in [(resource.RLIMIT_CORE, 0),
        (resource.RLIMIT_FSIZE, 16 * 1024 * 1024), (resource.RLIMIT_NOFILE, 128)]:
    actual = resource.getrlimit(kind)[0]
    if actual < 0 or actual > maximum: failures.append('resource-limit')
print(','.join(failures) if failures else 'contained')
sys.exit(1 if failures else 0)
''',
        canary.path,
        '${sink.port}',
      ], timeout: const Duration(seconds: 15));
      if (result.exitCode != 0 ||
          result.timedOut ||
          result.stdout.trim() != 'contained' ||
          acceptedConnections != 1) {
        return 'sandbox failed runtime, host-read, network, process or resource probe: '
            'exit=${result.exitCode}, timeout=${result.timedOut}: '
            '${result.stdout} ${result.stderr}';
      }
      final nested = await runner.execute('/bin/bash', [
        '-c',
        'python3 -I -c "import json,pathlib,ast,decimal,subprocess; print(1)"',
      ], timeout: const Duration(seconds: 15));
      if (nested.exitCode != 0 ||
          nested.timedOut ||
          nested.stdout.trim() != '1') {
        return 'contained Python stdlib or nested verifier processes '
            'unavailable: ${nested.stderr}';
      }
      return null;
    } on Object catch (error) {
      return 'strict sandbox unavailable: $error';
    } finally {
      await connections?.cancel();
      await sink?.close();
      await trial.delete(recursive: true);
    }
  }

  @override
  Future<HarnessCommandResult> run(
    String command, {
    String? workdir,
    int timeoutSeconds = 120,
    Map<String, String>? env,
    CancellationToken? cancel,
  }) async {
    final reason = await commandGuard?.call(command);
    if (reason != null) {
      return HarnessCommandResult.deny(reason);
    }
    final result = await execute(
      '/bin/bash',
      ['-c', command],
      workdir: workdir,
      timeout: Duration(seconds: timeoutSeconds),
      cancel: cancel ?? cancellation,
    );
    return HarnessCommandResult(
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
      timedOut: result.timedOut,
    );
  }

  /// Runs a command with bounded output, enforced deadline and descendant cleanup.
  Future<ControlledProcessResult> execute(
    String executable,
    List<String> arguments, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
    CancellationToken? cancel,
  }) async {
    cancel ??= cancellation;
    final unavailable = capabilityReason();
    if (unavailable != null) {
      throw UnsupportedError(unavailable);
    }
    if (cancel?.isCancelled ?? false) {
      throw StateError('evaluation cancelled');
    }
    final base = Directory(root).resolveSymbolicLinksSync();
    final cwd = Directory(workdir ?? root).resolveSymbolicLinksSync();
    if (cwd != base && !p.isWithin(base, cwd)) {
      throw StateError('command cwd escapes the attempt');
    }
    final homeType = FileSystemEntity.typeSync(home, followLinks: false);
    if (homeType == FileSystemEntityType.notFound) {
      Directory(home).createSync();
    } else if (homeType != FileSystemEntityType.directory) {
      throw StateError('evaluation home is not a regular directory');
    }
    final python = _pythonRuntime!;
    final guestExecutable = executable == '/usr/bin/python3'
        ? python.executable
        : executable;
    final String sandbox;
    final List<String> sandboxArgs;
    if (Platform.isMacOS) {
      // The profile is outside every path visible to the candidate.
      final profile = File(
        p.join(
          Directory(home).parent.path,
          'profile-${p.basename(home)}-${DateTime.now().microsecondsSinceEpoch}.sb',
        ),
      );
      await profile.writeAsString(_profile(base));
      // Restrict profile permissions; the guest cannot read its parent.
      await Process.run('/bin/chmod', ['600', profile.path]);
      sandbox = '/usr/bin/sandbox-exec';
      sandboxArgs = ['-f', profile.path, guestExecutable, ...arguments];
    } else {
      sandbox = '/usr/bin/bwrap';
      sandboxArgs = _linuxArgs(base, executable, arguments);
    }
    final Process process;
    try {
      process = await Process.start(
        python.executable,
        [
          '-I',
          '-S',
          '-c',
          _launcher,
          '${timeout.inSeconds < 1 ? 1 : timeout.inSeconds}',
          sandbox,
          ...sandboxArgs,
        ],
        workingDirectory: cwd,
        environment: {
          'HOME': home,
          'TMPDIR': home,
          'PATH': '${python.searchPath}:/usr/bin:/bin',
          'LANG': 'C',
          'PYTHONDONTWRITEBYTECODE': '1',
          'PYTHONNOUSERSITE': '1',
        },
        includeParentEnvironment: false,
        runInShell: false,
      );
    } on Object {
      if (Platform.isMacOS) {
        try {
          File(sandboxArgs[1]).deleteSync();
        } on FileSystemException {
          // Preserve the process-start failure if profile cleanup also fails.
        }
      }
      rethrow;
    }
    await process.stdin.close();
    var active = true;
    void terminate() {
      if (!active) {
        return;
      }
      if (Platform.isMacOS) {
        // The trusted launcher creates this session before applying Seatbelt.
        // Guest setsid/setpgid/posix_spawn are denied, so descendants cannot
        // escape this group by reparenting when their direct parent exits.
        Process.killPid(-process.pid, ProcessSignal.sigkill);
      }
      process.kill(ProcessSignal.sigkill);
    }

    unawaited(cancel?.whenCancelled.then((_) => terminate()));
    var timedOut = false;
    final stdoutFuture = _bounded(process.stdout);
    final stderrFuture = _bounded(process.stderr);
    try {
      final code = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          timedOut = true;
          terminate();
          return process.exitCode;
        },
      );
      // Also clean up on ordinary exit, before waiting for inherited pipe EOF.
      terminate();
      final output = await Future.wait([
        stdoutFuture,
        stderrFuture,
      ]).timeout(const Duration(seconds: 2));
      return ControlledProcessResult(
        exitCode: code,
        stdout: output[0],
        stderr: output[1],
        timedOut: timedOut,
      );
    } finally {
      terminate();
      active = false;
      if (Platform.isMacOS) {
        try {
          File(sandboxArgs[1]).deleteSync();
        } on FileSystemException {
          // The private per-attempt parent is removed during teardown.
        }
      }
    }
  }

  // This controller runs before the untrusted program, with an empty inherited
  // environment and isolated Python imports. Darwin has no usable RLIMIT_AS;
  // do not advertise a hard guest-memory quota there.
  static const _launcher = r'''
import os, resource, subprocess, sys
seconds = int(sys.argv[1])
def cap(kind, value):
    hard = resource.getrlimit(kind)[1]
    if hard != resource.RLIM_INFINITY: value = min(value, hard)
    resource.setrlimit(kind, (value, value))
cap(resource.RLIMIT_CORE, 0)
cap(resource.RLIMIT_CPU, seconds)
cap(resource.RLIMIT_FSIZE, 16 * 1024 * 1024)
cap(resource.RLIMIT_NOFILE, 128)
processes = len(subprocess.check_output(
    ['/bin/ps', '-U', str(os.getuid()), '-o', 'pid=']).splitlines())
cap(resource.RLIMIT_NPROC, processes + 16)
if sys.platform == 'darwin':
    os.setsid()
else:
    cap(resource.RLIMIT_AS, 512 * 1024 * 1024)
os.execv(sys.argv[2], sys.argv[2:])
''';

  static Future<String> _bounded(Stream<List<int>> stream) async {
    final bytes = <int>[];
    await for (final chunk in stream) {
      if (bytes.length < 16000) {
        bytes.addAll(chunk.take(16000 - bytes.length));
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  List<String> _linuxArgs(
    String base,
    String executable,
    List<String> arguments,
  ) {
    // Unlike the production dispatch profile, never ro-bind / or /etc.
    // bwrap's new mount namespace contains only runtime libraries, exact
    // executables, and the disposable task. PID + network namespaces prevent
    // guest interaction with host processes and all egress.
    final args = <String>[
      '--die-with-parent',
      '--new-session',
      '--unshare-all',
      '--proc',
      '/proc',
      '--dev',
      '/dev',
      '--tmpfs',
      '/tmp',
      '--dir',
      '/usr',
      '--dir',
      '/usr/bin',
      '--dir',
      '/usr/lib',
      '--dir',
      '/usr/share',
      '--dir',
      '/bin',
      '--dir',
      '/lib',
      '--dir',
      '/lib64',
      '--dir',
      '/home',
    ];
    for (final dir in [
      '/usr/lib',
      '/usr/lib64',
      '/lib',
      '/lib64',
      '/usr/share/python3',
      '/usr/share/python3.11',
    ]) {
      if (Directory(dir).existsSync()) {
        args.addAll(['--ro-bind', dir, dir]);
      }
    }
    for (final binary in ['/bin/bash', '/usr/bin/python3', '/usr/bin/env']) {
      if (File(binary).existsSync() || Link(binary).existsSync()) {
        final resolved = File(binary).resolveSymbolicLinksSync();
        if (!p.equals(binary, resolved)) {
          // A runtime outside the pinned prefixes cannot be made visible
          // without widening host reads; fail rather than broken/fake checks.
          if (!resolved.startsWith('/usr/lib/') &&
              !resolved.startsWith('/usr/bin/') &&
              !resolved.startsWith('/bin/')) {
            throw UnsupportedError(
              'runtime escapes the strict allowlist: $binary',
            );
          }
          args.addAll(['--ro-bind', resolved, resolved]);
        }
        args.addAll(['--ro-bind', binary, binary]);
      }
    }
    args.addAll(['--bind', base, base, '--bind', home, home]);
    for (final dir in readOnlyRoots) {
      args.addAll(['--ro-bind', dir, dir]);
    }
    args.addAll([
      '--chdir',
      base,
      '--setenv',
      'HOME',
      home,
      '--',
      executable,
      ...arguments,
    ]);
    return args;
  }

  String _profile(String base) {
    String quote(String value) =>
        value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    String subpath(String value) => '(subpath "${quote(value)}")';
    final home = Directory(this.home).resolveSymbolicLinksSync();
    final python = _pythonRuntime!;
    final runtime = <String>[
      '/System/Library',
      '/usr/lib',
      '/usr/share',
      python.prefix,
      python.searchPath,
    ];
    final binaries = <String>[
      '/bin/bash',
      '/usr/bin/env',
      python.executable,
      p.join(
        python.prefix,
        'Resources',
        'Python.app',
        'Contents',
        'MacOS',
        'Python',
      ),
    ];
    final ancestors = <String>{};
    for (final path in [...runtime, base, home]) {
      var parent = p.dirname(path);
      while (parent != '/') {
        ancestors.add(parent);
        parent = p.dirname(parent);
      }
    }
    return [
      '(version 1)',
      '(deny default)',
      // Apple maintains the exact dyld/Cryptex bootstrap paths. In particular,
      // libignition must open "/" as an openat root; this grants no descendants.
      if (File('/System/Library/Sandbox/Profiles/dyld-support.sb').existsSync())
        '(import "/System/Library/Sandbox/Profiles/dyld-support.sb")',
      '(allow file-read* (literal "/"))',
      for (final dir in ancestors)
        '(allow file-read-metadata (literal "${quote(dir)}"))',
      '(allow process-fork)',
      '(allow signal (target self))',
      '(allow sysctl-read (sysctl-name-prefix "hw.") '
          '(sysctl-name "kern.ostype" "kern.osrelease" "kern.osversion" '
          '"kern.version" "kern.osvariant_status"))',
      '(deny syscall-unix (syscall-number SYS_setsid SYS_setpgid '
          'SYS_posix_spawn SYS_setrlimit))',
      '(deny network*)',
      '(allow file-read* ${subpath(base)})',
      for (final dir in readOnlyRoots) '(allow file-read* ${subpath(dir)})',
      '(allow file-read* ${subpath(home)})',
      for (final dir in runtime)
        '(allow file-read* file-map-executable ${subpath(dir)})',
      for (final file in binaries)
        '(allow file-read* file-map-executable process-exec (literal "${quote(file)}"))',
      for (final file in [
        '/dev/null',
        '/dev/urandom',
        '/dev/random',
        '/dev/fd',
      ])
        '(allow file-read* ${subpath(file)})',
      '(allow file-write* ${subpath(base)})',
      '(allow file-write* ${subpath(home)})',
      '(allow file-write* (literal "/dev/null"))',
      // Do not let the guest rename the protected subtree via its parent.
      '(deny file-write-unlink (literal "${quote(base)}"))',
      '(deny file-write-unlink (literal "${quote(home)}"))',
      for (final dir in readOnlyRoots) '(deny file-write* ${subpath(dir)})',
      for (final dir in readOnlyRoots)
        '(deny file-write-unlink (literal "${quote(dir)}"))',
      '',
    ].join('\n');
  }
}

/// Bounded output from one contained guest process.
class ControlledProcessResult {
  /// Records the process outcome without interpreting it as task success.
  const ControlledProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.timedOut,
  });

  /// Native exit code, including a signal-induced termination.
  final int exitCode;

  /// At most 16,000 bytes of decoded standard output.
  final String stdout;

  /// At most 16,000 bytes of decoded standard error.
  final String stderr;

  /// Whether the wall-clock deadline terminated the process.
  final bool timedOut;
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/ios_automation_store.dart';
import 'package:cc_infra/src/rigs/wda_client.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Runs one finite Apple host tool.
typedef IosProcessRun =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      Map<String, String>? environment,
    });

/// Starts the long-lived WebDriverAgent runner sentinel.
typedef IosProcessStart =
    Future<IosRunnerProcess> Function(
      String executable,
      List<String> arguments, {
      Map<String, String>? environment,
    });

/// Allocates one currently-free loopback port.
typedef IosPortAllocator = Future<int> Function();

/// Injectable delay used by readiness polling.
typedef IosDelay = Future<void> Function(Duration duration);

/// Narrow process surface retained as WDA's death sentinel.
abstract interface class IosRunnerProcess {
  /// Process stdout.
  Stream<List<int>> get stdout;

  /// Process stderr.
  Stream<List<int>> get stderr;

  /// Exit code future.
  Future<int> get exitCode;

  /// Terminates the process.
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);
}

class _RealIosRunnerProcess implements IosRunnerProcess {
  _RealIosRunnerProcess(this._process);

  final Process _process;

  @override
  Stream<List<int>> get stdout => _process.stdout;

  @override
  Stream<List<int>> get stderr => _process.stderr;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      _process.kill(signal);
}

/// Selected iOS runtime and compatible iPhone model.
class IosSimulatorSelection {
  /// Creates a runtime/device selection.
  const IosSimulatorSelection({
    required this.runtimeIdentifier,
    required this.runtimeVersion,
    required this.deviceTypeIdentifier,
    required this.deviceTypeName,
  });

  /// CoreSimulator runtime identifier.
  final String runtimeIdentifier;

  /// Semantic iOS version.
  final String runtimeVersion;

  /// CoreSimulator device type identifier.
  final String deviceTypeIdentifier;

  /// Human-readable iPhone model.
  final String deviceTypeName;
}

/// One live ephemeral CoreSimulator device and its WDA session.
class IosSimulatorSession {
  /// Creates one live simulator session.
  IosSimulatorSession({
    required this.rigId,
    required this.name,
    required this.udid,
    required this.httpPort,
    required this.mjpegPort,
    required this.client,
    required this.display,
    required this.scale,
    required this.runner,
  });

  /// Owning rig id.
  final String rigId;

  /// Namespaced CoreSimulator display name.
  final String name;

  /// CoreSimulator device UDID.
  final String udid;

  /// WDA command port.
  final int httpPort;

  /// WDA MJPEG port.
  final int mjpegPort;

  /// Active typed WDA client.
  final WdaClient client;

  /// Last known logical display size.
  RigDisplaySize display;

  /// Last known native scale.
  double scale;

  /// Long-lived WDA launch process retained as a death sentinel.
  final IosRunnerProcess runner;

  bool _closed = false;
}

/// CoreSimulator lifecycle or prerequisite failure.
class IosSimulatorException implements Exception {
  /// Creates a lifecycle failure.
  const IosSimulatorException(this.message);

  /// Operator-facing detail.
  final String message;

  @override
  String toString() => 'IosSimulatorException: $message';
}

class _OwnedIosDevice {
  const _OwnedIosDevice({
    required this.rigId,
    required this.name,
    required this.udid,
  });

  final String rigId;
  final String name;
  final String? udid;

  Map<String, dynamic> toJson() => {'rigId': rigId, 'name': name, 'udid': udid};
}

/// macOS CoreSimulator adapter with explicit ownership and bounded startup.
class IosSimulatorBackend {
  /// Creates the backend.
  IosSimulatorBackend({
    required String dataDir,
    required this.automationStore,
    bool? isMacOS,
    IosProcessRun? runProcess,
    IosProcessStart? startProcess,
    IosPortAllocator? allocatePort,
    IosDelay? delay,
    WdaClient Function(Uri baseUri, Uri mjpegUri)? clientFactory,
    this.commandTimeout = const Duration(seconds: 30),
    this.bootTimeout = const Duration(minutes: 2),
    this.wdaTimeout = const Duration(seconds: 40),
    this.pollInterval = const Duration(milliseconds: 500),
    this.wdaLaunchAttempts = 3,
  }) : _registryPath = p.join(dataDir, 'rigs', 'ios', 'devices.json'),
       _namespace = sha256
           .convert(utf8.encode(p.canonicalize(p.absolute(dataDir))))
           .toString()
           .substring(0, 8),
       _isMacOS = isMacOS ?? Platform.isMacOS,
       _run = runProcess ?? _defaultRun,
       _start = startProcess ?? _defaultStart,
       _allocatePort = allocatePort ?? _defaultAllocatePort,
       _delay = delay ?? Future<void>.delayed,
       _clientFactory =
           clientFactory ??
           ((base, mjpeg) => WdaClient(baseUri: base, mjpegUri: mjpeg));

  static const String _xcrun = '/usr/bin/xcrun';
  static const String _xcodebuild = '/usr/bin/xcodebuild';
  static const String _plutil = '/usr/bin/plutil';

  final String _registryPath;
  final String _namespace;
  final bool _isMacOS;
  final IosProcessRun _run;
  final IosProcessStart _start;
  final IosPortAllocator _allocatePort;
  final IosDelay _delay;
  final WdaClient Function(Uri baseUri, Uri mjpegUri) _clientFactory;

  /// Pinned WDA artifact store.
  final IosAutomationStore automationStore;

  /// Finite Apple-tool deadline.
  final Duration commandTimeout;

  /// Simulator boot deadline.
  final Duration bootTimeout;

  /// WDA readiness deadline per launch attempt.
  final Duration wdaTimeout;

  /// Readiness polling cadence.
  final Duration pollInterval;

  /// Number of fresh port pairs attempted when WDA cannot bind.
  final int wdaLaunchAttempts;

  Future<void> _registryTail = Future<void>.value();
  RigBackendCapabilities? _cachedProbe;

  /// Re-probes every prerequisite when [refresh] is true.
  Future<RigBackendCapabilities> probe({bool refresh = false}) async {
    if (!refresh && _cachedProbe != null) {
      return _cachedProbe!;
    }
    final result = await _probe();
    _cachedProbe = result;
    return result;
  }

  Future<RigBackendCapabilities> _probe() async {
    const surfaces = {RigSurface.ios};
    const backend = EnclosureBackend.iosSimulator;
    if (!_isMacOS) {
      return RigBackendCapabilities.unavailable(
        backend,
        surfaces: surfaces,
        note:
            'iOS Simulator requires a macOS server with Xcode and an iOS 17 '
            'or newer Simulator runtime.',
      );
    }

    ProcessResult xcode;
    try {
      final simctl = await _command(_xcrun, const ['--find', 'simctl']);
      xcode = await _command(_xcodebuild, const ['-version']);
      if (simctl.exitCode != 0 || xcode.exitCode != 0) {
        throw const IosSimulatorException('Xcode tools are not selected.');
      }
    } on Object {
      return RigBackendCapabilities.unavailable(
        backend,
        surfaces: surfaces,
        requiresInstall: true,
        installHint:
            'sudo xcode-select --switch '
            '/Applications/Xcode.app/Contents/Developer',
        note:
            'Xcode is missing or its developer directory is not selected. '
            'Install Xcode, then select it for command-line tools.',
      );
    }

    final firstLaunch = await _command(_xcodebuild, const [
      '-checkFirstLaunchStatus',
    ]);
    if (firstLaunch.exitCode != 0) {
      return RigBackendCapabilities.unavailable(
        backend,
        surfaces: surfaces,
        requiresInstall: true,
        installHint: 'sudo xcodebuild -runFirstLaunch',
        note:
            'Xcode first-launch setup is incomplete. Complete its license and '
            'component installation before starting an iOS Simulator.',
        version: _firstLine(xcode.stdout),
      );
    }

    final list = await _command(_xcrun, const ['simctl', 'list', '--json']);
    if (list.exitCode != 0) {
      return RigBackendCapabilities.unavailable(
        backend,
        surfaces: surfaces,
        note:
            'simctl could not enumerate installed Simulator runtimes: '
            '${_diagnostic(list)}',
        version: _firstLine(xcode.stdout),
      );
    }

    final selection = selectIosSimulator(
      _decodeObject('${list.stdout}', sourceName: 'simctl list'),
    );
    if (selection == null) {
      return RigBackendCapabilities.unavailable(
        backend,
        surfaces: surfaces,
        requiresInstall: true,
        installHint: 'xcodebuild -downloadPlatform iOS',
        note:
            'No available iOS 17 or newer Simulator runtime with a compatible '
            'iPhone device type is installed.',
        version: _firstLine(xcode.stdout),
      );
    }

    final note =
        '${_firstLine(xcode.stdout)}; iOS ${selection.runtimeVersion}; '
        '${selection.deviceTypeName}; WebDriverAgent '
        '$kIosAutomationVersion ($kIosAutomationCommit). '
        'Networking is host-managed and is not enclosed.';
    if (!automationStore.isInstalled) {
      return RigBackendCapabilities.unavailable(
        backend,
        surfaces: surfaces,
        setupAction: RigBackendSetupAction.iosAutomation,
        note: '$note Install the pinned automation bridge to continue.',
        version: _firstLine(xcode.stdout),
      );
    }

    return RigBackendCapabilities(
      backend: backend,
      available: true,
      surfaces: surfaces,
      supportsTerminals: false,
      note: note,
      version: _firstLine(xcode.stdout),
    );
  }

  /// Creates, boots and automates one namespaced ephemeral simulator.
  Future<IosSimulatorSession> launch({
    required String rigId,
    void Function(String stage)? onProgress,
  }) async {
    final capability = await probe(refresh: true);
    if (!capability.supports(RigSurface.ios)) {
      throw IosSimulatorException(
        capability.note ?? 'iOS Simulator is unavailable on this server.',
      );
    }
    onProgress?.call('Finding iOS runtime');
    final selection = await _currentSelection();
    if (selection == null) {
      throw const IosSimulatorException(
        'No compatible iOS Simulator runtime is available.',
      );
    }

    final name = 'ccrig-$_namespace-$rigId';
    String? udid;
    IosRunnerProcess? runner;
    WdaClient? client;
    try {
      onProgress?.call('Creating iOS Simulator');
      await _withRegistry(() async {
        final records = await _readRegistry();
        if (records.any((record) => record.rigId == rigId)) {
          throw IosSimulatorException(
            'The iOS device registry already owns rig $rigId.',
          );
        }
        records.add(_OwnedIosDevice(rigId: rigId, name: name, udid: null));
        await _writeRegistry(records);
      });
      final created = await _requireSuccess(_xcrun, [
        'simctl',
        'create',
        name,
        selection.deviceTypeIdentifier,
        selection.runtimeIdentifier,
      ], operation: 'create iOS Simulator');
      udid = '${created.stdout}'.trim();
      if (udid.isEmpty) {
        throw const IosSimulatorException(
          'simctl create returned no device UDID.',
        );
      }
      final ownedUdid = udid;
      await _withRegistry(() async {
        final records = await _readRegistry();
        final index = records.indexWhere((record) => record.rigId == rigId);
        if (index < 0 || records[index].name != name) {
          throw IosSimulatorException(
            'The iOS device registry lost pending ownership for $rigId.',
          );
        }
        records[index] = _OwnedIosDevice(
          rigId: rigId,
          name: name,
          udid: ownedUdid,
        );
        await _writeRegistry(records);
      });

      onProgress?.call('Booting iOS Simulator');
      final boot = await _command(_xcrun, ['simctl', 'boot', udid]);
      if (boot.exitCode != 0 && !_alreadyBooted(boot)) {
        throw IosSimulatorException(
          'Could not boot iOS Simulator: ${_diagnostic(boot)}',
        );
      }
      await _waitForBooted(udid);
      await _requireSuccess(_xcrun, [
        'simctl',
        'install',
        udid,
        automationStore.runnerAppPath,
      ], operation: 'install WebDriverAgent');
      final infoPath = p.join(automationStore.runnerAppPath, 'Info.plist');
      final bundle = await _requireSuccess(_plutil, [
        '-extract',
        'CFBundleIdentifier',
        'raw',
        '-o',
        '-',
        infoPath,
      ], operation: 'read WebDriverAgent bundle id');
      final bundleId = '${bundle.stdout}'.trim();
      if (bundleId.isEmpty) {
        throw const IosSimulatorException(
          'WebDriverAgent Info.plist has no CFBundleIdentifier.',
        );
      }

      onProgress?.call('Starting iOS automation');
      Object? lastFailure;
      for (var attempt = 1; attempt <= wdaLaunchAttempts; attempt++) {
        final httpPort = await _allocatePort();
        var mjpegPort = await _allocatePort();
        while (mjpegPort == httpPort) {
          mjpegPort = await _allocatePort();
        }
        final launched = await _start(
          _xcrun,
          [
            'simctl',
            'launch',
            '--console',
            '--terminate-running-process',
            udid,
            bundleId,
          ],
          environment: {
            'SIMCTL_CHILD_USE_IP': '127.0.0.1',
            'SIMCTL_CHILD_USE_PORT': '$httpPort',
            'SIMCTL_CHILD_MJPEG_SERVER_PORT': '$mjpegPort',
          },
        );
        runner = launched;
        final tail = _ProcessTail(launched);
        client = _clientFactory(
          Uri.parse('http://127.0.0.1:$httpPort/'),
          Uri.parse('http://127.0.0.1:$mjpegPort/'),
        );
        try {
          await _waitForWda(client, launched, tail);
          await client.createSession();
          final screen = await client.screen();
          return IosSimulatorSession(
            rigId: rigId,
            name: name,
            udid: udid,
            httpPort: httpPort,
            mjpegPort: mjpegPort,
            client: client,
            display: screen.size,
            scale: screen.scale,
            runner: launched,
          );
        } on Object catch (error) {
          lastFailure = error;
          try {
            await client.deleteSession();
          } on Object {
            // The session often does not exist on a bind failure.
          }
          launched.kill();
          try {
            await launched.exitCode.timeout(const Duration(seconds: 3));
          } on Object {
            launched.kill(ProcessSignal.sigkill);
          }
          runner = null;
          client = null;
          if (attempt == wdaLaunchAttempts) {
            throw IosSimulatorException(
              'WebDriverAgent did not become ready after $attempt attempt(s): '
              '$lastFailure\n${tail.diagnostic}',
            );
          }
        }
      }
      throw IosSimulatorException('WebDriverAgent launch failed: $lastFailure');
    } on Object {
      if (client != null) {
        try {
          await client.deleteSession();
        } on Object {
          // Preserve the launch failure.
        }
      }
      runner?.kill();
      if (udid != null) {
        await _deleteOwnedDevice(
          _OwnedIosDevice(rigId: rigId, name: name, udid: udid),
          removeRecord: true,
          preserveFailure: true,
        );
      } else {
        await _recoverRecord(rigId, preserveFailure: true);
      }
      rethrow;
    }
  }

  /// Installs an app bundle into a live simulator.
  Future<void> installApp(IosSimulatorSession session, String appPath) async {
    await _requireSuccess(_xcrun, [
      'simctl',
      'install',
      session.udid,
      appPath,
    ], operation: 'install simulator app');
  }

  /// Terminates one running application.
  Future<void> stopApp(IosSimulatorSession session, String bundleId) async {
    await _requireSuccess(_xcrun, [
      'simctl',
      'terminate',
      session.udid,
      bundleId,
    ], operation: 'stop simulator app');
  }

  /// Removes one installed application.
  Future<void> uninstallApp(
    IosSimulatorSession session,
    String bundleId,
  ) async {
    await _requireSuccess(_xcrun, [
      'simctl',
      'uninstall',
      session.udid,
      bundleId,
    ], operation: 'uninstall simulator app');
  }

  /// Opens an absolute URL or app deep link.
  Future<void> openUrl(IosSimulatorSession session, String url) async {
    await _requireSuccess(_xcrun, [
      'simctl',
      'openurl',
      session.udid,
      url,
    ], operation: 'open simulator URL');
  }

  /// Runs one argv-shaped process inside the simulator.
  Future<String> spawn(IosSimulatorSession session, List<String> argv) async {
    if (argv.isEmpty ||
        argv.any((value) => value.isEmpty || value.contains('\u0000'))) {
      throw const IosSimulatorException(
        'Simulator process argv must contain non-empty strings without NUL bytes.',
      );
    }
    final result = await _requireSuccess(_xcrun, [
      'simctl',
      'spawn',
      session.udid,
      ...argv,
    ], operation: 'run simulator process');
    return [
      '${result.stdout}'.trim(),
      '${result.stderr}'.trim(),
    ].where((part) => part.isNotEmpty).join('\n');
  }

  /// Closes WDA and deletes the owned ephemeral simulator.
  Future<void> close(IosSimulatorSession session) async {
    if (session._closed) {
      return;
    }
    session._closed = true;
    Object? firstFailure;
    try {
      await session.client.deleteSession();
    } on Object catch (error) {
      firstFailure = error;
    }
    session.runner.kill();
    try {
      await session.runner.exitCode.timeout(const Duration(seconds: 3));
    } on Object {
      session.runner.kill(ProcessSignal.sigkill);
    }
    try {
      await _deleteOwnedDevice(
        _OwnedIosDevice(
          rigId: session.rigId,
          name: session.name,
          udid: session.udid,
        ),
        removeRecord: true,
      );
    } on Object catch (error) {
      firstFailure ??= error;
    }
    if (firstFailure != null) {
      throw firstFailure;
    }
  }

  /// Resolves every registry-owned or pending device left by a previous run.
  ///
  /// A single undeletable simulator is logged and left in the registry for
  /// the next pass. Throwing here used to abort `RigService.start` entirely,
  /// so a leftover from a crashed boot skipped the reaper and left QEMU and
  /// smolvm unarmed. QEMU's orphan sweep already steps over one failure the
  /// same way — this runs on every boot.
  Future<void> sweepOrphanedDevices() => _withRegistry(() async {
    final records = await _readRegistry();
    if (records.isEmpty) {
      return;
    }
    final devices = await _simctlDevices();
    final remaining = <_OwnedIosDevice>[];
    for (final record in records) {
      final udid = record.udid ?? _udidForExactName(devices, record.name);
      if (udid == null) {
        continue;
      }
      try {
        await _shutdownAndDelete(udid);
      } on Object catch (error) {
        remaining.add(record);
        CcInfraLog.warning(
          'rig: could not sweep owned iOS Simulator $udid '
          '(${record.name}): $error',
        );
      }
    }
    await _writeRegistry(remaining);
  });

  Future<IosSimulatorSelection?> _currentSelection() async {
    final list = await _requireSuccess(_xcrun, const [
      'simctl',
      'list',
      '--json',
    ], operation: 'list iOS Simulator runtimes');
    return selectIosSimulator(
      _decodeObject('${list.stdout}', sourceName: 'simctl list'),
    );
  }

  Future<void> _waitForBooted(String udid) async {
    final deadline = DateTime.now().add(bootTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final devices = await _simctlDevices();
      final device = _deviceByUdid(devices, udid);
      if (device?['state'] == 'Booted') {
        return;
      }
      await _delay(pollInterval);
    }
    throw IosSimulatorException(
      'iOS Simulator $udid did not reach Booted within '
      '${bootTimeout.inSeconds}s.',
    );
  }

  Future<void> _waitForWda(
    WdaClient client,
    IosRunnerProcess process,
    _ProcessTail tail,
  ) async {
    final deadline = DateTime.now().add(wdaTimeout);
    var exited = false;
    int? exitCode;
    unawaited(
      process.exitCode.then((code) {
        exited = true;
        exitCode = code;
      }),
    );
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      if (exited) {
        throw IosSimulatorException(
          'WebDriverAgent exited early with code $exitCode.\n${tail.diagnostic}',
        );
      }
      try {
        await client.status();
        return;
      } on Object catch (error) {
        lastError = error;
      }
      await _delay(pollInterval);
    }
    throw IosSimulatorException(
      'WebDriverAgent readiness timed out: $lastError\n${tail.diagnostic}',
    );
  }

  Future<List<Map<String, dynamic>>> _simctlDevices() async {
    final result = await _requireSuccess(_xcrun, const [
      'simctl',
      'list',
      'devices',
      '--json',
    ], operation: 'list iOS Simulator devices');
    final root = _decodeObject(
      '${result.stdout}',
      sourceName: 'simctl devices',
    );
    final output = <Map<String, dynamic>>[];
    final devices = root['devices'];
    if (devices is Map) {
      for (final list in devices.values) {
        if (list is List) {
          for (final device in list) {
            if (device is Map) {
              output.add(device.cast<String, dynamic>());
            }
          }
        }
      }
    }
    return output;
  }

  Future<void> _recoverRecord(
    String rigId, {
    required bool preserveFailure,
  }) async {
    try {
      await _withRegistry(() async {
        final records = await _readRegistry();
        final index = records.indexWhere((record) => record.rigId == rigId);
        if (index < 0) {
          return;
        }
        final record = records[index];
        final devices = await _simctlDevices();
        final udid = record.udid ?? _udidForExactName(devices, record.name);
        if (udid != null) {
          await _shutdownAndDelete(udid);
        }
        records.removeAt(index);
        await _writeRegistry(records);
      });
    } on Object {
      if (!preserveFailure) {
        rethrow;
      }
    }
  }

  Future<void> _deleteOwnedDevice(
    _OwnedIosDevice record, {
    required bool removeRecord,
    bool preserveFailure = false,
  }) async {
    try {
      if (record.udid != null) {
        await _shutdownAndDelete(record.udid!);
      }
      if (removeRecord) {
        await _withRegistry(() async {
          final records = await _readRegistry();
          records.removeWhere((candidate) => candidate.rigId == record.rigId);
          await _writeRegistry(records);
        });
      }
    } on Object {
      if (!preserveFailure) {
        rethrow;
      }
    }
  }

  Future<void> _shutdownAndDelete(String udid) async {
    final shutdown = await _command(_xcrun, ['simctl', 'shutdown', udid]);
    if (shutdown.exitCode != 0 && !_alreadyStoppedOrMissing(shutdown)) {
      throw IosSimulatorException(
        'Could not shut down owned iOS Simulator $udid: '
        '${_diagnostic(shutdown)}',
      );
    }
    final delete = await _command(_xcrun, ['simctl', 'delete', udid]);
    if (delete.exitCode != 0 && !_alreadyStoppedOrMissing(delete)) {
      throw IosSimulatorException(
        'Could not delete owned iOS Simulator $udid: ${_diagnostic(delete)}',
      );
    }
  }

  Future<T> _withRegistry<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _registryTail = _registryTail.then((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  Future<List<_OwnedIosDevice>> _readRegistry() async {
    final file = File(_registryPath);
    final link = Link(_registryPath);
    if (link.existsSync()) {
      throw IosSimulatorException(
        'Refusing symlinked iOS device registry at $_registryPath.',
      );
    }
    if (!file.existsSync()) {
      return [];
    }
    Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on Object catch (error) {
      throw IosSimulatorException(
        'The iOS device registry is invalid and was preserved: $error',
      );
    }
    if (decoded is! List) {
      throw const IosSimulatorException(
        'The iOS device registry is invalid and was preserved.',
      );
    }
    final records = <_OwnedIosDevice>[];
    final rigIds = <String>{};
    final names = <String>{};
    final udids = <String>{};
    for (final item in decoded) {
      if (item is! Map ||
          item['rigId'] is! String ||
          item['name'] is! String ||
          (item['udid'] != null && item['udid'] is! String)) {
        throw const IosSimulatorException(
          'The iOS device registry is invalid and was preserved.',
        );
      }
      final record = _OwnedIosDevice(
        rigId: item['rigId'] as String,
        name: item['name'] as String,
        udid: item['udid'] as String?,
      );
      if (!rigIds.add(record.rigId) ||
          !names.add(record.name) ||
          (record.udid != null && !udids.add(record.udid!))) {
        throw const IosSimulatorException(
          'The iOS device registry contains duplicate ownership records and '
          'was preserved.',
        );
      }
      records.add(record);
    }
    return records;
  }

  Future<void> _writeRegistry(List<_OwnedIosDevice> records) async {
    final file = File(_registryPath);
    if (Link(_registryPath).existsSync()) {
      throw IosSimulatorException(
        'Refusing symlinked iOS device registry at $_registryPath.',
      );
    }
    final directory = Directory(p.dirname(_registryPath));
    await directory.create(recursive: true);
    final temp = File('$_registryPath.tmp');
    await temp.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert([for (final record in records) record.toJson()])}\n',
      flush: true,
    );
    await _chmod600(temp.path);
    if (file.existsSync()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  Future<ProcessResult> _command(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) async {
    try {
      return await _run(
        executable,
        arguments,
        environment: environment,
      ).timeout(commandTimeout);
    } on TimeoutException {
      throw IosSimulatorException(
        '$executable ${arguments.join(' ')} timed out after '
        '${commandTimeout.inSeconds}s.',
      );
    }
  }

  Future<ProcessResult> _requireSuccess(
    String executable,
    List<String> arguments, {
    required String operation,
    Map<String, String>? environment,
  }) async {
    final result = await _command(
      executable,
      arguments,
      environment: environment,
    );
    if (result.exitCode != 0) {
      throw IosSimulatorException(
        'Could not $operation: ${_diagnostic(result)}',
      );
    }
    return result;
  }

  static Future<ProcessResult> _defaultRun(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) => Process.run(
    executable,
    arguments,
    environment: environment,
    includeParentEnvironment: true,
  );

  static Future<IosRunnerProcess> _defaultStart(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) async => _RealIosRunnerProcess(
    await Process.start(
      executable,
      arguments,
      environment: environment,
      includeParentEnvironment: true,
    ),
  );

  static Future<int> _defaultAllocatePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  static Future<void> _chmod600(String path) async {
    if (Platform.isWindows) {
      return;
    }
    final result = await Process.run('/bin/chmod', ['600', path]);
    if (result.exitCode != 0) {
      throw IosSimulatorException(
        'Could not protect iOS device registry $path: ${result.stderr}',
      );
    }
  }
}

/// Selects the newest available iOS 17+ runtime and a compatible iPhone type.
IosSimulatorSelection? selectIosSimulator(Map<String, dynamic> json) {
  final runtimes =
      <Map<String, dynamic>>[
          for (final value in json['runtimes'] as List? ?? const [])
            if (value is Map) value.cast<String, dynamic>(),
        ].where((runtime) {
          final identifier = runtime['identifier'];
          final version = runtime['version'];
          final available =
              runtime['isAvailable'] == true ||
              runtime['availability'] == '(available)';
          return identifier is String &&
              identifier.contains('iOS') &&
              version is String &&
              _compareVersions(version, '17.0') >= 0 &&
              available;
        }).toList()
        ..sort(
          (a, b) =>
              _compareVersions(b['version'] as String, a['version'] as String),
        );
  final types = <Map<String, dynamic>>[
    for (final value in json['devicetypes'] as List? ?? const [])
      if (value is Map) value.cast<String, dynamic>(),
  ];

  for (final runtime in runtimes) {
    final version = runtime['version'] as String;
    final compatible = types.where((type) {
      final name = type['name'];
      final identifier = type['identifier'];
      if (name is! String ||
          identifier is! String ||
          type['productFamily'] != 'iPhone' ||
          !name.startsWith('iPhone ')) {
        return false;
      }
      final min = type['minRuntimeVersion'];
      final max = type['maxRuntimeVersion'];
      return (min is! String || _compareVersions(version, min) >= 0) &&
          (max is! String || _compareVersions(version, max) <= 0);
    }).toList()..sort(_compareDeviceTypes);
    if (compatible.isNotEmpty) {
      final type = compatible.first;
      return IosSimulatorSelection(
        runtimeIdentifier: runtime['identifier'] as String,
        runtimeVersion: version,
        deviceTypeIdentifier: type['identifier'] as String,
        deviceTypeName: type['name'] as String,
      );
    }
  }
  return null;
}

int _compareDeviceTypes(Map<String, dynamic> a, Map<String, dynamic> b) {
  final aName = a['name'] as String;
  final bName = b['name'] as String;
  final pattern = RegExp(r'^iPhone (\d+) Pro$');
  final aGeneration = int.tryParse(pattern.firstMatch(aName)?.group(1) ?? '');
  final bGeneration = int.tryParse(pattern.firstMatch(bName)?.group(1) ?? '');
  if (aGeneration != null && bGeneration != null) {
    return bGeneration.compareTo(aGeneration);
  }
  if (aGeneration != null) {
    return -1;
  }
  if (bGeneration != null) {
    return 1;
  }
  return aName.compareTo(bName);
}

int _compareVersions(String a, String b) {
  final aParts = a.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  final bParts = b.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  final length = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var index = 0; index < length; index++) {
    final left = index < aParts.length ? aParts[index] : 0;
    final right = index < bParts.length ? bParts[index] : 0;
    final compared = left.compareTo(right);
    if (compared != 0) {
      return compared;
    }
  }
  return 0;
}

Map<String, dynamic> _decodeObject(
  String source, {
  required String sourceName,
}) {
  Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on Object catch (error) {
    throw IosSimulatorException('$sourceName returned invalid JSON: $error');
  }
  if (decoded is! Map) {
    throw IosSimulatorException('$sourceName returned a non-object payload.');
  }
  return decoded.cast<String, dynamic>();
}

Map<String, dynamic>? _deviceByUdid(
  List<Map<String, dynamic>> devices,
  String udid,
) {
  for (final device in devices) {
    if (device['udid'] == udid) {
      return device;
    }
  }
  return null;
}

String? _udidForExactName(List<Map<String, dynamic>> devices, String name) {
  for (final device in devices) {
    if (device['name'] == name && device['udid'] is String) {
      return device['udid'] as String;
    }
  }
  return null;
}

String _firstLine(Object? value) => '$value'.split('\n').first.trim();

String _diagnostic(ProcessResult result) {
  final stderr = '${result.stderr}'.trim();
  final stdout = '${result.stdout}'.trim();
  return stderr.isNotEmpty
      ? stderr
      : stdout.isNotEmpty
      ? stdout
      : 'exit ${result.exitCode}';
}

bool _alreadyBooted(ProcessResult result) =>
    _diagnostic(result).toLowerCase().contains('already booted');

bool _alreadyStoppedOrMissing(ProcessResult result) {
  final text = _diagnostic(result).toLowerCase();
  return text.contains('already shutdown') ||
      text.contains('already shut down') ||
      text.contains('unable to lookup') ||
      text.contains('not found') ||
      text.contains('invalid device');
}

class _ProcessTail {
  _ProcessTail(IosRunnerProcess process) {
    process.stdout.transform(utf8.decoder).listen(_appendStdout);
    process.stderr.transform(utf8.decoder).listen(_appendStderr);
  }

  static const int _limit = 8192;
  String _stdout = '';
  String _stderr = '';

  String get diagnostic => [
    if (_stdout.isNotEmpty) 'stdout:\n$_stdout',
    if (_stderr.isNotEmpty) 'stderr:\n$_stderr',
  ].join('\n');

  void _appendStdout(String value) => _stdout = _bounded('$_stdout$value');

  void _appendStderr(String value) => _stderr = _bounded('$_stderr$value');

  static String _bounded(String value) =>
      value.length <= _limit ? value : value.substring(value.length - _limit);
}

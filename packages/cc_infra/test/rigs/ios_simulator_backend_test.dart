import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/rigs/ios_automation_store.dart';
import 'package:cc_infra/src/rigs/ios_simulator_backend.dart';
import 'package:cc_infra/src/rigs/wda_client.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late IosAutomationStore store;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cc-ios-backend-');
    store = IosAutomationStore(dataDir: temp.path, architecture: 'arm64');
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  ProcessResult result({
    int exit = 0,
    Object stdout = '',
    Object stderr = '',
  }) => ProcessResult(1, exit, stdout, stderr);

  Map<String, dynamic> simulatorList({
    String runtime = '17.5',
    bool available = true,
    List<Map<String, dynamic>>? deviceTypes,
  }) => {
    'runtimes': [
      {
        'identifier':
            'com.apple.CoreSimulator.SimRuntime.iOS-${runtime.replaceAll('.', '-')}',
        'name': 'iOS $runtime',
        'version': runtime,
        'isAvailable': available,
      },
    ],
    'devicetypes':
        deviceTypes ??
        [
          {
            'identifier': 'com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro',
            'name': 'iPhone 15 Pro',
            'productFamily': 'iPhone',
          },
        ],
  };

  void installRunner() {
    final info = File(p.join(store.runnerAppPath, 'Info.plist'));
    info.parent.createSync(recursive: true);
    info.writeAsStringSync('<plist/>');
  }

  test('non-macOS keeps an unavailable iOS capability row visible', () async {
    final backend = IosSimulatorBackend(
      dataDir: temp.path,
      automationStore: store,
      isMacOS: false,
      runProcess: (_, _, {environment}) async => result(),
    );
    final capability = await backend.probe();
    expect(capability.backend, EnclosureBackend.iosSimulator);
    expect(capability.available, isFalse);
    expect(capability.surfaces, {RigSurface.ios});
    expect(capability.supportsTerminals, isFalse);
    expect(capability.toJson()['enforcedEgress'], isFalse);
    expect(capability.note, contains('macOS'));
  });

  test('missing Xcode names the exact xcode-select fix', () async {
    final backend = IosSimulatorBackend(
      dataDir: temp.path,
      automationStore: store,
      isMacOS: true,
      runProcess: (_, _, {environment}) =>
          throw const ProcessException('xcrun', [], 'missing'),
    );
    final capability = await backend.probe();
    expect(capability.available, isFalse);
    expect(capability.installHint, contains('xcode-select --switch'));
  });

  test(
    'incomplete first launch and missing runtime name distinct fixes',
    () async {
      Future<ProcessResult> firstLaunchIncomplete(
        String executable,
        List<String> args, {
        Map<String, String>? environment,
      }) async {
        if (args.contains('-checkFirstLaunchStatus')) {
          return result(exit: 1, stderr: 'license');
        }
        return result(
          stdout: executable.endsWith('xcodebuild')
              ? 'Xcode 16.4'
              : '/usr/bin/simctl',
        );
      }

      final incomplete = await IosSimulatorBackend(
        dataDir: temp.path,
        automationStore: store,
        isMacOS: true,
        runProcess: firstLaunchIncomplete,
      ).probe();
      expect(incomplete.installHint, 'sudo xcodebuild -runFirstLaunch');

      Future<ProcessResult> noRuntime(
        String executable,
        List<String> args, {
        Map<String, String>? environment,
      }) async {
        if (args.contains('list')) {
          return result(
            stdout: jsonEncode({'runtimes': [], 'devicetypes': []}),
          );
        }
        return result(
          stdout: executable.endsWith('xcodebuild')
              ? 'Xcode 16.4'
              : '/usr/bin/simctl',
        );
      }

      final runtimeMissing = await IosSimulatorBackend(
        dataDir: p.join(temp.path, 'other'),
        automationStore: IosAutomationStore(
          dataDir: p.join(temp.path, 'other'),
          architecture: 'arm64',
        ),
        isMacOS: true,
        runProcess: noRuntime,
      ).probe();
      expect(runtimeMissing.installHint, 'xcodebuild -downloadPlatform iOS');
    },
  );

  test(
    'missing bridge exposes owner-install action; installed bridge is ready',
    () async {
      Future<ProcessResult> run(
        String executable,
        List<String> args, {
        Map<String, String>? environment,
      }) async {
        if (args.contains('list')) {
          return result(stdout: jsonEncode(simulatorList()));
        }
        return result(
          stdout: executable.endsWith('xcodebuild')
              ? 'Xcode 16.4'
              : '/usr/bin/simctl',
        );
      }

      final backend = IosSimulatorBackend(
        dataDir: temp.path,
        automationStore: store,
        isMacOS: true,
        runProcess: run,
      );
      final missing = await backend.probe();
      expect(missing.setupAction, RigBackendSetupAction.iosAutomation);
      expect(missing.surfaces, {RigSurface.ios});
      expect(missing.note, contains(kIosAutomationVersion));

      installRunner();
      final ready = await backend.probe(refresh: true);
      expect(ready.available, isTrue);
      expect(ready.note, contains('iPhone 15 Pro'));
      expect(ready.note, contains('not enclosed'));
    },
  );

  test('selection prefers newest runtime and highest exact Pro generation', () {
    final selection = selectIosSimulator({
      'runtimes': [
        {
          'identifier': 'com.apple.CoreSimulator.SimRuntime.iOS-17-5',
          'version': '17.5',
          'name': 'iOS 17.5',
          'isAvailable': true,
        },
        {
          'identifier': 'com.apple.CoreSimulator.SimRuntime.iOS-18-2',
          'version': '18.2',
          'name': 'iOS 18.2',
          'isAvailable': true,
        },
      ],
      'devicetypes': [
        {
          'identifier': 'watch',
          'name': 'Apple Watch',
          'productFamily': 'Watch',
        },
        {
          'identifier': 'iphone-16',
          'name': 'iPhone 16 Pro',
          'productFamily': 'iPhone',
          'minRuntimeVersion': '18.0',
        },
        {
          'identifier': 'iphone-15',
          'name': 'iPhone 15 Pro',
          'productFamily': 'iPhone',
        },
      ],
    });
    expect(
      selection!.runtimeIdentifier,
      'com.apple.CoreSimulator.SimRuntime.iOS-18-2',
    );
    expect(selection.deviceTypeIdentifier, 'iphone-16');
  });

  test(
    'launch uses exact simctl argv, unique ports, registry, and idempotent teardown',
    () async {
      installRunner();
      final calls =
          <
            ({
              String executable,
              List<String> args,
              Map<String, String>? environment,
            })
          >[];
      var devices = <Map<String, dynamic>>[
        {'name': 'owned', 'udid': 'UDID-1', 'state': 'Booted'},
      ];
      Future<ProcessResult> run(
        String executable,
        List<String> args, {
        Map<String, String>? environment,
      }) async {
        calls.add((
          executable: executable,
          args: List.of(args),
          environment: environment,
        ));
        if (args.contains('create')) {
          return result(stdout: 'UDID-1\n');
        }
        if (args.contains('devices')) {
          return result(
            stdout: jsonEncode({
              'devices': {'ios-17': devices},
            }),
          );
        }
        if (args.contains('list')) {
          return result(stdout: jsonEncode(simulatorList()));
        }
        if (executable.endsWith('plutil')) {
          return result(
            stdout: 'com.facebook.WebDriverAgentRunner.xctrunner\n',
          );
        }
        if (args.contains('delete')) {
          devices = [];
        }
        return result(
          stdout: executable.endsWith('xcodebuild')
              ? 'Xcode 16.4'
              : '/usr/bin/simctl',
        );
      }

      final runner = _FakeRunner();
      final fakeWda = _FakeWda();
      final ports = [8100, 9100].iterator;
      final backend = IosSimulatorBackend(
        dataDir: temp.path,
        automationStore: store,
        isMacOS: true,
        runProcess: run,
        startProcess: (executable, args, {environment}) async {
          calls.add((
            executable: executable,
            args: List.of(args),
            environment: environment,
          ));
          return runner;
        },
        allocatePort: () async {
          ports.moveNext();
          return ports.current;
        },
        delay: (_) async {},
        clientFactory: (_, _) => fakeWda,
      );

      final stages = <String>[];
      final session = await backend.launch(rigId: 'r1', onProgress: stages.add);
      expect(session.udid, 'UDID-1');
      expect(session.httpPort, 8100);
      expect(session.mjpegPort, 9100);
      expect(stages, [
        'Finding iOS runtime',
        'Creating iOS Simulator',
        'Booting iOS Simulator',
        'Starting iOS automation',
      ]);
      final launch = calls.singleWhere((call) => call.args.contains('launch'));
      expect(launch.executable, '/usr/bin/xcrun');
      expect(launch.environment, {
        'SIMCTL_CHILD_USE_IP': '127.0.0.1',
        'SIMCTL_CHILD_USE_PORT': '8100',
        'SIMCTL_CHILD_MJPEG_SERVER_PORT': '9100',
      });
      final registry = File(p.join(temp.path, 'rigs', 'ios', 'devices.json'));
      expect(await registry.readAsString(), contains('UDID-1'));

      await backend.stopApp(session, 'com.example.app');
      await backend.uninstallApp(session, 'com.example.app');
      await backend.openUrl(session, 'my-app://debug?x=1&y=2');
      final spawned = await backend.spawn(session, [
        'log',
        'show',
        '--last',
        '1m',
      ]);
      expect(spawned, isNotEmpty);
      bool called(List<String> expected) => calls.any(
        (call) =>
            call.args.length == expected.length &&
            call.args.indexed.every((entry) => entry.$2 == expected[entry.$1]),
      );
      expect(
        called(['simctl', 'terminate', 'UDID-1', 'com.example.app']),
        isTrue,
      );
      expect(
        called(['simctl', 'uninstall', 'UDID-1', 'com.example.app']),
        isTrue,
      );
      expect(
        called(['simctl', 'openurl', 'UDID-1', 'my-app://debug?x=1&y=2']),
        isTrue,
      );
      expect(
        called(['simctl', 'spawn', 'UDID-1', 'log', 'show', '--last', '1m']),
        isTrue,
      );

      await backend.close(session);
      await backend.close(session);
      expect(fakeWda.deleted, 1);
      expect(calls.where((call) => call.args.contains('delete')), hasLength(1));
      expect(await registry.readAsString(), isNot(contains('UDID-1')));
    },
  );

  test(
    'corrupt and symlinked registries fail closed without deletion',
    () async {
      final registry = File(p.join(temp.path, 'rigs', 'ios', 'devices.json'));
      registry.parent.createSync(recursive: true);
      registry.writeAsStringSync('{broken');
      final backend = IosSimulatorBackend(
        dataDir: temp.path,
        automationStore: store,
        isMacOS: false,
        runProcess: (_, _, {environment}) async => result(),
      );
      await expectLater(
        backend.sweepOrphanedDevices(),
        throwsA(isA<IosSimulatorException>()),
      );
      expect(registry.readAsStringSync(), '{broken');

      registry.deleteSync();
      final target = File(p.join(temp.path, 'registry-target'))
        ..writeAsStringSync('[]');
      Link(registry.path).createSync(target.path);
      await expectLater(
        backend.sweepOrphanedDevices(),
        throwsA(isA<IosSimulatorException>()),
      );
      expect(target.readAsStringSync(), '[]');
    },
  );

  test('orphan sweep deletes only registry-owned exact devices', () async {
    final registry = File(p.join(temp.path, 'rigs', 'ios', 'devices.json'));
    registry.parent.createSync(recursive: true);
    registry.writeAsStringSync(
      jsonEncode([
        {'rigId': 'r1', 'name': 'owned-exact', 'udid': null},
      ]),
    );
    final deleted = <String>[];
    Future<ProcessResult> run(
      String executable,
      List<String> args, {
      Map<String, String>? environment,
    }) async {
      if (args.contains('devices')) {
        return result(
          stdout: jsonEncode({
            'devices': {
              'ios-17': [
                {'name': 'owned-exact', 'udid': 'OWNED', 'state': 'Shutdown'},
                {
                  'name': 'ccrig-lookalike',
                  'udid': 'FOREIGN',
                  'state': 'Shutdown',
                },
              ],
            },
          }),
        );
      }
      if (args.contains('delete')) {
        deleted.add(args.last);
      }
      return result();
    }

    final backend = IosSimulatorBackend(
      dataDir: temp.path,
      automationStore: store,
      isMacOS: true,
      runProcess: run,
    );
    await backend.sweepOrphanedDevices();
    expect(deleted, ['OWNED']);
    expect(await registry.readAsString(), isNot(contains('owned-exact')));
  });

  test(
    'orphan sweep keeps a device it cannot delete and does not throw',
    () async {
      final registry = File(p.join(temp.path, 'rigs', 'ios', 'devices.json'));
      registry.parent.createSync(recursive: true);
      registry.writeAsStringSync(
        jsonEncode([
          {'rigId': 'r1', 'name': 'stuck', 'udid': 'STUCK'},
        ]),
      );
      Future<ProcessResult> run(
        String executable,
        List<String> args, {
        Map<String, String>? environment,
      }) async {
        if (args.contains('devices')) {
          return result(
            stdout: jsonEncode({
              'devices': {
                'ios-17': [
                  {'name': 'stuck', 'udid': 'STUCK', 'state': 'Booted'},
                ],
              },
            }),
          );
        }
        if (args.contains('shutdown') || args.contains('delete')) {
          return result(
            exit: 1,
            stderr: 'Unable to delete device in current state: Booted',
          );
        }
        return result();
      }

      final backend = IosSimulatorBackend(
        dataDir: temp.path,
        automationStore: store,
        isMacOS: true,
        runProcess: run,
      );
      await backend.sweepOrphanedDevices();
      expect(await registry.readAsString(), contains('STUCK'));
    },
  );
}

class _FakeRunner implements IosRunnerProcess {
  final _stdout = StreamController<List<int>>();
  final _stderr = StreamController<List<int>>();
  final _exit = Completer<int>();

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => _stderr.stream;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    if (!_exit.isCompleted) {
      _exit.complete(0);
    }
    unawaited(_stdout.close());
    unawaited(_stderr.close());
    return true;
  }
}

class _FakeWda extends WdaClient {
  _FakeWda()
    : super(
        baseUri: Uri.parse('http://127.0.0.1:1/'),
        mjpegUri: Uri.parse('http://127.0.0.1:2/'),
      );

  int deleted = 0;

  @override
  Future<void> status() async {}

  @override
  Future<String> createSession() async => 'session';

  @override
  Future<WdaScreen> screen() async =>
      WdaScreen(size: RigDisplaySize(390, 844), scale: 3);

  @override
  Future<void> deleteSession() async {
    deleted++;
  }
}

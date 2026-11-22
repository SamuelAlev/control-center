import 'dart:io';

import 'package:cc_infra/cc_infra.dart' show BundledCodeRunner;
import 'package:cc_natives/cc_natives.dart' show GrammarManager;
import 'package:cc_server_core/src/native_preflight.dart';
import 'package:cc_server_core/src/runtime/server_native_preflight.dart';
import 'package:path/path.dart' as p;
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// The code mode runner is a required native: a bundle without it refuses to
/// boot (plan D12), like one without the media helpers. Whether it can
/// confine itself is a separate question its self-test answers after boot.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('cc_runner_preflight'));
  tearDown(() => tmp.deleteSync(recursive: true));

  NativeRequirement runnerRequirement(Map<String, String> environment) {
    final requirements = buildNativeRequirements(
      grammarsRoot: tmp.path,
      dataDir: tmp.path,
      inferenceLibPath: null,
      grammarManager: GrammarManager(
        httpClient: _NoHttp(),
        grammarsDir: () async => tmp,
      ),
      // Where the runner may be is read from the process environment only;
      // the test's map stands in for it.
      processEnvironment: environment,
    );
    return requirements.singleWhere(
      (r) => r.description.startsWith('codemode/'),
    );
  }

  test(
    'a bundle without the runner is refused, naming where it looked',
    () async {
      final requirement = runnerRequirement(const {});
      expect(requirement.requiredOnWindows, isTrue);
      expect(await missingRequiredNatives([requirement]), [
        requirement.description,
      ]);
      expect(
        requirement.description,
        contains(
          p.join(tmp.path, 'codemode', BundledCodeRunner.executableName),
        ),
      );
    },
  );

  test('a CC_CODEMODE_RUNNER that names nothing is refused too', () async {
    final requirement = runnerRequirement({
      BundledCodeRunner.environmentOverride: p.join(tmp.path, 'nope'),
    });
    expect(await missingRequiredNatives([requirement]), hasLength(1));
  });

  test('a runner staged in the data directory passes', () async {
    final runner = File(
      p.join(tmp.path, 'codemode', BundledCodeRunner.executableName),
    )..createSync(recursive: true);
    expect(runner.existsSync(), isTrue);
    expect(
      await missingRequiredNatives([runnerRequirement(const {})]),
      isEmpty,
    );
  });

  test('a runner named by CC_CODEMODE_RUNNER passes', () async {
    final runner = File(p.join(tmp.path, 'elsewhere', 'cc_codemode'))
      ..createSync(recursive: true);
    expect(
      await missingRequiredNatives([
        runnerRequirement({BundledCodeRunner.environmentOverride: runner.path}),
      ]),
      isEmpty,
    );
  });
}

class _NoHttp implements RhttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no network in this test');
}

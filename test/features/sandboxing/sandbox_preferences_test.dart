import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/storage/sandbox_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('docker → native migration on read', () async {
    SharedPreferences.setMockInitialValues({'sandbox_backend': 'docker'});
    final prefs = SandboxPreferences(await SharedPreferences.getInstance());
    expect(prefs.backend, SandboxBackend.native);
    // Re-read should still be native — the previous read rewrites the value
    // on disk.
    expect(prefs.backend, SandboxBackend.native);
  });

  test('native value passes through unchanged', () async {
    SharedPreferences.setMockInitialValues({'sandbox_backend': 'native'});
    final prefs = SandboxPreferences(await SharedPreferences.getInstance());
    expect(prefs.backend, SandboxBackend.native);
  });

  test('unknown value falls back to none', () async {
    SharedPreferences.setMockInitialValues({'sandbox_backend': 'foobar'});
    final prefs = SandboxPreferences(await SharedPreferences.getInstance());
    expect(prefs.backend, SandboxBackend.none);
  });

  test('isEnabled defaults to true on a fresh install', () async {
    final prefs = SandboxPreferences(await SharedPreferences.getInstance());
    expect(prefs.isEnabled, isTrue);
  });
}

import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/sandbox_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native value passes through unchanged', () async {
    final prefs = SandboxPreferences(
      AppPreferences.inMemory({'sandbox_backend': 'native'}),
    );
    expect(prefs.backend, SandboxBackend.native);
  });

  test('unknown value falls back to auto, never to none', () async {
    final prefs = SandboxPreferences(
      AppPreferences.inMemory({'sandbox_backend': 'foobar'}),
    );
    expect(prefs.backend, isNull);
  });

  test('isEnabled defaults to true on a fresh install', () async {
    final prefs = SandboxPreferences(AppPreferences.inMemory());
    expect(prefs.isEnabled, isTrue);
  });
}

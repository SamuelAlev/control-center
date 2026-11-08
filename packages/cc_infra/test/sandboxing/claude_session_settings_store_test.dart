import 'dart:io';

import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:cc_infra/src/sandboxing/claude_session_settings_store.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

void main() {
  late Directory temp;

  setUp(
    () => temp = Directory.systemTemp.createTempSync('cc_claude_settings_'),
  );
  tearDown(() => deleteDirBestEffort(temp));

  File stored() => File('${temp.path}/claude_session_settings.json');

  test('starts from the defaults', () {
    expect(
      ClaudeSessionSettingsStore(dataDir: temp.path).read(),
      ClaudeSessionSettings(),
    );
  });

  test('what is written survives a restart', () async {
    final settings = ClaudeSessionSettings(
      autoCompactWindow: 300000,
      compactIdleBeforeCacheExpires: true,
    );
    await ClaudeSessionSettingsStore(dataDir: temp.path).write(settings);

    expect(ClaudeSessionSettingsStore(dataDir: temp.path).read(), settings);
    expect(File('${stored().path}.tmp').existsSync(), isFalse);
  });

  test('a write is visible at once', () async {
    final store = ClaudeSessionSettingsStore(dataDir: temp.path);
    expect(store.read().compactIdleBeforeCacheExpires, isFalse);

    await store.write(
      ClaudeSessionSettings(compactIdleBeforeCacheExpires: true),
    );

    expect(store.read().compactIdleBeforeCacheExpires, isTrue);
  });

  test('a damaged file means the defaults, not a failed run', () {
    stored().writeAsStringSync('{not json');

    expect(
      ClaudeSessionSettingsStore(dataDir: temp.path).read(),
      ClaudeSessionSettings(),
    );
  });
}

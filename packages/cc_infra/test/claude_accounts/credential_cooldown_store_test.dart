import 'dart:io';

import 'package:cc_infra/src/claude_accounts/credential_cooldown_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late DateTime clock;

  CredentialCooldownStore build() =>
      CredentialCooldownStore(dataDir: dir.path, now: () => clock);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc-cooldowns-');
    clock = DateTime.utc(2026, 8, 24, 12);
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('an unmarked credential is not cooling off', () async {
    expect(await build().cooldownFor('openai', 'k1'), isNull);
  });

  test('marking parks a credential until the reported reset', () async {
    final store = build();
    final until = clock.add(const Duration(hours: 1));
    await store.mark('openai', 'k1', until: until);
    expect(await store.cooldownFor('openai', 'k1'), until);
  });

  test('with no reported reset it parks for the default', () async {
    final store = build();
    await store.mark('openai', 'k1');
    expect(
      await store.cooldownFor('openai', 'k1'),
      clock.add(CredentialCooldownStore.defaultCooldown),
    );
  });

  test('an expired cooldown stops counting', () async {
    final store = build();
    await store.mark('openai', 'k1', until: clock.add(const Duration(minutes: 5)));
    clock = clock.add(const Duration(minutes: 6));
    expect(await store.cooldownFor('openai', 'k1'), isNull);
  });

  test('cooldowns are scoped per provider', () async {
    // The same credentialId string in two providers is two different keys;
    // sharing a cooldown between them would sideline a working one.
    final store = build();
    await store.mark('openai', 'k1');
    expect(await store.cooldownFor('kimi-code', 'k1'), isNull);
    expect((await store.activeFor('openai')).keys, ['k1']);
    expect(await store.activeFor('kimi-code'), isEmpty);
  });

  test('clear releases it early', () async {
    final store = build();
    await store.mark('openai', 'k1');
    await store.clear('openai', 'k1');
    expect(await store.cooldownFor('openai', 'k1'), isNull);
  });

  test('it survives a reopen', () async {
    // A bounced server must not re-enter the spent key and pay another 429 to
    // learn what the previous process already knew.
    final until = clock.add(const Duration(hours: 2));
    await build().mark('openai', 'k1', until: until);
    expect(await build().cooldownFor('openai', 'k1'), until);
  });

  test('expired entries are pruned on write, so the file cannot grow', () async {
    final store = build();
    await store.mark('openai', 'old', until: clock.add(const Duration(minutes: 1)));
    clock = clock.add(const Duration(minutes: 5));
    await store.mark('openai', 'fresh');
    final raw = File('${dir.path}/credential-cooldowns.json').readAsStringSync();
    expect(raw, contains('fresh'));
    expect(raw, isNot(contains('old')));
  });

  test('a corrupt file costs a request, never a failed run', () async {
    File('${dir.path}/credential-cooldowns.json').writeAsStringSync('{ not json');
    expect(await build().cooldownFor('openai', 'k1'), isNull);
  });
}

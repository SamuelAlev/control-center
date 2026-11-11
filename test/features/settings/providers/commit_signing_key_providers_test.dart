import 'package:cc_domain/core/domain/repositories/commit_signing_key_repository.dart';
import 'package:cc_domain/core/domain/value_objects/commit_signing_key.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/providers/commit_signing_key_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _key = CommitSigningKey(
  publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA',
  fingerprint: 'SHA256:abc',
  createdAt: DateTime.utc(2026, 11, 10),
);

class _Keys implements CommitSigningKeyRepository {
  CommitSigningKey? key;
  Object? createError;
  int reads = 0;

  @override
  Future<CommitSigningKey?> get() async {
    reads++;
    return key;
  }

  @override
  Future<CommitSigningKey> create() async {
    if (createError case final error?) {
      throw error;
    }
    return key = _key;
  }

  @override
  Future<bool> delete() async {
    final had = key != null;
    key = null;
    return had;
  }
}

void main() {
  late _Keys keys;

  ProviderContainer containerFor({bool demo = false}) {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        isDemoServerProvider.overrideWith((ref) => demo),
        commitSigningKeyRepositoryProvider.overrideWithValue(keys),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => keys = _Keys());

  test('reads the caller key, null when there is none', () async {
    final container = containerFor();
    expect(await container.read(commitSigningKeyProvider.future), isNull);
    keys.key = _key;
    container.invalidate(commitSigningKeyProvider);
    expect(await container.read(commitSigningKeyProvider.future), _key);
  });

  test('a demo server is never asked', () async {
    final container = containerFor(demo: true);
    expect(await container.read(commitSigningKeyProvider.future), isNull);
    expect(keys.reads, 0);
  });

  test('create and delete update the state without another read', () async {
    final container = containerFor();
    await container.read(commitSigningKeyProvider.future);
    final notifier = container.read(commitSigningKeyProvider.notifier);

    expect(await notifier.create(), _key);
    expect(container.read(commitSigningKeyProvider).value, _key);

    await notifier.delete();
    expect(container.read(commitSigningKeyProvider).value, isNull);
    expect(keys.reads, 1);
  });

  test('a refused create rethrows and reads the key again', () async {
    final container = containerFor();
    await container.read(commitSigningKeyProvider.future);
    keys
      ..createError = StateError('exists')
      ..key = _key;

    await expectLater(
      container.read(commitSigningKeyProvider.notifier).create(),
      throwsStateError,
    );
    expect(await container.read(commitSigningKeyProvider.future), _key);
    expect(keys.reads, 2);
  });
}

import 'package:cc_domain/core/domain/value_objects/commit_signing_key.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in person's commit signing key: null until they create one.
///
/// A demo server has no `credentials.*` ops at all, so the provider answers
/// null there without asking; the page shows the demo notice instead.
final commitSigningKeyProvider =
    AsyncNotifierProvider<CommitSigningKeyNotifier, CommitSigningKey?>(
      CommitSigningKeyNotifier.new,
    );

/// Loads the caller's key and creates or deletes it on request.
///
/// [create] and [delete] rethrow what the server refused, so the caller can
/// say why; the state keeps the last known key meanwhile.
class CommitSigningKeyNotifier extends AsyncNotifier<CommitSigningKey?> {
  @override
  Future<CommitSigningKey?> build() async {
    if (ref.watch(isDemoServerProvider)) {
      return null;
    }
    return ref.watch(commitSigningKeyRepositoryProvider).get();
  }

  /// Creates the caller's key. When the server refuses (one already exists,
  /// a phone session), the key is read again so the page shows what is
  /// really there, and the refusal is rethrown.
  Future<CommitSigningKey> create() async {
    try {
      final key = await ref.read(commitSigningKeyRepositoryProvider).create();
      state = AsyncData(key);
      return key;
    } on Object {
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Deletes the caller's key. Commits are unsigned from then on.
  Future<void> delete() async {
    try {
      await ref.read(commitSigningKeyRepositoryProvider).delete();
      state = const AsyncData(null);
    } on Object {
      ref.invalidateSelf();
      rethrow;
    }
  }
}

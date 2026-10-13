import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A personal decision about a fully merged space, including after restore.
enum SpaceMergeArchiveChoice {
  /// Keep the space and never ask again.
  keep,

  /// Archive the space and remember the answer if restored.
  archive,
}

/// Explicit workspace scope prevents choices leaking between spaces/workspaces.
typedef SpaceMergeArchiveKey = ({String workspaceId, String spaceId});

/// Persisted on the server for the signed-in user, shared across their clients.
final spaceMergeArchiveChoiceProvider =
    NotifierProvider.family<
      SpaceMergeArchiveChoiceNotifier,
      AsyncValue<SpaceMergeArchiveChoice?>,
      SpaceMergeArchiveKey
    >(SpaceMergeArchiveChoiceNotifier.new);

/// Remembers successful writes immediately, without waiting for the prefs echo.
class SpaceMergeArchiveChoiceNotifier
    extends Notifier<AsyncValue<SpaceMergeArchiveChoice?>> {
  /// Binds the decision to one workspace and space.
  SpaceMergeArchiveChoiceNotifier(this.space);

  /// The space whose prompt was answered.
  final SpaceMergeArchiveKey space;
  SpaceMergeArchiveChoice? _saved;

  String get _key =>
      'space_merge_archive.${space.workspaceId}.${space.spaceId}';

  @override
  AsyncValue<SpaceMergeArchiveChoice?> build() {
    return ref
        .watch(ownServerPrefsProvider)
        .whenData(
          (prefs) =>
              _saved ??
              switch (prefs[_key]) {
                'keep' => SpaceMergeArchiveChoice.keep,
                'archive' => SpaceMergeArchiveChoice.archive,
                _ => null,
              },
        );
  }

  /// Only a successful durable write suppresses future prompts.
  Future<void> choose(SpaceMergeArchiveChoice choice) async {
    await ref.read(identityRepositoryProvider).prefsSet(_key, choice.name);
    if (!ref.mounted) {
      return;
    }
    _saved = choice;
    state = AsyncData(choice);
  }
}

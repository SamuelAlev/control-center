import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/synced_preferences.dart';
import 'package:control_center/features/pr_review/providers/comment_composer_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container(AppPreferences prefs) {
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

const _all = [
  CommentComposerMode.agent,
  CommentComposerMode.comment,
  CommentComposerMode.review,
];

void main() {
  group('commentComposerModes', () {
    test('lists agent, comment, review in that order', () {
      expect(commentComposerModes(agent: true, review: true), _all);
    });

    test('always offers a single comment', () {
      expect(commentComposerModes(agent: false, review: false), [
        CommentComposerMode.comment,
      ]);
    });
  });

  group('resolveCommentComposerMode', () {
    test('uses the remembered mode when it is offered', () {
      expect(
        resolveCommentComposerMode(CommentComposerMode.agent, _all),
        CommentComposerMode.agent,
      );
      expect(
        resolveCommentComposerMode(CommentComposerMode.comment, _all),
        CommentComposerMode.comment,
      );
    });

    test('defaults to review before anything was picked', () {
      expect(
        resolveCommentComposerMode(null, _all),
        CommentComposerMode.review,
      );
    });

    test('falls back to a single comment when review is not offered', () {
      expect(
        resolveCommentComposerMode(CommentComposerMode.review, const [
          CommentComposerMode.agent,
          CommentComposerMode.comment,
        ]),
        CommentComposerMode.comment,
      );
    });
  });

  group('commentComposerModeProvider', () {
    test('is null before the user picks a mode', () {
      final container = _container(AppPreferences.inMemory());
      expect(container.read(commentComposerModeProvider), isNull);
    });

    test('persists the pick and reads it back in a new session', () {
      final prefs = AppPreferences.inMemory();
      _container(prefs)
          .read(commentComposerModeProvider.notifier)
          .setMode(CommentComposerMode.agent);

      expect(prefs.getString(prCommentComposerModeKey), 'agent');
      expect(
        _container(prefs).read(commentComposerModeProvider),
        CommentComposerMode.agent,
      );
    });

    test('ignores an unknown persisted value', () async {
      final prefs = AppPreferences.inMemory();
      await prefs.setString(prCommentComposerModeKey, 'carrier-pigeon');
      expect(_container(prefs).read(commentComposerModeProvider), isNull);
    });

    test('follows the user across devices', () {
      final syncedKeys = buildSyncedPreferences().map((p) => p.key).toSet();
      expect(syncedKeys, contains(prCommentComposerModeKey));
    });
  });
}

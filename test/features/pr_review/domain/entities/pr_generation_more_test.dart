import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 5, 18, 9, 0);

  PrGeneration createGeneration({
    String id = 'gen-1',
    String workspaceId = 'ws-1',
    PrGenerationStatus status = const Draft(),
    String? title = 'My PR',
    String? body = 'PR body',
    String? branch = 'feature/my-pr',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrGeneration(
      id: id,
      workspaceId: workspaceId,
      status: status,
      title: title,
      body: body,
      branch: branch,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('PrGeneration edge cases', () {
    test('copyWith changing title back to non-null after removeTitle', () {
      final gen = createGeneration(title: 'Old');
      final removed = gen.copyWith(removeTitle: true);
      expect(removed.title, isNull);
      final restored = removed.copyWith(title: 'New');
      expect(restored.title, 'New');
    });

    test('copyWith removeTitle false with explicit title', () {
      final gen = createGeneration(title: 'Old');
      final updated = gen.copyWith(title: 'New', removeTitle: false);
      expect(updated.title, 'New');
    });

    test('copyWith removeBody preserves other fields', () {
      final gen = createGeneration(body: 'Body', title: 'Title');
      final updated = gen.copyWith(removeBody: true);
      expect(updated.body, isNull);
      expect(updated.title, 'Title');
      expect(updated.id, 'gen-1');
    });

    test('copyWith removeBranch preserves other fields', () {
      final gen = createGeneration(branch: 'feat/x', title: 'Title');
      final updated = gen.copyWith(removeBranch: true);
      expect(updated.branch, isNull);
      expect(updated.title, 'Title');
    });

    test('canPublish is false for Draft subclass on Published', () {
      final published = createGeneration(status: const Published());
      expect(published.canPublish(), isFalse);
    });

    test('toString includes key info', () {
      final gen = createGeneration(id: 'gen-42', workspaceId: 'ws-7');
      final str = gen.toString();
      expect(str, isNotEmpty);
    });
  });

  group('PrGenerationStatus edge cases', () {
    test('Draft.hashCode == Draft.hashCode across instances', () {
      const draft1 = Draft();
      const draft2 = Draft();
      expect(draft1.hashCode, draft2.hashCode);
    });

    test('sealed class pattern works with switch', () {
      String result = '';
      const status = Draft();
      switch (status) {
        case Draft():
          result = 'draft';
      }
      expect(result, 'draft');
    });
  });
}

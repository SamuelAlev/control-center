import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/review_drafts.dart';
import 'package:drift/drift.dart';

part 'review_dao.g.dart';

/// Data access object for [ReviewDrafts].
///
/// Session and comment tables were removed in schema v18. This DAO now only
/// handles review draft persistence (keyed by `{owner}/{repo}/{prNumber}`).
@DriftAccessor(tables: [ReviewDrafts])
class ReviewDao extends DatabaseAccessor<AppDatabase> with _$ReviewDaoMixin {
  /// Creates a [ReviewDao] for the given database.
  ReviewDao(super.attachedDatabase);

  /// Saves a draft comment, upserting by the composite key.
  Future<void> upsertDraft(
    String owner,
    String repo,
    int prNumber,
    String commentText,
  ) async {
    final id = '$owner/$repo/$prNumber';
    final data = ReviewDraftsCompanion(
      id: Value(id),
      owner: Value(owner),
      repo: Value(repo),
      prNumber: Value(prNumber),
      commentText: Value(commentText),
      updatedAt: Value(DateTime.now()),
    );
    await into(reviewDrafts).insertOnConflictUpdate(data);
  }

  /// Loads a draft comment for a given PR, or null.
  Future<String?> getDraft(String owner, String repo, int prNumber) async {
    final id = '$owner/$repo/$prNumber';
    final row = await (select(
      reviewDrafts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.commentText;
  }

  /// Clears a draft after it's been used.
  Future<void> clearDraft(String owner, String repo, int prNumber) async {
    final id = '$owner/$repo/$prNumber';
    await (delete(reviewDrafts)..where((t) => t.id.equals(id))).go();
  }
}

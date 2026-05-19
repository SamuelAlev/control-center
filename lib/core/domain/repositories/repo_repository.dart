import 'package:control_center/core/domain/entities/repo.dart';

/// Repository interface for repo data access.
abstract class RepoRepository {
  /// Watches all registered repos ordered by most recently updated.
  Stream<List<Repo>> watchAll();

  /// Returns a single repo by [id], or `null`.
  Future<Repo?> getById(String id);

  /// Inserts or updates a repo row. Returns the repo id.
  Future<String> upsert(Repo repo);

  /// Deletes a repo by [id]. Linked workspace_repos rows cascade.
  Future<void> delete(String id);
}

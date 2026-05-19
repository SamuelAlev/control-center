import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_persistence/database/app_database.dart';

/// Maps database rows to [Repo] domain entities.
class RepoMapper {
  /// Creates a const [RepoMapper].
  const RepoMapper();

  /// To domain.
  Repo toDomain(ReposTableData row) {
    return Repo(
      id: row.id,
      name: row.name,
      path: row.path,

      githubOwner: row.githubOwner,
      githubRepoName: row.githubRepoName,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// To domain list.
  List<Repo> toDomainList(List<ReposTableData> rows) =>
      rows.map(toDomain).toList(growable: false);
}


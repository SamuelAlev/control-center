import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watches all registered repos.
final reposProvider = StreamProvider<List<Repo>>((ref) {
  final repository = ref.watch(repoRepositoryProvider);
  return repository.watchAll();
});

/// Watches the repos linked to a specific workspace.
final reposForWorkspaceProvider = StreamProvider.family<List<Repo>, String>((
  ref,
  workspaceId,
) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return repository.watchReposForWorkspace(workspaceId);
});

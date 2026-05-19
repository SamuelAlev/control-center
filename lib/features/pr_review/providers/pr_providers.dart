import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream of PR generations for a given workspace.
final pullRequestsProvider = StreamProvider.family<List<PrGeneration>, String>((
  ref,
  workspaceId,
) {
  final repo = ref.watch(prLifecycleRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

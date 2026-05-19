import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_diff_scope_notifier.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The file set the diff surface shows for the current commit scope, plus the
/// load state of the per-commit fetches backing it.
typedef ScopedDiffFiles = ({List<PrFile> files, bool isLoading, Object? error});

/// Resolves the files in scope: the full PR file list when no commits are
/// selected, otherwise the union of the selected commits' files. Watches the
/// per-commit file providers, so callers must invoke this from `build`.
ScopedDiffFiles watchScopedDiffFiles(
  WidgetRef ref, {
  required PrDiffScopeState scope,
  required List<PrCommit> commits,
  required List<PrFile> allFiles,
  required bool isLoading,
  Object? error,
}) {
  if (!scope.isScoped) {
    return (files: allFiles, isLoading: isLoading, error: error);
  }

  final byPath = <String, PrFile>{};
  var scopeLoading = false;
  Object? scopeError;
  for (final commit in commits) {
    if (!scope.selectedShas.contains(commit.sha)) {
      continue;
    }

    final async = ref.watch(prCommitFilesProvider(commit.sha));
    if (async.isLoading) {
      scopeLoading = true;
    }

    if (async.hasError && scopeError == null) {
      scopeError = async.error;
    }

    for (final f in async.value ?? const <PrFile>[]) {
      byPath[f.filename] = f;
    }
  }
  return (
    files: byPath.values.toList(),
    isLoading: scopeLoading,
    error: scopeError,
  );
}

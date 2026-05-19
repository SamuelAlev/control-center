import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pr diff scope state.
class PrDiffScopeState {
  /// PrDiffScopeState({.
  const PrDiffScopeState({
    this.selectedShas = const {},
    this.scopedFiles = const [],
    this.isLoading = false,
    this.error,
  });

  /// SHAs of commits selected for scoped diff view.
  final Set<String> selectedShas;

  /// Files touched by the selected commit range.
  final List<PrFile> scopedFiles;

  /// Whether scoped files are being computed.
  final bool isLoading;

  /// Object?.
  final Object? error;

  /// Whether any commits are selected for scoping.
  bool get isScoped => selectedShas.isNotEmpty;

  /// Copy with.
  PrDiffScopeState copyWith({
    Set<String>? selectedShas,
    List<PrFile>? scopedFiles,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return PrDiffScopeState(
      selectedShas: selectedShas ?? this.selectedShas,
      scopedFiles: scopedFiles ?? this.scopedFiles,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Pr diff scope notifier.
class PrDiffScopeNotifier extends Notifier<PrDiffScopeState> {
  @override
  PrDiffScopeState build() => const PrDiffScopeState();

  /// Replace the set of selected commit SHAs.
  void updateSelection(Set<String> shas) {
    state = state.copyWith(selectedShas: shas);
  }

  /// Derive scoped files from commit file maps.
  void computeScopedFilesFromCommits(
    List<PrCommit> commits,
    Map<String, List<PrFile>?> commitFilesMap,
  ) {
    if (state.selectedShas.isEmpty) {
      state = const PrDiffScopeState();
      return;
    }

    final byPath = <String, PrFile>{};
    var anyLoading = false;
    Object? scopedError;

    for (final commit in commits) {
      if (!state.selectedShas.contains(commit.sha)) {
        continue;
      }

      final files = commitFilesMap[commit.sha];
      if (files == null) {
        anyLoading = true;
        continue;
      }
      for (final f in files) {
        byPath[f.filename] = f;
      }
    }

    state = state.copyWith(
      scopedFiles: byPath.values.toList(),
      isLoading: anyLoading,
      error: scopedError,
    );
  }
}

/// Notifier provider for the diff commit-scope state.
final prDiffScopeProvider =
    NotifierProvider<PrDiffScopeNotifier, PrDiffScopeState>(
      PrDiffScopeNotifier.new,
    );

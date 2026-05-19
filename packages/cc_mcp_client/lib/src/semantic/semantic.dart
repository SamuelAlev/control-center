/// Worktree-aware semantic code search (PRD 01 phase 1.6).
///
/// The novel piece is `WorktreeOverlay`: a shared committed-baseline index is
/// reused across worktrees, with per-worktree divergence tracked as `shadows`
/// (re-embed) vs `blocked` (in-flight) and validated at search time. The
/// chunker and search orchestrator are pure-Dart so they unit-test without an
/// embedder or vector store.
library;

export 'code_chunker.dart';
export 'semantic_search.dart';
export 'worktree_overlay.dart';

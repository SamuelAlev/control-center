/// Determinism primitives shared by every client and the server (PRD 19):
/// the idempotency-key minter and the preview/dry-run contract.
library;

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Mints a fresh idempotency key for **one logical action** (PRD 19 §3).
///
/// The contract: mint this once when the user commits an intent, then reuse
/// the same value across every retry of that intent (double-click, reconnect
/// replay, offline-queue flush) so they all collapse to a single application.
/// Minting per attempt dedupes nothing; minting per widget dedupes too much.
///
/// UUIDv7 is time-ordered so the write ledger and any debugging tooling see
/// keys in roughly creation order.
String newIdempotencyKey() => _uuid.v7();

/// Derives the per-item idempotency key for one element of a bulk action
/// (PRD 19 clarification: "bulk actions key per item").
///
/// A bulk operation mints one [bulkKey] and derives `bulkKey/itemId` per item,
/// so a partial failure retries only the failed items and each item's dedupe
/// stays independent.
String bulkItemIdempotencyKey(String bulkKey, String itemId) =>
    '$bulkKey/$itemId';

/// What a destructive or expensive action will do, shown before it runs
/// (PRD 19 §4). Deterministic: the same action against the same state yields
/// the same preview. Built server-side (it can read the code graph / plan
/// estimator) and rendered by the client's confirm sheet.
class ActionPreview {
  /// Creates an [ActionPreview].
  const ActionPreview({
    required this.summary,
    this.filesTouched = const [],
    this.estimatedCostUsd,
    this.blastRadiusSymbols = const [],
    this.warnings = const [],
    this.reversible = false,
  });

  /// Deserializes from the wire.
  factory ActionPreview.fromJson(Map<String, dynamic> json) => ActionPreview(
    summary: json['summary'] as String? ?? '',
    filesTouched:
        (json['files_touched'] as List?)?.whereType<String>().toList() ??
        const [],
    estimatedCostUsd: (json['estimated_cost_usd'] as num?)?.toDouble(),
    blastRadiusSymbols:
        (json['blast_radius_symbols'] as List?)?.whereType<String>().toList() ??
        const [],
    warnings:
        (json['warnings'] as List?)?.whereType<String>().toList() ?? const [],
    reversible: json['reversible'] as bool? ?? false,
  );

  /// One-line human summary of the effect ("Merge 5 pull requests").
  final String summary;

  /// Repository paths the action will create/modify/delete.
  final List<String> filesTouched;

  /// Estimated cost in USD when the action spends model budget (null = free).
  final double? estimatedCostUsd;

  /// Code-graph symbols in the blast radius (transitive dependents that could
  /// be affected). Empty when not code-bearing.
  final List<String> blastRadiusSymbols;

  /// Non-blocking cautions surfaced to the operator ("2 files have unsaved
  /// edits").
  final List<String> warnings;

  /// Whether the action can be undone afterwards (drives the confirm-sheet
  /// copy: reversible actions read "you can undo this").
  final bool reversible;

  /// Serializes to the wire.
  Map<String, dynamic> toJson() => {
    'summary': summary,
    'files_touched': filesTouched,
    if (estimatedCostUsd != null) 'estimated_cost_usd': estimatedCostUsd,
    'blast_radius_symbols': blastRadiusSymbols,
    'warnings': warnings,
    'reversible': reversible,
  };
}

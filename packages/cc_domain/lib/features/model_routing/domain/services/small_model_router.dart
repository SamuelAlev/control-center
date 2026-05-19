// ignore_for_file: avoid_classes_with_only_static_members

import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';

/// Routes utility work (titles, summaries, triage, compaction) to the cheapest
/// recent text-capable model.
///
/// Scoring (lower = better): normalize each candidate's blended cost and age
/// against the max in the set, then `score = cost*0.8 + age*0.2`. Models whose
/// id/family/name contain a "small" marker (`nano`, `flash`, `lite`, `mini`,
/// `haiku`, `small`, `fast`) are preferred — if any exist, the pick is made
/// from that subset only.
abstract final class SmallModelRouter {
  static final RegExp _smallName = RegExp(
    r'\b(nano|flash|lite|mini|haiku|small|fast)\b',
  );

  /// Roughly 30 days, in milliseconds — the "one month" age unit.
  static const int _monthMs = 1000 * 60 * 60 * 24 * 30;

  /// Maximum age (in months) for a model to count as "recent".
  static const double _maxAgeMonths = 18;

  /// Picks the best small model from [candidates], or null if none qualify.
  static ModelInfo? pick(List<ModelInfo> candidates, {DateTime? now}) {
    final clock = now ?? DateTime.now();

    List<_Scored> eligible = _eligible(candidates, clock, requireRecent: true);
    if (eligible.isEmpty) {
      // Relax recency if nothing recent qualifies (still text + cost-known).
      eligible = _eligible(candidates, clock, requireRecent: false);
    }
    if (eligible.isEmpty) {
      return null;
    }

    final named = eligible.where((s) => s.isSmallName).toList();
    final pool = named.isNotEmpty ? named : eligible;
    return _lowestScore(pool);
  }

  static List<_Scored> _eligible(
    List<ModelInfo> candidates,
    DateTime clock, {
    required bool requireRecent,
  }) {
    final out = <_Scored>[];
    for (final m in candidates) {
      if (!m.enabled || m.status != ModelStatus.active) {
        continue;
      }
      if (!m.isTextCapable) {
        continue;
      }
      final cost = m.cost;
      if (cost == null || !cost.isKnown) {
        continue;
      }
      final released = m.releasedAt;
      final double ageMonths;
      if (released != null) {
        ageMonths =
            (clock.millisecondsSinceEpoch - released.millisecondsSinceEpoch) /
            _monthMs;
        if (ageMonths < 0) {
          continue; // future-dated, treat as unknown
        }
        if (requireRecent && ageMonths > _maxAgeMonths) {
          continue;
        }
      } else {
        if (requireRecent) {
          continue; // can't prove recency
        }
        ageMonths = _maxAgeMonths; // neutral age when relaxed
      }
      final blended = cost.blended;
      if (blended <= 0) {
        continue;
      }
      final haystack = '${m.id} ${m.family ?? ''} ${m.name}'.toLowerCase();
      out.add(
        _Scored(
          model: m,
          cost: blended,
          ageMonths: ageMonths,
          isSmallName: _smallName.hasMatch(haystack),
        ),
      );
    }
    return out;
  }

  static ModelInfo _lowestScore(List<_Scored> items) {
    final maxCost = items
        .map((i) => i.cost)
        .fold<double>(0.01, (a, b) => a > b ? a : b);
    final maxAge = items
        .map((i) => i.ageMonths)
        .fold<double>(0.01, (a, b) => a > b ? a : b);
    _Scored? best;
    var bestScore = double.infinity;
    for (final i in items) {
      final score = (i.cost / maxCost) * 0.8 + (i.ageMonths / maxAge) * 0.2;
      if (score < bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best!.model;
  }
}

class _Scored {
  _Scored({
    required this.model,
    required this.cost,
    required this.ageMonths,
    required this.isSmallName,
  });

  final ModelInfo model;
  final double cost;
  final double ageMonths;
  final bool isSmallName;
}

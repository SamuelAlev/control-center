import 'package:control_center/core/domain/entities/agent.dart';

/// Picks the best [Agent] for a desired specialist `role` label.
///
/// Extracted from the original `delegate_review_tool` so it can be shared by
/// the new `dispatch_reviewers_tool` (parallel fan-out) and any future tool
/// that needs the same matching heuristic.
class ReviewerMatchingService {
  /// Creates a [ReviewerMatchingService].
  const ReviewerMatchingService();

  /// Returns the best-matching agent for [role] in [candidates], or `null`
  /// if no candidate scores above zero.
  Agent? findBestMatch(List<Agent> candidates, String role) {
    final needle = role.toLowerCase();
    Agent? best;
    var bestScore = 0;
    for (final agent in candidates) {
      final score = _scoreMatch(agent, needle);
      if (score > bestScore) {
        bestScore = score;
        best = agent;
      }
    }
    return bestScore == 0 ? null : best;
  }

  int _scoreMatch(Agent agent, String needle) {
    var score = 0;
    final title = agent.title.toLowerCase();
    if (title.contains(needle)) {
      score += 2;
    }
    for (final skill in agent.skills.toList()) {
      if (skill.toLowerCase().contains(needle)) {
        score += 3;
      }
    }
    if (agent.name.toLowerCase().contains(needle)) {
      score += 1;
    }
    return score;
  }
}

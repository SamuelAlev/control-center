import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_evaluation_summary.dart';

/// An improvement proposal as a client sees it: the proposal and whether
/// deciding on it takes a workspace admin (the server's `needs_admin`: a
/// skill change, or a workspace-wide policy). A client never derives it.
/// A skill change whose campaign reported also carries the report's numbers
/// ([evaluation]).
class ImprovementProposalView {
  /// Creates a view of [proposal].
  const ImprovementProposalView({
    required this.proposal,
    required this.needsAdmin,
    required this.evaluation,
  });

  /// The proposal.
  final ImprovementProposal proposal;

  /// Whether accepting, rejecting or rolling it back takes an admin.
  final bool needsAdmin;

  /// The campaign report's numbers; null until a skill change's campaign
  /// has a report, and always null for any other kind.
  final ImprovementEvaluationSummary? evaluation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementProposalView &&
          proposal == other.proposal &&
          needsAdmin == other.needsAdmin &&
          evaluation == other.evaluation;

  @override
  int get hashCode => Object.hash(proposal, needsAdmin, evaluation);
}

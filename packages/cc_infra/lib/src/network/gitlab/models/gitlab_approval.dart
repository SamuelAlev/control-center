import 'package:cc_infra/src/network/gitlab/models/gitlab_project.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// The approval summary of one merge request
/// (`GET .../merge_requests/:iid/approvals`).
///
/// GitLab has no "review" object: an approval is the only first-class verdict,
/// and it carries no body and no timestamp. That is why the mapper synthesizes
/// review submissions from this plus the reviewer states.
class GitLabApprovals {
  /// Creates a [GitLabApprovals].
  const GitLabApprovals({
    this.id = 0,
    this.iid = 0,
    this.approvalsRequired = 0,
    this.approvalsLeft = 0,
    this.approved = false,
    this.userHasApproved = false,
    this.userCanApprove = false,
    this.approvedBy = const <GitLabUser>[],
  });

  /// Reads a [GitLabApprovals] off a decoded JSON object.
  factory GitLabApprovals.fromJson(Map<String, dynamic> json) {
    // `approved_by` is an array of `{user: {...}}` wrappers, not of users.
    final raw = json['approved_by'];
    final approvers = <GitLabUser>[];
    if (raw is List) {
      for (final entry in raw.whereType<Map<String, dynamic>>()) {
        final user = GitLabUser.maybeFromJson(entry['user']);
        if (user != null) {
          approvers.add(user);
        }
      }
    }
    return GitLabApprovals(
      id: (json['id'] as num?)?.toInt() ?? 0,
      iid: (json['iid'] as num?)?.toInt() ?? 0,
      approvalsRequired: (json['approvals_required'] as num?)?.toInt() ?? 0,
      approvalsLeft: (json['approvals_left'] as num?)?.toInt() ?? 0,
      approved: json['approved'] as bool? ?? false,
      userHasApproved: json['user_has_approved'] as bool? ?? false,
      userCanApprove: json['user_can_approve'] as bool? ?? false,
      approvedBy: List<GitLabUser>.unmodifiable(approvers),
    );
  }

  /// An empty summary, for instances or MRs with no approval data.
  static const GitLabApprovals empty = GitLabApprovals();

  /// Instance-wide merge-request id.
  final int id;

  /// Per-project merge-request number.
  final int iid;

  /// How many approvals the rules demand.
  final int approvalsRequired;

  /// How many approvals are still outstanding.
  final int approvalsLeft;

  /// Whether the approval requirement is satisfied. Only meaningful when
  /// [approvalsRequired] is non-zero.
  final bool approved;

  /// Whether the requesting token's user has approved.
  final bool userHasApproved;

  /// Whether the requesting token's user is eligible to approve.
  final bool userCanApprove;

  /// Everyone who has approved.
  final List<GitLabUser> approvedBy;
}

/// One approval rule of a merge request
/// (`GET .../merge_requests/:iid/approval_state`).
///
/// Premium and up; the mapper treats an absent rule set as "no rules" rather
/// than as an error, because that is exactly what a Free instance means.
class GitLabApprovalRule {
  /// Creates a [GitLabApprovalRule].
  const GitLabApprovalRule({
    required this.id,
    required this.name,
    this.ruleType = '',
    this.approvalsRequired = 0,
    this.approved = false,
    this.section = '',
    this.eligibleApprovers = const <GitLabUser>[],
    this.approvedBy = const <GitLabUser>[],
    this.users = const <GitLabUser>[],
    this.groups = const <GitLabGroupRef>[],
  });

  /// Reads a [GitLabApprovalRule] off a decoded JSON object.
  factory GitLabApprovalRule.fromJson(Map<String, dynamic> json) =>
      GitLabApprovalRule(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        ruleType: json['rule_type'] as String? ?? '',
        approvalsRequired: (json['approvals_required'] as num?)?.toInt() ?? 0,
        approved: json['approved'] as bool? ?? false,
        section: json['section'] as String? ?? '',
        eligibleApprovers: GitLabUser.listFromJson(json['eligible_approvers']),
        approvedBy: GitLabUser.listFromJson(json['approved_by']),
        users: GitLabUser.listFromJson(json['users']),
        groups: GitLabGroupRef.listFromJson(json['groups']),
      );

  /// Rule id.
  final int id;

  /// Rule name (`Default`, or the CODEOWNERS section name).
  final String name;

  /// `regular`, `any_approver`, `code_owner`, or `report_approver`.
  /// `code_owner` is GitLab's CODEOWNERS equivalent.
  final String ruleType;

  /// How many approvals this rule demands.
  final int approvalsRequired;

  /// Whether this rule is satisfied.
  final bool approved;

  /// The CODEOWNERS section this rule came from, when [ruleType] is
  /// `code_owner`.
  final String section;

  /// Everyone allowed to satisfy the rule (users plus expanded group members).
  final List<GitLabUser> eligibleApprovers;

  /// Who has already approved under this rule.
  final List<GitLabUser> approvedBy;

  /// Users named directly by the rule.
  final List<GitLabUser> users;

  /// Groups named by the rule — the closest GitLab has to a reviewer team.
  final List<GitLabGroupRef> groups;

  /// Whether this rule comes from CODEOWNERS.
  bool get isCodeOwner => ruleType == 'code_owner';
}

/// The full approval picture of one merge request.
class GitLabApprovalState {
  /// Creates a [GitLabApprovalState].
  const GitLabApprovalState({
    this.approvalRulesOverwritten = false,
    this.rules = const <GitLabApprovalRule>[],
  });

  /// Reads a [GitLabApprovalState] off a decoded JSON object.
  factory GitLabApprovalState.fromJson(Map<String, dynamic> json) {
    final raw = json['rules'];
    return GitLabApprovalState(
      approvalRulesOverwritten:
          json['approval_rules_overwritten'] as bool? ?? false,
      rules: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(GitLabApprovalRule.fromJson)
                .toList(growable: false)
          : const <GitLabApprovalRule>[],
    );
  }

  /// An empty state, for instances that do not serve approval rules.
  static const GitLabApprovalState empty = GitLabApprovalState();

  /// Whether the MR overrides the project's rules.
  final bool approvalRulesOverwritten;

  /// The rules in force.
  final List<GitLabApprovalRule> rules;
}

/// One entry of `GET .../merge_requests/:iid/reviewers` — an assigned reviewer
/// together with the verdict they have (or have not) left.
///
/// This is the only place GitLab exposes a per-reviewer state, and therefore
/// the only source for "changes requested".
class GitLabMergeRequestReviewer {
  /// Creates a [GitLabMergeRequestReviewer].
  const GitLabMergeRequestReviewer({
    required this.user,
    required this.state,
    this.createdAt,
    this.updatedAt,
  });

  /// Reads a [GitLabMergeRequestReviewer] off a decoded JSON object.
  factory GitLabMergeRequestReviewer.fromJson(Map<String, dynamic> json) =>
      GitLabMergeRequestReviewer(
        user: GitLabUser.maybeFromJson(json['user']),
        state: json['state'] as String? ?? '',
        createdAt: parseDate(json['created_at']),
        updatedAt: parseDate(json['updated_at']),
      );

  /// The reviewer.
  final GitLabUser? user;

  /// `unreviewed`, `reviewed`, `requested_changes`, `approved` or
  /// `unapproved`.
  final String state;

  /// When the reviewer was assigned.
  final DateTime? createdAt;

  /// When the reviewer last changed state — the closest thing GitLab has to a
  /// review submission timestamp.
  final DateTime? updatedAt;
}

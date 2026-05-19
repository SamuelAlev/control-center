import 'package:control_center/core/network/models/github_check_run.dart';
import 'package:control_center/core/network/models/github_issue_comment.dart';
import 'package:control_center/core/network/models/github_pull_request.dart';
import 'package:control_center/core/network/models/github_review.dart';
import 'package:control_center/core/network/models/github_review_comment.dart';

/// Renders a `pr://owner/repo/N` view as markdown for the agent.
class PrMarkdownRenderer {
  /// Creates a const [PrMarkdownRenderer].
  const PrMarkdownRenderer();

  /// Renders the PR header + check-runs + reviews + comments to markdown.
  String render({
    required GitHubPullRequest pr,
    required List<GitHubCheckRun> checkRuns,
    required List<GitHubReview> reviews,
    required List<GitHubReviewComment> reviewComments,
    required List<GitHubIssueComment> issueComments,
  }) {
    final buf = StringBuffer()
      ..writeln('# ${pr.number}: ${pr.title}')
      ..writeln()
      ..writeln('- State: ${pr.state}')
      ..writeln('- Head: `${pr.headRef}` @ `${pr.headSha}`')
      ..writeln('- Base: `${pr.baseRef}`')
      ..writeln('- Author: ${pr.userLogin}')
      ..writeln();
    if (pr.body.isNotEmpty) {
      buf
        ..writeln('## Description')
        ..writeln()
        ..writeln(pr.body)
        ..writeln();
    }
    if (checkRuns.isNotEmpty) {
      buf
        ..writeln('## Check runs (${checkRuns.length})')
        ..writeln();
      for (final c in checkRuns) {
        buf.writeln(
          '- **${c.name}** — status: ${c.status.name}, '
          'conclusion: ${c.conclusion.name}',
        );
      }
      buf.writeln();
    }
    if (reviews.isNotEmpty) {
      buf
        ..writeln('## Reviews (${reviews.length})')
        ..writeln();
      for (final r in reviews) {
        buf
          ..writeln('### ${r.user?.login ?? 'unknown'} — ${r.state.name}')
          ..writeln()
          ..writeln(r.body)
          ..writeln();
      }
    }
    if (reviewComments.isNotEmpty) {
      buf
        ..writeln('## Inline comments (${reviewComments.length})')
        ..writeln();
      for (final c in reviewComments) {
        buf.writeln(
          '- `${c.path}:${c.line}` '
          '— ${c.user?.login ?? 'unknown'}: ${c.body}',
        );
      }
      buf.writeln();
    }
    if (issueComments.isNotEmpty) {
      buf
        ..writeln('## Comments (${issueComments.length})')
        ..writeln();
      for (final c in issueComments) {
        buf.writeln(
          '- ${c.user?.login ?? 'unknown'} '
          '(${c.createdAt?.toIso8601String() ?? ''}): ${c.body}',
        );
      }
    }
    return buf.toString();
  }
}

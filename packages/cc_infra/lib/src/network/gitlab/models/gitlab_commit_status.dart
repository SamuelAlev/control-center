import 'package:cc_infra/src/network/models/date_parser.dart';

/// One entry of `GET /projects/:id/repository/commits/:sha/statuses`.
///
/// GitLab folds two things into this feed: its own CI jobs *and* statuses
/// posted by external integrations through `POST .../statuses/:sha`. Only the
/// latter are the GitHub-Statuses-API analogue the domain models as a
/// `CommitStatus`; the mapper is what separates them.
class GitLabCommitStatus {
  /// Creates a [GitLabCommitStatus].
  const GitLabCommitStatus({
    required this.id,
    required this.name,
    required this.status,
    this.sha = '',
    this.ref = '',
    this.description = '',
    this.targetUrl = '',
    this.allowFailure = false,
    this.pipelineId = 0,
    this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  /// Reads a [GitLabCommitStatus] off a decoded JSON object.
  factory GitLabCommitStatus.fromJson(Map<String, dynamic> json) =>
      GitLabCommitStatus(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? '',
        sha: json['sha'] as String? ?? '',
        ref: json['ref'] as String? ?? '',
        description: json['description'] as String? ?? '',
        targetUrl: json['target_url'] as String? ?? '',
        allowFailure: json['allow_failure'] as bool? ?? false,
        pipelineId: (json['pipeline_id'] as num?)?.toInt() ?? 0,
        createdAt: parseDate(json['created_at']),
        startedAt: parseDate(json['started_at']),
        finishedAt: parseDate(json['finished_at']),
      );

  /// Status id.
  final int id;

  /// Context name (`netlify/deploy-preview`, or a CI job name).
  final String name;

  /// Raw status string (`pending`, `running`, `success`, `failed`, `canceled`,
  /// `skipped`, `manual`).
  final String status;

  /// The commit the status is attached to.
  final String sha;

  /// The ref the status was reported for.
  final String ref;

  /// Human-readable description ("Deploy preview ready!").
  final String description;

  /// The URL the status points at — the deploy preview itself for a preview
  /// integration. Empty when the reporter supplied none.
  final String targetUrl;

  /// Whether a failure is tolerated.
  final bool allowFailure;

  /// Pipeline the status belongs to, when GitLab attached it to one.
  final int pipelineId;

  /// When the status was created.
  final DateTime? createdAt;

  /// When it started.
  final DateTime? startedAt;

  /// When it settled.
  final DateTime? finishedAt;
}

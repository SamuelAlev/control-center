import 'package:cc_infra/src/network/models/date_parser.dart';

/// A GitLab CI pipeline, as returned by `GET /projects/:id/pipelines`,
/// `GET /projects/:id/merge_requests/:iid/pipelines` and embedded in a merge
/// request as `head_pipeline`.
///
/// A pipeline is the GitLab analogue of a GitHub Actions workflow run: it owns
/// the jobs (check runs) and carries the rolled-up status.
class GitLabPipeline {
  /// Creates a [GitLabPipeline].
  const GitLabPipeline({
    required this.id,
    required this.status,
    this.iid = 0,
    this.projectId = 0,
    this.sha = '',
    this.ref = '',
    this.source = '',
    this.name = '',
    this.webUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Reads a [GitLabPipeline] off a decoded JSON object.
  factory GitLabPipeline.fromJson(Map<String, dynamic> json) => GitLabPipeline(
    id: (json['id'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? '',
    iid: (json['iid'] as num?)?.toInt() ?? 0,
    projectId: (json['project_id'] as num?)?.toInt() ?? 0,
    sha: json['sha'] as String? ?? '',
    ref: json['ref'] as String? ?? '',
    source: json['source'] as String? ?? '',
    name: json['name'] as String? ?? '',
    webUrl: json['web_url'] as String? ?? '',
    createdAt: parseDate(json['created_at']),
    updatedAt: parseDate(json['updated_at']),
  );

  /// Reads a [GitLabPipeline] from [raw] when it is a JSON object, else null.
  static GitLabPipeline? maybeFromJson(Object? raw) =>
      raw is Map<String, dynamic> ? GitLabPipeline.fromJson(raw) : null;

  /// Instance-wide pipeline id — the value every `/pipelines/:id/...`
  /// sub-resource is addressed by.
  final int id;

  /// Raw status string (`created`, `waiting_for_resource`, `preparing`,
  /// `pending`, `running`, `success`, `failed`, `canceled`, `skipped`,
  /// `manual`, `scheduled`).
  final String status;

  /// Per-project pipeline number.
  final int iid;

  /// Owning project id.
  final int projectId;

  /// Commit the pipeline ran against.
  final String sha;

  /// Ref (branch or tag) the pipeline ran on.
  final String ref;

  /// What triggered it (`push`, `merge_request_event`, `schedule`, …).
  final String source;

  /// Optional pipeline display name (GitLab 16.3+, from `workflow:name`).
  /// Empty when the pipeline is unnamed.
  final String name;

  /// Link to the pipeline page.
  final String webUrl;

  /// When the pipeline was created.
  final DateTime? createdAt;

  /// When the pipeline last changed.
  final DateTime? updatedAt;
}

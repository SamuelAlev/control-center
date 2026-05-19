import 'package:cc_infra/src/network/models/date_parser.dart';

/// A GitLab CI job, as returned by `GET /projects/:id/pipelines/:id/jobs` and
/// `GET /projects/:id/jobs/:job_id`.
///
/// A job is the GitLab analogue of a GitHub Actions job / check run. Unlike
/// GitHub, GitLab exposes no per-step breakdown — a job is atomic and its only
/// detail is the trace — so there is no `steps` field to read here.
class GitLabJob {
  /// Creates a [GitLabJob].
  const GitLabJob({
    required this.id,
    required this.name,
    required this.status,
    this.stage = '',
    this.ref = '',
    this.allowFailure = false,
    this.webUrl = '',
    this.failureReason = '',
    this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.duration,
    this.pipelineId = 0,
    this.needs = const <String>[],
  });

  /// Reads a [GitLabJob] off a decoded JSON object.
  factory GitLabJob.fromJson(Map<String, dynamic> json) {
    final pipeline = json['pipeline'];
    return GitLabJob(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      stage: json['stage'] as String? ?? '',
      ref: json['ref'] as String? ?? '',
      allowFailure: json['allow_failure'] as bool? ?? false,
      webUrl: json['web_url'] as String? ?? '',
      failureReason: json['failure_reason'] as String? ?? '',
      createdAt: parseDate(json['created_at']),
      startedAt: parseDate(json['started_at']),
      finishedAt: parseDate(json['finished_at']),
      duration: (json['duration'] as num?)?.toDouble(),
      pipelineId: pipeline is Map<String, dynamic>
          ? (pipeline['id'] as num?)?.toInt() ?? 0
          : 0,
      needs: _parseNeeds(json['needs']),
    );
  }

  /// Reads the `needs` array.
  ///
  /// GitLab's REST job payload does not normally carry `needs` (only GraphQL
  /// does), so this is defensive: it accepts both the array-of-strings and the
  /// array-of-`{name}` spellings and yields an empty list when the key is
  /// absent, which is what makes the stage-ordering fallback kick in.
  static List<String> _parseNeeds(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    final names = <String>[];
    for (final entry in raw) {
      if (entry is String && entry.isNotEmpty) {
        names.add(entry);
      } else if (entry is Map<String, dynamic>) {
        final name = entry['name'] as String?;
        if (name != null && name.isNotEmpty) {
          names.add(name);
        }
      }
    }
    return List<String>.unmodifiable(names);
  }

  /// Instance-wide job id.
  final int id;

  /// Job name — the YAML key under the pipeline definition, and the name the
  /// UI groups check runs by.
  final String name;

  /// Raw status string (`created`, `pending`, `running`, `success`, `failed`,
  /// `canceled`, `skipped`, `manual`, `scheduled`, `waiting_for_resource`,
  /// `preparing`).
  final String status;

  /// The stage the job belongs to. The fallback edge source when `needs` is
  /// absent.
  final String stage;

  /// Ref the job ran on.
  final String ref;

  /// Whether a failure of this job is tolerated by the pipeline.
  final bool allowFailure;

  /// Link to the job page.
  final String webUrl;

  /// Why the job failed (`script_failure`, `runner_system_failure`, …). Empty
  /// when the job did not fail.
  final String failureReason;

  /// When the job was created.
  final DateTime? createdAt;

  /// When the job started running.
  final DateTime? startedAt;

  /// When the job finished.
  final DateTime? finishedAt;

  /// Runtime in seconds, null while running.
  final double? duration;

  /// Owning pipeline id, read from the embedded `pipeline` object.
  final int pipelineId;

  /// Upstream job names, when the payload happens to carry them.
  final List<String> needs;
}

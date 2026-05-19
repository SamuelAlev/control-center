import 'package:cc_infra/src/network/models/date_parser.dart';

/// A single commit-status context from the GitHub Statuses API
/// (`GET /repos/{owner}/{repo}/commits/{ref}/status`).
///
/// Distinct from the Checks API: deploy-preview integrations (Netlify, some
/// Vercel setups) publish the live preview URL through [targetUrl] here.
class GitHubCommitStatus {
  /// Creates a [GitHubCommitStatus].
  const GitHubCommitStatus({
    required this.context,
    required this.state,
    this.targetUrl = '',
    this.description = '',
    this.updatedAt,
  });

  /// Decodes one entry of the combined status's `statuses` array.
  factory GitHubCommitStatus.fromJson(Map<String, dynamic> json) =>
      GitHubCommitStatus(
        context: json['context'] as String? ?? '',
        state: json['state'] as String? ?? 'pending',
        targetUrl: json['target_url'] as String? ?? '',
        description: json['description'] as String? ?? '',
        updatedAt: parseDate(json['updated_at'] ?? json['created_at']),
      );

  /// The status context, e.g. `netlify/test-web-app/deploy-preview`.
  final String context;

  /// The raw GitHub state string (`success` / `pending` / `failure` / `error`).
  final String state;

  /// The URL the status points at (the preview site for a deploy-preview).
  final String targetUrl;

  /// Human-readable description.
  final String description;

  /// When the status last moved.
  final DateTime? updatedAt;

  /// Serializes back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'context': context,
    'state': state,
    'target_url': targetUrl,
    'description': description,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

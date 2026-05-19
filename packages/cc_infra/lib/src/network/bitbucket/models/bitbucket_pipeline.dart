import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// A Bitbucket Pipelines run
/// (`GET /repositories/{workspace}/{repo}/pipelines/`).
///
/// This is the native view of a pipeline, useful when a caller wants the run
/// number, trigger and target ref rather than the build status the run also
/// publishes. It is NOT a richer CI surface: Bitbucket exposes no per-step
/// structure or logs through this resource, which is why the `ciJobDetail`
/// capability stays false for Bitbucket.
///
/// The outcome is split across two fields: [stateName] is the lifecycle
/// (`PENDING` / `IN_PROGRESS` / `COMPLETED`) and [resultName] is the verdict
/// (`SUCCESSFUL` / `FAILED` / `ERROR` / `STOPPED`), which only exists once the
/// run completes.
class BitbucketPipeline {
  /// Creates a [BitbucketPipeline].
  const BitbucketPipeline({
    required this.uuid,
    required this.buildNumber,
    required this.stateName,
    this.resultName = '',
    this.targetCommitHash = '',
    this.targetRefName = '',
    this.triggerName = '',
    this.creator,
    this.createdOn,
    this.completedOn,
    this.buildSecondsUsed = 0,
  });

  /// Decodes a Bitbucket `pipeline` object.
  factory BitbucketPipeline.fromJson(Map<String, dynamic> json) {
    final state = asJsonMap(json['state']);
    // A completed run carries `state.result`; a running one carries
    // `state.stage`. Neither exists while the run is merely pending.
    final result = asJsonMap(state?['result']) ?? asJsonMap(state?['stage']);
    final target = asJsonMap(json['target']);
    final creator = asJsonMap(json['creator']);
    return BitbucketPipeline(
      uuid: json['uuid'] as String? ?? '',
      buildNumber: (json['build_number'] as num?)?.toInt() ?? 0,
      stateName: state?['name'] as String? ?? '',
      resultName: result?['name'] as String? ?? '',
      targetCommitHash: asJsonMap(target?['commit'])?['hash'] as String? ?? '',
      targetRefName: target?['ref_name'] as String? ?? '',
      triggerName: asJsonMap(json['trigger'])?['name'] as String? ?? '',
      creator: creator == null ? null : BitbucketUser.fromJson(creator),
      createdOn: parseDate(json['created_on']),
      completedOn: parseDate(json['completed_on']),
      buildSecondsUsed: (json['build_seconds_used'] as num?)?.toInt() ?? 0,
    );
  }

  /// Braced opaque run id.
  final String uuid;

  /// Monotonic per-repository build number, the label humans use.
  final int buildNumber;

  /// `PENDING`, `IN_PROGRESS`, `COMPLETED` or `PAUSED`.
  final String stateName;

  /// `SUCCESSFUL`, `FAILED`, `ERROR` or `STOPPED`. Empty until the run
  /// reaches a verdict.
  final String resultName;

  /// The commit the run targeted.
  final String targetCommitHash;

  /// The branch or tag the run targeted.
  final String targetRefName;

  /// What started the run (`PUSH`, `MANUAL`, `SCHEDULE`, …).
  final String triggerName;

  /// The account that triggered the run.
  final BitbucketUser? creator;

  /// When the run was created.
  final DateTime? createdOn;

  /// When the run finished. Null while it is still going.
  final DateTime? completedOn;

  /// Billable build minutes consumed, in seconds.
  final int buildSecondsUsed;

  /// The label to show for this run — `Pipeline #<build number>` — since
  /// Bitbucket gives a run no name of its own.
  String get displayName => 'Pipeline #$buildNumber';
}

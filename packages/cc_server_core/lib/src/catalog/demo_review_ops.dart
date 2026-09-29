import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/demo/demo_review_service.dart';

/// The scripted "Ask AI" op. Absent unless [demoReview] is wired, which is
/// only the public demo host — production keeps `review_hub.start`.
///
/// Declares no process-spawn action: the service writes pipeline rows and
/// review messages. It does not start the review pipeline.
List<RepoOp> buildDemoReviewOps(DemoReviewService? demoReview) {
  if (demoReview == null) {
    return const [];
  }
  return [
    RepoOp(
      name: 'review_hub.demoStart',
      kind: RepoOpKind.mutate,
      requiredArgs: ['workspace_id', 'owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final coords = _repoCoords(ctx.args);
        final rawLevel = ctx.args['level'];
        if (rawLevel != null &&
            (rawLevel is! String || ReviewLevel.fromWire(rawLevel) == null)) {
          throw ValidationException(
            'Unknown review level: $rawLevel. Expected one of '
            '${ReviewLevel.values.map((level) => level.wireName).join(', ')}.',
          );
        }
        final prNumber = ctx.args['pr_number'];
        if (prNumber is! num) {
          throw const ValidationException('pr_number must be a number');
        }
        return demoReview.start(
          workspaceId: ctx.workspaceId!,
          owner: coords.owner,
          repo: coords.repo,
          prNumber: prNumber.toInt(),
          level: rawLevel as String?,
        );
      },
    ),
  ];
}

({String owner, String repo}) _repoCoords(Map<String, dynamic> args) {
  final owner = args['owner'];
  final repo = args['repo'];
  if (owner is! String || owner.isEmpty || repo is! String || repo.isEmpty) {
    throw const ValidationException('Missing or invalid argument: owner/repo');
  }
  return (owner: owner, repo: repo);
}

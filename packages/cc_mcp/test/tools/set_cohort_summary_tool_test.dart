import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_mcp/src/tools/set_cohort_summary_tool.dart';
import 'package:test/test.dart';

void main() {
  late SetCohortSummaryTool tool;

  setUp(() {
    tool = SetCohortSummaryTool(cohorts: _FakeCohorts());
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'owner': 'acme',
      'repo': 'app',
      'pr_number': 1,
      'cohort_key': 'auth',
      'summary_markdown': 'Looks good',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('unknown cohort is refused', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'owner': 'acme',
      'repo': 'app',
      'pr_number': 1,
      'cohort_key': 'auth',
      'summary_markdown': 'Looks good',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('not found'));
  });
}

class _FakeCohorts implements ReviewCohortRepository {
  @override
  Future<List<ReviewCohort>> forPr(
    String workspaceId,
    String prExternalId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_mcp/src/tools/add_review_diagram_tool.dart';
import 'package:test/test.dart';

void main() {
  late AddReviewDiagramTool tool;

  setUp(() {
    tool = AddReviewDiagramTool(
      cohorts: _FakeCohorts(),
      corroborate:
          ({
            required String workspaceId,
            required String owner,
            required String repo,
            required List<String> filePaths,
          }) async => <String>{},
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'owner': 'acme',
      'repo': 'app',
      'pr_number': 1,
      'cohort_key': 'auth',
      'diagram': _validDiagram,
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
      'diagram': _validDiagram,
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('not found'));
  });

  test('invalid diagram JSON is refused', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'owner': 'acme',
      'repo': 'app',
      'pr_number': 1,
      'cohort_key': 'auth',
      'diagram': {'kind': 'sequence', 'title': 123},
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('Invalid diagram'));
  });
}

const _validDiagram = {
  'kind': 'sequence',
  'title': 'Login flow',
  'participants': <String>['Client', 'Server'],
  'messages': [
    {'from': 'Client', 'to': 'Server', 'label': 'auth'},
  ],
};

class _FakeCohorts implements ReviewCohortRepository {
  @override
  Future<List<ReviewCohort>> forPr(
    String workspaceId,
    String prExternalId,
  ) async => const <ReviewCohort>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

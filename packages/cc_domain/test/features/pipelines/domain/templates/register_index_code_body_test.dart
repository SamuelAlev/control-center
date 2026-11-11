import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_index_code_body.dart';
import 'package:cc_domain/testing/fake_repo_repository.dart';
import 'package:test/test.dart';

/// `code.index` reads the checkout the server serves for `repo_id`, never a
/// path from the trigger payload: a run cannot point the indexer at a path the
/// server refuses to serve.
void main() {
  late _Indexer indexer;
  late _ServedRepos repos;
  late StepBodyFn body;

  Repo repo(String id, String path) => Repo(
    id: id,
    name: 'acme/$id',
    path: path,
    remoteOwner: 'acme',
    remoteName: id,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  PipelineContext ctx(Map<String, dynamic> trigger) => PipelineContext(
    pipelineRunId: 'run-1',
    templateId: 'index_code',
    stepId: 'index',
    stepRunId: 'steprun-1',
    workspaceId: 'ws-1',
    state: const {},
    triggerPayload: trigger,
  );

  setUp(() {
    indexer = _Indexer();
    repos = _ServedRepos()
      ..seed('ws-1', [repo('api', '/srv/ws-1/repos/api')])
      ..seed('ws-1', [repo('host', '/Users/someone/secrets')])
      ..refused.add('host');
    final registry = PipelineBodyRegistry();
    registerIndexCodeBody(
      registry,
      codeIndexer: indexer,
      servedRepos: repos,
      runRepository: _Runs(),
      stepProcessRegistry: StepProcessRegistry(),
    );
    body = registry.body(BuiltInBodyKeys.indexCode);
  });

  test('indexes the served checkout, not the payload path', () async {
    final result = await body(
      ctx({'repo_id': 'api', 'repo_local_path': '/etc'}),
    );
    expect(result.isFailed, isFalse);
    expect(indexer.paths, ['/srv/ws-1/repos/api']);
  });

  test('a repository whose path is not served is never indexed', () async {
    final result = await body(
      ctx({'repo_id': 'host', 'repo_local_path': '/Users/someone/secrets'}),
    );
    expect(result.isFailed, isTrue);
    expect(indexer.paths, isEmpty);
  });

  test('an unknown repository is never indexed', () async {
    final result = await body(
      ctx({'repo_id': 'nope', 'repo_local_path': '/srv/ws-1/repos/api'}),
    );
    expect(result.isFailed, isTrue);
    expect(indexer.paths, isEmpty);
  });
}

/// Serves every seeded repository but the [refused] ones, which throw as
/// the server's path guard does.
final class _ServedRepos extends FakeRepoRepository {
  final refused = <String>{};

  @override
  Future<Repo?> getById(String workspaceId, String repoId) async {
    if (refused.contains(repoId)) {
      throw StateError('repo_path.host_path');
    }
    return super.getById(workspaceId, repoId);
  }
}

final class _Indexer implements CodeIndexer {
  final paths = <String>[];

  @override
  Future<CodeIndexResult> indexRepo({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
    bool force = false,
    List<String>? changedPaths,
    void Function(CodeIndexProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    paths.add(repoPath);
    return const CodeIndexResult.skipped('test');
  }
}

final class _Runs implements PipelineRunRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

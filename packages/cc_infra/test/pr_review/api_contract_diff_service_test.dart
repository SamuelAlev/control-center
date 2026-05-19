import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_infra/src/pr_review/api_contract_diff_service.dart';
import 'package:test/test.dart';

class _RecordingRepo implements ApiContractDiffRepository {
  final List<ApiContractDiff> upserted = [];

  @override
  Future<void> upsert(String workspaceId, ApiContractDiff diff) async =>
      upserted.add(diff);

  @override
  Future<List<ApiContractDiff>> forPr(
    String workspaceId,
    String prExternalId,
  ) async => upserted.where((d) => d.prExternalId == prExternalId).toList();

  @override
  Stream<List<ApiContractDiff>> watchForPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(const <ApiContractDiff>[]);

  @override
  Future<void> setChangeDecision(
    String workspaceId,
    String diffId,
    String changeId,
    ApiChangeDecision decision,
  ) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Programmed content reader: returns the content for a (path, ref) pair, or
/// throws to simulate a read failure.
Future<String?> Function({required String path, required String ref}) reader(
  Map<String, String> byKey,
) {
  return ({required path, required ref}) async {
    final key = '$ref:$path';
    final v = byKey[key];
    if (v == null) {
      throw StateError('not found: $key');
    }
    return v;
  };
}

void main() {
  group('ApiContractDiffService.matchingSpecs', () {
    test('matches default spec file names anywhere in the tree', () {
      final svc = ApiContractDiffService(repository: _RecordingRepo());
      final matches = svc.matchingSpecs([
        'src/openapi.yaml',
        'docs/swagger.json',
        'README.md',
        'lib/main.dart',
        'subdir/OpenAPI.yml',
      ]);
      expect(
        matches,
        containsAll([
          'src/openapi.yaml',
          'docs/swagger.json',
          'subdir/OpenAPI.yml',
        ]),
      );
      expect(matches, isNot(contains('README.md')));
    });

    test('matches *openapi* / *swagger* with spec extensions', () {
      final svc = ApiContractDiffService(repository: _RecordingRepo());
      final matches = svc.matchingSpecs([
        'api/my-openapi-v2.json',
        'legacy/swagger-v1.yaml',
        'openapi.txt', // wrong ext
        'swagger.md', // wrong ext
      ]);
      expect(
        matches,
        containsAll(['api/my-openapi-v2.json', 'legacy/swagger-v1.yaml']),
      );
      expect(matches, isNot(contains('openapi.txt')));
      expect(matches, isNot(contains('swagger.md')));
    });

    test('honors custom spec globs (additive to the heuristic)', () {
      // Custom globs are additive: the *openapi*/*swagger* heuristic still
      // matches `openapi.yaml`, but a custom `contract.json` glob also matches.
      final svc = ApiContractDiffService(
        repository: _RecordingRepo(),
        specGlobs: const ['contract.json'],
      );
      final matches = svc.matchingSpecs(['contract.json', 'openapi.yaml']);
      expect(matches, containsAll(['contract.json', 'openapi.yaml']));
      // But files that aren't specs at all are excluded.
      expect(matches, isNot(contains('README.md')));
    });

    test('empty input returns empty', () {
      final svc = ApiContractDiffService(repository: _RecordingRepo());
      expect(svc.matchingSpecs(const []), isEmpty);
    });
  });

  group('ApiContractDiffService.compute', () {
    test('parses YAML specs and persists a diff per changed spec', () async {
      final repo = _RecordingRepo();
      final svc = ApiContractDiffService(repository: repo);
      const before = '''
openapi: 3.0.0
info:
  title: Demo
  version: 1.0.0
paths:
  /users:
    get:
      operationId: listUsers
''';
      const after = '''
openapi: 3.0.0
info:
  title: Demo
  version: 1.1.0
paths:
  /users:
    get:
      operationId: listUsers
  /users/{id}:
    get:
      operationId: getUser
''';

      final diffs = await svc.compute(
        workspaceId: 'ws',
        repoId: 'repo',
        prExternalId: 'pr_1',
        baseSha: 'base',
        headSha: 'head',
        changedFiles: const ['openapi.yaml', 'README.md'],
        readContent: reader({
          'base:openapi.yaml': before,
          'head:openapi.yaml': after,
        }),
      );

      expect(diffs, hasLength(1));
      expect(diffs.single.specPath, 'openapi.yaml');
      expect(diffs.single.headSha, 'head');
      expect(repo.upserted, hasLength(1));
      expect(repo.upserted.single.id, 'pr_1:openapi.yaml');
    });

    test('parses JSON specs', () async {
      final repo = _RecordingRepo();
      final svc = ApiContractDiffService(repository: repo);

      final diffs = await svc.compute(
        workspaceId: 'ws',
        repoId: 'repo',
        prExternalId: 'pr_1',
        baseSha: 'base',
        headSha: 'head',
        changedFiles: const ['swagger.json'],
        readContent: reader({
          'base:swagger.json': '{"openapi":"3.0.0","paths":{}}',
          'head:swagger.json':
              '{"openapi":"3.0.0","paths":{"/x":{"get":{"operationId":"x"}}}}',
        }),
      );

      expect(diffs, hasLength(1));
      expect(repo.upserted, hasLength(1));
    });

    test('skips specs absent at both sides', () async {
      final repo = _RecordingRepo();
      final svc = ApiContractDiffService(repository: repo);

      final diffs = await svc.compute(
        workspaceId: 'ws',
        repoId: 'repo',
        prExternalId: 'pr_1',
        baseSha: 'base',
        headSha: 'head',
        changedFiles: const ['openapi.yaml'],
        readContent: reader({}), // all reads throw
      );

      expect(diffs, isEmpty);
      expect(repo.upserted, isEmpty);
    });

    test('no spec files changed returns empty', () async {
      final repo = _RecordingRepo();
      final svc = ApiContractDiffService(repository: repo);

      final diffs = await svc.compute(
        workspaceId: 'ws',
        repoId: 'repo',
        prExternalId: 'pr_1',
        baseSha: 'base',
        headSha: 'head',
        changedFiles: const ['lib/main.dart', 'README.md'],
        readContent: reader({}),
      );

      expect(diffs, isEmpty);
    });

    test('skips specs whose content is unparseable on both sides', () async {
      final repo = _RecordingRepo();
      final svc = ApiContractDiffService(repository: repo);

      final diffs = await svc.compute(
        workspaceId: 'ws',
        repoId: 'repo',
        prExternalId: 'pr_1',
        baseSha: 'base',
        headSha: 'head',
        changedFiles: const ['openapi.yaml'],
        readContent: reader({
          'base:openapi.yaml': '<<binary>>',
          'head:openapi.yaml': 'also not yaml: : :',
        }),
      );

      expect(diffs, isEmpty);
    });

    test('new spec at head (null at base) is still diffed', () async {
      final repo = _RecordingRepo();
      final svc = ApiContractDiffService(repository: repo);

      // Reader throws for base (absent), returns content for head.
      Future<String?> read({required String path, required String ref}) async {
        if (ref == 'base') {
          return null;
        }
        return '{"openapi":"3.0.0","paths":{"/a":{"get":{"operationId":"a"}}}}';
      }

      final diffs = await svc.compute(
        workspaceId: 'ws',
        repoId: 'repo',
        prExternalId: 'pr_1',
        baseSha: 'base',
        headSha: 'head',
        changedFiles: const ['openapi.json'],
        readContent: read,
      );

      expect(diffs, hasLength(1));
    });
  });
}

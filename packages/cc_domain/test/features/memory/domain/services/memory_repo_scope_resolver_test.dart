import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/memory/domain/services/memory_repo_scope_resolver.dart';
import 'package:cc_domain/testing/fake_repo_repository.dart';
import 'package:test/test.dart';

Repo _repo({
  required String id,
  required String name,
  String? remoteOwner,
  String? remoteName,
}) {
  final parts = name.split('/');
  return Repo(
    id: id,
    name: name,
    path: '/tmp/$id',
    remoteOwner: remoteOwner ?? (parts.length > 1 ? parts.first : ''),
    remoteName: remoteName ?? parts.last,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  const ws = 'ws-1';

  late FakeRepoRepository repos;
  late MemoryRepoScopeResolver resolver;

  setUp(() {
    repos = FakeRepoRepository();
    resolver = MemoryRepoScopeResolver(repos);
  });

  group('MemoryRepoScopeResolver', () {
    test('null and blank mean workspace-wide', () async {
      expect(await resolver.resolve(ws, null), isNull);
      expect(await resolver.resolve(ws, ''), isNull);
      expect(await resolver.resolve(ws, '   '), isNull);
    });

    test('resolves by repo id', () async {
      repos.seed(ws, [_repo(id: 'r1', name: 'acme/api')]);
      expect(await resolver.resolve(ws, 'r1'), equals('acme-api'));
    });

    test('resolves by owner/name', () async {
      repos.seed(ws, [_repo(id: 'r1', name: 'acme/api')]);
      expect(await resolver.resolve(ws, 'acme/api'), equals('acme-api'));
    });

    test('resolves by the scope slug it hands back', () async {
      repos.seed(ws, [_repo(id: 'r1', name: 'acme/api')]);
      final once = await resolver.resolve(ws, 'acme/api');
      expect(await resolver.resolve(ws, once), equals(once));
    });

    test('resolves case-insensitively', () async {
      repos.seed(ws, [_repo(id: 'r1', name: 'Acme/My-API')]);
      expect(await resolver.resolve(ws, 'acme/my-api'), equals('acme-my-api'));
    });

    test('resolves an unambiguous bare remote name', () async {
      repos.seed(ws, [_repo(id: 'r1', name: 'acme/api')]);
      expect(await resolver.resolve(ws, 'api'), equals('acme-api'));
    });

    test('refuses an ambiguous bare remote name', () async {
      // Two owners, one short name. Silently picking the first would attach
      // memory to whichever repo happened to be registered earlier.
      repos.seed(ws, [
        _repo(id: 'r1', name: 'acme/api'),
        _repo(id: 'r2', name: 'globex/api'),
      ]);
      expect(
        () => resolver.resolve(ws, 'api'),
        throwsA(isA<UnknownMemoryRepoScope>()),
      );
    });

    test(
      'an unknown repo is an error, not a silent workspace-wide write',
      () async {
        repos.seed(ws, [_repo(id: 'r1', name: 'acme/api')]);
        expect(
          () => resolver.resolve(ws, 'acme/typo'),
          throwsA(isA<UnknownMemoryRepoScope>()),
        );
      },
    );

    test('a repo in another workspace does not resolve', () async {
      repos.seed('other-ws', [_repo(id: 'r1', name: 'acme/api')]);
      expect(
        () => resolver.resolve(ws, 'r1'),
        throwsA(isA<UnknownMemoryRepoScope>()),
      );
    });

    test('the error names the workspace and how to recover', () async {
      final err = await resolver
          .resolve(ws, 'nope')
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(err, isA<UnknownMemoryRepoScope>());
      expect(err.toString(), contains('nope'));
      expect(err.toString(), contains(ws));
      expect(err.toString(), contains('list_repos'));
    });
  });
}

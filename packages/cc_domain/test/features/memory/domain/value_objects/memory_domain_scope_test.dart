import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:test/test.dart';

Repo _repo({
  String id = 'r1',
  String name = 'anthropics/control-center',
  String path = '/tmp/cc',
  String remoteOwner = 'anthropics',
  String remoteName = 'control-center',
}) => Repo(
  id: id,
  name: name,
  path: path,
  remoteOwner: remoteOwner,
  remoteName: remoteName,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('MemoryDomainScope.qualify', () {
    test('leaves an unscoped domain bare', () {
      expect(
        MemoryDomainScope.qualify(domainInput: 'Auth Flow'),
        equals('auth-flow'),
      );
    });

    test('prefixes a repo-scoped domain', () {
      expect(
        MemoryDomainScope.qualify(
          domainInput: 'Auth Flow',
          repoSlug: 'anthropics-control-center',
        ),
        equals('repo:anthropics-control-center/auth-flow'),
      );
    });

    test('slugifies the bare name without eating the prefix', () {
      // The regression this design exists for: the shared slugifier strips `:`
      // and `/`, so qualifying BEFORE slugifying collapsed the whole slug to
      // `repoanthropicscontrolcenterauthflow`.
      final slug = MemoryDomainScope.qualify(
        domainInput: 'auth flow',
        repoSlug: 'anthropics-control-center',
      );
      expect(slug, contains(':'));
      expect(slug, contains('/'));
      expect(MemoryDomainScope.bareName(slug), equals('auth-flow'));
      expect(
        MemoryDomainScope.repoSlugOf(slug),
        equals('anthropics-control-center'),
      );
    });

    test('an already-qualified input does not accumulate prefixes', () {
      final once = MemoryDomainScope.qualify(
        domainInput: 'architecture',
        repoSlug: 'proj',
      );
      final twice = MemoryDomainScope.qualify(
        domainInput: once,
        repoSlug: 'proj',
      );
      expect(twice, equals(once));
    });

    test('the caller repo replaces a scope carried by the input', () {
      expect(
        MemoryDomainScope.qualify(
          domainInput: 'repo:old/architecture',
          repoSlug: 'new',
        ),
        equals('repo:new/architecture'),
      );
    });

    test('an empty repo slug means workspace-wide', () {
      expect(
        MemoryDomainScope.qualify(domainInput: 'architecture', repoSlug: ''),
        equals('architecture'),
      );
    });
  });

  group('MemoryDomainScope.parse', () {
    test('reads back a qualified slug', () {
      final scope = MemoryDomainScope.parse('repo:my-proj/architecture');
      expect(scope.repoSlug, equals('my-proj'));
      expect(scope.name, equals('architecture'));
      expect(scope.isRepoScoped, isTrue);
      expect(scope.slug, equals('repo:my-proj/architecture'));
    });

    test('an unprefixed slug is workspace-wide', () {
      final scope = MemoryDomainScope.parse('architecture');
      expect(scope.repoSlug, isNull);
      expect(scope.isRepoScoped, isFalse);
      expect(scope.name, equals('architecture'));
    });

    test('a malformed prefix is kept verbatim rather than losing text', () {
      for (final malformed in [
        'repo:orphan',
        'repo:/architecture',
        'repo:x/',
      ]) {
        final scope = MemoryDomainScope.parse(malformed);
        expect(scope.isRepoScoped, isFalse, reason: malformed);
        expect(scope.name, equals(malformed), reason: malformed);
      }
    });

    test('a domain literally named "repo" is not mistaken for a prefix', () {
      final scope = MemoryDomainScope.parse('repo');
      expect(scope.isRepoScoped, isFalse);
      expect(scope.name, equals('repo'));
    });
  });

  group('matchesDomainFilter', () {
    test('a bare filter matches every scope of that domain', () {
      expect(matchesDomainFilter('architecture', 'architecture'), isTrue);
      expect(
        matchesDomainFilter('repo:a/architecture', 'architecture'),
        isTrue,
      );
      expect(
        matchesDomainFilter('repo:b/architecture', 'architecture'),
        isTrue,
      );
    });

    test('a bare filter does not match a different domain', () {
      expect(matchesDomainFilter('repo:a/auth-flow', 'architecture'), isFalse);
    });

    test('a qualified filter matches only that repo', () {
      expect(
        matchesDomainFilter('repo:a/architecture', 'repo:a/architecture'),
        isTrue,
      );
      expect(
        matchesDomainFilter('repo:b/architecture', 'repo:a/architecture'),
        isFalse,
      );
      expect(
        matchesDomainFilter('architecture', 'repo:a/architecture'),
        isFalse,
      );
    });

    test('an empty filter matches nothing', () {
      // Preserves the pre-existing behaviour of the SQL equality predicate: a
      // caller passing `domain: ""` got no rows, not every row.
      expect(matchesDomainFilter('architecture', ''), isFalse);
      expect(matchesDomainFilter('repo:a/architecture', ''), isFalse);
    });
  });

  group('sortByRepoAffinity', () {
    List<String> order(List<String> domains, String? repo) =>
        sortByRepoAffinity<String>(domains, repo, domainOf: (d) => d);

    test('floats the repo\'s own domains without dropping the rest', () {
      final result = order([
        'architecture',
        'repo:other/architecture',
        'repo:mine/architecture',
      ], 'mine');
      expect(result.first, equals('repo:mine/architecture'));
      expect(result, hasLength(3));
      expect(result, contains('architecture'));
      expect(result, contains('repo:other/architecture'));
    });

    test('is a stable partition, preserving incoming relevance order', () {
      final result = order([
        'repo:mine/a',
        'z-global',
        'repo:other/b',
        'repo:mine/c',
        'a-global',
      ], 'mine');
      expect(
        result,
        equals([
          'repo:mine/a',
          'repo:mine/c',
          'z-global',
          'repo:other/b',
          'a-global',
        ]),
      );
    });

    test('a null repo leaves the order untouched', () {
      final input = ['repo:mine/a', 'global', 'repo:other/b'];
      expect(order(input, null), equals(input));
    });
  });

  group('repoSlugFor', () {
    test('flattens owner/repo so the scope slug has one separator', () {
      final slug = repoSlugFor(_repo());
      expect(slug, equals('anthropics-control-center'));
      expect(slug, isNot(contains('/')));
    });

    test('two repos sharing a short name get distinct scopes', () {
      final a = repoSlugFor(_repo(id: 'r1', name: 'acme/api'));
      final b = repoSlugFor(_repo(id: 'r2', name: 'globex/api'));
      expect(a, isNot(equals(b)));
    });

    test('falls back when the repo has no usable name', () {
      final slug = repoSlugFor(_repo(name: '///', remoteName: 'fallback'));
      expect(slug, equals('fallback'));
    });

    test('round-trips through qualify and parse', () {
      final slug = repoSlugFor(_repo());
      final domain = MemoryDomainScope.qualify(
        domainInput: 'architecture',
        repoSlug: slug,
      );
      expect(MemoryDomainScope.repoSlugOf(domain), equals(slug));
      expect(MemoryDomainScope.bareName(domain), equals('architecture'));
    });
  });
}

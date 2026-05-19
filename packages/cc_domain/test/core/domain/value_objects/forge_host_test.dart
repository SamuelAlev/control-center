import 'package:cc_domain/core/domain/value_objects/forge_git_conventions.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/forge_urls.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:test/test.dart';

void main() {
  group('ForgeHost', () {
    test('every wire value is unique', () {
      final wires = ForgeHost.values.map((f) => f.wire).toList();
      expect(wires.toSet().length, wires.length);
    });

    test('round-trips through the wire', () {
      for (final forge in ForgeHost.values) {
        expect(ForgeHost.fromWire(forge.wire), forge);
      }
    });

    test('an unknown wire value degrades to local, never throws', () {
      // A row written by a newer build must not take a workspace's repo list
      // down; it degrades to "no forge operations available".
      expect(ForgeHost.fromWire('cursor-origin'), ForgeHost.local);
      expect(ForgeHost.fromWire(null), ForgeHost.local);
      expect(ForgeHost.fromWire(''), ForgeHost.local);
    });

    test('supported excludes local and covers the rest', () {
      expect(ForgeHost.supported, isNot(contains(ForgeHost.local)));
      expect(
        ForgeHost.supported.toSet(),
        ForgeHost.values.toSet().difference({ForgeHost.local}),
      );
      expect(ForgeHost.supported.every((f) => f.isSupported), isTrue);
      expect(ForgeHost.local.isSupported, isFalse);
    });

    test('every supported forge declares its hosts and URLs', () {
      for (final forge in ForgeHost.supported) {
        expect(forge.gitHost, isNotEmpty, reason: forge.name);
        expect(forge.webBaseUrl, startsWith('https://'), reason: forge.name);
        expect(forge.apiBaseUrl, startsWith('https://'), reason: forge.name);
        expect(forge.webBaseUrl, isNot(endsWith('/')), reason: forge.name);
        expect(forge.apiBaseUrl, isNot(endsWith('/')), reason: forge.name);
      }
    });

    test('resolves a forge from its git host', () {
      expect(ForgeHost.fromGitHost('github.com'), ForgeHost.github);
      expect(ForgeHost.fromGitHost('GitLab.com'), ForgeHost.gitlab);
      expect(ForgeHost.fromGitHost('www.bitbucket.org'), ForgeHost.bitbucket);
      expect(ForgeHost.fromGitHost('git.example.com'), isNull);
    });

    test('names a change request in each forge’s own vocabulary', () {
      expect(ForgeHost.gitlab.changeRequestNoun, 'merge request');
      expect(ForgeHost.gitlab.changeRequestAbbreviation, 'MR');
      expect(ForgeHost.github.changeRequestNoun, 'pull request');
      expect(ForgeHost.bitbucket.changeRequestAbbreviation, 'PR');
    });
  });

  group('ForgeCapabilities', () {
    test('every forge has an entry, including local', () {
      for (final forge in ForgeHost.values) {
        expect(kForgeCapabilities[forge], isNotNull, reason: forge.name);
        expect(capabilitiesOf(forge).forge, forge);
      }
    });

    test('local can do nothing', () {
      final caps = capabilitiesOf(ForgeHost.local);
      for (final name in ForgeCapabilities.allNames) {
        expect(caps.byName(name), isFalse, reason: name);
      }
    });

    test('allNames covers every declared flag', () {
      // The ratchet: a capability added to the class but not to `allNames`
      // would be invisible to the wire, the settings matrix and this test.
      final json = capabilitiesOf(ForgeHost.github).toJson();
      expect(
        json.keys.toSet(),
        {'forge', ...ForgeCapabilities.allNames},
      );
    });

    test('byName rejects an unknown capability rather than reading false', () {
      expect(
        () => capabilitiesOf(ForgeHost.github).byName('teleportation'),
        throwsArgumentError,
      );
    });

    test('round-trips through the wire', () {
      for (final forge in ForgeHost.values) {
        final original = capabilitiesOf(forge);
        final restored = ForgeCapabilities.fromJson(original.toJson());
        expect(restored.forge, original.forge, reason: forge.name);
        for (final name in ForgeCapabilities.allNames) {
          expect(restored.byName(name), original.byName(name), reason: name);
        }
      }
    });

    test('an older wire payload reads missing flags as false', () {
      final caps = ForgeCapabilities.fromJson({'forge': 'github'});
      expect(caps.forge, ForgeHost.github);
      for (final name in ForgeCapabilities.allNames) {
        expect(caps.byName(name), isFalse, reason: name);
      }
    });

    test('serverSidePrHeadRef agrees with the git conventions', () {
      // Two places encode the same fact; if they disagree, a checkout silently
      // tries a ref that does not exist.
      for (final forge in ForgeHost.values) {
        expect(
          capabilitiesOf(forge).serverSidePrHeadRef,
          ForgeGitConventions.of(forge).hasServerSidePrHeadRef,
          reason: forge.name,
        );
      }
    });
  });

  group('ForgeGitConventions', () {
    test('each forge addresses a PR head its own way', () {
      expect(
        ForgeGitConventions.of(ForgeHost.github).prHeadRef(7),
        'refs/pull/7/head',
      );
      expect(
        ForgeGitConventions.of(ForgeHost.gitlab).prHeadRef(7),
        'refs/merge-requests/7/head',
      );
      // Bitbucket publishes none — callers must fetch the source branch.
      expect(ForgeGitConventions.of(ForgeHost.bitbucket).prHeadRef(7), isNull);
    });

    test('authenticated clone URLs use each forge’s expected username', () {
      expect(
        ForgeGitConventions.of(
          ForgeHost.github,
        ).authenticatedCloneUrl('o', 'r', 'tok'),
        'https://x-access-token:tok@github.com/o/r.git',
      );
      expect(
        ForgeGitConventions.of(
          ForgeHost.gitlab,
        ).authenticatedCloneUrl('o', 'r', 'tok'),
        'https://oauth2:tok@gitlab.com/o/r.git',
      );
      expect(
        ForgeGitConventions.of(ForgeHost.bitbucket).authenticatedCloneUrl(
          'o',
          'r',
          'tok',
          username: 'me@example.com',
        ),
        'https://me@example.com:tok@bitbucket.org/o/r.git',
      );
    });
  });

  group('ForgeUrls', () {
    test('builds a pull request URL in each forge’s vocabulary', () {
      expect(
        const ForgeUrls(ForgeHost.github).pullRequest('o', 'r', 3),
        'https://github.com/o/r/pull/3',
      );
      expect(
        const ForgeUrls(ForgeHost.gitlab).pullRequest('g/sub', 'r', 3),
        'https://gitlab.com/g/sub/r/-/merge_requests/3',
      );
      expect(
        const ForgeUrls(ForgeHost.bitbucket).pullRequest('w', 'r', 3),
        'https://bitbucket.org/w/r/pull-requests/3',
      );
    });

    test('builds a commit URL in each forge’s vocabulary', () {
      expect(
        const ForgeUrls(ForgeHost.github).commit('o', 'r', 'abc'),
        'https://github.com/o/r/commit/abc',
      );
      expect(
        const ForgeUrls(ForgeHost.gitlab).commit('o', 'r', 'abc'),
        'https://gitlab.com/o/r/-/commit/abc',
      );
      expect(
        const ForgeUrls(ForgeHost.bitbucket).commit('o', 'r', 'abc'),
        'https://bitbucket.org/o/r/commits/abc',
      );
    });

    test('every supported forge has a status feed and a token page', () {
      for (final forge in ForgeHost.supported) {
        final urls = ForgeUrls(forge);
        expect(urls.statusPage, startsWith('https://'), reason: forge.name);
        expect(
          urls.statusSummaryUrl,
          endsWith('/api/v2/summary.json'),
          reason: forge.name,
        );
        expect(
          urls.tokenSettingsUrl,
          startsWith('https://'),
          reason: forge.name,
        );
      }
    });

    test('local builds nothing rather than a wrong link', () {
      const urls = ForgeUrls(ForgeHost.local);
      expect(urls.pullRequest('o', 'r', 1), '');
      expect(urls.commit('o', 'r', 's'), '');
      expect(urls.statusPage, '');
    });
  });
}

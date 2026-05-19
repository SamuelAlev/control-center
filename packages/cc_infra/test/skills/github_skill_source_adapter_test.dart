import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/skills/github_skill_source_adapter.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Routes GitHub REST calls to canned JSON keyed by path prefix, so the
/// adapter's tree-walking can be exercised without a network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes, {this.status = 200});

  /// path substring → response body (decoded for every matching request).
  final Map<String, Object> routes;
  final int status;
  final List<Uri> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    requests.add(uri);
    // Longest match wins: '/repos/o/r' would otherwise shadow the more
    // specific '/git/trees/…' and '/contents/…' routes of the same repo.
    final matches = routes.entries
        .where((e) => uri.path.contains(e.key))
        .toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in matches) {
      // String routes serve RAW bodies (the contents API's raw media type);
      // map/list routes are JSON endpoints.
      final body =
          entry.value is String
              ? entry.value as String
              : jsonEncode(entry.value);
      return ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    return ResponseBody.fromString('{"message": "no route"}', 404);
  }

  @override
  void close({bool force = false}) {}
}

GitHubSkillSourceAdapter _adapter(Map<String, Object> routes, {int status = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = _FakeAdapter(routes, status: status);
  return GitHubSkillSourceAdapter(GitHubApiClient(dio));
}

void main() {
  group('GitHubSkillSourceAdapter.repoSnapshot', () {
    test('maps repo metadata', () async {
      final adapter = _adapter({
        '/repos/o/r': {
          'description': 'skills!',
          'default_branch': 'trunk',
          'stargazers_count': 42,
        },
      });
      final snapshot = await adapter.repoSnapshot('o', 'r');
      expect(snapshot.owner, 'o');
      expect(snapshot.repo, 'r');
      expect(snapshot.description, 'skills!');
      expect(snapshot.defaultBranch, 'trunk');
      expect(snapshot.starCount, 42);
    });

    test('a 404 fails with a typed error naming the repo', () async {
      final adapter = _adapter(const {}, status: 404);
      await expectLater(
        adapter.repoSnapshot('o', 'gone'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.code,
            'code',
            'repo_not_found',
          ),
        ),
      );
    });
  });

  group('GitHubSkillSourceAdapter.listSkills', () {
    test('finds skills in a Claude plugin marketplace layout', () async {
      final adapter = _adapter({
        '/repos/o/r': {'default_branch': 'main'},
        '/git/trees/main': {
          'tree': [
            {'path': '.claude-plugin/marketplace.json', 'type': 'blob'},
            // The Claude plugin-marketplace shape: plugins/<plugin>/skills/<slug>.
            {'path': 'plugins/auto-bugfix/skills/fix/SKILL.md', 'type': 'blob'},
            {'path': 'plugins/auto-bugfix/skills/retrospect/SKILL.md', 'type': 'blob'},
            {'path': 'plugins/engineering/skills/pull-request/SKILL.md', 'type': 'blob'},
            // Four deep but NOT ending in skills/<slug> — still excluded.
            {'path': 'a/b/c/d/SKILL.md', 'type': 'blob'},
            // A plugin's other directory is not a skill.
            {'path': 'plugins/auto-bugfix/src/x/SKILL.md', 'type': 'blob'},
          ],
        },
        '/contents/plugins/auto-bugfix/skills/fix/SKILL.md':
            '---\nname: fix\ndescription: Fix bugs at the root cause\n---\n\n# fix',
        '/contents/plugins/auto-bugfix/skills/retrospect/SKILL.md':
            '# retrospect',
        '/contents/plugins/engineering/skills/pull-request/SKILL.md':
            '# pull-request',
      });

      final listings = await adapter.listSkills('o', 'r');

      expect(listings.map((l) => l.slug), ['fix', 'pull-request', 'retrospect']);
      final fix = listings.firstWhere((l) => l.slug == 'fix');
      expect(
        fix.skillFilePath,
        'plugins/auto-bugfix/skills/fix/SKILL.md',
      );
      expect(fix.name, 'fix');
      expect(fix.description, 'Fix bugs at the root cause');
    });

    test('finds SKILL.md dirs, dedupes slugs and parses frontmatter', () async {
      final adapter = _adapter({
        '/repos/o/r': {'default_branch': 'main'},
        '/git/trees/main': {
          'tree': [
            {'path': 'README.md', 'type': 'blob'},
            {'path': 'SKILL.md', 'type': 'blob'},
            {'path': 'skills/pdf/SKILL.md', 'type': 'blob'},
            // Same slug at a second conventional root — deduped.
            {'path': '.agents/skills/pdf/SKILL.md', 'type': 'blob'},
            {'path': 'document-skills/xlsx/SKILL.md', 'type': 'blob'},
            // Too deep — a monorepo, not a skill catalog.
            {'path': 'a/b/c/d/SKILL.md', 'type': 'blob'},
            // Vendor trees never scanned.
            {'path': 'vendor/dep/SKILL.md', 'type': 'blob'},
            {'path': 'skills/pdf/scripts/run.sh', 'type': 'blob'},
          ],
        },
        // Frontmatter probes (raw contents served per SKILL.md path).
        '/contents/skills/pdf/SKILL.md': '# pdf',
        '/contents/.agents/skills/pdf/SKILL.md': '# pdf',
        '/contents/document-skills/xlsx/SKILL.md':
            '---\nname: "Excel skills"\ndescription: Sheets magic\n---\n\n# xlsx',
      });

      final listings = await adapter.listSkills('o', 'r');

      expect(listings, hasLength(2));
      final pdf = listings.firstWhere((l) => l.slug == 'pdf');
      expect(pdf.skillFilePath, 'skills/pdf/SKILL.md');
      // No frontmatter → slug-derived defaults.
      expect(pdf.name, 'pdf');
      expect(pdf.description, '');
      final xlsx = listings.firstWhere((l) => l.slug == 'xlsx');
      expect(xlsx.name, 'Excel skills');
      expect(xlsx.description, 'Sheets magic');
    });
  });

  group('GitHubSkillSourceAdapter.resolve', () {
    test('fetches the whole skill directory at a pinned ref', () async {
      final adapter = _adapter({
        '/commits': [
          {'sha': 'c0ffee'},
        ],
        '/git/trees/c0ffee': {
          'tree': [
            {'path': 'skills/pdf/SKILL.md', 'type': 'blob'},
            {'path': 'skills/pdf/scripts/run.sh', 'type': 'blob'},
            {'path': 'skills/pdf/logo.png', 'type': 'blob'},
            {'path': 'skills/pdf/README.md', 'type': 'blob'},
            {'path': 'skills/pdf/.hidden', 'type': 'blob'},
            {'path': 'other/thing.md', 'type': 'blob'},
          ],
        },
        '/contents/skills/pdf/SKILL.md':
            '---\nname: pdf\n---\n\n# body',
        '/contents/skills/pdf/scripts/run.sh': 'echo hi',
        '/contents/skills/pdf/README.md': '# The README',
      });

      final resolved = await adapter.resolve('o', 'r', 'skills/pdf/SKILL.md');

      expect(resolved.ref, 'c0ffee');
      // Binary + hidden files skipped; only text under the skill dir.
      expect(
        resolved.files.keys,
        containsAll(<String>['SKILL.md', 'scripts/run.sh', 'README.md']),
      );
      expect(resolved.files.keys, isNot(contains('logo.png')));
      expect(resolved.files.keys, isNot(contains('.hidden')));
      // README wins over the SKILL.md body for the detail view.
      expect(resolved.readme, '# The README');
    });

    test('falls back to the SKILL.md body (frontmatter stripped)', () async {
      final adapter = _adapter({
        '/commits': [
          {'sha': 'c0ffee'},
        ],
        '/git/trees/c0ffee': {
          'tree': [
            {'path': 'skills/pdf/SKILL.md', 'type': 'blob'},
          ],
        },
        '/contents/skills/pdf/SKILL.md':
            '---\nname: pdf\ndescription: d\n---\n\n# Hello body',
      });

      final resolved = await adapter.resolve('o', 'r', 'skills/pdf/SKILL.md');
      expect(resolved.readme, '# Hello body');
    });

    test('a repo-root SKILL.md resolves as the single file it is', () async {
      final adapter = _adapter({
        '/commits': [
          {'sha': 'c0ffee'},
        ],
        '/contents/SKILL.md': '# root skill',
      });

      final resolved = await adapter.resolve('o', 'r', 'SKILL.md');
      expect(resolved.files, {'SKILL.md': '# root skill'});
      expect(resolved.ref, 'c0ffee');
    });

    test('an explicit commit SHA is used as-is (no commit probe)', () async {
      final sha = 'a' * 40;
      final fake = _FakeAdapter({
        '/git/trees/$sha': {
          'tree': [
            {'path': 'skills/pdf/SKILL.md', 'type': 'blob'},
          ],
        },
        '/contents/skills/pdf/SKILL.md': '# pinned',
      });
      final adapter = GitHubSkillSourceAdapter(
        GitHubApiClient(
          Dio(BaseOptions(baseUrl: 'https://api.github.com'))
            ..httpClientAdapter = fake,
        ),
      );

      final resolved = await adapter.resolve(
        'o',
        'r',
        'skills/pdf/SKILL.md',
        ref: sha,
      );
      expect(resolved.ref, sha);
      // No /commits probe happened.
      expect(
        fake.requests.any((u) => u.path.contains('/commits')),
        isFalse,
      );
    });
  });
}

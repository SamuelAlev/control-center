import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_infra/src/git/github_api_pr_diff_source.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200}) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

PrSourceRequest _req() => const PrSourceRequest(
  prNumber: 42,
  owner: 'acme',
  repo: 'widget',
  baseRef: 'main',
  headRef: 'feature',
  headSha: 'deadbeef',
  changedFiles: 2,
  workspaceId: 'ws',
);

Map<String, dynamic> _file(String name) => {
  'filename': name,
  'status': 'modified',
  'additions': 1,
  'deletions': 2,
  'sha': 'abc',
};

Map<String, dynamic> _commit(String sha) => {
  'sha': sha,
  'commit': {
    'message': 'msg',
    'author': {'name': 'A', 'email': 'a@x', 'date': '2025-01-01T00:00:00Z'},
  },
  'author': {'login': 'octocat'},
};

void main() {
  group('GitHubApiPrDiffSource.watchFiles', () {
    test('streams pages as a growing accumulator', () async {
      var call = 0;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((_) {
          call++;
          // Two small pages (< 100 each) then nothing.
          if (call == 1) {
            return _json([_file('a.dart'), _file('b.dart')]);
          }
          return _json(<Map<String, dynamic>>[]);
        });
      final source = GitHubApiPrDiffSource(GitHubApiClient(dio));

      final loads = await source.watchFiles(_req()).toList();

      // One page emission (page 2 is empty so no yield) + final isComplete.
      expect(loads, hasLength(2));
      expect(loads[0].files.map((f) => f.filename), ['a.dart', 'b.dart']);
      expect(loads[0].isComplete, isFalse);
      expect(loads[1].files.map((f) => f.filename), ['a.dart', 'b.dart']);
      expect(loads[1].isComplete, isTrue);
    });

    test('accumulates across multiple non-empty pages', () async {
      var call = 0;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((_) {
          call++;
          if (call == 1) {
            return _json(List.generate(100, (i) => _file('f$i.dart')));
          }
          if (call == 2) {
            return _json([_file('last.dart')]);
          }
          return _json(<Map<String, dynamic>>[]);
        });
      final source = GitHubApiPrDiffSource(GitHubApiClient(dio));

      final loads = await source.watchFiles(_req()).toList();

      // Page 1 yields 100 files, page 2 (< 100) yields 101 files, then final.
      expect(loads[0].files, hasLength(100));
      expect(loads[1].files, hasLength(101));
      expect(loads.last.isComplete, isTrue);
      expect(loads.last.files.last.filename, 'last.dart');
    });

    test('emits a single complete load when there are no files', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => _json(<Map<String, dynamic>>[]),
        );
      final source = GitHubApiPrDiffSource(GitHubApiClient(dio));

      final loads = await source.watchFiles(_req()).toList();

      // No pages yielded (empty page); only the final isComplete emission.
      expect(loads, hasLength(1));
      expect(loads.single.files, isEmpty);
      expect(loads.single.isComplete, isTrue);
    });
  });

  group('GitHubApiPrDiffSource.watchCommits', () {
    test('emits a single list of commits', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => _json([_commit('sha1'), _commit('sha2')]),
        );
      final source = GitHubApiPrDiffSource(GitHubApiClient(dio));

      final emissions = await source.watchCommits(_req()).toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.map((c) => c.sha), ['sha1', 'sha2']);
    });
  });

  group('GitHubApiPrDiffSource.watchCommitFiles', () {
    test('emits the files for the given sha', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => _json({
            'files': [_file('x.dart')],
          }),
        );
      final source = GitHubApiPrDiffSource(GitHubApiClient(dio));

      final emissions = await source
          .watchCommitFiles(_req(), 'abc123')
          .toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.single.filename, 'x.dart');
    });
  });
}

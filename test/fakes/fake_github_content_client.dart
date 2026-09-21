import 'dart:typed_data';

import 'package:cc_infra/src/network/github_content_client.dart';
import 'package:dio/dio.dart';

/// In-memory fake [GitHubContentClient] for testing protocol handlers.
class FakeGitHubContentClient extends GitHubContentClient {
  FakeGitHubContentClient() : super(_fakeDio);

  static final _fakeDio = _NullDio();

  /// File content by "$owner/$repo/$path@$ref".
  final Map<String, String> files = {};

  /// Record of the last call's arguments for assertion.
  ({String owner, String repo, String path, String ref})? lastCall;

  @override
  Future<String> getFileContent(
    String owner,
    String repo,
    String path,
    String ref, {
    CancelToken? cancelToken,
  }) async {
    lastCall = (owner: owner, repo: repo, path: path, ref: ref);
    return files['$owner/$repo/$path@$ref'] ?? '';
  }

  /// Bytes keyed like [files].
  final Map<String, Uint8List> bytes = {};

  @override
  Future<Uint8List> getFileBytes(
    String owner,
    String repo,
    String path,
    String ref, {
    CancelToken? cancelToken,
  }) async {
    lastCall = (owner: owner, repo: repo, path: path, ref: ref);
    return bytes['$owner/$repo/$path@$ref'] ?? Uint8List(0);
  }
}

/// A Dio instance that never gets called — all methods are overridden.
class _NullDio implements Dio {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('FakeGitHubContentClient should not reach Dio');
}

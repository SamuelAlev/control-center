import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/network/error_mapper.dart';
import 'package:control_center/core/network/models/github_user.dart';
import 'package:dio/dio.dart';

/// Client for GitHub content and user operations that don't target a specific PR.
class GitHubContentClient {
  /// Creates a [GitHubContentClient] backed by [Dio].
  GitHubContentClient(this._dio);

  final Dio _dio;

  /// Fetches the raw contents of a single file at a specific [ref] (branch
  /// name, tag, or commit SHA). Used by the diff viewer for context-expansion.
  Future<String> getFileContent(
    String owner,
    String repo,
    String path,
    String ref, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/contents/$path',
        queryParameters: {'ref': ref},
        options: Options(
          headers: {'Accept': 'application/vnd.github.raw'},
          responseType: ResponseType.plain,
        ),
        cancelToken: cancelToken,
      );
      return response.data?.toString() ?? '';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Creates a git blob in [owner]/[repo].
  ///
  /// Returns the blob SHA. Note: a blob SHA cannot be used directly in a
  /// raw.githubusercontent.com URL (those require a branch/tag/commit ref).
  Future<String> createBlob(
    String owner,
    String repo,
    String base64Content, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/git/blobs',
        data: {'content': base64Content, 'encoding': 'base64'},
        cancelToken: cancelToken,
      );
      return (response.data as Map<String, dynamic>)['sha'] as String;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Creates or updates a file in [owner]/[repo] at [path] with [base64Content].
  ///
  /// Returns the `download_url` from the created content, which is a real
  /// `raw.githubusercontent.com` URL that can be embedded in markdown.
  Future<String> createFileContent(
    String owner,
    String repo,
    String path,
    String base64Content,
    String message, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.put(
        '$githubApiBaseUrl/repos/$owner/$repo/contents/$path',
        data: {'message': message, 'content': base64Content},
        cancelToken: cancelToken,
      );
      final data = response.data as Map<String, dynamic>;
      final content = data['content'] as Map<String, dynamic>?;
      final downloadUrl = content?['download_url'] as String?;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw const NetworkException(
          'GitHub did not return a download_url',
          code: 'missing_download_url',
        );
      }
      return downloadUrl;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Fetches the authenticated user's profile.
  Future<GitHubUser?> getAuthenticatedUser({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/user',
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubUser.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Fetches a GitHub user's profile by login via the REST API.
  ///
  /// Returns [GitHubUser] with login, avatarUrl, name, and bio if available.
  /// This is a simpler REST fallback that does not include contribution data.
  Future<GitHubUser?> getUserByLogin(
    String login, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/users/$login',
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubUser.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Fetches the repository permission level for [username].
  ///
  /// Returns one of: "admin", "write", "read", "none".
  Future<String> getCollaboratorPermission(
    String owner,
    String repo,
    String username, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/collaborators/$username/permission',
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['permission'] as String?) ?? 'none';
      }
      return 'none';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Fetches public members of the GitHub organization [org].
  ///
  /// Paginates up to 100 members. Returns an empty list on 404 (the owner may
  /// be a user, not an org) or on other non-catastrophic errors.
  Future<List<GitHubUser>> getOrganizationMembers(
    String org, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/orgs/$org/members',
        queryParameters: {'per_page': 100},
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(GitHubUser.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      // 404 = not an org or no access; return empty rather than crashing.
      if (e.response?.statusCode == 404) {
        return const [];
      }
      throw mapDioException(e);
    }
  }

  void _requireOwnerRepo(String owner, String repo) {
    if (owner.isEmpty || repo.isEmpty) {
      throw ArgumentError('owner and repo must not be empty');
    }
  }
}

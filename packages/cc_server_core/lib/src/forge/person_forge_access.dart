import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_infra/cc_infra.dart' show httpJsonBody, mapHttpException;
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
import 'package:rhttp/rhttp.dart';

/// [PersonForgeAccess] over the server's credential seams: every read rides
/// the person's OWN sign-in for the workspace and nothing else.
///
/// * GitHub: the person's App user token lists the installations it can see
///   (`GET /user/installations`) and, under the owners of the repos asked
///   about, their repositories (`GET /user/installations/{id}/repositories`,
///   paginated). A repo no installation covers (a public repo, an owner
///   without the App) is asked directly (`GET /repos/{owner}/{repo}`).
/// * GitLab and Bitbucket: the person's own token reads each repo's open
///   list fingerprint (one small request per repo).
final class ServerPersonForgeAccess implements PersonForgeAccess {
  /// Creates the access reader.
  ///
  /// `personToken` is the person's own credential for a forge in a
  /// workspace (never a fallback); `githubPersonHttp` the GitHub client that
  /// sends exactly that credential (`GitHubClients.personHttp`);
  /// `personClientFor` a GitLab/Bitbucket PR client acting as the person.
  const ServerPersonForgeAccess({
    required this._personToken,
    required this._githubPersonHttp,
    required this._personClientFor,
    required this._viewerLogin,
    required this._githubTeams,
  });

  /// Pages read per installation before the rest is asked repo by repo.
  static const int _maxRepoPages = 20;

  /// Direct per-repo reads in flight at once for one person.
  static const int _perRepoConcurrency = 4;

  final Future<String?> Function(
    ForgeHost forge,
    String userId,
    String workspaceId,
  )
  _personToken;
  final RhttpClient Function(String userId, String workspaceId)
  _githubPersonHttp;
  final ForgePrClient Function(
    Repo repo, {
    required String workspaceId,
    required String userId,
  })
  _personClientFor;
  final Future<String> Function(
    ForgeHost forge,
    String userId,
    String workspaceId,
  )
  _viewerLogin;
  final Future<Map<String, Set<String>>?> Function(
    String userId,
    String workspaceId,
  )
  _githubTeams;

  @override
  Future<String> viewerLogin(
    String workspaceId,
    String userId,
    ForgeHost forge,
  ) async {
    if (!forge.isSupported) {
      return '';
    }
    return _viewerLogin(forge, userId, workspaceId);
  }

  @override
  Future<Map<String, Set<String>>> githubTeams(
    String workspaceId,
    String userId,
  ) async => await _githubTeams(userId, workspaceId) ?? const {};

  @override
  Future<Set<String>?> readableRepoIds(
    String workspaceId,
    String userId,
    ForgeHost forge,
    List<Repo> repos,
  ) async {
    if (!forge.isSupported || repos.isEmpty) {
      return const {};
    }
    final token = await _personToken(forge, userId, workspaceId);
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      return forge == ForgeHost.github
          ? await _githubReadable(workspaceId, userId, repos)
          : await _perRepoReadable(workspaceId, userId, repos);
    } on _CredentialRefused {
      return null;
    }
  }

  // --- GitHub ----------------------------------------------------------------

  Future<Set<String>> _githubReadable(
    String workspaceId,
    String userId,
    List<Repo> repos,
  ) async {
    final http = _githubPersonHttp(userId, workspaceId);
    final wanted = {for (final r in repos) r.fullName.toLowerCase(): r.id};
    final owners = {for (final r in repos) r.remoteOwner.toLowerCase()};
    final readable = <String>{};

    final installations = await _paged(
      http,
      '/user/installations',
      'installations',
    );
    for (final install in installations) {
      final account = install['account'];
      final login = account is Map ? account['login'] as String? : null;
      final id = install['id'];
      if (login == null || id is! num || !owners.contains(login.toLowerCase())) {
        continue;
      }
      final listed = await _paged(
        http,
        '/user/installations/${id.toInt()}/repositories',
        'repositories',
      );
      for (final repo in listed) {
        final name = (repo['full_name'] as String? ?? '').toLowerCase();
        final repoId = wanted[name];
        if (repoId != null) {
          readable.add(repoId);
        }
      }
    }

    final rest = [
      for (final r in repos)
        if (!readable.contains(r.id)) r,
    ];
    await _bounded(rest, (repo) async {
      try {
        await http.get('/repos/${repo.remoteOwner}/${repo.remoteName}');
        readable.add(repo.id);
      } on RhttpException catch (e) {
        if (!_isDenial(_mapped(e))) {
          rethrow;
        }
      }
    });
    return readable;
  }

  /// Every item under [field] of [path]'s pages (100 per page, at most
  /// [_maxRepoPages] pages).
  Future<List<Map<String, dynamic>>> _paged(
    RhttpClient http,
    String path,
    String field,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (var page = 1; page <= _maxRepoPages; page++) {
      final HttpTextResponse response;
      try {
        response = await http.get(
          path,
          query: {'per_page': '100', 'page': '$page'},
        );
      } on RhttpException catch (e) {
        _mapped(e);
        rethrow;
      }
      final body = httpJsonBody(response);
      final items = body is Map ? body[field] : null;
      if (items is! List) {
        break;
      }
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          out.add(item);
        }
      }
      if (items.length < 100) {
        break;
      }
    }
    return out;
  }

  // --- GitLab / Bitbucket ----------------------------------------------------

  Future<Set<String>> _perRepoReadable(
    String workspaceId,
    String userId,
    List<Repo> repos,
  ) async {
    final readable = <String>{};
    await _bounded(repos, (repo) async {
      final client = _personClientFor(
        repo,
        workspaceId: workspaceId,
        userId: userId,
      );
      try {
        if (client is ForgeOpenPrChangeProbeClient) {
          await (client as ForgeOpenPrChangeProbeClient)
              .openPullRequestsFingerprint();
        } else {
          await client.listOpenPullRequests(limit: 1);
        }
        readable.add(repo.id);
      } on RhttpException catch (e) {
        if (!_isDenial(_mapped(e))) {
          rethrow;
        }
      } on NetworkException catch (e) {
        if (e.statusCode == 401) {
          throw const _CredentialRefused();
        }
        if (!_isDenial(e)) {
          rethrow;
        }
      }
    });
    return readable;
  }

  // --- Shared ----------------------------------------------------------------

  /// [e] as a [NetworkException]; a 401 (the forge refused the credential
  /// itself) aborts the whole listing as "not signed in".
  static NetworkException _mapped(RhttpException e) {
    final mapped = mapHttpException(e);
    if (mapped.statusCode == 401) {
      throw const _CredentialRefused();
    }
    return mapped;
  }

  static bool _isDenial(NetworkException e) => isForgeRepoDenial(e);

  static Future<void> _bounded(
    List<Repo> repos,
    Future<void> Function(Repo repo) each,
  ) async {
    for (var i = 0; i < repos.length; i += _perRepoConcurrency) {
      await Future.wait(repos.skip(i).take(_perRepoConcurrency).map(each));
    }
  }
}

/// Whether [e] answers "this credential cannot see that repository" for
/// good, so the repository is listed as unreadable: a 404, or a 403 that
/// refuses access (SAML single sign-on not authorized among them). A 401
/// never gets here (the whole listing reads "not signed in").
///
/// Anything else says nothing about access and must not be remembered as a
/// denial: a rate limit (a 429, or a 403 carrying one), a 5xx, a suspended
/// installation, a timeout or a dropped connection. Those fail the listing,
/// which keeps its previous answer while fresh, otherwise fails closed, and
/// is retried soon.
bool isForgeRepoDenial(NetworkException e) {
  if (e.code == 'not_found' || e.statusCode == 404) {
    return true;
  }
  if (e.code != 'auth_error' || e.statusCode != 403) {
    return false;
  }
  final body = (e.responseBody ?? '').toLowerCase();
  return !body.contains('rate limit');
}

/// The forge refused the person's credential outright (401).
final class _CredentialRefused implements Exception {
  const _CredentialRefused();
}

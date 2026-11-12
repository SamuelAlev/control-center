import 'dart:io';

import 'package:test/test.dart';

/// CI ratchet for the server's forge identity and child-process boundaries.
///
/// Server code never:
///
/// 1. spawns a process outside `ChildProcess` (allowlisted environment, never
///    the parent's), except at the few chokepoints listed below — and every
///    one of those that is not the server's own launch passes an exact
///    environment (`includeParentEnvironment: false`);
/// 2. spreads `Platform.environment` into anything, or inherits it with
///    `includeParentEnvironment: true`;
/// 3. invokes `git` outside the isolated git helper (`IsolatedGit`);
/// 4. names `GH_TOKEN`/`GITHUB_TOKEN` outside the strip list and the files
///    that carry a minted one-repo token;
/// 5. builds an authenticated GitHub client, a `ForgeHttpClientFactory`, or
///    a hand-rolled authenticated request to a GitHub host outside
///    `GitHubClients` and the cc_infra transport primitives;
/// 6. builds a `ForgeHttpClientFactory` without a `requestGuard`, except a
///    person's own client (a person may approve; automation may not);
/// 7. builds git's HTTP credentials by hand (a Basic `x-access-token`
///    header, an `extraHeader` Authorization) instead of through
///    `forgeGitAuthConfigParameter`/`forgeGitHttpAuth`, hard-codes a
///    `https://github.com/<owner>/<repo>.git` remote, or builds a GitLab or
///    Bitbucket API client over anything but an authenticated forge client.
///
/// Every allowlist entry says why. An entry that no longer matches anything
/// fails too, so the lists only shrink.
void main() {
  final root = _repoRoot();
  final sources = _serverSources(root);

  test('the scan covers the server packages', () {
    expect(sources, isNotEmpty);
    for (final must in const [
      'packages/cc_server_core/lib/src/cc_server_runtime.dart',
      'packages/cc_infra/lib/src/process/child_process.dart',
      'packages/cc_natives/lib/src/git/isolated_git.dart',
      'apps/cc_server/bin/cc_server.dart',
    ]) {
      expect(sources.keys, contains(must));
    }
  });

  group('child processes', () {
    test('no raw Process spawn outside the chokepoints', () {
      final offenders = <String>[];
      for (final MapEntry(key: path, value: text) in sources.entries) {
        final spawns = _rawSpawn.allMatches(text).length;
        if (spawns == 0) {
          continue;
        }
        final allowed = _rawSpawnAllowlist[path];
        if (allowed == null) {
          offenders.add('$path: $spawns raw Process spawn(s)');
          continue;
        }
        if (allowed.exactEnvironment &&
            _exactEnvironment.allMatches(text).length < spawns) {
          offenders.add(
            '$path: every spawn here must pass '
            'includeParentEnvironment: false',
          );
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'Spawn through ChildProcess (cc_infra) so the child gets the '
            'allowlisted ChildEnvironment, or IsolatedGit for git.',
      );
    });

    test('nothing spreads or inherits the parent environment', () {
      final offenders = [
        for (final MapEntry(key: path, value: text) in sources.entries)
          for (final m in _parentEnvironment.allMatches(text)) '$path: ${m[0]}',
      ];
      expect(
        offenders,
        isEmpty,
        reason: 'Build child environments with ChildEnvironment.build.',
      );
    });

    test('git runs only through the isolated helper', () {
      final offenders = [
        for (final MapEntry(key: path, value: text) in sources.entries)
          if (path != _isolatedGit && _gitSpawn.hasMatch(text)) path,
      ];
      expect(
        offenders,
        isEmpty,
        reason:
            'Use IsolatedGit (no global/system config, no credential helper, '
            'no SSH agent).',
      );
      // The environment runner's argv path is the one indirect git caller:
      // it must keep routing a literal `git` argv to the helper.
      expect(
        sources['packages/cc_infra/lib/src/environments/environment_command_runner.dart'],
        allOf(
          contains('IsolatedGit.args('),
          contains('IsolatedGit.environmentFor('),
        ),
      );
    });
  });

  group('GitHub identity', () {
    test('GitHub token variables are named only where a minted token is '
        'carried, or stripped', () {
      final offenders = <String>[];
      for (final MapEntry(key: path, value: text) in sources.entries) {
        if (!_githubTokenName.hasMatch(text)) {
          continue;
        }
        if (!_githubTokenNameAllowlist.containsKey(path)) {
          offenders.add(path);
        }
        if (_hostGitHubTokenRead.hasMatch(text)) {
          offenders.add('$path reads a GitHub token from the host environment');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'Host GH_TOKEN/GITHUB_TOKEN are never read; GitHub credentials '
            'come from GitHubClients and the credential broker.',
      );
    });

    test('authenticated GitHub clients are built only by GitHubClients and '
        'the transport primitives', () {
      final offenders = <String>[];
      for (final MapEntry(key: path, value: text) in sources.entries) {
        final builds = _clientConstruction.hasMatch(text);
        final handRolled =
            _githubHost.hasMatch(text) && _authHeader.hasMatch(text);
        if (builds && !_clientConstructionAllowlist.containsKey(path)) {
          offenders.add('$path constructs a GitHub client or factory');
        }
        if (handRolled && !_handRolledAuthAllowlist.containsKey(path)) {
          offenders.add('$path sends its own Authorization to GitHub');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Ask GitHubClients (asPerson / forOwner) for a client.',
      );
    });

    test('git credentials, GitHub remotes and GitLab/Bitbucket clients are '
        'built only at their chokepoints', () {
      final offenders = <String>[];
      for (final MapEntry(key: path, value: text) in sources.entries) {
        for (final (rule, detector, allowlist) in _forgeChokepoints) {
          if (detector.hasMatch(text) && !allowlist.containsKey(path)) {
            offenders.add('$path: $rule');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'Git credentials go through forgeGitAuthConfigParameter (one '
            'username per forge, every token shape); remotes through '
            "the forge's gitHost; GitLab/Bitbucket clients through "
            'forge_provider_factories over the per-actor or automation client.',
      );
    });

    test('every automation client is built with a request guard', () {
      final offenders = <String>[];
      for (final MapEntry(key: path, value: text) in sources.entries) {
        final built = _factoryConstruction.allMatches(text).length;
        if (built == 0) {
          continue;
        }
        final guarded = _requestGuard.allMatches(text).length;
        final unguarded = _unguardedFactoryAllowlist[path]?.count ?? 0;
        if (built - guarded > unguarded) {
          offenders.add(
            '$path: $built factories, $guarded guarded, $unguarded allowed '
            'without one',
          );
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'An automation client confines its requests to its repository and '
            'never approves: pass requestGuard (refuseForgeAutomationRequest, '
            'or the GitHub request policy).',
      );
    });
  });

  test('every allowlist entry still matches, so the lists only shrink', () {
    final stale = <String>[];
    void check(
      Map<String, Object> allowlist,
      bool Function(String text) matches,
      String rule,
    ) {
      for (final path in allowlist.keys) {
        final text = sources[path];
        if (text == null || !matches(text)) {
          stale.add('$rule: $path');
        }
      }
    }

    check(_rawSpawnAllowlist, _rawSpawn.hasMatch, 'raw spawn');
    check(_githubTokenNameAllowlist, _githubTokenName.hasMatch, 'token name');
    check(
      _clientConstructionAllowlist,
      _clientConstruction.hasMatch,
      'client construction',
    );
    check(
      _handRolledAuthAllowlist,
      (t) => _githubHost.hasMatch(t) && _authHeader.hasMatch(t),
      'hand-rolled auth',
    );
    for (final (rule, detector, allowlist) in _forgeChokepoints) {
      check(allowlist, detector.hasMatch, rule);
    }
    for (final MapEntry(key: path, value: allowed)
        in _unguardedFactoryAllowlist.entries) {
      final text = sources[path] ?? '';
      if (_factoryConstruction.allMatches(text).length -
              _requestGuard.allMatches(text).length <
          allowed.count) {
        stale.add('unguarded factory: $path');
      }
    }
    expect(stale, isEmpty, reason: 'Remove the entries that no longer apply.');
  });

  group('detectors still match what they guard against', () {
    test('raw spawns, not ChildProcess', () {
      expect(_rawSpawn.hasMatch("await Process.start('x', []);"), isTrue);
      expect(_rawSpawn.hasMatch('Process.runSync(cmd, args)'), isTrue);
      expect(_rawSpawn.hasMatch("ChildProcess.run('x', [])"), isFalse);
    });

    test('parent environment', () {
      expect(_parentEnvironment.hasMatch('{...Platform.environment}'), isTrue);
      expect(
        _parentEnvironment.hasMatch('includeParentEnvironment: true'),
        isTrue,
      );
      expect(
        _parentEnvironment.hasMatch('Map.of(Platform.environment)'),
        isTrue,
      );
      expect(
        _parentEnvironment.hasMatch("Platform.environment['HOME']"),
        isFalse,
      );
    });

    test('git spawns, across lines', () {
      expect(_gitSpawn.hasMatch("Process.run('git', ['status'])"), isTrue);
      expect(
        _gitSpawn.hasMatch("ChildProcess.start(\n  'git',\n  args)"),
        isTrue,
      );
      expect(_gitSpawn.hasMatch("ChildProcess.run('/usr/bin/git', a)"), isTrue);
      expect(_gitSpawn.hasMatch("IsolatedGit.run(['status'])"), isFalse);
    });

    test('token names and host reads', () {
      expect(_githubTokenName.hasMatch("env['GH_TOKEN']"), isTrue);
      expect(_githubTokenName.hasMatch('"GITHUB_TOKEN"'), isTrue);
      expect(_githubTokenName.hasMatch("r'|GITHUB_TOKEN|X'"), isFalse);
      expect(
        _hostGitHubTokenRead.hasMatch("Platform.environment['GITHUB_TOKEN']"),
        isTrue,
      );
      expect(_hostGitHubTokenRead.hasMatch("serverEnv['GH_TOKEN']"), isTrue);
      expect(
        _hostGitHubTokenRead.hasMatch("minted.environment['GH_TOKEN']"),
        isFalse,
      );
    });

    test('git credentials, GitHub remotes and forge clients', () {
      expect(
        _handBuiltGitAuth.hasMatch("utf8.encode('x-access-token:\$token')"),
        isTrue,
      );
      expect(
        _handBuiltGitAuth.hasMatch(
          "'http.https://gitlab.com/.extraHeader=Authorization: Basic \$b'",
        ),
        isTrue,
      );
      expect(
        _handBuiltGitAuth.hasMatch("('http.\$base.extraHeader', header)"),
        isTrue,
      );
      expect(_handBuiltGitAuth.hasMatch('forgeGitHttpAuth(forge, t)'), isFalse);
      expect(
        _githubGitRemote.hasMatch("'https://github.com/\$owner/\$repo.git'"),
        isTrue,
      );
      expect(
        _githubGitRemote.hasMatch(
          "'https://github.com/\${repo.remoteOwner}/\${repo.remoteName}.git'",
        ),
        isTrue,
      );
      expect(
        _githubGitRemote.hasMatch("'https://github.com/\$owner/\$repo'"),
        isFalse,
      );
      expect(_forgeApiClient.hasMatch('GitLabApiClient(http)'), isTrue);
      expect(_forgeApiClient.hasMatch('BitbucketApiClient(\n'), isTrue);
    });

    test('client construction and hand-rolled auth', () {
      expect(_clientConstruction.hasMatch('GitHubApiClient(http)'), isTrue);
      expect(_clientConstruction.hasMatch('ForgeHttpClientFactory(\n'), isTrue);
      expect(_clientConstruction.hasMatch('GitHubApiClient get x'), isFalse);
      expect(_githubHost.hasMatch("'https://api.github.com/user'"), isTrue);
      expect(_authHeader.hasMatch("'Bearer \$token'"), isTrue);
      expect(_authHeader.hasMatch('HttpHeaders.authorizationHeader'), isTrue);
    });
  });
}

// --- Detectors -------------------------------------------------------------

/// `Process.start/run/runSync(` — `ChildProcess.` does not match (`\b`).
final RegExp _rawSpawn = RegExp(r'\bProcess\s*\.\s*(?:start|run|runSync)\s*\(');

/// One exact-environment spawn argument.
final RegExp _exactEnvironment = RegExp(
  r'includeParentEnvironment\s*:\s*false',
);

/// The parent's environment reaching a child wholesale.
final RegExp _parentEnvironment = RegExp(
  r'\.\.\.\??\s*Platform\.environment\b'
  r'|includeParentEnvironment\s*:\s*true'
  r'|Map(?:<[^>]*>)?\.(?:of|from)\(\s*Platform\.environment\s*\)',
);

/// A process whose executable is git.
final RegExp _gitSpawn = RegExp(
  r'''(?:\bProcess|ChildProcess)\s*\.\s*(?:start|run|runSync)\s*\(\s*'''
  r'''['"](?:git|git\.exe|/usr/bin/git|/usr/local/bin/git|/opt/homebrew/bin/git)['"]''',
);

/// A GitHub token variable named as a whole string literal.
final RegExp _githubTokenName = RegExp(
  r'''['"](?:GH_TOKEN|GITHUB_TOKEN|GH_ENTERPRISE_TOKEN|GITHUB_ENTERPRISE_TOKEN)['"]''',
);

/// Reading one of those from the host (process or `.env`-layered) map.
final RegExp _hostGitHubTokenRead = RegExp(
  r'''(?:Platform\.environment|serverEnv|environmentWithDotenv\(\))\s*\[\s*'''
  r'''['"](?:GH_TOKEN|GITHUB_TOKEN|GH_ENTERPRISE_TOKEN|GITHUB_ENTERPRISE_TOKEN)['"]''',
);

/// Construction of an authenticated GitHub client or the forge HTTP factory.
final RegExp _clientConstruction = RegExp(
  r'\b(?:GitHubApiClient|GitHubAppClient|GitHubPrClient|GitHubContentClient'
  r'|ForgeHttpClientFactory)\s*\(',
);

/// Construction of the forge HTTP factory (or its declaration).
final RegExp _factoryConstruction = RegExp(r'\bForgeHttpClientFactory\s*\(');

/// A request guard handed to that factory.
final RegExp _requestGuard = RegExp(r'\brequestGuard\s*:');

/// A GitHub API host.
final RegExp _githubHost = RegExp(
  r'api\.github\.com|uploads\.github\.com|raw\.githubusercontent\.com'
  r'|github\.com/login/oauth',
);

/// An Authorization header set by hand.
final RegExp _authHeader = RegExp(
  r'''['"]Authorization['"]|authorizationHeader|['"]Bearer |['"]token \$''',
);

/// Git HTTP credentials built by hand.
final RegExp _handBuiltGitAuth = RegExp(
  r'''x-access-token:|extraHeader=Authorization|\.extraHeader['"]''',
);

/// A GitHub git remote spelled out with its owner and repository.
final RegExp _githubGitRemote = RegExp(
  r'https://github\.com/\$\{?[\w.]+\}?/\$\{?[\w.]+\}?\.git',
);

/// Construction of a GitLab or Bitbucket API client.
final RegExp _forgeApiClient = RegExp(
  r'\b(?:GitLabApiClient|BitbucketApiClient)\s*\(',
);

// --- Allowlists ------------------------------------------------------------

/// Each forge chokepoint: the rule, its detector and the files allowed to
/// match it (and why).
final List<(String, RegExp, Map<String, String>)> _forgeChokepoints = [
  ('hand-built git credentials', _handBuiltGitAuth, _handBuiltGitAuthAllowlist),
  ('hard-coded GitHub remote', _githubGitRemote, _githubGitRemoteAllowlist),
  ('GitLab/Bitbucket client', _forgeApiClient, _forgeApiClientAllowlist),
];

const Map<String, String> _handBuiltGitAuthAllowlist = {
  'packages/cc_infra/lib/src/util/command_redaction.dart':
      'Redacts such credentials from logged command lines.',
  'packages/cc_infra/lib/src/dispatch/agent_run_gateway.dart':
      "The run's lease secret rides an extraHeader scoped to the gateway's "
      'own URL; it carries no forge credential.',
};

const Map<String, String> _githubGitRemoteAllowlist = {
  'packages/cc_infra/lib/src/pr_review/pr_clone_manager.dart':
      'Pull request clones are GitHub-only by design; the remote is clean '
      '(no credential), auth rides forgeGitAuthConfigParameter.',
};

const Map<String, String> _forgeApiClientAllowlist = {
  'packages/cc_infra/lib/src/network/gitlab/gitlab_api_client.dart':
      'The class itself.',
  'packages/cc_infra/lib/src/network/bitbucket/bitbucket_api_client.dart':
      'The class itself.',
  'packages/cc_server_core/lib/src/forge/forge_provider_factories.dart':
      'Wraps the RhttpClient its caller authenticated (per-actor or '
      'automation); holds no credential of its own.',
  'packages/cc_server_core/lib/src/runtime/server_forge_wiring.dart':
      "GitLab's merged-history search over the person's own per-actor "
      'client.',
};

const String _isolatedGit = 'packages/cc_natives/lib/src/git/isolated_git.dart';

typedef _Spawn = ({bool exactEnvironment, String why});

const Map<String, _Spawn> _rawSpawnAllowlist = {
  'packages/cc_infra/lib/src/process/child_process.dart': (
    exactEnvironment: true,
    why: 'The chokepoint: every call passes ChildEnvironment.build.',
  ),
  _isolatedGit: (
    exactEnvironment: true,
    why:
        'The git chokepoint (cc_natives cannot depend on cc_infra): '
        'isolation env over ChildEnvironment.',
  ),
  'packages/cc_mcp_client/lib/src/transports/stdio_transport.dart': (
    exactEnvironment: true,
    why:
        'cc_mcp_client depends only on cc_domain: builds ChildEnvironment '
        'itself for a third-party MCP server.',
  ),
  'packages/cc_mcp_client/lib/src/process/terminate_process_tree.dart': (
    exactEnvironment: true,
    why: 'pkill for the MCP child tree; ChildEnvironment base only.',
  ),
  'packages/cc_infra/lib/src/process/cc_server_process.dart': (
    exactEnvironment: false,
    why:
        'The desktop launching cc_server itself. The server is the trust '
        'root: it builds every child environment from the real one and its '
        'boot refusal must see what was exported.',
  ),
};

const Map<String, String> _githubTokenNameAllowlist = {
  'packages/cc_domain/lib/features/sandboxing/domain/child_environment.dart':
      'The strip list: host GitHub tokens never reach a child.',
  'packages/cc_infra/lib/src/dispatch/agent_run_forge_tokens.dart':
      "The key of the broker's minted token; read from the minted "
      'ScopedCredentials, never the host, and never placed in a run\'s '
      'environment.',
  'packages/cc_server_core/lib/src/forge/github_scoped_broker.dart':
      'Places a minted one-repo token in the child environment it is for.',
  'packages/cc_infra/lib/src/rigs/guest_credential_service.dart':
      'Names the minted token inside a rig guest.',
};

const Map<String, String> _clientConstructionAllowlist = {
  'packages/cc_server_core/lib/src/forge/github_clients.dart':
      'GitHubClients: the one place a GitHub identity is chosen.',
  'packages/cc_infra/lib/src/network/github_api_client.dart':
      'Transport primitive: composes the PR/content clients over the '
      'RhttpClient it is handed.',
  'packages/cc_infra/lib/src/network/github_pr_client.dart':
      'Transport primitive: the class itself.',
  'packages/cc_infra/lib/src/network/github_content_client.dart':
      'Transport primitive: the class itself.',
  'packages/cc_infra/lib/src/network/forge_http_client_factory.dart':
      'Transport primitive: the class itself.',
  'packages/cc_infra/lib/src/network/github/github_app_client.dart':
      'Transport primitive: the App JWT client and its factory.',
  'packages/cc_server_core/lib/src/forge/forge_provider_factories.dart':
      'Wraps an RhttpClient its caller already authenticated (GitHubClients '
      'or the per-actor factory); holds no credential of its own.',
  'packages/cc_server_core/lib/src/runtime/server_forge_wiring.dart':
      "_ForgeHttpClients.forActor (the runtime's "
      'forgeHttpClientFactoryForActor): GitLab and Bitbucket only. Its GitHub '
      'lookup always returns null; a person reaches GitHub through '
      'GitHubClients.personHttp and automation through httpForOwner.',
};

const Map<String, String> _handRolledAuthAllowlist = {
  'packages/cc_server_core/lib/src/forge/github_rest.dart':
      "GitHubClients' REST transport: the App-authenticated /applications "
      'calls, the bare reads that bound a mint, and revocation. Callers '
      'hand it the credential GitHubClients chose.',
  'packages/cc_infra/lib/src/network/github/github_app_client.dart':
      'Transport primitive: App JWT requests.',
  'packages/cc_server_core/lib/src/runtime/server_helpers.dart':
      "The media proxy fetches a private GitHub attachment with the viewer's "
      'own person token in effect for the viewed workspace, for GitHub hosts '
      'only.',
};

/// Files that build a `ForgeHttpClientFactory` without a request guard, and
/// how many.
const Map<String, ({int count, String why})> _unguardedFactoryAllowlist = {
  'packages/cc_infra/lib/src/network/forge_http_client_factory.dart': (
    count: 1,
    why: 'The class itself.',
  ),
  'packages/cc_server_core/lib/src/forge/github_clients.dart': (
    count: 1,
    why: "personHttp: a person's own GitHub client (a person may approve).",
  ),
  'packages/cc_server_core/lib/src/runtime/server_forge_wiring.dart': (
    count: 1,
    why:
        "forActor: a person's own GitLab/Bitbucket client; without a person "
        'it sends nothing.',
  ),
};

// --- Sources ---------------------------------------------------------------

/// Server-side source roots, relative to the repo root.
const List<String> _serverRoots = [
  'packages/cc_domain/lib',
  'packages/cc_natives/lib',
  'packages/cc_infra/lib',
  'packages/cc_persistence/lib',
  'packages/cc_server_core/lib',
  'packages/cc_host/lib',
  'packages/cc_mcp/lib',
  'packages/cc_mcp_client/lib',
  'packages/cc_harness/lib',
  'packages/cc_harness_runtime/lib',
  'packages/cc_rpc/lib',
  'apps/cc_server/bin',
  'apps/cc_server/lib',
  'apps/cc_demo_server/bin',
  'apps/cc_demo_server/lib',
];

Directory _repoRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/packages/cc_server_core/pubspec.yaml').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('repo root not found from ${Directory.current.path}');
    }
    dir = parent;
  }
}

/// Repo-relative path → source with whole-line comments removed (doc
/// comments name forbidden calls to explain why they are forbidden).
Map<String, String> _serverSources(Directory root) {
  final out = <String, String>{};
  for (final rel in _serverRoots) {
    final dir = Directory('${root.path}/$rel');
    if (!dir.existsSync()) {
      continue;
    }
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final path = entity.path.substring(root.path.length + 1);
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
        continue;
      }
      out[path] = entity
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
    }
  }
  return out;
}

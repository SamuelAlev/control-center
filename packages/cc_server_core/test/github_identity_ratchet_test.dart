import 'dart:io';

import 'package:test/test.dart';

/// CI ratchet for the server's GitHub identity and child-process boundaries
/// (CONNECT_PLAN §5.14, I6, I23).
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
///    `GitHubClients` and the cc_infra transport primitives.
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

/// A GitHub API host.
final RegExp _githubHost = RegExp(
  r'api\.github\.com|uploads\.github\.com|raw\.githubusercontent\.com'
  r'|github\.com/login/oauth',
);

/// An Authorization header set by hand.
final RegExp _authHeader = RegExp(
  r'''['"]Authorization['"]|authorizationHeader|['"]Bearer |['"]token \$''',
);

// --- Allowlists ------------------------------------------------------------

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
  'packages/cc_harness_runtime/lib/src/shell_agent_loop_hooks.dart': (
    exactEnvironment: true,
    why:
        'cc_harness_runtime has no cc_domain dependency: the caller hands '
        'the hook its whole ChildEnvironment.',
  ),
  'packages/cc_harness_runtime/lib/src/file_provider_credential_store.dart': (
    exactEnvironment: true,
    why: '/bin/chmod with an empty environment.',
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
  'packages/cc_infra/lib/src/dispatch/agent_run_gateway.dart':
      "The name of the broker's minted token in a run's env; read from the "
      'minted ScopedCredentials, never the host.',
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
  'packages/cc_server_core/lib/src/cc_server_runtime.dart':
      'forgeHttpClientFactoryForActor: GitLab and Bitbucket only. Its GitHub '
      'lookup always returns null; a person reaches GitHub through '
      'GitHubClients.personHttp and automation through httpForOwner.',
};

const Map<String, String> _handRolledAuthAllowlist = {
  'packages/cc_server_core/lib/src/forge/github_clients.dart':
      'GitHubClients itself.',
  'packages/cc_infra/lib/src/network/github/github_app_client.dart':
      'Transport primitive: App JWT requests.',
  'packages/cc_server_core/lib/src/forge/forge_viewer_probe.dart':
      'Identifies the bearer of a token a person just supplied, before it '
      'is stored.',
  'packages/cc_server_core/lib/src/connect/github_sign_in_lane.dart':
      'Identifies the user token a sign-in just issued.',
  'packages/cc_server_core/lib/src/cc_server_runtime.dart':
      "The media proxy fetches a private GitHub attachment with the viewer's "
      'own person token, for GitHub hosts only.',
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

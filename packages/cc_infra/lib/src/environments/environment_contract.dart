import 'dart:convert';

import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:path/path.dart' as p;

/// One repo role present in a space.
class EnvironmentContractRepo {
  /// Creates an [EnvironmentContractRepo].
  const EnvironmentContractRepo({
    required this.role,
    required this.repoId,
    required this.name,
    required this.slug,
    required this.path,
    required this.sourcePath,
    this.branch,
  });

  /// The role key from the definition.
  final String role;

  /// The workspace repo.
  final String repoId;

  /// Display name.
  final String name;

  /// Directory slug.
  final String slug;

  /// The worktree, or the source checkout for a `useSource` role.
  final String path;

  /// The registered source checkout.
  final String sourcePath;

  /// The checked-out branch.
  final String? branch;
}

/// What a PR space adds.
class EnvironmentContractPr {
  /// Creates an [EnvironmentContractPr].
  const EnvironmentContractPr({
    required this.number,
    required this.repo,
    required this.headSha,
    required this.isFork,
  });

  /// PR number.
  final int number;

  /// `owner/name`.
  final String repo;

  /// Head commit.
  final String headSha;

  /// Whether the head lives in a fork.
  final bool isFork;
}

/// Everything the contract is built from.
class EnvironmentContractInput {
  /// Creates an [EnvironmentContractInput].
  const EnvironmentContractInput({
    required this.name,
    required this.id,
    required this.stateDir,
    required this.home,
    required this.branch,
    required this.spaceId,
    required this.spaceName,
    required this.spaceKind,
    required this.repos,
    this.ports = const {},
    this.urls = const {},
    this.primaryUrl,
    this.options = const {},
    this.definitionEnv = const {},
    this.pr,
    this.compose = const {},
  });

  /// The environment's name.
  final String name;

  /// Its UUID.
  final String id;

  /// `<dataDir>/<ws>/environments/<id>/`.
  final String stateDir;

  /// The server user's home.
  final String home;

  /// The space's branch.
  final String branch;

  /// The space.
  final String spaceId;

  /// Its name.
  final String spaceName;

  /// `space` or `pr`.
  final String spaceKind;

  /// Roles present, in definition order.
  final List<EnvironmentContractRepo> repos;

  /// Allocated ports by key: `web`, `postgres.5432`.
  final Map<String, int> ports;

  /// Endpoint URLs by role.
  final Map<String, String> urls;

  /// The primary endpoint.
  final String? primaryUrl;

  /// Chosen options.
  final Map<String, Object?> options;

  /// The definition's `env`, unexpanded.
  final Map<String, String> definitionEnv;

  /// Set in PR spaces.
  final EnvironmentContractPr? pr;

  /// `COMPOSE_PROJECT_NAME` and `COMPOSE_FILE`, when there is a compose
  /// component.
  final Map<String, String> compose;
}

/// The variables and placeholder values of one environment.
class EnvironmentContract {
  /// Builds the contract for [input]. Throws `EnvironmentTemplateException`
  /// when the definition's `env` names an unknown placeholder.
  EnvironmentContract(this.input) : values = _values(input) {
    _expandedDefinitionEnv = {
      for (final entry in input.definitionEnv.entries)
        entry.key: values.expand(entry.value),
    };
  }

  /// What this was built from.
  final EnvironmentContractInput input;

  /// The table `{placeholder}`s and conditions resolve against.
  final EnvironmentValues values;

  late final Map<String, String> _expandedDefinitionEnv;

  static EnvironmentValues _values(EnvironmentContractInput input) =>
      EnvironmentValues({
        'name': input.name,
        'id': input.id,
        'branch': input.branch,
        'stateDir': input.stateDir,
        'home': input.home,
        for (final repo in input.repos) ...{
          'repo.${repo.role}': repo.path,
          'source.${repo.role}': repo.sourcePath,
        },
        for (final entry in input.ports.entries)
          'port.${entry.key}': '${entry.value}',
        for (final entry in input.urls.entries) 'url.${entry.key}': entry.value,
        for (final entry in input.options.entries)
          if (entry.value != null)
            'opt.${entry.key}': environmentOptionText(entry.value),
      });

  /// The variables for a command running in [role], or in the first role the
  /// space has.
  ///
  /// The contract is written last, so a definition can never shadow it even if
  /// a stored row got past the validator.
  ///
  /// [overrides] sit between the two: a component's `env` beats the
  /// definition's, and neither beats the contract.
  Map<String, String> environment({
    String? role,
    Map<String, String> overrides = const {},
  }) {
    final repo = _repo(role);
    final pr = input.pr;
    return {
      ..._expandedDefinitionEnv,
      ...overrides,
      'CC_ENV_NAME': input.name,
      'CC_ENV_ID': input.id,
      'CC_ENV_BRANCH': input.branch,
      'CC_ENV_STATE_DIR': input.stateDir,
      'CC_ENV_HOME': input.home,
      for (final entry in input.ports.entries)
        'CC_ENV_PORT_${environmentVariableKey(entry.key)}': '${entry.value}',
      'CC_ENV_URL': ?input.primaryUrl,
      for (final entry in input.urls.entries)
        'CC_ENV_URL_${environmentVariableKey(entry.key)}': entry.value,
      for (final entry in input.options.entries)
        if (entry.value != null)
          'CC_ENV_OPT_${environmentVariableKey(entry.key)}':
              environmentOptionText(entry.value),
      'CC_SPACE_ID': input.spaceId,
      'CC_SPACE_NAME': input.spaceName,
      'CC_SPACE_KIND': input.spaceKind,
      if (pr != null) ...{
        'CC_PR_NUMBER': '${pr.number}',
        'CC_PR_REPO': pr.repo,
        'CC_PR_HEAD_SHA': pr.headSha,
        'CC_PR_IS_FORK': '${pr.isFork}',
      },
      if (repo != null) ...{
        'CC_WORKSPACE_PATH': repo.path,
        'CC_ROOT_PATH': repo.sourcePath,
      },
      for (final item in input.repos) ...{
        'CC_REPO_PATH_${environmentVariableKey(item.role)}': item.path,
        'CC_ENV_REPO_${environmentVariableKey(item.role)}': item.path,
        'CC_ENV_SOURCE_${environmentVariableKey(item.role)}': item.sourcePath,
      },
      'CC_SPACE_REPOS': jsonEncode([
        for (final item in input.repos)
          {
            'repoId': item.repoId,
            'name': item.name,
            'slug': item.slug,
            'path': item.path,
            'branch': item.branch,
            'role': item.role,
          },
      ]),
      ...input.compose,
      'NO_COLOR': '1',
    };
  }

  /// The variables for [component]: the contract in its role, its own `env`,
  /// and `PORT` and `HOST` when it declares a port.
  Map<String, String> forComponent(EnvironmentComponent component) {
    final port = component.ports.isEmpty ? null : component.ports.first;
    final value = port == null ? null : input.ports[port];
    return {
      ...environment(
        role: component.cwd?.role,
        overrides: {
          for (final entry in component.env.entries)
            entry.key: values.expand(entry.value),
        },
      ),
      if (value != null) ...{'PORT': '$value', 'HOST': '127.0.0.1'},
    };
  }

  /// Where a command with [cwd] runs.
  ///
  /// Throws `EnvironmentTemplateException` when the space has no such role or
  /// no role at all, and refuses a path that climbs out of the worktree.
  String workingDirectory(EnvironmentCwd? cwd) {
    final repo = _repo(cwd?.role);
    if (repo == null) {
      throw EnvironmentTemplateException(
        cwd?.role == null
            ? 'This space has no repo to run in'
            : 'This space has no repo for the role ${cwd?.role}',
      );
    }
    final relative = cwd?.path;
    if (relative == null || relative.isEmpty) {
      return repo.path;
    }
    final joined = p.normalize(p.join(repo.path, relative));
    if (!p.isWithin(repo.path, joined) && joined != repo.path) {
      throw EnvironmentTemplateException(
        'cwd $relative is outside the worktree',
      );
    }
    return joined;
  }

  EnvironmentContractRepo? _repo(String? role) {
    for (final repo in input.repos) {
      if (role == null || repo.role == role) {
        return repo;
      }
    }
    return null;
  }
}

/// The variables a `provision` or `archive` task sees: no environment exists,
/// so no name, port, URL or option, and not the definition's `env`.
Map<String, String> worktreeTaskVariables({
  required String worktreePath,
  required String sourcePath,
  required String repoName,
  String? spaceId,
  String? spaceName,
  String? spaceKind,
  bool isTest = false,
}) => {
  'CC_WORKSPACE_PATH': worktreePath,
  'CC_ROOT_PATH': sourcePath,
  'CC_SPACE_ID': ?spaceId,
  'CC_SPACE_NAME': ?spaceName,
  'CC_SPACE_KIND': ?spaceKind,
  'CC_REPO_NAME': repoName,
  if (isTest) 'CC_SCRIPT_TEST': '1',
  'NO_COLOR': '1',
};

/// `postgres.5432` as `POSTGRES_5432`.
String environmentVariableKey(String key) =>
    key.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '_');

/// An option as text: `multi` comma-joined, `bool` as `true` or `false`.
String environmentOptionText(Object? value) =>
    value is Iterable ? value.join(',') : '$value';

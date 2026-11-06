import 'dart:convert';

import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:cc_infra/src/environments/environment_contract.dart';
import 'package:test/test.dart';

void main() {
  const app = EnvironmentContractRepo(
    role: 'app',
    repoId: 'repo-1',
    name: 'Shop',
    slug: 'shop',
    path: '/data/spaces/s/repos/shop',
    sourcePath: '/src/shop',
    branch: 'fix-login',
  );
  const e2e = EnvironmentContractRepo(
    role: 'e2e_suite',
    repoId: 'repo-2',
    name: 'E2E',
    slug: 'e2e',
    path: '/data/spaces/s/repos/e2e',
    sourcePath: '/src/e2e',
  );

  EnvironmentContract contract({
    Map<String, String> definitionEnv = const {},
    EnvironmentContractPr? pr,
    Map<String, String> compose = const {},
  }) => EnvironmentContract(
    EnvironmentContractInput(
      name: 'fix-login',
      id: 'env-1',
      stateDir: '/data/ws/environments/env-1',
      home: '/home/acme',
      branch: 'fix/login',
      spaceId: 'space-1',
      spaceName: 'Fix login',
      spaceKind: pr == null ? 'space' : 'pr',
      repos: const [app, e2e],
      ports: const {'web': 42000, 'postgres.5432': 42001},
      urls: const {'web': 'http://web--fix-login--shop.localhost:7355'},
      primaryUrl: 'http://web--fix-login--shop.localhost:7355',
      options: const {
        'seed': true,
        'quiet': false,
        'services': ['a', 'b'],
        'mode': 'desktop',
        'unset': null,
      },
      definitionEnv: definitionEnv,
      pr: pr,
      compose: compose,
    ),
  );

  group('values', () {
    test('holds every placeholder family', () {
      expect(contract().values.values, {
        'name': 'fix-login',
        'id': 'env-1',
        'branch': 'fix/login',
        'stateDir': '/data/ws/environments/env-1',
        'home': '/home/acme',
        'repo.app': app.path,
        'source.app': app.sourcePath,
        'repo.e2e_suite': e2e.path,
        'source.e2e_suite': e2e.sourcePath,
        'port.web': '42000',
        'port.postgres.5432': '42001',
        'url.web': 'http://web--fix-login--shop.localhost:7355',
        'opt.seed': 'true',
        'opt.quiet': 'false',
        'opt.services': 'a,b',
        'opt.mode': 'desktop',
      });
    });

    test('conditions read options and roles', () {
      final values = contract().values;
      expect(values.evaluate('opt.seed'), isTrue);
      expect(values.evaluate('!opt.quiet'), isTrue);
      expect(values.evaluate('opt.mode == desktop'), isTrue);
      expect(values.evaluate('repo.web_app'), isFalse);
    });
  });

  group('environment', () {
    final env = contract().environment();

    test('has the section 4.3 variables', () {
      expect(env, containsPair('CC_ENV_NAME', 'fix-login'));
      expect(env, containsPair('CC_ENV_ID', 'env-1'));
      expect(
        env,
        containsPair('CC_ENV_STATE_DIR', '/data/ws/environments/env-1'),
      );
      expect(env, containsPair('CC_ENV_PORT_WEB', '42000'));
      expect(env, containsPair('CC_ENV_PORT_POSTGRES_5432', '42001'));
      expect(env, containsPair('CC_ENV_URL', startsWith('http://web--')));
      expect(env, containsPair('CC_ENV_URL_WEB', startsWith('http://web--')));
      expect(env, containsPair('CC_ENV_OPT_SERVICES', 'a,b'));
      expect(env, containsPair('CC_ENV_OPT_SEED', 'true'));
      expect(env, containsPair('CC_ENV_OPT_QUIET', 'false'));
      expect(env, containsPair('CC_SPACE_ID', 'space-1'));
      expect(env, containsPair('CC_SPACE_NAME', 'Fix login'));
      expect(env, containsPair('CC_SPACE_KIND', 'space'));
      expect(env, containsPair('CC_WORKSPACE_PATH', app.path));
      expect(env, containsPair('CC_ROOT_PATH', app.sourcePath));
      expect(env, containsPair('CC_REPO_PATH_APP', app.path));
      expect(env, containsPair('CC_REPO_PATH_E2E_SUITE', e2e.path));
      expect(env, containsPair('NO_COLOR', '1'));
    });

    test('exports each placeholder as CC_ENV_*', () {
      expect(env, containsPair('CC_ENV_BRANCH', 'fix/login'));
      expect(env, containsPair('CC_ENV_HOME', '/home/acme'));
      expect(env, containsPair('CC_ENV_REPO_APP', app.path));
      expect(env, containsPair('CC_ENV_SOURCE_E2E_SUITE', e2e.sourcePath));
    });

    test('CC_SPACE_REPOS is the documented JSON', () {
      final repos = jsonDecode(env['CC_SPACE_REPOS']!) as List;
      expect(repos.first, {
        'repoId': 'repo-1',
        'name': 'Shop',
        'slug': 'shop',
        'path': app.path,
        'branch': 'fix-login',
        'role': 'app',
      });
      expect(repos, hasLength(2));
    });

    test('PR variables only in a PR space', () {
      expect(env.keys.where((key) => key.startsWith('CC_PR_')), isEmpty);
      final pr = contract(
        pr: const EnvironmentContractPr(
          number: 42,
          repo: 'acme/shop',
          headSha: 'abc123',
          isFork: true,
        ),
      ).environment();
      expect(pr, containsPair('CC_PR_NUMBER', '42'));
      expect(pr, containsPair('CC_PR_REPO', 'acme/shop'));
      expect(pr, containsPair('CC_PR_HEAD_SHA', 'abc123'));
      expect(pr, containsPair('CC_PR_IS_FORK', 'true'));
      expect(pr, containsPair('CC_SPACE_KIND', 'pr'));
    });

    test('compose variables only when given', () {
      expect(env.keys, isNot(contains('COMPOSE_FILE')));
      final compose = contract(
        compose: const {
          'COMPOSE_PROJECT_NAME': 'cc-x',
          'COMPOSE_FILE': '/a:/b',
        },
      ).environment();
      expect(compose, containsPair('COMPOSE_PROJECT_NAME', 'cc-x'));
      expect(compose, containsPair('COMPOSE_FILE', '/a:/b'));
    });

    test('the role sets CC_WORKSPACE_PATH', () {
      final other = contract().environment(role: 'e2e_suite');
      expect(other, containsPair('CC_WORKSPACE_PATH', e2e.path));
      expect(other, containsPair('CC_ROOT_PATH', e2e.sourcePath));
    });

    test('expands the definition env, under the contract', () {
      final env = contract(
        definitionEnv: const {
          'DATABASE_URL': 'postgres://127.0.0.1:{port.postgres.5432}/app',
          'CC_ENV_NAME': 'shadowed',
        },
      ).environment();
      expect(
        env,
        containsPair('DATABASE_URL', 'postgres://127.0.0.1:42001/app'),
      );
      expect(env, containsPair('CC_ENV_NAME', 'fix-login'));
    });

    test('an unknown placeholder in the definition env is an error', () {
      expect(
        () => contract(definitionEnv: const {'X': '{port.nope}'}),
        throwsA(isA<EnvironmentTemplateException>()),
      );
    });
  });

  group('forComponent', () {
    ProcessEnvironmentComponent component({
      List<String> ports = const ['web'],
      Map<String, String> env = const {},
      EnvironmentCwd? cwd,
    }) => ProcessEnvironmentComponent(
      id: 'web',
      ports: ports,
      env: env,
      cwd: cwd,
      command: ShellEnvironmentCommand('true'),
    );

    test('a declared port sets PORT and HOST', () {
      final env = contract().forComponent(component());
      expect(env, containsPair('PORT', '42000'));
      expect(env, containsPair('HOST', '127.0.0.1'));
    });

    test('no port, no PORT', () {
      final env = contract().forComponent(component(ports: const []));
      expect(env.keys, isNot(contains('PORT')));
    });

    test('its env beats the definition\'s and expands', () {
      final env = contract(definitionEnv: const {'LEVEL': 'definition'})
          .forComponent(
            component(env: const {'LEVEL': 'component', 'AT': '{port.web}'}),
          );
      expect(env, containsPair('LEVEL', 'component'));
      expect(env, containsPair('AT', '42000'));
    });

    test('follows the component\'s role', () {
      final env = contract().forComponent(
        component(cwd: const EnvironmentCwd(role: 'e2e_suite')),
      );
      expect(env, containsPair('CC_WORKSPACE_PATH', e2e.path));
    });
  });

  group('workingDirectory', () {
    test('defaults to the first role present', () {
      expect(contract().workingDirectory(null), app.path);
    });

    test('takes a role and a path', () {
      expect(
        contract().workingDirectory(
          const EnvironmentCwd(role: 'e2e_suite', path: 'packages/ui'),
        ),
        '${e2e.path}/packages/ui',
      );
    });

    test('refuses an absent role and a climbing path', () {
      expect(
        () => contract().workingDirectory(const EnvironmentCwd(role: 'nope')),
        throwsA(isA<EnvironmentTemplateException>()),
      );
      expect(
        () => contract().workingDirectory(const EnvironmentCwd(path: '../x')),
        throwsA(isA<EnvironmentTemplateException>()),
      );
    });
  });

  test('worktree tasks see no environment values', () {
    final variables = worktreeTaskVariables(
      worktreePath: '/w',
      sourcePath: '/s',
      repoName: 'Shop',
      spaceId: 'space-1',
      spaceName: 'Fix login',
      spaceKind: 'space',
    );
    expect(variables, {
      'CC_WORKSPACE_PATH': '/w',
      'CC_ROOT_PATH': '/s',
      'CC_SPACE_ID': 'space-1',
      'CC_SPACE_NAME': 'Fix login',
      'CC_SPACE_KIND': 'space',
      'CC_REPO_NAME': 'Shop',
      'NO_COLOR': '1',
    });
    expect(
      worktreeTaskVariables(
        worktreePath: '/w',
        sourcePath: '/s',
        repoName: 'Shop',
        isTest: true,
      ),
      containsPair('CC_SCRIPT_TEST', '1'),
    );
  });

  test('variable keys are upper snake', () {
    expect(environmentVariableKey('dev-server'), 'DEV_SERVER');
    expect(environmentVariableKey('postgres.5432'), 'POSTGRES_5432');
  });
}

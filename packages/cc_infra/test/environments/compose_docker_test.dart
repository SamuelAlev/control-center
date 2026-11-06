@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_infra/src/environments/compose_driver.dart';
import 'package:cc_infra/src/environments/compose_plan.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_lease_allocator.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'helpers/environment_fakes.dart';

const _images = ['redis:7-alpine', 'nginx:1.31.8-alpine'];

/// Null when Docker and both images are here, else why not. Nothing here may
/// pull: an unattended test shouldn't depend on the network.
String? _whyNoDocker() {
  try {
    if (Process.runSync('docker', ['info']).exitCode != 0) {
      return 'the Docker daemon is not running';
    }
    for (final image in _images) {
      if (Process.runSync('docker', ['image', 'inspect', image]).exitCode !=
          0) {
        return '$image is not available locally';
      }
    }
    return null;
  } on ProcessException {
    return 'docker is not installed';
  }
}

/// Fixed ports and container names on purpose: the point is that two
/// environments run from this one file without colliding.
const _composeFile = '''
name: shop-fixed
services:
  cache:
    image: redis:7-alpine
    container_name: shop-fixed-cache
    ports:
      - "16399:6379"
  web:
    image: nginx:1.31.8-alpine
    container_name: shop-fixed-web
    ports:
      - "18099:80"
    volumes:
      - ./site:/usr/share/nginx/html:ro
    depends_on:
      - cache
  seed:
    image: redis:7-alpine
    container_name: shop-fixed-seed
    command: ["sh", "-c", "echo seeded"]
''';

void main() {
  final skip = _whyNoDocker() ?? false;

  late Directory dir;
  late EnvironmentLeaseAllocator allocator;
  late ComposeDriver driver;
  final projects = <String>[];

  void removeEverything(String environmentId) {
    Process.runSync('docker', [
      'compose',
      '-p',
      composeProjectName(environmentId),
      'down',
      '-v',
      '--remove-orphans',
    ]);
  }

  List<String> containersOf(String environmentId) {
    final result = Process.runSync('docker', [
      'ps',
      '-a',
      '--filter',
      'label=cc.env=$environmentId',
      '--format',
      '{{.Names}}',
    ]);
    return const LineSplitter().convert('${result.stdout}');
  }

  setUp(() {
    dir = tempDir(addTearDown);
    // A range far from the defaults, so a running server can't be in the way.
    allocator = EnvironmentLeaseAllocator(
      repository: InMemoryLeases(),
      firstPort: 47300,
      lastPort: 47999,
    );
    driver = ComposeDriver(pollInterval: const Duration(milliseconds: 500));
    addTearDown(() {
      projects.forEach(removeEverything);
      projects.clear();
    });
  });

  /// A worktree of its own, with a page saying whose it is.
  String worktree(String name) {
    final path = '${dir.path}/$name';
    Directory('$path/site').createSync(recursive: true);
    File('$path/compose.yaml').writeAsStringSync(_composeFile);
    File('$path/site/index.html').writeAsStringSync(name);
    return path;
  }

  Future<ComposePlan> plan(
    String name, {
    required String path,
    required EnvironmentLease lease,
  }) {
    final environmentId = const Uuid().v4();
    projects.add(environmentId);
    return driver.plan(
      ComposeContext(
        component: ComposeEnvironmentComponent(
          id: 'stack',
          build: false,
          healthchecks: const {
            'cache': ['redis-cli', 'ping'],
          },
          timeoutSeconds: 90,
        ),
        environmentId: environmentId,
        workspaceId: 'ws-test',
        spaceId: name,
        stateDir: '${dir.path}/state-$name',
        workingDirectory: path,
        allowedRoots: [path],
      ),
      lease: lease,
    );
  }

  Future<EnvironmentLease> lease(String space) => allocator.acquire(
    workspaceId: 'ws-test',
    spaceId: space,
    definitionId: 'def',
  );

  Future<String> fetch(int port) async {
    final client = HttpClient();
    addTearDown(client.close);
    final request = await client.get('127.0.0.1', port, '/');
    final response = await request.close();
    return response.transform(utf8.decoder).join();
  }

  test('two projects from one file run side by side', () async {
    final first = await plan(
      'first',
      path: worktree('first'),
      lease: await lease('first'),
    );
    final second = await plan(
      'second',
      path: worktree('second'),
      lease: await lease('second'),
    );
    expect(first.ports['web.80'], isNot(second.ports['web.80']));

    await Future.wait([driver.up(first), driver.up(second)]);
    final states = await Future.wait([
      driver.waitReady(first),
      driver.waitReady(second),
    ]);

    for (final result in states) {
      final byName = {for (final state in result) state.service: state};
      expect(byName['web']?.state, 'ready');
      expect(byName['seed']?.state, 'completed', reason: 'a one-shot is fine');
      expect(byName['cache']?.state, 'ready');
      expect(byName['cache']?.health, 'healthy', reason: 'injected check ran');
    }

    expect(await fetch(first.ports['web.80']!), 'first');
    expect(await fetch(second.ports['web.80']!), 'second');

    final names = containersOf(first.context.environmentId);
    expect(names, hasLength(3));
    expect(names, everyElement(startsWith(first.context.projectName)));

    final labels = Process.runSync('docker', [
      'inspect',
      '-f',
      '{{index .Config.Labels "cc.workspace"}}/{{index .Config.Labels "cc.space"}}',
      names.first,
    ]);
    expect('${labels.stdout}'.trim(), 'ws-test/first');

    final bound = Process.runSync('docker', [
      'port',
      '${first.context.projectName}-web-1',
      '80',
    ]);
    expect('${bound.stdout}'.trim(), '127.0.0.1:${first.ports['web.80']}');

    final endpoints = await driver.detectEndpoints(first, states.first);
    final byRole = {for (final item in endpoints) item.role: item};
    expect(byRole['web']?.url, 'http://127.0.0.1:${first.ports['web.80']}');
    expect(byRole['cache']?.url, isNull);
    expect(byRole['cache']?.hostPort, first.ports['cache.6379']);

    final variables = first.variables;
    final plain = await Process.run(
      'docker',
      ['compose', 'ps', '--services', '--status', 'running'],
      workingDirectory: dir.path,
      environment: variables,
    );
    expect(
      const LineSplitter().convert('${plain.stdout}'),
      unorderedEquals(['cache', 'web']),
      reason: 'a plain command in a terminal targets this environment',
    );

    final exec = await driver.exec(first, 'cache', ['redis-cli', 'ping']);
    expect(exec.stdout.trim(), 'PONG');

    final owned = await driver.ownedContainers();
    expect(
      owned.where((item) => item.environmentId == first.context.environmentId),
      hasLength(3),
    );

    await driver.stop(second);
    expect(await fetch(first.ports['web.80']!), 'first');

    await driver.destroy(first);
    await driver.destroy(second);
    expect(containersOf(first.context.environmentId), isEmpty);
    expect(containersOf(second.context.environmentId), isEmpty);
  }, skip: skip);

  test('a failing one-shot fails readiness with its output', () async {
    final path = worktree('failing');
    File('$path/compose.yaml').writeAsStringSync('''
services:
  seed:
    image: redis:7-alpine
    command: ["sh", "-c", "echo the seed broke; exit 3"]
''');
    final subject = await plan(
      'failing',
      path: path,
      lease: await lease('failing'),
    );
    await driver.up(subject);
    await expectLater(
      driver.waitReady(subject),
      throwsA(
        isA<EnvironmentDriverException>().having(
          (e) => e.error.message,
          'message',
          allOf(
            contains('Service seed exited with code 3'),
            contains('the seed broke'),
          ),
        ),
      ),
    );
  }, skip: skip);

  test('a missing bind source stops it before anything exists', () async {
    final path = worktree('missing');
    File('$path/.gitignore').writeAsStringSync('secret.sh\n');
    Process.runSync('git', ['init', '-q', path]);
    File('$path/compose.yaml').writeAsStringSync('''
services:
  app:
    image: redis:7-alpine
    volumes:
      - ./secret.sh:/seed.sh
''');
    final subject = await plan(
      'missing',
      path: path,
      lease: await lease('missing'),
    );
    await expectLater(
      driver.up(subject),
      throwsA(
        isA<EnvironmentDriverException>().having(
          (e) => e.error.message,
          'message',
          allOf(
            contains('secret.sh'),
            contains('gitignored'),
            contains('seedFiles'),
          ),
        ),
      ),
    );
    expect(containersOf(subject.context.environmentId), isEmpty);
    expect(
      File('$path/secret.sh').existsSync() ||
          Directory('$path/secret.sh').existsSync(),
      isFalse,
      reason: 'Docker never got the chance to create the directory',
    );
  }, skip: skip);

  test('refresh keeps ports and running containers', () async {
    final path = worktree('refresh');
    final held = await lease('refresh');
    final subject = await plan('refresh', path: path, lease: held);
    await driver.up(subject);
    await driver.waitReady(subject);

    final unchanged = await driver.refresh(
      subject.context,
      lease: held,
      existingPorts: subject.ports,
    );
    expect(unchanged.changed, isFalse);

    File('$path/compose.yaml').writeAsStringSync(
      '$_composeFile'
      '  extra:\n'
      '    image: nginx:1.31.8-alpine\n'
      '    ports:\n'
      '      - "18100:80"\n',
    );
    final changed = await driver.refresh(
      subject.context,
      lease: held,
      existingPorts: subject.ports,
    );
    expect(changed.changed, isTrue);
    for (final entry in subject.ports.entries) {
      expect(changed.plan.ports[entry.key], entry.value);
    }
    expect(changed.plan.ports.keys, contains('extra.80'));
    await driver.waitReady(changed.plan);
    expect(await fetch(changed.plan.ports['web.80']!), 'refresh');
  }, skip: skip);

  test('compose refuses a remote include even past the scan', () async {
    final path = worktree('remote');
    File('$path/compose.yaml').writeAsStringSync(r'''
include:
  - ${REMOTE_COMPOSE}
services: {}
''');
    final environmentId = const Uuid().v4();
    await expectLater(
      driver.plan(
        ComposeContext(
          component: ComposeEnvironmentComponent(id: 'stack'),
          environmentId: environmentId,
          workspaceId: 'ws-test',
          spaceId: 'remote',
          stateDir: '${dir.path}/state-remote',
          workingDirectory: path,
          environment: const {
            'REMOTE_COMPOSE': 'oci://registry.invalid/shop:latest',
          },
        ),
        lease: await lease('remote'),
      ),
      throwsA(
        isA<EnvironmentDriverException>().having(
          (e) => e.error.message,
          'message',
          contains('disabled'),
        ),
      ),
    );
  }, skip: skip);
}

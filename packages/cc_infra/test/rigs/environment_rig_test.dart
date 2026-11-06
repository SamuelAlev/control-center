import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_infra/src/rigs/environment_rig_host.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart' show kRigPortMuxGuestPort;
import 'package:cc_infra/src/rigs/smolvm_enclosure_backend.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  RigSpec spec({
    String worktree = '/work/acme',
    Map<String, String> extraMounts = const {},
  }) => RigSpec.environment(
    conversationId: 'space-1',
    environmentId: 'env-1',
    worktreePath: worktree,
    egressAllowlist: const ['docker.io', 'production.cloudflare.docker.com'],
    extraMounts: extraMounts,
  );

  List<String> args({String? pack, String worktree = '/work/acme'}) =>
      buildSmolvmCreateArgs(
        SmolvmLaunchPlan(
          rigId: 'r1',
          spec: spec(worktree: worktree),
          image: kSmolvmEnvironmentImage,
          dataDir: '/data',
          packPath: pack,
          portMuxHostPort: 40000,
        ),
      );

  String? valueAfter(List<String> argv, String flag) {
    final at = argv.indexOf(flag);
    return at < 0 ? null : argv[at + 1];
  }

  List<String> allowed(List<String> argv) => [
    for (var i = 0; i < argv.length - 1; i++)
      if (argv[i] == '--allow-host') argv[i + 1],
  ];

  group('create arguments', () {
    test('use virtio-net, which TSI cannot replace', () {
      expect(valueAfter(args(), '--net-backend'), 'virtio-net');
    });

    test('stay filtered, and never use bare --net', () {
      expect(args(), contains('--outbound-localhost-only'));
      expect(args(), isNot(contains('--net')));
    });

    test('run dockerd with the flags the guest needs', () {
      final argv = args();
      expect(argv.sublist(argv.indexOf('--') + 1), [
        'dockerd',
        '--data-root=/storage/docker',
        '--storage-driver=overlay2',
        '--feature',
        'containerd-snapshotter=false',
      ]);
    });

    test('size the storage disk from the spec', () {
      expect(valueAfter(args(), '--storage'), '16');
    });

    test('stay within what smolvm can restart', () {
      expect(valueAfter(args(), '--overlay'), '8');
      expect(
        () => buildSmolvmCreateArgs(
          SmolvmLaunchPlan(
            rigId: 'r1',
            spec: spec().copyWith(storageGb: 17),
            image: kSmolvmEnvironmentImage,
            dataDir: '/data',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('share the worktree read-only, never read-write', () {
      expect(valueAfter(args(), '-v'), '/work/acme:/mnt/cc-ro/workspace:ro');
      expect(args().join(' '), isNot(contains(':rw')));
      // /workspace exists only once the overlay is mounted after boot.
      expect(args(), isNot(contains('--workdir')));
    });

    test('the overlay keeps writes on the guest disk', () {
      final script = smolvmEnvironmentOverlayScript(const [
        '/workspace',
        '/workspaces/api',
      ]);
      expect(script, contains('lowerdir=/mnt/cc-ro/workspace,'));
      expect(script, contains('upperdir=/storage/cc-overlay/workspace/upper'));
      expect(script, contains('lowerdir=/mnt/cc-ro/workspaces/api,'));
      expect(script, contains('grep -q " /workspace overlay "'));
    });

    test('mount every further worktree', () {
      final argv = buildSmolvmCreateArgs(
        SmolvmLaunchPlan(
          rigId: 'r1',
          spec: spec(extraMounts: const {'/workspaces/api': '/work/api'}),
          image: kSmolvmEnvironmentImage,
          dataDir: '/data',
        ),
      );
      expect(argv, contains('/work/api:/mnt/cc-ro/workspaces/api:ro'));
    });

    test('forward the port mux', () {
      expect(args(), contains('40000:$kRigPortMuxGuestPort'));
    });

    test('allow the spec, the image registry and the mirror before a pack', () {
      expect(
        allowed(args()),
        unorderedEquals([
          'docker.io',
          'production.cloudflare.docker.com',
          'production.cloudfront.docker.com',
          ...kEnvironmentRigApkMirrors,
        ]),
      );
    });

    test('drop the mirror once a pack holds what it would install', () {
      final argv = args(pack: '/packs/p.smolmachine');
      expect(allowed(argv), isNot(contains(kEnvironmentRigApkMirrors.first)));
      expect(valueAfter(argv, '--from'), '/packs/p.smolmachine');
      expect(argv, isNot(contains('--image')));
    });

    test('carry no credentials', () {
      final line = args().join(' ');
      expect(line, isNot(contains('--secret-file')));
      expect(line, isNot(contains('CC_BROKER_PORT')));
    });

    test('are labelled as what they are', () {
      expect(args(), contains('cc-surface=environment'));
      expect(args().join(' '), isNot(contains('cc-engine')));
    });

    test('refuse a worktree -v cannot carry', () {
      expect(() => args(worktree: '/work/a:b'), throwsArgumentError);
      expect(
        () => buildSmolvmCreateArgs(
          SmolvmLaunchPlan(
            rigId: 'r1',
            spec: spec(extraMounts: const {'/workspaces/api': '/work/a:b'}),
            image: kSmolvmEnvironmentImage,
            dataDir: '/data',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('leave other machines on their default net backend', () {
      final argv = buildSmolvmCreateArgs(
        SmolvmLaunchPlan(
          rigId: 'r2',
          spec: RigSpec.exec(conversationId: 'c'),
          image: kSmolvmExecImage,
          dataDir: '/data',
        ),
      );
      expect(argv, isNot(contains('--net-backend')));
      expect(argv, isNot(contains('-v')));
    });
  });

  test('the image is pinned by digest and is not the exec image', () {
    expect(kSmolvmEnvironmentImage, contains('@sha256:'));
    expect(kSmolvmEnvironmentImage, isNot(kSmolvmExecImage));
  });

  test('the pack is its own variant', () {
    expect(smolvmPackVariantFor(spec()), kSmolvmEnvironmentPackVariant);
    expect(
      smolvmPackFileName(
        kSmolvmEnvironmentImage,
        variant: kSmolvmEnvironmentPackVariant,
      ),
      isNot(smolvmPackFileName(kSmolvmEnvironmentImage)),
    );
  });

  test('init is a no-op on a warmed guest and installs socat otherwise', () {
    expect(smolvmEnvironmentInit(), contains('command -v socat'));
    expect(smolvmEnvironmentInit(), contains('apk add'));
  });

  group('exec arguments', () {
    test('keep an argument one argument', () {
      final argv = buildSmolvmExecArgs(
        'm1',
        ['docker', 'compose', 'up', '-d'],
        workdir: '/workspace',
        environment: {'ACME': 'a b'},
        timeout: const Duration(seconds: 90),
      );
      expect(argv, [
        'machine',
        'exec',
        '--name',
        'm1',
        '--timeout',
        '90s',
        '--workdir',
        '/workspace',
        '-e',
        'ACME=a b',
        '--',
        'docker',
        'compose',
        'up',
        '-d',
      ]);
    });
  });

  group('dockerfileBaseImages', () {
    test('reads bases and ignores stage names and scratch', () {
      expect(
        dockerfileBaseImages('''
FROM --platform=linux/arm64 golang:1.24 AS build
RUN go build
FROM build AS test
FROM scratch
from ghcr.io/acme/base:1
'''),
        {'golang:1.24', 'ghcr.io/acme/base:1'},
      );
    });

    test('refuses a base it cannot know before boot', () {
      expect(
        () => dockerfileBaseImages(r'FROM ${BASE_IMAGE}'),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
    });
  });

  group('composeModelImages', () {
    late Directory context;

    setUp(() {
      context = Directory.systemTemp.createTempSync('cc_env_rig');
      File(
        p.join(context.path, 'Dockerfile'),
      ).writeAsStringSync('FROM node:22');
      File(
        p.join(context.path, 'api.Dockerfile'),
      ).writeAsStringSync('FROM ruby:3');
    });

    tearDown(() => context.deleteSync(recursive: true));

    test('collects images and the bases of built services', () {
      expect(
        composeModelImages({
          'services': {
            'db': {'image': 'postgres:17'},
            'web': {
              'image': 'acme/web:dev',
              'build': {'context': context.path},
            },
            'api': {
              'build': {
                'context': context.path,
                'dockerfile': 'api.Dockerfile',
              },
            },
            'tool': {
              'build': {
                'context': context.path,
                'dockerfile_inline': 'FROM alpine:3',
              },
            },
          },
        }),
        {'postgres:17', 'node:22', 'ruby:3', 'alpine:3'},
      );
    });

    test('counts only the selected services', () {
      expect(
        composeModelImages(
          {
            'services': {
              'db': {'image': 'postgres:17'},
              'cache': {'image': 'redis:7'},
            },
          },
          services: const ['db'],
        ),
        {'postgres:17'},
      );
    });

    test('a model with no services pulls nothing', () {
      expect(composeModelImages(const {}), isEmpty);
    });

    test('a remote build context is refused, not guessed at', () {
      expect(
        () => composeModelImages({
          'services': {
            'web': {
              'build': {'context': 'https://acme.test/repo.git'},
            },
          },
        }),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
    });

    test('a build outside the worktree is refused, never read', () {
      expect(
        () => composeModelImages(
          {
            'services': {
              'web': {
                'build': {'context': '../..', 'dockerfile': 'etc/passwd'},
              },
            },
          },
          directory: context.path,
          root: context.path,
        ),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
    });

    test('a missing Dockerfile is named', () {
      expect(
        () => composeModelImages(
          {
            'services': {
              'web': {'build': 'missing'},
            },
          },
          directory: context.path,
          root: context.path,
        ),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
    });
  });

  group('composeFileImages', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('cc_env_compose'));
    tearDown(() => root.deleteSync(recursive: true));

    String write(String text, {String name = 'compose.yaml'}) {
      final file = File(p.join(root.path, name))..writeAsStringSync(text);
      return file.path;
    }

    test('reads images without any Docker', () {
      expect(
        composeFileImages(write('services:\n  web:\n    image: nginx:1\n')),
        {'nginx:1'},
      );
    });

    test('interpolates, and variables win over .env', () {
      File(p.join(root.path, '.env')).writeAsStringSync('TAG=7\nBASE=redis\n');
      final file = write(
        'services:\n'
        '  a:\n    image: \${BASE}:\${TAG}\n'
        '  b:\n    image: nginx:\${MISSING:-1}\n',
      );
      expect(composeFileImages(file, variables: const {'TAG': '8'}), {
        'redis:8',
        'nginx:1',
      });
    });

    test('an image that resolves to nothing is refused', () {
      expect(
        () => composeFileImages(
          write('services:\n  web:\n    image: \${UNSET}\n'),
        ),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
    });

    test('include and extends are refused, not half understood', () {
      expect(
        () => composeFileImages(write('include:\n  - other.yaml\n')),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
      expect(
        () => composeFileImages(
          write(
            'services:\n  web:\n    extends:\n      file: x.yaml\n'
            '      service: y\n',
          ),
        ),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
    });

    test('a nested file may reach its worktree, and no further', () {
      Directory(p.join(root.path, 'deploy')).createSync();
      File(p.join(root.path, 'Dockerfile')).writeAsStringSync('FROM node:22');
      final nested = write(
        'services:\n  web:\n    build:\n      context: ..\n',
        name: 'deploy/compose.yaml',
      );
      expect(composeFileImages(nested, root: root.path), {'node:22'});
      final escaping = write(
        'services:\n  web:\n    build:\n      context: ../..\n',
        name: 'deploy/compose.yaml',
      );
      expect(
        () => composeFileImages(escaping, root: root.path),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
    });

    test('invalid YAML is a named failure', () {
      expect(
        () => composeFileImages(write('services: [')),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
    });
  });

  group('parseComposePs', () {
    test('reads lines and arrays alike', () {
      const row =
          '{"Service":"web","State":"running","Health":"healthy",'
          '"ExitCode":0,"Publishers":[{"PublishedPort":18080},'
          '{"PublishedPort":0},{"PublishedPort":18080}]}';
      for (final output in const [row, '[$row]']) {
        final web = parseComposePs(output).single;
        expect(web.name, 'web');
        expect(web.publishedPorts, [18080]);
        expect(web.isSettled, isTrue);
      }
    });

    test('nothing running yet is an empty list', () {
      expect(parseComposePs('  '), isEmpty);
    });

    test('a one-shot that exited 0 is settled, which --wait gets wrong', () {
      const done = EnvironmentRigService(name: 'seed', state: 'exited');
      expect(done.isSettled, isTrue);
      expect(done.isFailed, isFalse);
    });

    test('a non-zero exit and an unhealthy service have failed', () {
      expect(
        const EnvironmentRigService(
          name: 'a',
          state: 'exited',
          exitCode: 1,
        ).isFailed,
        isTrue,
      );
      expect(
        const EnvironmentRigService(
          name: 'a',
          state: 'running',
          health: 'unhealthy',
        ).isFailed,
        isTrue,
      );
    });

    test('a service still starting is neither', () {
      const starting = EnvironmentRigService(
        name: 'a',
        state: 'running',
        health: 'starting',
      );
      expect(starting.isSettled, isFalse);
      expect(starting.isFailed, isFalse);
    });
  });

  group('environmentRigEndpoints', () {
    const web = EnvironmentRigService(
      name: 'web',
      state: 'running',
      publishedPorts: [80, 443],
    );

    test('gives each forwarded port a unique role', () {
      final endpoints = environmentRigEndpoints(
        [web],
        const {80: 5000, 443: 5001},
      );
      expect(endpoints.map((e) => e.role), ['web', 'web-443']);
      expect(endpoints.map((e) => e.hostPort), [5000, 5001]);
    });

    test('a port with no forward yields no endpoint', () {
      expect(environmentRigEndpoints([web], const {80: 5000}), hasLength(1));
    });

    test('only declared HTTP services get a URL', () {
      expect(
        environmentRigEndpoints(
          [web],
          const {80: 5000},
          http: const ['web'],
        ).single.url,
        'http://127.0.0.1:5000',
      );
      expect(
        environmentRigEndpoints([web], const {80: 5000}).single.url,
        isNull,
      );
    });
  });
}

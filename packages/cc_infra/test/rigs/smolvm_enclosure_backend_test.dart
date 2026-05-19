import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/rigs/qemu_enclosure_backend.dart'
    show RigToolException;
import 'package:cc_infra/src/rigs/rig_browser_defaults.dart'
    show
        RigBrowserHomeTheme,
        browserRigHomeHtml,
        kBrowserRigHomePath,
        kBrowserRigHomeUrl;
import 'package:cc_infra/src/rigs/rig_ports.dart' show kRigPortMuxGuestPort;
import 'package:cc_infra/src/rigs/smolvm_enclosure_backend.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The create argv is where a microVM rig's containment actually lives. A
/// missing `--outbound-localhost-only` or a bare `--net` does not fail any
/// test that only checks behaviour — the machine boots, the shell works, and
/// the enclosure is simply not one. So the flags are pinned here.
void main() {
  SmolvmLaunchPlan plan({
    RigSpec? spec,
    String? image,
    int? devtoolsHostPort,
    int? portMuxHostPort,
    String? secretFilePath = '/data/rigs/smolvm/r1/broker-secret',
    int? credentialPort = 4100,
  }) => SmolvmLaunchPlan(
    rigId: 'r1',
    spec: spec ?? RigSpec.exec(conversationId: 'c1'),
    image: image ?? kSmolvmExecImage,
    dataDir: '/data',
    devtoolsHostPort: devtoolsHostPort,
    portMuxHostPort: portMuxHostPort,
    secretFilePath: secretFilePath,
    credentialPort: credentialPort,
  );

  group('create argv containment', () {
    test(
      'loopback-only outbound is always present and bare --net never is',
      () {
        final args = buildSmolvmCreateArgs(plan());
        expect(
          args,
          contains('--outbound-localhost-only'),
          reason:
              'Without it the guest has no route to the host-loopback '
              'credential broker, and without a bare --net ban nothing stops a '
              'later edit handing the guest unfenced egress.',
        );
        expect(args, isNot(contains('--net')));
      },
    );

    test('every allowlist entry becomes its own --allow-host', () {
      final args = buildSmolvmCreateArgs(
        plan(
          spec: RigSpec.exec(
            conversationId: 'c1',
            egressAllowlist: const ['github.com', '*.githubusercontent.com'],
          ),
        ),
      );
      final hosts = [
        for (var i = 0; i < args.length - 1; i++)
          if (args[i] == '--allow-host') args[i + 1],
      ];
      expect(
        hosts,
        containsAll(['github.com', 'githubusercontent.com']),
        reason: 'A dropped entry reads as a mysterious guest network failure.',
      );
    });

    test('a wildcard entry maps to its apex', () {
      // smolvm has no wildcard syntax and its host entries already match
      // subdomains, so `*.x.com` becomes `x.com` — the smallest faithful
      // widening available.
      expect(mapSmolvmAllowlistEntry('*.example.com'), 'example.com');
      expect(mapSmolvmAllowlistEntry('example.com'), 'example.com');
    });

    test('a MIDDLE-label wildcard is dropped, never widened', () {
      // The only smolvm entry that would cover `bedrock.*.amazonaws.com` is
      // `amazonaws.com`, which admits every S3 bucket in the world — the exact
      // over-grant the middle-label form exists to remove. Widening an entry
      // until it fits the tool is how a narrow rule becomes a broad one with
      // nobody deciding to broaden it.
      expect(mapSmolvmAllowlistEntry('bedrock.*.amazonaws.com'), isNull);
      expect(mapSmolvmAllowlistEntry('*.bedrock.*.amazonaws.com'), isNull);
    });

    test('a dropped entry does not leak its apex into the argv', () {
      final args = buildSmolvmCreateArgs(
        plan(
          spec: RigSpec.exec(
            conversationId: 'c1',
            egressAllowlist: const [
              'bedrock-runtime.*.amazonaws.com',
              'github.com',
            ],
          ),
        ),
      );
      final hosts = [
        for (var i = 0; i < args.length - 1; i++)
          if (args[i] == '--allow-host') args[i + 1],
      ];
      expect(hosts, contains('github.com'));
      expect(
        hosts.any((h) => h.contains('amazonaws')),
        isFalse,
        reason: 'Dropping means dropping, not falling back to the apex.',
      );
    });

    test('the broker secret travels by file reference, never by value', () {
      final args = buildSmolvmCreateArgs(plan());
      final i = args.indexOf('--secret-file');
      expect(i, greaterThanOrEqualTo(0));
      expect(
        args[i + 1],
        'CC_RIG_SECRET=/data/rigs/smolvm/r1/broker-secret',
        reason:
            'Passing the secret as -e CC_RIG_SECRET=... would persist it in '
            'smolvm\'s machine record on disk.',
      );
      // And the env block carries only the coordinates, not the secret.
      final env = [
        for (var i = 0; i < args.length - 1; i++)
          if (args[i] == '-e') args[i + 1],
      ];
      expect(env, contains('CC_BROKER_PORT=4100'));
      expect(env, contains('CC_RIG_ID=r1'));
      expect(env.every((e) => !e.startsWith('CC_RIG_SECRET=')), isTrue);
    });

    test('a machine without a broker gets no broker coordinates', () {
      final args = buildSmolvmCreateArgs(plan(credentialPort: null));
      final env = [
        for (var i = 0; i < args.length - 1; i++)
          if (args[i] == '-e') args[i + 1],
      ];
      expect(env, isEmpty);
    });

    test('ownership labels are on every machine', () {
      final args = buildSmolvmCreateArgs(plan());
      final labels = [
        for (var i = 0; i < args.length - 1; i++)
          if (args[i] == '--label') args[i + 1],
      ];
      expect(labels, contains('cc-owner=control-center'));
      expect(labels, contains('cc-data-dir=/data'));
      expect(labels, contains('cc-rig=r1'));
      expect(
        labels,
        contains('cc-surface=exec'),
        reason:
            'The sweep deletes by label, never by name: a missing label is a '
            'leaked machine.',
      );
    });

    test('an exec machine sizes its disks and forwards only the port mux', () {
      // In production `launch()` always allocates a mux forward for an exec
      // machine — it is the single host→guest hole every future dev-server
      // port is reached through (`rig_ports.dart`), because smolvm's `-p` set
      // is immutable while the machine runs.
      final args = buildSmolvmCreateArgs(plan(portMuxHostPort: 41000));
      expect(args, contains('--storage'));
      expect(args, contains('--overlay'));
      final forwards = [
        for (var i = 0; i < args.length - 1; i++)
          if (args[i] == '-p') args[i + 1],
      ];
      expect(
        forwards,
        ['41000:$kRigPortMuxGuestPort'],
        reason:
            'The port mux is the only host-reachable port an exec rig needs; '
            'every dev-server port rides through it.',
      );
    });

    test('an exec machine with no mux port gets no forwards', () {
      // The pure-data guard: without a mux port allocated, nothing is exposed.
      expect(buildSmolvmCreateArgs(plan()), isNot(contains('-p')));
    });

    test('a cached pack replaces --image and changes nothing else', () {
      final fromRegistry = buildSmolvmCreateArgs(plan(portMuxHostPort: 41000));
      final fromPack = buildSmolvmCreateArgs(
        SmolvmLaunchPlan(
          rigId: 'r1',
          spec: RigSpec.exec(conversationId: 'c1'),
          image: kSmolvmExecImage,
          dataDir: '/data',
          packPath: '/data/rigs/smolvm-packs/pack-abc.smolmachine',
          portMuxHostPort: 41000,
          secretFilePath: '/data/rigs/smolvm/r1/broker-secret',
          credentialPort: 4100,
        ),
      );
      expect(fromPack, contains('--from'));
      expect(
        fromPack,
        contains('/data/rigs/smolvm-packs/pack-abc.smolmachine'),
      );
      expect(fromPack, isNot(contains('--image')));
      // The pack is a faster path to the same bytes, never a different
      // policy: with the source flags removed, both argv are identical —
      // labels, egress filter, forwards, secrets, init, everything.
      List<String> withoutSource(List<String> args) {
        final out = [...args];
        for (final flag in ['--image', '--from']) {
          final at = out.indexOf(flag);
          if (at >= 0) {
            out.removeRange(at, at + 2);
          }
        }
        return out;
      }

      expect(withoutSource(fromPack), withoutSource(fromRegistry));
    });

    test("a custom image's own registry is admitted through the gate", () {
      // The pull happens from INSIDE the gated network, so a workspace image
      // on another registry needs that registry's hosts admitted — or the
      // machine can never boot an uncached image.
      final args = buildSmolvmCreateArgs(
        SmolvmLaunchPlan(
          rigId: 'r1',
          spec: RigSpec.exec(conversationId: 'c1'),
          image: 'ghcr.io/acme/dev-shell:1.2',
          dataDir: '/data',
        ),
      );
      final hosts = [
        for (var i = 0; i < args.length - 1; i++)
          if (args[i] == '--allow-host') args[i + 1],
      ];
      expect(hosts, contains('ghcr.io'));
      expect(hosts, contains('pkg-containers.githubusercontent.com'));
    });

    test('a blocked delete names its path only inside the smolvm VM store', () {
      // The healing path feeds a recursive chmod, so the parser must refuse
      // anything outside smolvm's own store — a corrupted error message must
      // not be able to aim it at the host.
      // Built with p.join: the containment check is separator-strict on
      // purpose (the path feeds a recursive chmod), so the fixture must be
      // shaped like the host smolvm actually reports on THIS platform.
      final vmDir = p.join(
        Platform.isMacOS ? '/Users/x/Library/Caches' : 'C:\\vmcache',
        'smolvm',
        'vms',
        '8d988d1d',
      );
      expect(
        smolvmBlockedDeletePath(
          'Error: storage operation failed: delete machine data: '
          '$vmDir: Permission denied (os error 13)',
        ),
        vmDir,
      );
      expect(
        smolvmBlockedDeletePath('delete machine data: /etc: Permission denied'),
        isNull,
      );
      expect(smolvmBlockedDeletePath('vm not found: x'), isNull);
    });

    test('pack names are keyed on the full pinned reference', () {
      // Same digest → same pack; a bumped pin → a different file, so a stale
      // pack can never serve a new pin and simply falls to the sweep.
      expect(
        smolvmPackFileName(kSmolvmExecImage),
        smolvmPackFileName(kSmolvmExecImage),
      );
      expect(
        smolvmPackFileName(kSmolvmExecImage),
        isNot(smolvmPackFileName(kSmolvmBrowserImage)),
      );
      expect(smolvmPackFileName(kSmolvmExecImage), endsWith('.smolmachine'));
    });

    test('a browser machine forwards exactly one loopback port', () {
      final args = buildSmolvmCreateArgs(
        plan(
          spec: RigSpec(surface: RigSurface.browser, conversationId: 'c1'),
          devtoolsHostPort: 9222,
        ),
      );
      final forwards = [
        for (var i = 0; i < args.length - 1; i++)
          if (args[i] == '-p') args[i + 1],
      ];
      expect(
        forwards,
        ['9222:9222'],
        reason:
            'The DevTools relay is the only host-reachable port a browser rig '
            'needs; anything else is attack surface.',
      );
    });

    test('every machine may reach the pinned images\' registry', () {
      for (final p in [
        plan(),
        plan(
          spec: RigSpec(surface: RigSurface.browser, conversationId: 'c1'),
          devtoolsHostPort: 9222,
        ),
      ]) {
        final args = buildSmolvmCreateArgs(p);
        final hosts = [
          for (var i = 0; i < args.length - 1; i++)
            if (args[i] == '--allow-host') args[i + 1],
        ];
        expect(hosts, contains('docker.io'));
        expect(
          hosts,
          contains('production.cloudflare.docker.com'),
          reason:
              'The guest agent pulls the image through this gate — without '
              'the registry hosts a machine can never boot an unpulled '
              'image. This is image maintenance, not workload policy.',
        );
      }
    });

    test('a Chromium machine installs nothing at boot', () {
      final args = buildSmolvmCreateArgs(
        plan(
          spec: RigSpec(surface: RigSurface.browser, conversationId: 'c1'),
          image: kSmolvmBrowserImage,
          devtoolsHostPort: 9222,
        ),
      );
      expect(
        args,
        isNot(contains('--init')),
        reason:
            'The browser image is baked, not installed: a boot-time package '
            'install is the first-start race that hung CDP behind a dead '
            'forward. The pinned image exists to make it impossible.',
      );
      final hosts = [
        for (var i = 0; i < args.length - 1; i++)
          if (args[i] == '--allow-host') args[i + 1],
      ];
      expect(
        hosts,
        isNot(contains('dl-cdn.alpinelinux.org')),
        reason: 'No install means no package mirror in the egress policy.',
      );
    });

    test('every pinned image carries a digest', () {
      expect(kSmolvmExecImage, contains('@sha256:'));
      expect(kSmolvmBrowserImage, contains('@sha256:'));
      expect(kSmolvmDebianBrowserImage, contains('@sha256:'));
      for (final engine in RigBrowserEngine.values) {
        expect(
          smolvmBrowserImageFor(engine),
          contains('@sha256:'),
          reason:
              'An unpinned image is a different machine on a different day, '
              'and a browser rig is supposed to be a controlled comparison.',
        );
      }
    });

    test('a browser machine fronts DevTools with the image\'s socat relay', () {
      final args = buildSmolvmCreateArgs(
        plan(
          spec: RigSpec(surface: RigSurface.browser, conversationId: 'c1'),
          devtoolsHostPort: 9222,
        ),
      );
      final dashdash = args.indexOf('--');
      expect(dashdash, greaterThanOrEqualTo(0));
      final command = args.sublist(dashdash + 1);
      expect(command.first, 'bash');
      final script = command.last;
      expect(
        script,
        contains('socat TCP4-LISTEN:9222,fork TCP4:127.0.0.1:9223'),
        reason:
            'Chromium ignores --remote-debugging-address and binds DevTools '
            'to loopback unconditionally, and the host -p forward reaches '
            'the guest NIC, never guest loopback. The image bakes in socat '
            'for exactly this (chromedp/docker-headless-shell#31); without '
            'the relay the forward black-holes and the rig never reports '
            'ready.',
      );
      expect(
        script,
        contains('exec /headless-shell/headless-shell'),
        reason:
            'exec keeps the browser the workload\'s main process: when it '
            'dies the machine stops and the rig is reported dead, instead '
            'of wedging behind a still-live relay.',
      );
      expect(script, contains('--remote-debugging-port=9223'));
      expect(
        script,
        isNot(contains('--remote-debugging-address')),
        reason:
            'The flag is dead in current Chromium — carrying it re-embeds '
            'the myth that headless-shell can bind the NIC itself.',
      );
      expect(
        script,
        isNot(contains('--remote-allow-origins')),
        reason:
            'The flag relaxes an origin check that never applies to us — the '
            'host attaches with a Dart WebSocket, which sends no Origin. With '
            'DevTools forwarded to a host port, the wildcard is admission for '
            'a cross-origin drive-by from any local page that can reach it.',
      );
      expect(script, contains('--window-size=1280,800'));
      expect(
        script,
        endsWith(' $kBrowserRigHomeUrl'),
        reason:
            'The rig boots to the home page rather than about:blank — a '
            'white rectangle is indistinguishable from a broken rig.',
      );
    });

    test('the boot home page is local and needs no egress', () {
      final args = buildSmolvmCreateArgs(
        plan(
          spec: RigSpec(surface: RigSurface.browser, conversationId: 'c1'),
          devtoolsHostPort: 9222,
        ),
      );
      final script = args.last;
      // The home URL is a file:// page written into the guest, NOT an external
      // site: the old https default was silently refused by the egress gate
      // (rotated CDN IP) and rendered a blank white "Ready" rig.
      expect(kBrowserRigHomeUrl, startsWith('file://'));
      expect(script, contains('base64 -d > $kBrowserRigHomePath'));
      expect(
        script,
        isNot(contains('http')),
        reason:
            'A boot that depends on reaching an external site over the '
            'deny-by-default egress gate is a blank page waiting to happen.',
      );
    });

    test('dev-domain resolver rules are comma-joined with no stray space', () {
      final script = buildSmolvmBrowserWorkload(
        RigDisplaySize.defaultDesktop,
      ).last;
      // Chromium's rule parser trims, but a lone " MAP" after a comma is an
      // avoidable ambiguity — pin the tight form.
      expect(
        script,
        contains(
          '--host-resolver-rules=MAP *.test 127.0.0.1,MAP *.localhost '
          '127.0.0.1',
        ),
      );
    });

    test('the dev TLS pin rides the workload only when material exists', () {
      // Verified against the real image: WITH the pin, https://secure.test
      // loads through the domain router; WITHOUT it, the same navigation
      // fails with net::ERR_CERT_AUTHORITY_INVALID. The pin names OUR leaf
      // key specifically, so TLS to anything else still validates normally.
      final pinned = buildSmolvmBrowserWorkload(
        RigDisplaySize.defaultDesktop,
        tlsSpkiFingerprint: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      ).last;
      expect(
        pinned,
        contains(
          '--ignore-certificate-errors-spki-list='
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        ),
      );
      final unpinned = buildSmolvmBrowserWorkload(
        RigDisplaySize.defaultDesktop,
      ).last;
      expect(
        unpinned,
        isNot(contains('--ignore-certificate-errors')),
        reason:
            'A host with no TLS material must not carry the flag at all — '
            'an empty pin list is a lie about an HTTPS lane that is not '
            'there.',
      );
    });
  });

  // Firefox and WebKit are not "Chromium with a different binary": each one
  // fails in a way that produces a machine which boots, answers nothing, and
  // reports no error. These pin the three lines that were each paid for by
  // watching exactly that happen.
  group('browser engines', () {
    RigSpec browserSpec(RigBrowserEngine engine) => RigSpec(
      surface: RigSurface.browser,
      browserEngine: engine,
      conversationId: 'c1',
    );

    List<String> argvFor(RigBrowserEngine engine) => buildSmolvmCreateArgs(
      plan(
        spec: browserSpec(engine),
        image: smolvmBrowserImageFor(engine),
        devtoolsHostPort: 41222,
      ),
    );

    String workloadOf(List<String> args) {
      final sep = args.indexOf('--');
      expect(sep, greaterThan(-1), reason: 'a browser machine has a workload');
      return args.sublist(sep + 1).join(' ');
    }

    test('the Firefox workload creates its profile directory', () {
      expect(
        workloadOf(argvFor(RigBrowserEngine.firefox)),
        contains('mkdir -p /tmp/cc-profile'),
        reason:
            'Firefox does not create a --profile directory that does not '
            'exist, and does not complain either: it falls back to a default '
            'profile and never starts its remote agent. Nothing listens on '
            'the debug port, the rig times out on readiness, and the only '
            'symptom is silence.',
      );
    });

    test('the Firefox workload relays the loopback-bound remote agent', () {
      final workload = workloadOf(argvFor(RigBrowserEngine.firefox));
      final endpoint = browserRigEndpointPort(RigBrowserEngine.firefox);
      expect(endpoint, isNot(kBrowserRigGuestPort));
      expect(
        workload,
        contains(
          'socat TCP4-LISTEN:$kBrowserRigGuestPort,fork '
          'TCP4:127.0.0.1:$endpoint',
        ),
        reason:
            'The remote agent binds guest loopback and Firefox has no flag '
            'to change that, so the relay is the only address a host forward '
            'can reach.',
      );
      expect(workload, contains('--remote-debugging-port=$endpoint'));
      expect(
        workload,
        contains('--remote-allow-hosts=127.0.0.1,localhost'),
        reason: 'Firefox validates the Host header on the upgrade.',
      );
      expect(workload, contains('--headless'));
    });

    test('the WebKit workload brings up a display before its driver', () {
      final workload = workloadOf(argvFor(RigBrowserEngine.webkit));
      expect(
        workload,
        contains('Xvfb :99'),
        reason:
            'WebKitGTK has no headless mode: MiniBrowser renders into an X '
            'display or it does not run.',
      );
      expect(
        workload.indexOf('Xvfb'),
        lessThan(workload.indexOf('WebKitWebDriver')),
        reason:
            'A driver that beats Xvfb to the socket fails the session rather '
            'than retrying.',
      );
      expect(
        workload,
        contains('--host=0.0.0.0 --port=$kBrowserRigGuestPort'),
        reason:
            'WebKit\'s driver DOES take a --host, so unlike the other two it '
            'binds the guest NIC itself and needs no relay of its own.',
      );
    });

    test('every browser workload writes the local welcome page', () {
      for (final engine in RigBrowserEngine.values) {
        expect(
          workloadOf(argvFor(engine)),
          contains(kBrowserRigHomePath),
          reason:
              'A rig that boots to nothing cannot be told from a broken one.',
        );
      }
    });

    test('every browser workload writes ITS OWN engine\'s page', () {
      for (final engine in RigBrowserEngine.values) {
        final workload = workloadOf(argvFor(engine));
        expect(
          workload,
          contains(base64Encode(utf8.encode(browserRigHomeHtml(engine)))),
          reason:
              'The welcome page is per-engine — its mark and name say WHICH '
              'browser this tab is, which is the entire reason a rig per '
              'engine exists. A shared page (or the wrong engine\'s) would '
              'pass the mere "writes a page" check above.',
        );
        expect(
          workload,
          isNot(contains('http')),
          reason:
              'The no-external-dependency invariant holds for all three '
              'engines, including the base64 blob: a page whose encoding '
              'happens to spell "http" would erode the grep-level claim the '
              'chromium test pins.',
        );
      }
    });

    test('the spec\'s home theme reaches the page written into the guest', () {
      for (final theme in RigBrowserHomeTheme.values) {
        final workload = workloadOf(
          buildSmolvmCreateArgs(
            plan(
              spec: RigSpec(
                surface: RigSurface.browser,
                browserEngine: RigBrowserEngine.chromium,
                conversationId: 'c1',
                homeTheme: theme,
              ),
              image: smolvmBrowserImageFor(RigBrowserEngine.chromium),
              devtoolsHostPort: 41222,
            ),
          ),
        );
        expect(
          workload,
          contains(
            base64Encode(
              utf8.encode(
                browserRigHomeHtml(RigBrowserEngine.chromium, theme: theme),
              ),
            ),
          ),
          reason:
              'The page is baked at boot, so the scheme has to ride the spec '
              'into the workload — a light app staring at a dark page is the '
              'bug this threads through.',
        );
      }
    });

    test('only the engines that install get the archives in their gate', () {
      List<String> hostsFor(RigBrowserEngine engine) {
        final args = argvFor(engine);
        return [
          for (var i = 0; i < args.length - 1; i++)
            if (args[i] == '--allow-host') args[i + 1],
        ];
      }

      expect(
        hostsFor(RigBrowserEngine.chromium),
        isNot(contains('deb.debian.org')),
        reason:
            'Chromium boots a baked image and installs nothing, so a package '
            'mirror in its egress policy would be a grant nothing uses.',
      );
      for (final engine in [
        RigBrowserEngine.firefox,
        RigBrowserEngine.webkit,
      ]) {
        expect(
          hostsFor(engine),
          containsAll(kBrowserRigAptMirrors),
          reason:
              'A bare Debian cannot become ${engine.label} without the '
              'archives, and the failure would look like a browser that never '
              'appears.',
        );
      }
    });

    test('an installing engine gets an overlay to install into', () {
      for (final engine in [
        RigBrowserEngine.firefox,
        RigBrowserEngine.webkit,
      ]) {
        expect(
          argvFor(engine),
          containsAllInOrder(['--overlay']),
          reason:
              'Without one the apt write fails inside a guest whose only '
              'symptom is a browser that never appears.',
        );
        expect(argvFor(engine), containsAllInOrder(['--init']));
      }
    });

    test('the containment flags hold for every engine', () {
      for (final engine in RigBrowserEngine.values) {
        final args = argvFor(engine);
        expect(args, contains('--outbound-localhost-only'));
        expect(args, isNot(contains('--net')));
        expect(
          args,
          containsAllInOrder(['-p', '41222:$kBrowserRigGuestPort']),
          reason: 'One forward, whichever browser is behind it.',
        );
      }
    });

    test('Firefox and WebKit packs cannot be mistaken for each other', () {
      // They share a base image, so the image reference alone does not
      // identify the pack: warming Firefox and booting WebKit from that pack
      // gives a machine with no WebKit in it.
      expect(
        smolvmBrowserImageFor(RigBrowserEngine.firefox),
        smolvmBrowserImageFor(RigBrowserEngine.webkit),
      );
      final firefox = smolvmPackFileName(
        smolvmBrowserImageFor(RigBrowserEngine.firefox),
        variant: smolvmPackVariantFor(browserSpec(RigBrowserEngine.firefox)),
      );
      final webkit = smolvmPackFileName(
        smolvmBrowserImageFor(RigBrowserEngine.webkit),
        variant: smolvmPackVariantFor(browserSpec(RigBrowserEngine.webkit)),
      );
      expect(firefox, isNot(webkit));
      expect(
        smolvmPackVariantFor(browserSpec(RigBrowserEngine.chromium)),
        isEmpty,
        reason:
            'Chromium keeps the unvariant name so an existing cached pack on '
            'an upgraded host is still the pack it was.',
      );
    });

    test('the endpoint port is the forwarded one only where no relay sits', () {
      expect(
        browserRigEndpointPort(RigBrowserEngine.webkit),
        kBrowserRigGuestPort,
      );
      for (final engine in [
        RigBrowserEngine.chromium,
        RigBrowserEngine.firefox,
      ]) {
        expect(
          browserRigEndpointPort(engine),
          isNot(kBrowserRigGuestPort),
          reason:
              'A relay in front means the endpoint is somewhere else, and '
              'Firefox refuses a Host header naming any other port.',
        );
      }
    });
  });

  group('machine list parsing', () {
    test('parses rows with labels and pids', () {
      final machines = parseSmolvmMachineList(
        jsonEncode([
          {
            'name': 'ccrig-r1',
            'state': 'running',
            'pid': 42,
            'labels': {'cc-owner': 'control-center', 'cc-rig': 'r1'},
          },
          {
            'name': 'ccrig-r2',
            'state': 'created',
            'labels': <String, String>{},
          },
        ]),
      );
      expect(machines, hasLength(2));
      expect(machines.first.name, 'ccrig-r1');
      expect(machines.first.running, isTrue);
      expect(machines.first.labels['cc-rig'], 'r1');
      expect(machines.last.running, isFalse);
    });

    test('a malformed document reads as no machines, never a crash', () {
      expect(parseSmolvmMachineList('not json'), isEmpty);
      expect(parseSmolvmMachineList('{}'), isEmpty);
      expect(parseSmolvmMachineList('[42, null, "x"]'), isEmpty);
    });
  });

  group('sweep', () {
    test('deletes only machines carrying this server\'s labels', () async {
      final dataDir = await Directory.systemTemp.createTemp('smolvm-sweep');
      addTearDown(() => dataDir.delete(recursive: true));
      final calls = <List<String>>[];
      final listing = jsonEncode([
        {
          'name': 'ccrig-ours',
          'state': 'running',
          'pid': 1,
          'labels': {'cc-owner': 'control-center', 'cc-data-dir': dataDir.path},
        },
        {
          'name': 'ccrig-other-server',
          'state': 'running',
          'pid': 2,
          'labels': {
            'cc-owner': 'control-center',
            'cc-data-dir': '/somewhere/else',
          },
        },
        {
          'name': 'ccrig-user-owned',
          'state': 'running',
          'pid': 3,
          'labels': <String, String>{},
        },
      ]);
      Future<ProcessResult> fakeRun(String exe, List<String> args) async {
        calls.add(args);
        if (args.contains('ls')) {
          return ProcessResult(0, 0, listing, '');
        }
        return ProcessResult(0, 0, '', '');
      }

      final backend = SmolvmEnclosureBackend(
        dataDir: dataDir.path,
        binaryPath: '/fake/smolvm',
        runFn: fakeRun,
        // No grace: this test is about the sweep's DECISION, not about the
        // "a boot may be in flight" window that protects a runtime dir whose
        // `machine create` has not registered its name yet.
        runtimeDirGrace: Duration.zero,
      );
      // A runtime dir whose machine is not in the listing is debris.
      await Directory(
        '${dataDir.path}/rigs/smolvm/dead-rig',
      ).create(recursive: true);
      final removed = await backend.sweepOrphanedRuntimes();

      expect(removed, 1);
      final deletes = calls.where((c) => c.contains('delete')).toList();
      expect(deletes, hasLength(1));
      expect(deletes.single, contains('ccrig-ours'));
      expect(
        calls.where((c) => c.contains('ccrig-other-server')),
        isEmpty,
        reason: 'Another server instance\'s machines are not ours to reap.',
      );
      expect(calls.where((c) => c.contains('ccrig-user-owned')), isEmpty);
      expect(
        Directory('${dataDir.path}/rigs/smolvm/dead-rig').existsSync(),
        isFalse,
      );
    });
  });

  group('launch failure', () {
    test(
      'a failed create leaves neither machine record nor runtime dir',
      () async {
        final dataDir = await Directory.systemTemp.createTemp('smolvm-fail');
        addTearDown(() => dataDir.delete(recursive: true));
        final calls = <List<String>>[];
        Future<ProcessResult> fakeRun(String exe, List<String> args) async {
          calls.add(args);
          if (args.contains('create')) {
            return ProcessResult(0, 1, '', 'no space left on device');
          }
          return ProcessResult(0, 0, '', '');
        }

        final backend = SmolvmEnclosureBackend(
          dataDir: dataDir.path,
          binaryPath: '/fake/smolvm',
          runFn: fakeRun,
        );
        await expectLater(
          backend.launch(
            rigId: 'r9',
            spec: RigSpec.exec(conversationId: 'c1'),
          ),
          throwsA(isA<RigToolException>()),
        );
        expect(
          calls.where((c) => c.contains('delete') && c.contains('ccrig-r9')),
          isNotEmpty,
          reason:
              'A half-created machine in smolvm\'s global store is a leak '
              'visible to every later rig.',
        );
        expect(
          Directory('${dataDir.path}/rigs/smolvm/r9').existsSync(),
          isFalse,
          reason: 'The broker-secret file must not outlive the failed rig.',
        );
      },
    );
  });
}

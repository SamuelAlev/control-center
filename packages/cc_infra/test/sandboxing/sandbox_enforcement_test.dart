import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// End-to-end proof that the OS sandbox is actually ENFORCED, not merely
/// configured.
///
/// This exists because the whole chain — resolver, policy, profile emitter —
/// was correct and fully unit-tested while agent dispatch silently ran with
/// `NoSandboxAdapter()`, so `SandboxSpec.protectedPaths` was computed on every
/// dispatch and then thrown away. Every unit test still passed. The only thing
/// that catches that class of regression is spawning a real process and
/// checking what it can write.
void main() {
  group(
    'sandbox enforcement (real process)',
    () {
      late Directory root;
      late Directory work;
      late Directory protected;
      late SandboxManager manager;

      setUp(() {
        root = Directory.systemTemp.createTempSync('cc-sbx-enforce-');
        work = Directory('${root.path}/work')..createSync(recursive: true);
        protected = Directory('${root.path}/checkout')
          ..createSync(recursive: true);
        File('${protected.path}/tracked.txt').writeAsStringSync('original\n');
        manager = SandboxManager();
      });

      tearDown(() async {
        await manager.disposeSession('enforcement-test');
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      Future<ProcessResult> runSandboxed(String script) async {
        final spec = SandboxSpec(
          sessionId: 'enforcement-test',
          workspaceId: 'ws',
          agentId: 'agent',
          // Only the agent's own worktree is mounted, exactly as dispatch does.
          bindMounts: [
            SandboxBindMount(hostPath: work.path, guestPath: work.path),
          ],
          guestWorkdir: work.path,
          networkEnabled: false,
          mode: Mode.chat,
          protectedPaths: [protected.path],
        );
        final config = await buildSandboxConfigFromPolicy(
          const SandboxPolicyResolver().resolve(
            spec: spec,
            homeDir: Platform.environment['HOME'],
            runDir: '${work.path}/.cc-runs/enforcement-test',
          ),
        );
        final wrap = await manager.wrap(
          config: config,
          argv: ['bash', '-lc', script],
          workingDirectory: work.path,
        );
        final process = await Process.start(
          wrap.executable,
          wrap.argv,
          workingDirectory: work.path,
          environment: wrap.environment,
          runInShell: false,
        );
        final stdoutText = await process.stdout
            .transform(const SystemEncoding().decoder)
            .join();
        final stderrText = await process.stderr
            .transform(const SystemEncoding().decoder)
            .join();
        return ProcessResult(
          process.pid,
          await process.exitCode,
          stdoutText,
          stderrText,
        );
      }

      test('a sandboxed command still runs', () async {
        final result = await runSandboxed('echo alive');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('alive'));
      });

      test('writes inside the agent worktree are allowed', () async {
        final result = await runSandboxed('echo ok > ${work.path}/out.txt');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(File('${work.path}/out.txt').existsSync(), isTrue);
      });

      test('writes to a protected checkout are denied', () async {
        final target = '${protected.path}/tracked.txt';
        final result = await runSandboxed('echo pwned > $target');
        expect(
          result.exitCode,
          isNot(0),
          reason: 'the write should have been refused by the sandbox',
        );
        expect(
          File(target).readAsStringSync().trim(),
          'original',
          reason:
              'SandboxSpec.protectedPaths must survive as a deny-write rule',
        );
      });

      test(
        'a protected path reached through a symlink is still denied',
        () async {
          // macOS resolves /var/folders -> /private/var/folders (and /tmp ->
          // /private/tmp) before matching, so a rule written against the
          // unresolved spelling never fires. `Directory.systemTemp` is exactly
          // that case, which is why this test uses it rather than $HOME.
          final target = '${protected.path}/tracked.txt';
          final resolved = protected.resolveSymbolicLinksSync();
          expect(
            resolved,
            isNot(protected.path),
            reason: 'this test is only meaningful on a symlinked temp root',
            skip: resolved == protected.path,
          );
          final result = await runSandboxed(
            'echo pwned > $resolved/tracked.txt',
          );
          expect(result.exitCode, isNot(0));
          expect(File(target).readAsStringSync().trim(), 'original');
        },
      );
    },
    // The production Linux policy contains wildcard secret write-denies.
    // bwrap cannot enforce them for newly created names, so wrap refuses
    // BEFORE spawning. The unit test pins that refusal; these real-process
    // checks remain for macOS Seatbelt's pathname-pattern support.
    skip: _skipReason(),
  );

  group('network enforcement (real process)', () {
    late SandboxManager manager;
    late HttpServer target;
    late HttpServer gateway;
    late List<String> requests;

    setUp(() async {
      manager = SandboxManager();
      requests = [];
      target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      gateway = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      target.listen((request) async {
        requests.add(request.uri.path);
        request.response.write('allowed destination');
        await request.response.close();
      });
      gateway.listen((request) async {
        request.response.write('agent gateway');
        await request.response.close();
      });
    });

    tearDown(() async {
      await manager.reset();
      await target.close(force: true);
      await gateway.close(force: true);
    });

    Future<ProcessResult> curl(
      String url, {
      bool direct = false,
      bool socks = false,
      bool networkOff = false,
    }) async {
      final wrap = await manager.wrap(
        config: SandboxConfig(
          sessionId: 'network-enforcement',
          network: NetworkConfig(
            allowAll: false,
            allowedDomains: networkOff ? const [] : const ['127.0.0.1'],
            loopbackPorts: [gateway.port],
          ),
          filesystem: const FilesystemConfig(),
        ),
        argv: [
          '/bin/sh',
          '-c',
          if (direct)
            'unset HTTP_PROXY HTTPS_PROXY ALL_PROXY FTP_PROXY '
                'http_proxy https_proxy all_proxy ftp_proxy; '
                'exec /usr/bin/curl -fsS --max-time 5 --noproxy "*" "\$1"'
          else if (socks)
            'exec /usr/bin/curl -fsS --max-time 5 --noproxy "" '
                '--proxy "socks5h://\${ALL_PROXY#*://}" "\$1"'
          else
            'exec /usr/bin/curl -fsS --max-time 5 --noproxy "" "\$1"',
          'network-probe',
          url,
        ],
      );
      return Process.run(
        wrap.executable,
        wrap.argv,
        environment: wrap.environment,
      );
    }

    test('HTTP and SOCKS allow only admitted destinations', () async {
      for (final socks in [false, true]) {
        final path = socks ? '/socks' : '/http';
        final allowed = await curl(
          'http://127.0.0.1:${target.port}$path',
          socks: socks,
        );
        expect(allowed.exitCode, 0, reason: '${allowed.stderr}');
        expect(allowed.stdout, 'allowed destination');

        // Same reachable server, but its hostname is outside the allowlist.
        final denied = await curl(
          'http://localhost:${target.port}/denied',
          socks: socks,
        );
        expect(denied.exitCode, isNot(0), reason: '${denied.stderr}');
      }
      expect(requests, ['/http', '/socks']);
    });

    test('clearing proxies cannot bypass IPv4 or IPv6 confinement', () async {
      final ipv6 = await HttpServer.bind(InternetAddress.loopbackIPv6, 0);
      addTearDown(() => ipv6.close(force: true));
      ipv6.listen((request) async {
        requests.add('/ipv6-bypass');
        await request.response.close();
      });
      for (final url in [
        'http://127.0.0.1:${target.port}/ipv4-bypass',
        'http://[::1]:${ipv6.port}/ipv6-bypass',
      ]) {
        final result = await curl(url, direct: true);
        expect(result.exitCode, isNot(0), reason: '$url: ${result.stderr}');
      }
      expect(requests, isEmpty);

      // The MCP/approval endpoint remains usable with the same profile.
      final result = await curl(
        'http://127.0.0.1:${gateway.port}/',
        direct: true,
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, 'agent gateway');
    });

    test(
      'network-off denies proxy and direct access but retains gateway',
      () async {
        for (final direct in [false, true]) {
          final result = await curl(
            'http://127.0.0.1:${target.port}/network-off',
            direct: direct,
            networkOff: true,
          );
          expect(result.exitCode, isNot(0), reason: '${result.stderr}');
        }
        expect(requests, isEmpty);
        final result = await curl(
          'http://127.0.0.1:${gateway.port}/',
          direct: true,
          networkOff: true,
        );
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(result.stdout, 'agent gateway');
      },
    );
  }, skip: !Platform.isMacOS ? 'requires macOS Seatbelt' : false);
}

String? _skipReason() => Platform.isMacOS
    ? null
    : Platform.isLinux
    ? 'bwrap cannot enforce secret filename globs; Linux fails closed'
    : 'no OS-native sandbox backend on ${Platform.operatingSystem}';

import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/agent_shell_output.dart';
import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_infra/src/process/agent_shell_file_output.dart';
import 'package:cc_infra/src/process/agent_shell_process_service.dart';
import 'package:test/test.dart';

class _RunLogs implements AgentRunLogRepository {
  _RunLogs(this.active);

  final List<AgentRunLog> active;
  final queried = <(String, String)>[];

  @override
  Stream<List<AgentRunLog>> watchActiveBySpace(
    String workspaceId,
    String spaceId,
  ) {
    queried.add((workspaceId, spaceId));
    return Stream.value([
      for (final r in active)
        if (r.workspaceId == workspaceId && r.spaceId == spaceId) r,
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// The shape of a live Claude Code run, from a real host: the dispatch's
// `bash -c cd … && claude` wrapper, the CLI, one command shell (a vitest run
// with a nested pipeline shell and workers), and a fresh `ls` still under
// the minimum age.
const _claudeCommand =
    r'/bin/zsh -c source /data/claude-accounts/account/shell-snapshots/'
    r'snapshot-zsh-1-x.sh 2>/dev/null || true && setopt NO_EXTENDED_GLOB '
    r"2>/dev/null || true && eval 'cd repos/web-app && node vitest.mjs run "
    r"--shard=2/10 > /tmp/shard2.log 2>&1; echo '\''done'\''' < /dev/null "
    r'&& pwd -P >| /tmp/claude-1-cwd';

const _ps =
    '  100     1   02:00:00 /bin/bash -c cd /data/ws/spaces/s1/agents/a && '
    '/usr/bin/claude -p --output-format stream-json\n'
    '  101   100   01:59:58 /usr/bin/claude -p --output-format stream-json\n'
    '  102   101   01:59:50 npm exec @acme/mcp-server\n'
    '  103   102   01:59:49 sh -c acme-mcp-server\n'
    '  200   101      04:12 $_claudeCommand\n'
    '  201   200      04:12 node vitest.mjs run --shard=2/10\n'
    '  202   201      04:10 node worker.js\n'
    '  203   200      04:12 /bin/zsh -c source x && eval \'grep FAIL\'\n'
    '  300   101      00:01 /bin/zsh -c eval \'ls\'\n'
    '  900     1   10:00:00 /bin/bash -c sleep 1000\n';

// The service walks no `ps` tree on Windows: CLI commands are listed and
// killed on POSIX hosts only.
final Object _noPsWalk = Platform.isWindows
    ? 'the CLI command walk reads ps, which Windows does not have'
    : false;

void main() {
  group('parseEtime', () {
    test('reads every ps elapsed shape', () {
      expect(parseEtime('00:07'), const Duration(seconds: 7));
      expect(parseEtime('04:12'), const Duration(minutes: 4, seconds: 12));
      expect(parseEtime('02:00:00'), const Duration(hours: 2));
      expect(
        parseEtime('3-01:02:03'),
        const Duration(days: 3, hours: 1, minutes: 2, seconds: 3),
      );
      expect(parseEtime('garbage'), isNull);
    });
  });

  group('agentCommandOf', () {
    test("unwraps Claude Code's eval line, quotes and all", () {
      expect(
        agentCommandOf(_claudeCommand),
        'cd repos/web-app && node vitest.mjs run --shard=2/10 > '
        "/tmp/shard2.log 2>&1; echo 'done'",
      );
    });

    test('takes the command string of a bash -lc line', () {
      expect(agentCommandOf('bash -lc npm run dev'), 'npm run dev');
      expect(agentCommandOf('/bin/bash --login -c make test'), 'make test');
    });

    test('restores newlines ps escaped', () {
      expect(
        agentCommandOf(r"/bin/zsh -c eval 'echo a\012echo b' < /dev/null"),
        'echo a\necho b',
      );
    });
  });

  group('cliCommandShells', () {
    test("lists only the CLI's own shells, never the launcher or MCP", () {
      final rows = parsePsRows(_ps);
      expect(
        cliCommandShells(rows, 100).map((r) => r.pid),
        unorderedEquals([200, 300]),
      );
    });

    test('falls back to the first program under the launch chain', () {
      final rows = parsePsRows(
        '  10     1  10:00 /bin/bash -c cd /x && my-agent run\n'
        '  11    10  10:00 my-agent run\n'
        '  12    11  05:00 bash -lc pnpm dev\n',
      );
      expect(cliCommandShells(rows, 10).map((r) => r.pid), [12]);
    });
  });

  group('AgentShellProcessService', () {
    final now = DateTime.utc(2026, 10, 9, 12);
    AgentRunLog run({String space = 's1', int pid = 100}) => AgentRunLog(
      id: 'run-1',
      agentId: 'engineer',
      workspaceId: 'ws',
      spaceId: space,
      startedAt: now.subtract(const Duration(hours: 2, minutes: 1)),
      status: RunStatus.running,
      pid: pid,
    );

    AgentShellProcessService service(
      _RunLogs logs, {
      HarnessShellRegistry? harness,
      List<(int, ProcessSignal)>? signals,
    }) => AgentShellProcessService(
      runLogs: logs,
      harnessShells: harness ?? HarnessShellRegistry(),
      psSnapshot: () async => _ps,
      signal: (pid, sig) {
        signals?.add((pid, sig));
        return true;
      },
      now: () => now,
      serverPid: 1,
    );

    test('lists the space’s long-running CLI commands, unwrapped', () async {
      final found = await service(
        _RunLogs([run()]),
      ).list(workspaceId: 'ws', spaceId: 's1');
      expect(found, hasLength(1));
      final p = found.single;
      expect(p.pid, 200);
      expect(p.origin, AgentShellOrigin.cli);
      expect(p.agentId, 'engineer');
      expect(p.runId, 'run-1');
      expect(p.command, startsWith('cd repos/web-app && node vitest.mjs'));
      expect(
        p.startedAt,
        now.subtract(const Duration(minutes: 4, seconds: 12)),
      );
    }, skip: _noPsWalk);

    test('another space sees nothing of this run', () async {
      final found = await service(
        _RunLogs([run()]),
      ).list(workspaceId: 'ws', spaceId: 's2');
      expect(found, isEmpty);
    });

    test('a recycled root pid is not walked', () async {
      // The run started an hour ago; pid 900 has been alive for ten.
      final found = await service(
        _RunLogs([run(pid: 900)]),
      ).list(workspaceId: 'ws', spaceId: 's1');
      expect(found, isEmpty);
    });

    test('the server pid never roots a walk', () async {
      final found = await service(
        _RunLogs([run(pid: 1)]),
      ).list(workspaceId: 'ws', spaceId: 's1');
      expect(found, isEmpty);
    });

    test('kill signals the command tree, nothing else', () async {
      final signals = <(int, ProcessSignal)>[];
      final killed = await service(
        _RunLogs([run()]),
        signals: signals,
      ).kill(workspaceId: 'ws', spaceId: 's1', pid: 200);
      expect(killed, isTrue);
      expect(
        {
          for (final (p, s) in signals)
            if (s == ProcessSignal.sigterm) p,
        },
        {200, 201, 202, 203},
      );
    }, skip: _noPsWalk);

    test('kill refuses a pid the space does not own', () async {
      final signals = <(int, ProcessSignal)>[];
      final svc = service(_RunLogs([run()]), signals: signals);
      // The CLI itself, an MCP server, an unrelated process, and a real
      // command asked for from the wrong space.
      for (final pid in [101, 103, 900]) {
        expect(
          await svc.kill(workspaceId: 'ws', spaceId: 's1', pid: pid),
          isFalse,
        );
      }
      expect(
        await svc.kill(workspaceId: 'ws', spaceId: 's2', pid: 200),
        isFalse,
      );
      expect(signals, isEmpty);
    });

    test('harness commands are listed per space once past the min age', () {
      final harness = HarnessShellRegistry();
      final close = harness.register(
        pid: 4242,
        workspaceId: 'ws',
        spaceId: 's1',
        agentId: 'builder',
        command: 'pnpm build',
      );
      harness.register(
        pid: 4343,
        workspaceId: 'ws',
        spaceId: 's2',
        agentId: 'builder',
        command: 'pnpm lint',
      );
      expect(harness.forSpace('ws', 's1').map((p) => p.command), [
        'pnpm build',
      ]);
      close();
      expect(harness.forSpace('ws', 's1'), isEmpty);
    });
    test('reads bounded CLI file output, then retains final snapshot without '
        'following a recycled pid', () async {
      final temp = Directory.systemTemp.createTempSync('shell-output-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final path = '${temp.resolveSymbolicLinksSync()}/command.log';
      final file = File(path)..writeAsStringSync('before\n');
      var ps = _ps;
      var clock = now;
      var descriptorCalls = 0;
      final svc = AgentShellProcessService(
        runLogs: _RunLogs([run()]),
        harnessShells: HarnessShellRegistry(),
        psSnapshot: () async => ps,
        fileOutput: AgentShellFileOutput(
          descriptors: (pid) async {
            descriptorCalls++;
            return 'p$pid\nf1\ntREG\nn$path\nf2\ntREG\nn$path\n';
          },
        ),
        now: () => clock,
        serverPid: 1,
      );
      final first = (await svc.list(workspaceId: 'ws', spaceId: 's1')).single;
      final second = (await svc.list(workspaceId: 'ws', spaceId: 's1')).single;
      expect(second.outputId, first.outputId);
      expect(
        () => svc.readOutput(
          workspaceId: 'other',
          spaceId: 's1',
          outputId: first.outputId,
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect(
        () => svc.readOutput(
          workspaceId: 'ws',
          spaceId: 'other',
          outputId: first.outputId,
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect(descriptorCalls, 0);
      var snapshot = await svc.readOutput(
        workspaceId: 'ws',
        spaceId: 's1',
        outputId: first.outputId,
      );
      expect(snapshot.state, AgentShellOutputState.running);
      expect(snapshot.output, 'before\n'); // same file on fd1+fd2, not doubled
      file.writeAsStringSync('after\n', mode: FileMode.append);
      snapshot = await svc.readOutput(
        workspaceId: 'ws',
        spaceId: 's1',
        outputId: first.outputId,
      );
      expect(snapshot.output, 'before\nafter\n');
      file.renameSync('$path.old');
      File(path).writeAsStringSync('impostor\n');
      snapshot = await svc.readOutput(
        workspaceId: 'ws',
        spaceId: 's1',
        outputId: first.outputId,
      );
      expect(snapshot.output, 'before\nafter\n');
      ps = _ps.replaceFirst('  200   101      04:12', '  200   101   09:00:00');
      clock = clock.add(const Duration(seconds: 1));
      snapshot = await svc.readOutput(
        workspaceId: 'ws',
        spaceId: 's1',
        outputId: first.outputId,
      );
      expect(snapshot.state, AgentShellOutputState.exited);
      expect(snapshot.output, 'before\nafter\n');
      expect(descriptorCalls, 1); // retained fd, not a recycled pid's pathname
      expect(
        await svc.list(workspaceId: 'ws', spaceId: 's1'),
        isNot(contains(first)),
      );
      ps = _ps.replaceFirst('  200   101      04:12', '  200   101      00:08');
      clock = clock.add(const Duration(seconds: 1));
      final reused = (await svc.list(workspaceId: 'ws', spaceId: 's1')).single;
      expect(reused.pid, first.pid);
      expect(reused.outputId, isNot(first.outputId));
      expect(
        (await svc.readOutput(
          workspaceId: 'ws',
          spaceId: 's1',
          outputId: first.outputId,
        )).state,
        AgentShellOutputState.exited,
      );
    }, skip: _noPsWalk);

    test(
      'does not expose output first opened after its process identity exits',
      () async {
        final temp = Directory.systemTemp.createTempSync('shell-output-race-');
        addTearDown(() => temp.deleteSync(recursive: true));
        final path = '${temp.resolveSymbolicLinksSync()}/replacement.log';
        File(path).writeAsStringSync('another process output');
        var ps = _ps;
        final svc = AgentShellProcessService(
          runLogs: _RunLogs([run()]),
          harnessShells: HarnessShellRegistry(),
          psSnapshot: () async => ps,
          fileOutput: AgentShellFileOutput(
            descriptors: (pid) async {
              ps = '';
              return 'p$pid\nf1\ntREG\nn$path\n';
            },
          ),
          now: () => now,
          serverPid: 1,
        );
        final process = (await svc.list(
          workspaceId: 'ws',
          spaceId: 's1',
        )).single;
        final snapshot = await svc.readOutput(
          workspaceId: 'ws',
          spaceId: 's1',
          outputId: process.outputId,
        );
        expect(snapshot.output, isEmpty);
        expect(snapshot.state, AgentShellOutputState.unavailable);
        final next = await svc.readOutput(
          workspaceId: 'ws',
          spaceId: 's1',
          outputId: process.outputId,
        );
        expect(
          next.output,
          isEmpty,
          reason: 'the provisional descriptor is discarded',
        );
      },
      skip: _noPsWalk,
    );

    test('rejects links, pipes, and unreadable CLI descriptors', () async {
      final temp = Directory.systemTemp.createTempSync('shell-fd-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final path = '${temp.resolveSymbolicLinksSync()}/capture.log';
      File(path).writeAsStringSync('secret\n');
      final reader = AgentShellFileOutput(
        descriptors: (pid) async => 'p$pid\nf1\ntPIPE\nn$path\n',
      );
      expect(await reader.read(200), isNull);
      final link = Link('$path.link')..createSync(path);
      final links = AgentShellFileOutput(
        descriptors: (pid) async => 'p$pid\nf1\ntREG\nn${link.path}\n',
      );
      expect(await links.read(200), isNull);
    }, skip: _noPsWalk);

    test('truncates by bytes and tolerates partial UTF-8', () async {
      final temp = Directory.systemTemp.createTempSync('shell-utf8-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final path = '${temp.resolveSymbolicLinksSync()}/capture.log';
      File(path).writeAsStringSync('${'x' * AgentShellFileOutput.maxBytes}☃');
      final reader = AgentShellFileOutput(
        descriptors: (pid) async => 'p$pid\nf1\ntREG\nn$path\n',
      );
      final output = await reader.read(200);
      expect(output?.truncated, isTrue);
      expect(output?.output, endsWith('☃'));
      expect(
        output!.output.length,
        lessThanOrEqualTo(AgentShellFileOutput.maxBytes),
      );
    }, skip: _noPsWalk);
    test(
      'reports unsupported CLI capture as unavailable, not empty success',
      () async {
        final svc = AgentShellProcessService(
          runLogs: _RunLogs([run()]),
          harnessShells: HarnessShellRegistry(),
          psSnapshot: () async => _ps,
          fileOutput: AgentShellFileOutput(
            descriptors: (pid) async => 'p$pid\nf1\ntPIPE\nnignored\n',
          ),
          now: () => now,
          serverPid: 1,
        );
        final outputId = (await svc.list(
          workspaceId: 'ws',
          spaceId: 's1',
        )).single.outputId;
        final snapshot = await svc.readOutput(
          workspaceId: 'ws',
          spaceId: 's1',
          outputId: outputId,
        );
        expect(snapshot.state, AgentShellOutputState.unavailable);
        expect(snapshot.output, isEmpty);
      },
      skip: _noPsWalk,
    );

    test('rejects an fd whose pathname was replaced before opening', () async {
      final temp = Directory.systemTemp.createTempSync('shell-inode-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final path = '${temp.resolveSymbolicLinksSync()}/capture.log';
      File(path).writeAsStringSync('not the original descriptor');
      final reader = AgentShellFileOutput(
        descriptors: (pid) async =>
            'p$pid\nf1\ntREG\ni1\nD0xdeadbeef\nn$path\n',
      );
      expect(await reader.read(200), isNull);
    }, skip: Platform.isMacOS ? false : 'macOS lsof inode/device validation');
  });
}

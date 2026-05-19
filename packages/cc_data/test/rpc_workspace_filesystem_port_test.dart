import 'dart:io';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart'
    show WorkspaceFilesystemPort;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcWorkspaceFilesystemPort] — the thin-client filesystem adapter
/// that forwards every [WorkspaceFilesystemPort] method to an `fs.*` RPC op.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcWorkspaceFilesystemPort path accessors', () {
    test(
      'each path accessor calls the right fs.* op and returns the path',
      () async {
        final port = RpcWorkspaceFilesystemPort(client);
        host.callResults['fs.workspaceDir'] = {'path': '/srv/ws'};
        host.callResults['fs.spacesDir'] = {'path': '/srv/ws/convos'};
        host.callResults['fs.skillsDir'] = {'path': '/srv/ws/skills'};
        host.callResults['fs.agentsDir'] = {'path': '/srv/ws/agents'};

        expect(await port.workspaceDir('ws'), '/srv/ws');
        expect(await port.spacesDir('ws'), '/srv/ws/convos');
        expect(await port.skillsDir('ws'), '/srv/ws/skills');
        expect(await port.agentsDir('ws'), '/srv/ws/agents');
      },
    );

    test('spaceDir passes the conversation_id', () async {
      host.callResults['fs.spaceDir'] = {'path': '/srv/ws/convos/c-1'};
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.spaceDir('ws', 'c-1'), '/srv/ws/convos/c-1');
      expect(
        host.lastCall('fs.spaceDir')!.args['conversation_id'],
        'c-1',
      );
    });

    test('skillDir passes the slug', () async {
      host.callResults['fs.skillDir'] = {'path': '/srv/ws/skills/my-skill'};
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.skillDir('ws', 'my-skill'), '/srv/ws/skills/my-skill');
      expect(host.lastCall('fs.skillDir')!.args['skill_slug'], 'my-skill');
    });

    test('agentDir passes the slug', () async {
      host.callResults['fs.agentDir'] = {'path': '/srv/ws/agents/architect'};
      final port = RpcWorkspaceFilesystemPort(client);
      expect(
        await port.agentDir('ws', 'architect'),
        '/srv/ws/agents/architect',
      );
    });

    test('prCloneDir passes owner + repo', () async {
      host.callResults['fs.prCloneDir'] = {'path': '/srv/ws/pr/o-r'};
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.prCloneDir('ws', 'o', 'r'), '/srv/ws/pr/o-r');
      final call = host.lastCall('fs.prCloneDir')!;
      expect(call.args['owner'], 'o');
      expect(call.args['repo'], 'r');
    });
  });

  group('RpcWorkspaceFilesystemPort content + slugs', () {
    test('readSkillFile returns the content', () async {
      host.callResults['fs.readSkillFile'] = {'content': '# My Skill'};
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.readSkillFile('ws', 'my-skill'), '# My Skill');
    });

    test('readSkillFile returns null when missing', () async {
      host.callResults['fs.readSkillFile'] = {};
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.readSkillFile('ws', 'my-skill'), isNull);
    });

    test('listAgentSlugs decodes the slugs list', () async {
      host.callResults['fs.listAgentSlugs'] = {
        'slugs': ['architect', 'coder'],
      };
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.listAgentSlugs('ws'), ['architect', 'coder']);
    });

    test('listSkillSlugs decodes the slugs list', () async {
      host.callResults['fs.listSkillSlugs'] = {
        'slugs': ['lint', 'test'],
      };
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.listSkillSlugs('ws'), ['lint', 'test']);
    });
  });

  group('RpcWorkspaceFilesystemPort mutations', () {
    test('ensureSpaceDir returns the ensured path', () async {
      host.callResults['fs.ensureSpaceDir'] = {
        'path': '/srv/ws/convos/c-1',
      };
      final port = RpcWorkspaceFilesystemPort(client);
      expect(
        await port.ensureSpaceDir('ws', 'c-1'),
        '/srv/ws/convos/c-1',
      );
    });

    test('writeString sends content + path', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.writeString('/srv/file.txt', 'hello');
      final call = host.lastCall('fs.writeString')!;
      expect(call.args['path'], '/srv/file.txt');
      expect(call.args['content'], 'hello');
    });

    test('ensureWorkspaceDirs calls the op', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.ensureWorkspaceDirs('ws');
      expect(host.lastCall('fs.ensureWorkspaceDirs'), isNotNull);
    });

    test('ensureDir forwards the opaque path', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.ensureDir('/srv/nested');
      expect(host.lastCall('fs.ensureDir')!.args['path'], '/srv/nested');
    });
  });

  group('RpcWorkspaceFilesystemPort remaining accessors', () {
    test('skillFilePath passes the slug', () async {
      host.callResults['fs.skillFilePath'] = {
        'path': '/srv/ws/skills/s/SKILL.md',
      };
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.skillFilePath('ws', 's'), '/srv/ws/skills/s/SKILL.md');
      expect(host.lastCall('fs.skillFilePath')!.args['skill_slug'], 's');
    });

    test('agentFilePath passes the slug', () async {
      host.callResults['fs.agentFilePath'] = {
        'path': '/srv/ws/agents/a/AGENT.md',
      };
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.agentFilePath('ws', 'a'), '/srv/ws/agents/a/AGENT.md');
      expect(host.lastCall('fs.agentFilePath')!.args['agent_slug'], 'a');
    });

    test('agentSkillsLinkDir passes the slug', () async {
      host.callResults['fs.agentSkillsLinkDir'] = {
        'path': '/srv/ws/agents/a/skills',
      };
      final port = RpcWorkspaceFilesystemPort(client);
      expect(
        await port.agentSkillsLinkDir('ws', 'a'),
        '/srv/ws/agents/a/skills',
      );
      expect(host.lastCall('fs.agentSkillsLinkDir')!.args['agent_slug'], 'a');
    });
  });

  group('RpcWorkspaceFilesystemPort agent/skill mutations', () {
    test('ensureAgentDir forwards the slug', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.ensureAgentDir('ws', 'a');
      expect(host.lastCall('fs.ensureAgentDir')!.args['agent_slug'], 'a');
    });

    test('ensureMcpSymlink forwards the slug', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.ensureMcpSymlink('ws', 'a');
      expect(host.lastCall('fs.ensureMcpSymlink')!.args['agent_slug'], 'a');
    });

    test('writeAgentFile forwards slug + content', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.writeAgentFile('ws', 'a', 'body');
      final call = host.lastCall('fs.writeAgentFile')!;
      expect(call.args['agent_slug'], 'a');
      expect(call.args['content'], 'body');
    });

    test('deleteAgentDir forwards the slug', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.deleteAgentDir('ws', 'a');
      expect(host.lastCall('fs.deleteAgentDir')!.args['agent_slug'], 'a');
    });

    test('syncAgentSkillLinks forwards slug + skill_slugs', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.syncAgentSkillLinks('ws', 'a', ['lint', 'test']);
      final call = host.lastCall('fs.syncAgentSkillLinks')!;
      expect(call.args['agent_slug'], 'a');
      expect(call.args['skill_slugs'], ['lint', 'test']);
    });

    test('writeSkillFile forwards slug + content', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.writeSkillFile('ws', 's', 'content');
      final call = host.lastCall('fs.writeSkillFile')!;
      expect(call.args['skill_slug'], 's');
      expect(call.args['content'], 'content');
    });

    test('deleteSkillDir forwards the slug', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      await port.deleteSkillDir('ws', 's');
      expect(host.lastCall('fs.deleteSkillDir')!.args['skill_slug'], 's');
    });
  });

  group('RpcWorkspaceFilesystemPort logo persistence', () {
    test('persistLogo forwards source_path and returns the path', () async {
      host.callResults['fs.persistLogo'] = {'path': '/srv/logo.png'};
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.persistLogo('ws', '/tmp/up.png'), '/srv/logo.png');
      expect(
        host.lastCall('fs.persistLogo')!.args['source_path'],
        '/tmp/up.png',
      );
    });

    test('persistLogo returns null when path absent', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.persistLogo('ws', '/tmp/up.png'), isNull);
    });

    test(
      'persistLogoBytes base64-encodes bytes and forwards extension',
      () async {
        host.callResults['fs.persistLogoBytes'] = {'path': '/srv/logo.png'};
        final port = RpcWorkspaceFilesystemPort(client);
        expect(
          await port.persistLogoBytes('ws', [1, 2, 3], 'png'),
          '/srv/logo.png',
        );
        final call = host.lastCall('fs.persistLogoBytes')!;
        expect(call.args['extension'], 'png');
        // base64.encode([1,2,3]) == 'AQID'
        expect(call.args['bytes'], 'AQID');
      },
    );

    test('persistLogoBytes returns null when path absent', () async {
      final port = RpcWorkspaceFilesystemPort(client);
      expect(await port.persistLogoBytes('ws', [1], 'png'), isNull);
    });
  });

  // The two ops that take a server path and no workspace. They are the only
  // calls allowed to fall back to the client's active workspace.
  const opaquePathOps = {'fs.ensureDir', 'fs.writeString'};

  group('RpcWorkspaceFilesystemPort workspace scoping', () {
    test('every op targets the workspace it was handed, not the client '
        'default', () async {
      // The ambient default points at a DIFFERENT workspace on purpose. The host
      // is stateless and injects nothing, so a method that dropped its
      // workspaceId would silently act on this one instead — which is how a new
      // workspace's logo ended up written into the open workspace's directory.
      // With no default at all (onboarding, before any workspace exists) the
      // same drop fails the host's validation with a missing workspace_id.
      client.activeWorkspaceId = 'ws-active';
      final port = RpcWorkspaceFilesystemPort(client);
      const target = 'ws-target';

      // The path accessors cast the reply, so every one of them needs a stub.
      for (final op in const [
        'fs.workspaceDir',
        'fs.spacesDir',
        'fs.spaceDir',
        'fs.ensureSpaceDir',
        'fs.skillsDir',
        'fs.skillDir',
        'fs.skillFilePath',
        'fs.agentsDir',
        'fs.agentDir',
        'fs.agentFilePath',
        'fs.agentSkillsLinkDir',
        'fs.prCloneDir',
      ]) {
        host.callResults[op] = {'path': '/srv/p'};
      }

      await port.workspaceDir(target);
      await port.spacesDir(target);
      await port.spaceDir(target, 'c-1');
      await port.ensureSpaceDir(target, 'c-1');
      await port.skillsDir(target);
      await port.skillDir(target, 's');
      await port.skillFilePath(target, 's');
      await port.agentsDir(target);
      await port.agentDir(target, 'a');
      await port.agentFilePath(target, 'a');
      await port.agentSkillsLinkDir(target, 'a');
      await port.prCloneDir(target, 'o', 'r');
      await port.readSkillFile(target, 's');
      await port.listAgentSlugs(target);
      await port.listSkillSlugs(target);
      await port.ensureWorkspaceDirs(target);
      await port.ensureAgentDir(target, 'a');
      await port.ensureMcpSymlink(target, 'a');
      await port.writeAgentFile(target, 'a', 'body');
      await port.deleteAgentDir(target, 'a');
      await port.syncAgentSkillLinks(target, 'a', const ['lint']);
      await port.writeSkillFile(target, 's', 'body');
      await port.deleteSkillDir(target, 's');
      await port.persistLogo(target, '/tmp/up.png');
      await port.persistLogoBytes(target, const [1], 'png');

      final scoped = host.calls
          .where((c) => !opaquePathOps.contains(c.op))
          .toList();
      expect(scoped, isNotEmpty);
      for (final call in scoped) {
        expect(
          call.args['workspace_id'],
          target,
          reason:
              '${call.op} did not carry the workspace it was handed — it would '
              'act on the client default instead',
        );
      }
    });

    test('the opaque-path ops send no workspace of their own', () async {
      client.activeWorkspaceId = 'ws-active';
      final port = RpcWorkspaceFilesystemPort(client);
      await port.ensureDir('/srv/nested');
      await port.writeString('/srv/file.txt', 'hello');

      // They carry no workspace argument, so the client's active workspace is
      // merged in — which is all the host needs to reject an unbound session.
      for (final op in opaquePathOps) {
        expect(host.lastCall(op)!.args['workspace_id'], 'ws-active');
      }
    });

    // Source-level ratchet: the behavioural test above can only cover the
    // methods someone remembered to add to it and this whole class of bug is a
    // method that quietly omits the argument. Every `fs.*` call site in the
    // adapter must name a workspace unless it is one of the opaque-path ops.
    test('no fs.* call site omits workspace_id', () {
      final fromPackage = File(
        'lib/src/repositories/rpc_workspace_filesystem_port.dart',
      );
      final source = fromPackage.existsSync()
          ? fromPackage
          : File(
              'packages/cc_data/lib/src/repositories/'
              'rpc_workspace_filesystem_port.dart',
            );
      expect(
        source.existsSync(),
        isTrue,
        reason: 'could not locate the adapter source from ${Directory.current}',
      );

      // Each call is `_client.call('fs.x', { ... })`; match up to the closing
      // brace of the argument map, which contains no nested braces.
      final callSites = RegExp(
        // `readOr` is the same call with an `ifAbsent` tail — a read that
        // tolerates a server which does not expose the op at all. It still
        // has to carry `workspace_id`, so it is matched here too.
        r"_client\.(?:call|readOr)\(\s*'(fs\.[A-Za-z]+)'\s*,\s*"
        r'(const\s*)?\{([^}]*)\}',
        multiLine: true,
      ).allMatches(source.readAsStringSync());

      final offenders = <String>[];
      var seen = 0;
      for (final match in callSites) {
        final op = match.group(1)!;
        if (opaquePathOps.contains(op)) {
          continue;
        }
        seen++;
        if (!match.group(3)!.contains("'workspace_id'")) {
          offenders.add(op);
        }
      }

      // Guards the regex itself: a refactor that changes the call shape would
      // otherwise silently match nothing and pass.
      expect(
        seen,
        greaterThanOrEqualTo(23),
        reason: 'the call-site regex stopped matching the adapter',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'these ops are workspace-scoped but pass no workspace_id, so they '
            'fall back to the client default: ${offenders.join(', ')}',
      );
    });
  });
}

class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}

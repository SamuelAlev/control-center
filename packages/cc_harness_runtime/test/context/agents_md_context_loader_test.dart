import 'dart:io';

import 'package:cc_harness_runtime/src/context/agents_md_context_loader.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('agents_md_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('loads root and nested AGENTS.md, skipping build/VCS dirs', () async {
    File(p.join(dir.path, 'AGENTS.md')).writeAsStringSync('Root rules.');
    final nested = Directory(p.join(dir.path, 'packages', 'app'))
      ..createSync(recursive: true);
    File(p.join(nested.path, 'AGENTS.md')).writeAsStringSync('Nested rules.');
    final skipped = Directory(p.join(dir.path, 'node_modules', 'x'))
      ..createSync(recursive: true);
    File(p.join(skipped.path, 'AGENTS.md')).writeAsStringSync('Ignore me.');

    final result = await const AgentsMdContextLoader().load(dir.path);
    expect(result, contains('Root rules.'));
    expect(result, contains('Nested rules.'));
    expect(result, contains('AGENTS.md')); // root header
    expect(result, contains(p.join('packages', 'app', 'AGENTS.md')));
    expect(result, isNot(contains('Ignore me.')));
  });

  test('returns empty when there is no AGENTS.md', () async {
    expect(await const AgentsMdContextLoader().load(dir.path), isEmpty);
  });

  test('returns empty for a missing directory', () async {
    const loader = AgentsMdContextLoader();
    expect(await loader.load(p.join(dir.path, 'nope')), isEmpty);
  });

  group('symlinked AGENTS.md', () {
    late Directory agentConfig;

    setUp(() {
      AgentsMdContextLoader.clearDiscoveryCache();
      agentConfig = Directory.systemTemp.createTempSync('agent_cfg_');
      File(
        p.join(agentConfig.path, 'AGENTS.md'),
      ).writeAsStringSync('Agent profile.');
      // The provisioner links the overlay's AGENTS.md to the agent's global
      // profile rather than copying it.
      Link(
        p.join(dir.path, 'AGENTS.md'),
      ).createSync(p.join(agentConfig.path, 'AGENTS.md'));
    });
    tearDown(() => agentConfig.deleteSync(recursive: true));

    test('loads a link into a permitted root', () async {
      final result = await const AgentsMdContextLoader().load(
        dir.path,
        permittedLinkRoots: [agentConfig.path],
      );
      expect(result, contains('Agent profile.'));
    });

    test('ignores the link when no root permits it', () async {
      expect(await const AgentsMdContextLoader().load(dir.path), isEmpty);
    });

    test('never descends a symlinked directory', () async {
      final repos = Directory(p.join(agentConfig.path, 'repos', 'web-app'))
        ..createSync(recursive: true);
      File(p.join(repos.path, 'AGENTS.md')).writeAsStringSync('Repo rules.');
      Link(
        p.join(dir.path, 'repos'),
      ).createSync(p.join(agentConfig.path, 'repos'));

      final result = await const AgentsMdContextLoader().load(
        dir.path,
        permittedLinkRoots: [agentConfig.path],
      );
      expect(result, contains('Agent profile.'));
      // Descending it would load every repo at once, defeating repo scoping.
      expect(result, isNot(contains('Repo rules.')));
    });
  });
}

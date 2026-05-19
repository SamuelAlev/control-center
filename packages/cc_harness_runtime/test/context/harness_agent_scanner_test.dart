import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _Tool extends HarnessTool {
  _Tool(this._name, this._tier);
  final String _name;
  final ToolApprovalTier _tier;
  @override
  String get name => _name;
  @override
  String get description => 'x';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => _tier;
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ok');
}

void main() {
  late Directory root;
  const scanner = HarnessAgentScanner();

  setUp(() => root = Directory.systemTemp.createTempSync('cc_agents'));
  tearDown(() => root.deleteSync(recursive: true));

  void writeAgent(String relative, String content) {
    final file = File(p.join(root.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  group('scan', () {
    test('parses a definition and its frontmatter', () async {
      writeAgent('.agents/agents/reviewer.md', '''
---
description: Reviews a diff against our conventions
base: explore
tools: read, search
model: claude-haiku-4-5
max-turns: 12
read-summarize: false
---
Report P0 issues first.
''');
      final agent = (await scanner.scan([root.path])).single;
      expect(agent.name, 'reviewer');
      expect(agent.description, 'Reviews a diff against our conventions');
      expect(agent.base, SubagentType.explore);
      expect(agent.toolAllowlist, ['read', 'search']);
      expect(agent.model, 'claude-haiku-4-5');
      expect(agent.maxTurns, 12);
      expect(agent.readSummarize, isFalse);
      expect(agent.systemPrompt, 'Report P0 issues first.');
    });

    test('a definition may not shadow a built-in', () async {
      // Redefining `general` with a different tier would be privilege
      // escalation dressed up as configuration.
      writeAgent('.agents/agents/general.md', '---\nbase: explore\n---\nx');
      expect(await scanner.scan([root.path]), isEmpty);
    });

    test('an unrecognized base defaults to the SAFEST built-in', () async {
      // Another harness's frontmatter is not this contract. An agent that
      // turns out read-only is a complaint; one that turns out to write is an
      // incident.
      writeAgent('.claude/agents/other.md', '---\nmodel: x\n---\nDo things.');
      expect((await scanner.scan([root.path])).single.base, SubagentType.explore);
    });

    test('needs frontmatter and a body', () async {
      writeAgent('.agents/agents/nofm.md', 'just prose');
      writeAgent('.agents/agents/nobody.md', '---\nbase: plan\n---\n');
      expect(await scanner.scan([root.path]), isEmpty);
    });

    test('the first base wins on a collision', () async {
      final other = Directory.systemTemp.createTempSync('cc_agents_b');
      addTearDown(() => other.deleteSync(recursive: true));
      writeAgent('.agents/agents/r.md', '---\nbase: plan\n---\nPROJECT');
      File(p.join(other.path, '.agents', 'agents', 'r.md'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('---\nbase: plan\n---\nHOME');
      final agent = (await scanner.scan([root.path, other.path])).single;
      expect(agent.systemPrompt, 'PROJECT');
    });
  });

  group('CustomSubagentProfile — narrowing only', () {
    test('inherits the base tiers and never widens them', () {
      const agent = CustomSubagentProfile(
        name: 'reviewer',
        description: 'x',
        base: SubagentType.explore,
        systemPrompt: 'Review.',
      );
      final resolved = agent.resolve();
      expect(resolved.allowedTiers, {ToolApprovalTier.read});
      expect(
        resolved.systemPromptAddendum,
        contains('Review.'),
        reason: 'the specialization is appended to the base contract',
      );
      expect(
        resolved.systemPromptAddendum,
        contains('READ-ONLY'),
        reason: 'the base contract is not replaced by the specialization',
      );
    });

    test('the allowlist intersects, never unions', () {
      const agent = CustomSubagentProfile(
        name: 'reviewer',
        description: 'x',
        base: SubagentType.explore,
        systemPrompt: 'Review.',
        // `bash` is exec-tier and NOT reachable from an explore base — asking
        // for it must not grant it.
        toolAllowlist: ['read', 'bash'],
      );
      final tools = agent.filterTools([
        _Tool('read', ToolApprovalTier.read),
        _Tool('search', ToolApprovalTier.read),
        _Tool('bash', ToolApprovalTier.exec),
      ]);
      expect(tools.map((t) => t.name), ['read']);
    });

    test('an empty allowlist means whatever the base allows', () {
      const agent = CustomSubagentProfile(
        name: 'r',
        description: 'x',
        base: SubagentType.explore,
        systemPrompt: 'y',
      );
      final tools = agent.filterTools([
        _Tool('read', ToolApprovalTier.read),
        _Tool('write', ToolApprovalTier.write),
      ]);
      expect(tools.map((t) => t.name), ['read']);
    });
  });

  group('SubagentCatalog', () {
    const catalog = SubagentCatalog(
      custom: [
        CustomSubagentProfile(
          name: 'reviewer',
          description: 'Reviews diffs',
          base: SubagentType.explore,
          systemPrompt: 'Review.',
        ),
      ],
    );

    test('lists built-ins and custom agents', () {
      expect(
        catalog.typeNames,
        containsAll(['general', 'explore', 'plan', 'reviewer']),
      );
      expect(catalog.describeTypes(), contains('Reviews diffs'));
    });

    test('a built-in name never resolves to a custom agent', () {
      expect(catalog.customFor('general'), isNull);
      expect(catalog.profileFor('general').type, SubagentType.general);
    });

    test('a custom name resolves to its narrowed profile', () {
      expect(catalog.customFor('reviewer')!.base, SubagentType.explore);
      expect(catalog.profileFor('reviewer').type, SubagentType.explore);
      expect(
        catalog.profileFor('reviewer').allowedTiers,
        {ToolApprovalTier.read},
      );
    });

    test('an unknown name falls back to the built-in default', () {
      expect(catalog.profileFor('nope').type, SubagentType.general);
      expect(catalog.profileFor(null).type, SubagentType.general);
    });
  });
}

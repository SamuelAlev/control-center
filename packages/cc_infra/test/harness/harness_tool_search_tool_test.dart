import 'dart:convert';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/harness_tool_search_tool.dart';
import 'package:cc_infra/src/harness/harness_tool_surface.dart';
import 'package:test/test.dart';

class _FakeTool extends HarnessTool {
  _FakeTool(this.name, this.description, {this.args = const []});

  @override
  final String name;
  @override
  final String description;
  final List<String> args;

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      for (final a in args) a: const {'type': 'string'},
    },
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> arguments,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ok');
}

final _catalog = [
  _FakeTool('read', 'Reads a file from disk.', args: ['path']),
  _FakeTool(
    'assign_ticket',
    'Assigns a ticket to an agent so they own the work.',
    args: ['ticket_id', 'agent_id'],
  ),
  _FakeTool(
    'search_memory',
    'Searches workspace memory facts and policies.',
    args: ['query'],
  ),
];

const _residency = ToolResidencySpec(residentNames: {'read'});

Future<Map<String, dynamic>> _search(String query, {int? limit}) async {
  final tool = HarnessToolSearchTool(catalog: _catalog, residency: _residency);
  final result = await tool.execute({
    'query': query,
    'limit': ?limit,
  }, const HarnessToolContext(workingDirectory: '.'));
  return jsonDecode(result.content) as Map<String, dynamic>;
}

void main() {
  group('search_tools', () {
    test('finds a tool by intent and asks for it to be loaded', () async {
      final tool = HarnessToolSearchTool(
        catalog: _catalog,
        residency: _residency,
      );
      final result = await tool.execute({
        'query': 'assign a ticket to someone',
      }, const HarnessToolContext(workingDirectory: '.'));

      final body = jsonDecode(result.content) as Map<String, dynamic>;
      final names = [
        for (final m in body['matches'] as List)
          (m as Map<String, dynamic>)['name'],
      ];
      expect(names, contains('assign_ticket'));
      // Loading is the point: a search that only described tools would cost a
      // whole extra round trip before the model could act on what it found.
      expect(result.activateTools, contains('assign_ticket'));
    });

    test('does not ask to load something already resident', () async {
      final tool = HarnessToolSearchTool(
        catalog: _catalog,
        residency: _residency,
      );
      final result = await tool.execute({
        'query': 'read a file from disk',
      }, const HarnessToolContext(workingDirectory: '.'));

      expect(result.activateTools, isNot(contains('read')));
      final body = jsonDecode(result.content) as Map<String, dynamic>;
      final read = (body['matches'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((m) => m['name'] == 'read');
      // Reported as already available so the model does not read a tool it has
      // had all along as a new discovery.
      expect(read['already_loaded'], isTrue);
    });

    test(
      'reports an empty search as empty, and says how to widen it',
      () async {
        // The BFCL "missing function" case. An agent that reads a miss as "no
        // such capability" confabulates a substitute; one that reads it as "not
        // found yet" searches again. The wording has to produce the second.
        final body = await _search('launch a rocket to the moon');
        expect(body['matches'], isEmpty);
        final hint = body['hint'] as String;
        expect(hint, contains('different vocabulary'));
        expect(hint, contains('limit'));
        expect(
          hint,
          contains('say so'),
          reason: 'a second empty search must license an honest "I cannot"',
        );
      },
    );

    test('honours a limit and clamps an absurd one', () async {
      expect((await _search('ticket', limit: 1))['matches'], hasLength(1));
      final wide = await _search('ticket', limit: 100000);
      expect(
        (wide['matches'] as List).length,
        lessThanOrEqualTo(_catalog.length),
      );
    });

    test('a missing query is an error, not an empty search', () async {
      final tool = HarnessToolSearchTool(
        catalog: _catalog,
        residency: _residency,
      );
      final result = await tool.execute(
        const {},
        const HarnessToolContext(workingDirectory: '.'),
      );
      expect(result.isError, isTrue);
    });

    test('it is read-tier, so finding a tool never needs approval', () {
      final tool = HarnessToolSearchTool(
        catalog: _catalog,
        residency: _residency,
      );
      expect(tool.approvalTier, ToolApprovalTier.read);
    });
  });

  group('materializeHarnessToolSurface', () {
    final registry = HarnessToolRegistry.of(_catalog);

    test('adds the search tool first, and only when something is deferred', () {
      final partition = materializeHarnessToolSurface(
        registry: registry,
        surface: const ToolSurfaceSpec.unrestricted(),
        residency: _residency,
      );
      expect(partition.resident.first.name, 'search_tools');
      expect(
        [for (final t in partition.resident) t.name],
        ['search_tools', 'read'],
      );
      expect(
        [for (final t in partition.deferred) t.name],
        ['assign_ticket', 'search_memory'],
      );
    });

    test('with deferral off there is nothing to search for', () {
      final partition = materializeHarnessToolSurface(
        registry: registry,
        surface: const ToolSurfaceSpec.unrestricted(),
        residency: const ToolResidencySpec.allResident(),
      );
      // A search over an already-complete list is a tool that wastes turns, so
      // the kill switch must not leave one behind.
      expect([
        for (final t in partition.resident) t.name,
      ], isNot(contains('search_tools')));
      expect(partition.deferred, isEmpty);
    });

    test('residency never widens what the surface admitted', () {
      final partition = materializeHarnessToolSurface(
        registry: registry,
        // Only `read` survives; everything else is denied outright.
        surface: const ToolSurfaceSpec(
          denyNames: {'assign_ticket', 'search_memory'},
        ),
        residency: _residency,
      );
      final all = [for (final t in partition.all) t.name];
      expect(all, isNot(contains('assign_ticket')));
      expect(all, isNot(contains('search_memory')));
    });

    test('the token estimate matches the loop own accounting', () {
      // Three numbers for "how big is the tool block" is how a regression
      // hides, so this must be the same formula the loop budgets with.
      final tokens = estimateToolSchemaTokens(_catalog);
      expect(tokens, greaterThan(0));
      expect(estimateToolSchemaTokens(const []), 0);
    });
  });
}

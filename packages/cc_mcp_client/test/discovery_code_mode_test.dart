import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

class _Tool extends McpTool {
  _Tool(this.name, this.description);

  @override
  final String name;
  @override
  final String description;
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ok');
}

McpToolRegistry _catalog() => McpToolRegistry([
  _Tool('repl', 'Run a script that calls tools.'),
  _Tool('run_report', 'Run a report script over tickets.'),
  _Tool('todo_write', 'Write the checklist.'),
]);

Map<String, dynamic> _json(CallResult result) =>
    jsonDecode(result.content.first.text) as Map<String, dynamic>;

List<String> _listed(Map<String, dynamic> json) => [
  for (final entry in json['available'] as List)
    (entry as Map<String, dynamic>)['name'] as String,
];

void main() {
  group('list_my_tools', () {
    test('lists repl only on a server that runs scripts, to a caller that '
        'names its workspace', () async {
      var runs = true;
      final tool = ListMyToolsTool(
        catalog: _catalog(),
        replAvailable: () => runs,
      );

      final on = _json(
        await tool.run({'workspace_id': 'ws-1', 'agent_id': 'agent-1'}),
      );
      expect(_listed(on), contains('repl'));
      expect(on['total_tools'], 3);

      runs = false;
      final off = _json(await tool.run({'workspace_id': 'ws-1'}));
      expect(_listed(off), isNot(contains('repl')));
      expect(_listed(off), containsAll(['run_report', 'todo_write']));
      expect(off['total_tools'], 2);
    });

    test('never lists repl without the answer, a workspace or when the '
        'answer fails', () async {
      final noAnswer = ListMyToolsTool(catalog: _catalog());
      expect(
        _listed(_json(await noAnswer.run({'workspace_id': 'ws-1'}))),
        isNot(contains('repl')),
      );

      final tool = ListMyToolsTool(
        catalog: _catalog(),
        replAvailable: () => true,
      );
      expect(_listed(_json(await tool.run({}))), isNot(contains('repl')));

      final failing = ListMyToolsTool(
        catalog: _catalog(),
        replAvailable: () => throw StateError('unreadable'),
      );
      expect(
        _listed(_json(await failing.run({'workspace_id': 'ws-1'}))),
        isNot(contains('repl')),
      );
    });
  });

  group('search_tool_bm25', () {
    test('finds repl only on a server that runs scripts, and keeps the hit '
        'count', () async {
      var runs = true;
      final search = SearchToolBm25(
        catalog: _catalog(),
        replAvailable: () => runs,
      );

      final on = _json(
        await search.run({
          'query': 'run script calls tools',
          'limit': 1,
          'workspace_id': 'ws-1',
        }),
      );
      expect(on['matches'], ['repl']);
      expect(on['total_tools'], 3);

      runs = false;
      final off = _json(
        await search.run({
          'query': 'run script calls tools',
          'limit': 1,
          'workspace_id': 'ws-1',
        }),
      );
      expect(off['matches'], ['run_report']);
      expect(off['total_tools'], 2);

      final unscoped = _json(
        await SearchToolBm25(
          catalog: _catalog(),
          replAvailable: () => true,
        ).run({'query': 'run script calls tools', 'limit': 5}),
      );
      expect(unscoped['matches'], isNot(contains('repl')));
    });
  });
}

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

ToolDef _def(String name, String description, [List<String> keys = const []]) =>
    ToolDef(
      name: name,
      description: description,
      inputSchema: {
        'type': 'object',
        'properties': {for (final k in keys) k: <String, dynamic>{}},
      },
    );

void main() {
  group('tokenizeToolText', () {
    test('splits camelCase, acronyms, digits and lowercases', () {
      // camelCase + digit→letter boundaries split; letter→digit does not, so
      // `BM25v2` → `bm25` + `v2`.
      expect(tokenizeToolText('searchCodeBM25v2'),
          containsAll(['search', 'code', 'bm25', 'v2']));
      expect(tokenizeToolText('MCPToolBridge'),
          containsAll(['mcp', 'tool', 'bridge']));
    });

    test('strips punctuation and diacritics', () {
      expect(tokenizeToolText('café-search!'), ['cafe', 'search']);
    });
  });

  group('ToolIndex BM25', () {
    final tools = [
      _def('list_pull_requests', 'List GitHub pull requests for a repo'),
      _def('search_memory', 'Semantic search over stored memory facts'),
      _def('send_channel_message', 'Send a message to a chat channel', ['body']),
      _def('create_workspace', 'Create a new workspace'),
    ];

    test('ranks the name-matching tool first', () {
      final index = ToolIndex.build(tools);
      final hits = index.search('pull request');
      expect(hits.first.name, 'list_pull_requests');
    });

    test('matches on description terms', () {
      final index = ToolIndex.build(tools);
      final hits = index.search('semantic memory');
      expect(hits.first.name, 'search_memory');
    });

    test('returns empty for no match', () {
      final index = ToolIndex.build(tools);
      expect(index.search('xyzzy-nonexistent'), isEmpty);
    });

    test('respects the limit', () {
      final index = ToolIndex.build(tools);
      expect(index.search('a', limit: 2).length, lessThanOrEqualTo(2));
    });
  });

  group('McpToolRegistry discovery gating', () {
    test('gates tools/list above threshold to essentials only', () {
      final tools = [
        for (var i = 0; i < 45; i++)
          _TestTool('tool_$i', approval: i.isEven ? null : true),
      ];
      final registry = McpToolRegistry(
        tools,
        discoveryThreshold: 40,
        essentialToolNames: {'tool_0', 'tool_1'},
      );
      final search = SearchToolBm25(catalog: registry);
      registry.register(search, essential: true);

      expect(registry.isDiscoveryActive, isTrue);
      final listed = registry.listDefinitions().map((d) => d.name).toSet();
      expect(listed, {'tool_0', 'tool_1', 'search_tool_bm25'});

      // Hidden tools remain resolvable by name (post-search activation).
      expect(registry.lookup('tool_30'), isNotNull);
      // The full catalogue is still indexable by the search tool.
      expect(registry.allToolDefinitions().length, 46);
    });

    test('lists everything below the threshold', () {
      final registry = McpToolRegistry(
        [for (var i = 0; i < 5; i++) _TestTool('t$i')],
        discoveryThreshold: 40,
      );
      expect(registry.isDiscoveryActive, isFalse);
      expect(registry.listDefinitions().length, 5);
    });

    test('dynamic bridged tools count toward the total and are listed', () {
      final registry = McpToolRegistry([_TestTool('native')]);
      registry.setDynamicTools([_TestTool('mcp__srv__x')]);
      expect(registry.toolNames, containsAll(['native', 'mcp__srv__x']));
      expect(registry.lookup('mcp__srv__x'), isNotNull);
    });
  });
}

class _TestTool extends McpTool {
  _TestTool(this.name, {bool? approval}) : _approval = approval;
  final bool? _approval;
  @override
  final String name;
  @override
  String get description => 'test tool $name';
  @override
  Map<String, dynamic> get inputSchema =>
      {'type': 'object', 'properties': <String, dynamic>{}};
  @override
  bool get requiresApproval => _approval ?? false;
  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ok');
}

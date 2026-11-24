import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/tool_index.dart';
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
      expect(
        tokenizeToolText('searchCodeBM25v2'),
        containsAll(['search', 'code', 'bm25', 'v2']),
      );
      expect(
        tokenizeToolText('MCPToolBridge'),
        containsAll(['mcp', 'tool', 'bridge']),
      );
    });

    test('strips punctuation and diacritics', () {
      expect(tokenizeToolText('café-search!'), ['cafe', 'search']);
    });
  });

  group('ToolIndex BM25', () {
    final tools = [
      _def('list_pull_requests', 'List GitHub pull requests for a repo'),
      _def('search_memory', 'Semantic search over stored memory facts'),
      _def('send_message', 'Send a message to a chat channel', ['body']),
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

  group('McpToolRegistry', () {
    test('tools/list advertises the FULL catalogue — no discovery gating', () {
      // External MCP clients (Claude Code) validate calls
      // against their cached tools/list client-side; anything unlisted is
      // unreachable. The registry therefore never hides tools.
      final tools = [
        for (var i = 0; i < 45; i++)
          _TestTool('tool_$i', approval: i.isEven ? null : true),
      ];
      final registry = McpToolRegistry(tools);
      registry.register(SearchToolBm25(catalog: registry));

      final listed = registry
          .listDefinitions(view: McpToolView.shared)
          .map((d) => d.name)
          .toSet();
      expect(listed.length, 46);
      expect(listed, contains('tool_30'));
      expect(listed, contains('search_tool_bm25'));
      expect(registry.lookup('tool_30', view: McpToolView.shared), isNotNull);
      expect(registry.allToolDefinitions().length, 46);
    });

    test('dynamic bridged tools are personal: listed and resolvable only '
        'when asked for', () {
      const mine = McpToolView(workspaceId: 'ws', personalUserId: 'u1');
      final registry = McpToolRegistry([_TestTool('native')]);
      registry.setPersonalTools('ws', 'u1', [_TestTool('mcp__srv__x')]);
      expect(
        registry.toolNames(view: mine),
        containsAll(['native', 'mcp__srv__x']),
      );
      expect(registry.lookup('mcp__srv__x', view: mine), isNotNull);
      expect(
        registry.listDefinitions(view: mine).map((d) => d.name),
        containsAll(['native', 'mcp__srv__x']),
      );
      expect(registry.toolNames(view: McpToolView.shared), ['native']);
      expect(registry.lookup('mcp__srv__x', view: McpToolView.shared), isNull);
      expect(registry.resolve('mcp__srv__x', view: McpToolView.shared), isNull);
      expect(registry.allToolDefinitions().map((d) => d.name), ['native']);
    });

    test('a member\'s own tools reach neither another member nor the same '
        'member in another workspace', () {
      final registry = McpToolRegistry([_TestTool('native')]);
      registry.setPersonalTools('ws', 'u1', [_TestTool('mcp__srv__x')]);
      for (final view in const [
        McpToolView(workspaceId: 'ws', personalUserId: 'u2'),
        McpToolView(workspaceId: 'other', personalUserId: 'u1'),
        McpToolView(workspaceId: 'ws'),
        McpToolView(personalUserId: 'u1'),
      ]) {
        expect(
          registry.lookup('mcp__srv__x', view: view),
          isNull,
          reason: '$view',
        );
        expect(registry.isExternal('mcp__srv__x', view: view), isFalse);
        expect(registry.toolNames(view: view), ['native']);
      }
    });

    test('a member\'s own tool resolves before the workspace\'s of the same '
        'name, and only for that member', () {
      final own = _TestTool('mcp__srv__x');
      final shared = _TestTool('mcp__srv__x');
      final registry = McpToolRegistry([])
        ..setWorkspaceTools('ws', [shared])
        ..setPersonalTools('ws', 'u1', [own]);
      expect(
        registry.lookup(
          'mcp__srv__x',
          view: const McpToolView(workspaceId: 'ws', personalUserId: 'u1'),
        ),
        same(own),
      );
      expect(
        registry.lookup(
          'mcp__srv__x',
          view: const McpToolView(workspaceId: 'ws', personalUserId: 'u2'),
        ),
        same(shared),
      );
      registry.dropPersonalTools('ws');
      expect(
        registry.lookup(
          'mcp__srv__x',
          view: const McpToolView(workspaceId: 'ws', personalUserId: 'u1'),
        ),
        same(shared),
      );
    });

    test('a personal tool never stands in for a shared one', () {
      final shared = _TestTool('same');
      final registry = McpToolRegistry([shared]);
      registry.setPersonalTools('ws', 'u1', [_TestTool('same')]);
      expect(registry.lookup('same', view: McpToolView.shared), same(shared));
    });

    test('personal tools do not change the shared revision', () {
      final registry = McpToolRegistry([_TestTool('native')]);
      final before = registry.toolsetRevision;
      registry.setPersonalTools('ws', 'u1', [_TestTool('mcp__srv__x')]);
      expect(registry.toolsetRevision, before);
    });

    test('onToolsChanged fires on register and setPersonalTools', () {
      final registry = McpToolRegistry([_TestTool('native')]);
      var fired = 0;
      registry.onToolsChanged = () => fired++;
      registry.register(_TestTool('extra'));
      expect(fired, 1);
      registry.setPersonalTools('ws', 'u1', [_TestTool('bridged')]);
      expect(fired, 2);
    });

    test('toolsetRevision is stable and changes only with the toolset', () {
      McpToolRegistry build() =>
          McpToolRegistry([_TestTool('a'), _TestTool('b')]);
      // Same catalogue → same revision (cross-instance stability is what lets
      // dispatch embed it in .mcp.json as a client-cache buster).
      expect(build().toolsetRevision, build().toolsetRevision);
      expect(build().toolsetRevision, matches(RegExp(r'^[0-9a-f]{16}$')));

      final mutated = build()..register(_TestTool('c'));
      expect(mutated.toolsetRevision, isNot(build().toolsetRevision));
    });
  });

  group('SearchToolBm25', () {
    test('returns honest matches over the full catalogue', () async {
      final registry = McpToolRegistry([
        _TestTool('todo_write'),
        _TestTool('unrelated_tool'),
      ]);
      final search = SearchToolBm25(catalog: registry);
      registry.register(search);

      final result = await search.run({'query': 'todo write'});
      expect(result.isError, isFalse);
      final text = result.content.first.text;
      // The old response claimed "activated_tools" — nothing was ever
      // activated. The honest shape names matches and states callability.
      expect(text, isNot(contains('activated_tools')));
      expect(text, contains('"matches"'));
      expect(text, contains('todo_write'));
      expect(text, contains('directly callable'));
    });
  });
}

class _TestTool extends McpTool {
  _TestTool(this.name, {this._approval});
  final bool? _approval;
  @override
  final String name;
  @override
  String get description => 'test tool $name';
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': <String, dynamic>{},
  };
  @override
  bool get requiresApproval => _approval ?? false;
  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ok');
}

import 'dart:math' as math;

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_catalog.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/tool_index.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/server_mcp_registry_fixture.dart';
import '../helpers/test_database.dart';

/// The first-party catalogs are small enough that the index's equal share
/// ([ToolIndex.shareFor]) cuts none of them: every tool's argument names
/// and description head are indexed as they would be with no total at all.
/// Nor does `ALL_TOOLS`'s ([ScriptCatalog.allToolsShare]): every
/// description travels whole.
///
/// The catalogs are the ones the indexes are built over: a chat run's
/// `search_tools` catalog (the production registry builder over the
/// server's MCP registry, as a run materializes it) and the MCP registry's
/// shared view (`search_tool_bm25`). [_firstPartyBound] is the catalog size
/// the share is checked at, above both.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late McpToolRegistry mcp;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    mcp = buildTestServerMcpRegistry(global: global, dbs: dbs);
  });
  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  List<ToolDef> harnessCatalog() {
    final profile = profileFor(Mode.chat);
    final registry = buildHarnessToolRegistry(
      mode: Mode.chat,
      networkEnabled: true,
      env: const {},
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      conversationId: 'conv-1',
      spaceId: 'space-1',
      fileSearch: _NoFileSearch(),
      mcpRegistry: mcp,
      toolOutputStore: InMemoryToolOutputStore(),
      replSlot: true,
    );
    final surface = materializeHarnessToolSurface(
      registry: registry,
      surface: profile.toToolSurfaceSpec(),
      residency: profile.toToolResidencySpec(enabled: true),
    );
    return [
      for (final tool in [
        ...surface.resident,
        ...surface.deferred,
        ...surface.scriptOnly,
      ])
        ToolDef(
          name: tool.name,
          description: tool.description,
          inputSchema: tool.inputSchema,
        ),
    ];
  }

  List<ToolDef> mcpCatalog() => [
    for (final name in mcp.toolNames(view: McpToolView.shared))
      if (mcp.lookup(name, view: McpToolView.shared) case final tool?)
        ToolDef(
          name: tool.name,
          description: tool.description,
          inputSchema: tool.inputSchema,
        ),
  ];

  /// What [tool] asks of its share: its argument names as the index reads
  /// them, and its description up to the per-tool head.
  int unitsOf(ToolDef tool) {
    final properties = tool.inputSchema['properties'];
    final keys = <String>[
      if (properties is Map)
        for (final k in properties.keys)
          if (k.toString().length <= ToolIndex.maxTermChars) k.toString(),
    ]..sort();
    return keys
            .take(ToolIndex.maxSchemaKeys)
            .fold<int>(0, (sum, k) => sum + k.length) +
        math.min(tool.description.length, ToolIndex.maxIndexedDescriptionChars);
  }

  for (final (label, catalog) in [
    ('a chat run\'s search_tools catalog', harnessCatalog),
    ('the MCP registry', mcpCatalog),
  ]) {
    test('$label is cut nowhere at $_firstPartyBound tools', () {
      final tools = catalog();
      final share = ToolIndex.shareFor(_firstPartyBound);
      final largest = tools.map(unitsOf).fold<int>(0, math.max);
      final cutAt400 = [
        for (final t in tools)
          if (unitsOf(t) > ToolIndex.shareFor(400))
            '${t.name} ${unitsOf(t) - ToolIndex.shareFor(400)}',
      ];
      // ignore: avoid_print
      print(
        '$label: ${tools.length} tools; share at $_firstPartyBound '
        '$share, at 400 ${ToolIndex.shareFor(400)}; largest tool $largest; '
        'ALL_TOOLS share at $_firstPartyBound '
        '${ScriptCatalog.allToolsShare(_firstPartyBound)}, longest description '
        '${tools.map((t) => t.description.length).fold<int>(0, math.max)}; '
        'cut at 400: ${cutAt400.isEmpty ? 'none' : cutAt400.join(', ')}',
      );
      expect(tools.length, lessThanOrEqualTo(_firstPartyBound));
      final allToolsShare = ScriptCatalog.allToolsShare(_firstPartyBound);
      for (final tool in tools) {
        expect(unitsOf(tool), lessThanOrEqualTo(share), reason: tool.name);
        expect(
          ScriptCatalog.cutTo(tool.description, allToolsShare),
          tool.description,
          reason: tool.name,
        );
      }
      // As built: every hit keeps the description head and names it would
      // keep with no total.
      final index = ToolIndex.build(tools);
      for (final tool in tools) {
        final hit = index
            .search(tool.name, limit: tools.length)
            .firstWhere((h) => h.name == tool.name);
        expect(
          hit.description,
          tool.description.length > ToolIndex.maxIndexedDescriptionChars
              ? tool.description.substring(
                  0,
                  ToolIndex.maxIndexedDescriptionChars,
                )
              : tool.description,
          reason: tool.name,
        );
      }
    });
  }
}

/// The catalog size the first-party share is checked at.
const _firstPartyBound = 170;

class _NoFileSearch implements FileSearchPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no file search in this test');
}

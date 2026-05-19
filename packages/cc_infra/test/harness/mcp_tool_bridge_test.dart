import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/mcp_tool_bridge.dart';
import 'package:test/test.dart';

class _ImageMcpTool extends McpTool {
  _ImageMcpTool(this.images);

  final List<({String data, String mimeType})> images;

  @override
  String get name => 'screenshot';
  @override
  String get description => 'captures';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  ToolApproval toolApproval(Map<String, dynamic> arguments) =>
      const ToolApproval(CapabilityTier.read);

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.withImages('captured', images);
}

class _FakeMcpTool extends McpTool {
  _FakeMcpTool({this.tier = CapabilityTier.read, Map<String, dynamic>? schema})
    : _schema =
          schema ??
          {
            'type': 'object',
            'properties': {
              'workspace_id': {'type': 'string'},
              'agent_id': {'type': 'string'},
              'query': {'type': 'string'},
            },
          };

  final CapabilityTier tier;
  final Map<String, dynamic> _schema;
  Map<String, dynamic>? lastArgs;

  @override
  String get name => 'recall_facts';
  @override
  String get description => 'recall';
  @override
  Map<String, dynamic> get inputSchema => _schema;

  @override
  ToolApproval toolApproval(Map<String, dynamic> arguments) =>
      ToolApproval(tier);

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    lastArgs = arguments;
    return CallResult.success('facts');
  }
}

void main() {
  group('McpToolBridge hides context-injected arguments', () {
    const ctx = HarnessToolContext(
      workingDirectory: '.',
      workspaceId: 'ws1',
      agentId: 'a1',
    );

    test('a hidden argument leaves the model-facing schema', () {
      // The bridge forces `workspace_id` to the run's workspace whatever the
      // model sends, so advertising it costs ~every request and invites the
      // model to guess an id it must not choose.
      final bridge = McpToolBridge(
        _FakeMcpTool(),
        hiddenScopeParams: const {'workspace_id'},
      );
      final props = bridge.inputSchema['properties'] as Map<String, dynamic>;
      expect(props.containsKey('workspace_id'), isFalse);
      expect(props.containsKey('query'), isTrue);
      // `agent_id` stays: on some tools it names the CALLER and on others a
      // TARGET, so the model must remain able to choose it.
      expect(props.containsKey('agent_id'), isTrue);
    });

    test('a hidden argument is dropped from `required` too', () {
      final bridge = McpToolBridge(
        _FakeMcpTool(
          schema: const {
            'type': 'object',
            'properties': {
              'workspace_id': {'type': 'string'},
              'query': {'type': 'string'},
            },
            'required': ['workspace_id', 'query'],
          },
        ),
        hiddenScopeParams: const {'workspace_id'},
      );
      expect(bridge.inputSchema['required'], ['query']);
    });

    test('the wrapped tool still RECEIVES the injected value', () async {
      // Hiding is a presentation change only; the isolation boundary is
      // unaffected.
      final inner = _FakeMcpTool();
      await McpToolBridge(
        inner,
        hiddenScopeParams: const {'workspace_id'},
      ).execute(const {'query': 'x'}, ctx);
      expect(inner.lastArgs?['workspace_id'], 'ws1');
    });

    test('the MCP tool own schema is untouched', () {
      // External MCP clients must keep seeing the full contract.
      final inner = _FakeMcpTool();
      McpToolBridge(inner, hiddenScopeParams: const {'workspace_id'}).inputSchema;
      expect(
        (inner.inputSchema['properties'] as Map).containsKey('workspace_id'),
        isTrue,
      );
    });

    test('hiding nothing returns the schema identically', () {
      final inner = _FakeMcpTool();
      expect(identical(McpToolBridge(inner).inputSchema, inner.inputSchema),
          isTrue);
    });

    test('the schema is stable across reads', () {
      // The tools array heads the provider cache prefix, so a schema that
      // serialized differently between two reads would cost a full cache write.
      final bridge = McpToolBridge(
        _FakeMcpTool(),
        hiddenScopeParams: const {'workspace_id'},
      );
      expect(identical(bridge.inputSchema, bridge.inputSchema), isTrue);
    });
  });

  group('McpToolBridge', () {
    test('exposes the wrapped tool name/description/schema', () {
      final bridge = McpToolBridge(_FakeMcpTool());
      expect(bridge.name, 'recall_facts');
      expect(bridge.description, 'recall');
      expect(bridge.inputSchema['type'], 'object');
      expect(bridge.toSchema().name, 'recall_facts');
    });

    test('maps capability tier to approval tier', () {
      expect(
        McpToolBridge(_FakeMcpTool(tier: CapabilityTier.read)).approvalTier,
        ToolApprovalTier.read,
      );
      expect(
        McpToolBridge(_FakeMcpTool(tier: CapabilityTier.write)).approvalTier,
        ToolApprovalTier.write,
      );
      expect(
        McpToolBridge(_FakeMcpTool(tier: CapabilityTier.exec)).approvalTier,
        ToolApprovalTier.exec,
      );
    });

    test(
      'injects workspace_id and agent_id from context when omitted',
      () async {
        final tool = _FakeMcpTool();
        final bridge = McpToolBridge(tool);
        final result = await bridge.execute(
          {'query': 'auth'},
          const HarnessToolContext(
            workingDirectory: '.',
            workspaceId: 'ws-1',
            agentId: 'agent-1',
          ),
        );
        expect(result.isError, isFalse);
        expect(result.content, 'facts');
        expect(tool.lastArgs?['workspace_id'], 'ws-1');
        expect(tool.lastArgs?['agent_id'], 'agent-1');
        expect(tool.lastArgs?['query'], 'auth');
      },
    );

    test('forces the context workspace_id over a model-supplied one', () async {
      // Isolation boundary: a model-supplied foreign workspace_id must be
      // overridden with the run's workspace, never honored.
      final tool = _FakeMcpTool();
      await McpToolBridge(tool).execute({
        'workspace_id': 'someone-elses-workspace',
      }, const HarnessToolContext(workingDirectory: '.', workspaceId: 'ws-1'));
      expect(tool.lastArgs?['workspace_id'], 'ws-1');
    });

    // Regression: `space_id` must come from the run's SPACE, never from its
    // conversation id. A conversation owns its own uuid, so filling a
    // space-scoped argument from it named no space — `todo_write`/`todo_read`
    // failed their ownership check on every call and the agent's task list
    // silently never worked.
    test('fills space_id from the space, not the conversation', () async {
      final tool = _FakeMcpTool(
        schema: {
          'type': 'object',
          'properties': {
            'workspace_id': {'type': 'string'},
            'conversation_id': {'type': 'string'},
            'space_id': {'type': 'string'},
          },
        },
      );
      await McpToolBridge(tool).execute(
        const {},
        const HarnessToolContext(
          workingDirectory: '.',
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          spaceId: 'space-1',
        ),
      );
      expect(tool.lastArgs?['space_id'], 'space-1');
      expect(tool.lastArgs?['conversation_id'], 'conv-1');
    });

    test('a model-supplied space_id is left alone', () async {
      // Unlike workspace_id (the isolation boundary, always forced), space_id
      // is a convenience fill: an explicit value wins.
      final tool = _FakeMcpTool(
        schema: {
          'type': 'object',
          'properties': {
            'space_id': {'type': 'string'},
          },
        },
      );
      await McpToolBridge(tool).execute(const {
        'space_id': 'chosen',
      }, const HarnessToolContext(workingDirectory: '.', spaceId: 'space-1'));
      expect(tool.lastArgs?['space_id'], 'chosen');
    });

    test('does not inject ids the schema does not declare', () async {
      final tool = _FakeMcpTool(
        schema: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
        },
      );
      await McpToolBridge(tool).execute({
        'query': 'x',
      }, const HarnessToolContext(workingDirectory: '.', workspaceId: 'ws-1'));
      expect(tool.lastArgs?.containsKey('workspace_id'), isFalse);
    });

    // -------------------------------------------------------------------------
    // Image ingress. This bridge is where a tool result's images enter the
    // transcript, and nothing downstream inspects them again: the loop's budget
    // caps the COUNT, and token accounting charges a FLAT ~1200 per image, so
    // size and media type are invisible to every later check.
    // -------------------------------------------------------------------------
    group('image ingress', () {
      const ctx = HarnessToolContext(workingDirectory: '.');

      test('a normal raster image rides through', () async {
        final result = await McpToolBridge(
          _ImageMcpTool([(data: 'AAAA', mimeType: 'image/jpeg')]),
        ).execute(const {}, ctx);
        expect(result.images, hasLength(1));
        expect(result.images.single.mediaType, 'image/jpeg');
        expect(result.content, 'captured');
      });

      test('the media type is normalised, not trusted verbatim', () async {
        final result = await McpToolBridge(
          _ImageMcpTool([(data: 'AAAA', mimeType: '  IMAGE/PNG  ')]),
        ).execute(const {}, ctx);
        expect(result.images.single.mediaType, 'image/png');
      });

      test('an unsupported media type is dropped and SAID', () async {
        // `image/svg+xml` is an XML document, not a raster, and the string
        // lands verbatim in the provider request. A model that asked for a
        // screenshot and silently got none retries forever.
        final result = await McpToolBridge(
          _ImageMcpTool([(data: 'AAAA', mimeType: 'image/svg+xml')]),
        ).execute(const {}, ctx);
        expect(result.images, isEmpty);
        expect(result.content, contains('image/svg+xml'));
        expect(result.content, contains('not included'));
      });

      test('an oversized image is dropped and SAID', () async {
        final huge = 'A' * (kMaxBridgedImageBase64Chars + 1);
        final result = await McpToolBridge(
          _ImageMcpTool([(data: huge, mimeType: 'image/png')]),
        ).execute(const {}, ctx);
        expect(result.images, isEmpty);
        expect(result.content, contains('MB'));
      });

      test('a good image survives beside a rejected one', () async {
        final result = await McpToolBridge(
          _ImageMcpTool([
            (data: 'AAAA', mimeType: 'image/png'),
            (data: 'BBBB', mimeType: 'application/octet-stream'),
          ]),
        ).execute(const {}, ctx);
        expect(result.images, hasLength(1));
        expect(result.images.single.data, 'AAAA');
      });
    });
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/render_media_tool.dart';
import 'package:test/test.dart';

class _Renderer implements MediaRenderPort {
  MediaRenderRequest? lastRequest;
  int calls = 0;
  int bytesPerImage = 1;

  @override
  Future<MediaRenderResult> render(MediaRenderRequest request) async {
    lastRequest = request;
    calls++;
    return MediaRenderResult(
      source: 'video',
      durationSeconds: 12,
      images: [
        for (var i = 0; i < request.timestampsSeconds.length; i++)
          RenderedMediaImage(
            bytes: Uint8List(bytesPerImage)..[0] = i + 1,
            image: ToolImageRef(
              ref: 'blob:sha256:$i',
              mediaType: 'image/jpeg',
              bytes: bytesPerImage,
              width: 300,
              height: 200,
            ),
            timestampSeconds: request.timestampsSeconds[i],
            requestedTimestampSeconds: request.timestampsSeconds[i],
          ),
      ],
    );
  }
}

void main() {
  late _Renderer renderer;
  late McpToolDispatcher dispatcher;
  setUp(() {
    renderer = _Renderer();
    dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([RenderMediaTool(renderer: renderer)]),
    );
  });

  Future<Map<String, dynamic>> call(
    Map<String, dynamic> args, {
    McpCallScope? scope = const McpCallScope(
      workspaceId: 'ws',
      agentId: 'agent',
      spaceId: 'space',
      conversationId: 'conversation',
    ),
    Future<void>? abandoned,
  }) async {
    final result = await dispatcher.handleScopedRequest(
      JsonRpcRequest(
        method: 'tools/call',
        id: 1,
        params: {'name': 'render_media', 'arguments': args},
      ),
      scope: scope,
      abandoned: abandoned,
    );
    return result['result'] as Map<String, dynamic>;
  }

  test('should remain available in read-only conversation modes', () {
    for (final mode in Mode.values) {
      expect(ModeToolPolicy.isAllowed('render_media', mode), true);
    }
  });

  test(
    'should reject missing authenticated scope even with claimed ids',
    () async {
      final result = await call({
        'workspace_id': 'claimed',
        'agent_id': 'claimed',
        'path': 'movie.mp4',
        'timestamps_seconds': [0],
      }, scope: null);
      expect(result['isError'], true);
      expect(renderer.calls, 0);
    },
  );

  test('should override every model-claimed identity', () async {
    final result = await call({
      'workspace_id': 'other',
      'agent_id': 'other',
      'space_id': 'other',
      'conversation_id': 'other',
      'path': 'movie.mp4',
      'timestamps_seconds': [0],
    });
    expect(result['isError'], false);
    expect(renderer.lastRequest?.workspaceId, 'ws');
    expect(renderer.lastRequest?.agentId, 'agent');
    expect(renderer.lastRequest?.spaceId, 'space');
    expect(renderer.lastRequest?.conversationId, 'conversation');
  });

  test('should ignore a model-claimed space in an agent-only run', () async {
    await call({
      'space_id': 'other',
      'conversation_id': 'other',
      'path': 'movie.mp4',
      'timestamps_seconds': [0],
    }, scope: const McpCallScope(workspaceId: 'ws', agentId: 'agent'));
    expect(renderer.lastRequest?.spaceId, isNull);
    expect(renderer.lastRequest?.conversationId, isNull);
  });

  test(
    'should reject malformed selectors and paths without invoking renderer',
    () async {
      for (final args in [
        <String, dynamic>{'path': 'movie.mp4', 'timestamps_seconds': null},
        {
          'path': 'movie.mp4',
          'pages': [1],
          'timestamps_seconds': [0],
        },
        {'path': 'movie.mp4', 'timestamps_seconds': []},
        {
          'path': 'movie.mp4',
          'timestamps_seconds': [0, 1, 2, 3, 4],
        },
        {
          'path': 'movie.mp4',
          'timestamps_seconds': [double.nan],
        },
        {
          'path': 'movie.mp4',
          'timestamps_seconds': [double.infinity],
        },
        {
          'path': 'movie.mp4',
          'timestamps_seconds': [-1],
        },
        {
          'path': 'doc.pdf',
          'pages': [0],
        },
        {
          'path': 'doc.pdf',
          'pages': [1.5],
        },
        {
          'path': 'doc.pdf',
          'pages': [1, 2, 3, 4, 5],
        },
        {
          'path': 'doc.pdf',
          'pages': [1],
          'max_dimension': 127,
        },
        {
          'path': 'doc.pdf',
          'pages': [1],
          'max_dimension': 2049,
        },
        {
          'path': 'doc.pdf',
          'pages': [1],
          'max_dimension': 1600.5,
        },
        {
          'path': 'https://example.com/file.pdf',
          'pages': [1],
        },
        {
          'path': 'data:application/pdf;base64,AA==',
          'pages': [1],
        },
        {
          'path': 'file\x00.pdf',
          'pages': [1],
        },
      ]) {
        final result = await call(args);
        expect(result['isError'], true, reason: '$args');
      }
      expect(renderer.calls, 0);
    },
  );

  test(
    'should forward cancellation and preserve four images plus durable metadata',
    () async {
      final abandoned = Completer<void>();
      final result = await call({
        'path': 'movie.mp4',
        'timestamps_seconds': [0, 1, 2, 3],
      }, abandoned: abandoned.future);
      expect(renderer.lastRequest?.abandoned, same(abandoned.future));
      expect(result['isError'], false);
      final content = result['content'] as List;
      expect(content, hasLength(5));
      final metadata =
          jsonDecode((content.first as Map)['text'] as String) as Map;
      expect(metadata['source'], 'video');
      expect(
        (metadata['images'] as List).cast<Map<String, dynamic>>().map(
          (entry) => entry['ref'],
        ),
        ['blob:sha256:0', 'blob:sha256:1', 'blob:sha256:2', 'blob:sha256:3'],
      );
      expect(metadata.toString(), isNot(contains('AQ==')));
      expect(
        content
            .skip(1)
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['type']),
        everyElement('image'),
      );
      expect(
        content
            .skip(1)
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['mimeType']),
        everyElement('image/jpeg'),
      );
    },
  );

  test('should not truncate four images against the text budget', () async {
    renderer.bytesPerImage = 800 * 1024;
    final result = await call({
      'path': 'movie.mp4',
      'timestamps_seconds': [0, 1, 2, 3],
    });
    final content = result['content'] as List;
    expect(content, hasLength(5));
    expect(
      content
          .skip(1)
          .every(
            (entry) => ((entry as Map)['data'] as String).length > 1024 * 1024,
          ),
      true,
    );
  });
}

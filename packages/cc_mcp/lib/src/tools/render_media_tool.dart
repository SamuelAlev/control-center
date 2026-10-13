import 'dart:convert';

import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// Previews images, video frames or PDF pages inside the authenticated scope.
class RenderMediaTool extends McpTool {
  /// Creates the tool with the server-owned renderer.
  RenderMediaTool({required this.renderer});

  /// The renderer responsible for confinement, conversion and blob storage.
  final MediaRenderPort renderer;

  @override
  String get name => 'render_media';

  @override
  String get description =>
      'Render a still image, up to four video or animation frames, or up to four '
      'PDF pages as model-safe images using bundled decoders. For SVG, HEIF, '
      'HEIC, WebP, or the first GIF/APNG frame, supply path only. For video or '
      'selected GIF/APNG frames supply timestamps_seconds. For PDF or '
      'PDF-compatible Illustrator AI supply one-based pages. Never supply both '
      'selector lists. Legacy AI, EPS and other vector formats must first be '
      'exported as SVG or PDF.';

  @override
  Set<String> get requiredScopeKeys => const {'workspace_id', 'agent_id'};

  @override
  Set<String> get forcedScopeKeys => const {
    'agent_id',
    'space_id',
    'conversation_id',
  };

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Authenticated caller workspace, filled by transport.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'Authenticated caller agent, filled by transport.',
      },
      'conversation_id': {
        'type': 'string',
        'description':
            'Current conversation, when present; filled by transport.',
      },
      'space_id': {
        'type': 'string',
        'description': 'Current space, when present; filled by transport.',
      },
      'path': {'type': 'string', 'description': 'Image, video or PDF path.'},
      'timestamps_seconds': {
        'type': 'array',
        'items': {'type': 'number', 'minimum': 0},
        'minItems': 1,
        'maxItems': 4,
        'description':
            'Video or GIF/APNG timestamps in seconds (finite and nonnegative).',
      },
      'pages': {
        'type': 'array',
        'items': {'type': 'integer', 'minimum': 1},
        'minItems': 1,
        'maxItems': 4,
        'description': 'One-based PDF page numbers.',
      },
      'max_dimension': {
        'type': 'integer',
        'minimum': 128,
        'maximum': 2048,
        'default': 1600,
        'description': 'Maximum output image edge in pixels.',
      },
    },
    'required': ['workspace_id', 'agent_id', 'path'],
    'not': {
      'required': ['timestamps_seconds', 'pages'],
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) =>
      _render(arguments, null);

  @override
  Future<CallResult> runUntilAbandoned(
    Map<String, dynamic> arguments,
    Future<void> abandoned,
  ) => _render(arguments, abandoned);
  Future<CallResult> _render(
    Map<String, dynamic> arguments,
    Future<void>? abandoned,
  ) async {
    final (workspaceId, workspaceError) = McpTool.requireString(
      arguments,
      'workspace_id',
    );
    if (workspaceError != null) {
      return workspaceError;
    }
    final (agentId, agentError) = McpTool.requireString(arguments, 'agent_id');
    if (agentError != null) {
      return agentError;
    }
    final (path, pathError) = McpTool.requireString(arguments, 'path');
    if (pathError != null) {
      return pathError;
    }

    final space = arguments['space_id'];
    if (space != null && (space is! String || space.isEmpty)) {
      return CallResult.error(McpTool.missingArgument('space_id'));
    }
    final conversation = arguments['conversation_id'];
    if (conversation != null &&
        (conversation is! String || conversation.isEmpty)) {
      return CallResult.error(McpTool.missingArgument('conversation_id'));
    }
    final hasTimestamps = arguments.containsKey('timestamps_seconds');
    final hasPages = arguments.containsKey('pages');
    if (hasTimestamps && hasPages) {
      return CallResult.error(
        'Specify timestamps_seconds or pages, but not both.',
      );
    }
    List<double> timestamps = const [];
    List<int> pages = const [];
    if (hasTimestamps) {
      final raw = arguments['timestamps_seconds'];
      if (raw is! List || raw.isEmpty || raw.any((value) => value is! num)) {
        return CallResult.error('timestamps_seconds must contain numbers.');
      }
      timestamps = [for (final value in raw) (value as num).toDouble()];
    } else if (hasPages) {
      final raw = arguments['pages'];
      if (raw is! List || raw.isEmpty || raw.any((value) => value is! int)) {
        return CallResult.error('pages must contain one-based integers.');
      }
      pages = List<int>.from(raw);
    }
    final dimension = arguments['max_dimension'] ?? 1600;
    if (dimension is! int) {
      return CallResult.error('max_dimension must be an integer.');
    }

    final request = MediaRenderRequest(
      workspaceId: workspaceId!,
      agentId: agentId!,
      spaceId: space as String?,
      conversationId: conversation as String?,
      path: path!,
      timestampsSeconds: timestamps,
      pages: pages,
      maxDimension: dimension,
      abandoned: abandoned,
    );
    request.validate();
    final result = await renderer.render(request);
    return CallResult.withImages(
      jsonEncode({
        'source': result.source,
        if (result.durationSeconds != null)
          'duration_seconds': result.durationSeconds,
        if (result.pageCount != null) 'page_count': result.pageCount,
        'images': [
          for (final entry in result.images)
            {
              ...entry.image.toJson(),
              if (entry.page != null) 'page': entry.page,
              if (entry.timestampSeconds != null)
                'timestamp_seconds': entry.timestampSeconds,
              if (entry.requestedTimestampSeconds != null)
                'requested_timestamp_seconds': entry.requestedTimestampSeconds,
            },
        ],
      }),
      [
        for (final entry in result.images)
          (data: base64Encode(entry.bytes), mimeType: entry.image.mediaType),
      ],
    );
  }
}

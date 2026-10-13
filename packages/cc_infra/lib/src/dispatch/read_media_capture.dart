import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

typedef _ReadSource = ({String path, String mime});
const _vectorExtensions = {
  '.ai',
  '.eps',
  '.ps',
  '.emf',
  '.wmf',
  '.cdr',
  '.dxf',
  '.svgz',
};
const _inlineImageTypes = {
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/apng',
  'image/webp',
  'image/bmp',
};
final _selector = RegExp(r':(?:img|\d+(?:[-+]\d*)?(?:,\d+(?:[-+]\d*)?)*)$');

/// Saves successfully read media before its result reaches the transcript.
/// Subsequent events stay ordered behind the save, including turn completion.
class ReadMediaCapture {
  /// Routes events through the workspace's bounded media store.
  ReadMediaCapture({
    required this.emit,
    required this.workingDirectory,
    required this.workspaceId,
    required this.store,
    this.renderer,
    this.agentId,
    this.spaceId,
    this.conversationId,
  });

  /// Receives events in their original order after any media is saved.
  final void Function(AgentProcessEvent event) emit;

  /// Host directory used to resolve relative Read paths.
  final String workingDirectory;

  /// Workspace that owns the captured media.
  final String? workspaceId;

  /// Existing workspace blob store, or null when capture is unavailable.
  final BlobStore? store;

  /// Shared, workspace-scoped renderer for images the client cannot decode.
  final MediaRenderPort? renderer;

  /// Identity of the live dispatch, never inferred from a Read tool argument.
  final String? agentId;

  /// Space containing the live dispatch, when the run is space-scoped.
  final String? spaceId;

  /// Conversation containing the live dispatch, when present.
  final String? conversationId;
  final Map<String, _ReadSource> _paths = {};
  Future<void>? _pending;

  /// Completes after all accepted events have been emitted.
  Future<void> get drained => _pending ?? Future<void>.value();

  /// Whether no accepted event is still waiting on a capture.
  bool get isIdle => _pending == null;

  /// Captures final, successful Read results without delaying ordinary text.
  void add(AgentProcessEvent event) {
    _ReadSource? source;
    if (store != null && workspaceId != null && workspaceId!.isNotEmpty) {
      if (event is ToolCallEvent && event.toolName.toLowerCase() == 'read') {
        final inputs = event.inputs;
        final raw =
            inputs?['file_path'] ?? inputs?['path'] ?? inputs?['filename'];
        if (raw is String && raw.isNotEmpty && event.toolCallId.isNotEmpty) {
          final source = _source(raw);
          if (source != null) {
            _paths[event.toolCallId] = source;
          }
        }
      } else if (event is ToolResultEvent && !event.isPartial) {
        final candidate = _paths.remove(event.toolCallId);
        if (!event.isError && event.attachments.isEmpty) {
          source = candidate;
        }
      }
    }
    if (source == null && _pending == null) {
      emit(event);
      return;
    }
    final readSource = source;
    final next = (_pending ?? Future<void>.value()).then((_) async {
      emit(
        readSource == null
            ? event
            : await _capture(event as ToolResultEvent, readSource),
      );
    });
    _pending = next;
    unawaited(
      next.whenComplete(() {
        if (identical(_pending, next)) {
          _pending = null;
        }
      }),
    );
  }

  _ReadSource? _source(String rawPath) {
    if (rawPath.endsWith(':raw') || rawPath.contains('://')) {
      return null;
    }
    var path = rawPath.replaceFirst(_selector, '');
    if (path.startsWith('~/')) {
      final home = Platform.environment['HOME'];
      if (home == null) {
        return null;
      }
      path = p.join(home, path.substring(2));
    }
    final ext = p.extension(path).toLowerCase();
    final mime = switch (ext) {
      '.apng' => 'image/apng',
      '.heic' => 'image/heic',
      '.heif' => 'image/heif',
      '.avif' => 'image/avif',
      '.jxl' => 'image/jxl',
      '.tif' || '.tiff' => 'image/tiff',
      '.svg' => 'image/svg+xml',
      '.ai' || '.eps' || '.ps' => 'application/postscript',
      _ when _vectorExtensions.contains(ext) => 'application/octet-stream',
      _ => lookupMimeType(path),
    };
    return mime != null && (_vectorExtensions.contains(ext) || _isMedia(mime))
        ? (path: path, mime: mime)
        : null;
  }

  Future<ToolResultEvent> _capture(
    ToolResultEvent event,
    _ReadSource source,
  ) async {
    final store = this.store!;
    final (:path, :mime) = source;
    final name = p.basename(path);
    if (_inlineImageTypes.contains(mime) &&
        mime != 'image/png' &&
        mime != 'image/gif' &&
        mime != 'image/apng' &&
        event.images.isNotEmpty) {
      return event;
    }
    final file = File(
      p.isAbsolute(path) ? path : p.join(workingDirectory, path),
    );
    try {
      final stat = file.statSync();
      if (stat.type != FileSystemEntityType.file ||
          stat.size > store.maxBytes) {
        return event;
      }
      final handle = await file.open();
      final bytes = await handle.read(stat.size + 1).whenComplete(handle.close);
      if (bytes.length != stat.size) {
        return event;
      }
      final effectiveMime =
          p.extension(path).toLowerCase() == '.ai' &&
              bytes.length >= 5 &&
              bytes[0] == 0x25 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x44 &&
              bytes[3] == 0x46 &&
              bytes[4] == 0x2d
          ? 'application/pdf'
          : mime == 'image/png' && _isAnimatedPng(bytes)
          ? 'image/apng'
          : mime;
      if (effectiveMime == 'image/png' && event.images.isNotEmpty) {
        return event;
      }
      final blob = await store.put(
        workspaceId!,
        bytes,
        mediaType: effectiveMime,
      );
      if (blob == null) {
        return event;
      }
      var images = event.images;
      if (mime.startsWith('image/')) {
        images = const [];
      }
      final renderer = this.renderer;
      final agentId = this.agentId;
      if (renderer != null &&
          agentId != null &&
          agentId.isNotEmpty &&
          effectiveMime.startsWith('image/') &&
          !_inlineImageTypes.contains(effectiveMime)) {
        try {
          final result = await renderer.render(
            MediaRenderRequest(
              workspaceId: workspaceId!,
              agentId: agentId,
              spaceId: spaceId,
              conversationId: conversationId,
              path: path,
            ),
          );
          if (result.source == 'image' && result.images.isNotEmpty) {
            images = [
              ...images,
              for (final preview in result.images) preview.image,
            ];
          }
        } on Object catch (error) {
          CcInfraLog.warning('Unable to preview read media "$path": $error');
        }
      }
      return ToolResultEvent(
        toolCallId: event.toolCallId,
        outputs: event.outputs,
        toolName: event.toolName,
        isError: event.isError,
        isPartial: event.isPartial,
        timestamp: event.timestamp,
        images: images,
        attachments: [
          MessageAttachment(
            id: 'read:${event.toolCallId}',
            path: blob.ref,
            name: name,
            kind: _inlineImageTypes.contains(effectiveMime)
                ? AttachmentKind.image
                : AttachmentKind.file,
            mediaType: effectiveMime,
            size: blob.bytes,
          ),
        ],
      );
    } on Object catch (error) {
      CcInfraLog.warning('Unable to preserve read media "$path": $error');
      return event;
    }
  }

  static bool _isAnimatedPng(List<int> bytes) {
    if (bytes.length < 20 ||
        bytes[0] != 0x89 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x4e ||
        bytes[3] != 0x47 ||
        bytes[4] != 0x0d ||
        bytes[5] != 0x0a ||
        bytes[6] != 0x1a ||
        bytes[7] != 0x0a) {
      return false;
    }
    var offset = 8;
    while (offset + 12 <= bytes.length) {
      final size =
          (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      if (size > bytes.length - offset - 12) {
        return false;
      }
      final a = bytes[offset + 4];
      final b = bytes[offset + 5];
      final c = bytes[offset + 6];
      final d = bytes[offset + 7];
      if (a == 0x61 && b == 0x63 && c == 0x54 && d == 0x4c) {
        return size >= 8;
      }
      if ((a == 0x49 && b == 0x44 && c == 0x41 && d == 0x54) ||
          (a == 0x49 && b == 0x45 && c == 0x4e && d == 0x44)) {
        return false;
      }
      offset += size + 12;
    }
    return false;
  }

  static bool _isMedia(String mime) =>
      mime.startsWith('image/') ||
      mime.startsWith('video/') ||
      mime.startsWith('audio/') ||
      mime == 'application/pdf' ||
      mime == 'application/rtf' ||
      mime == 'application/msword' ||
      mime.startsWith('application/vnd.openxmlformats-officedocument.') ||
      mime.startsWith('application/vnd.oasis.opendocument.') ||
      mime == 'application/vnd.ms-excel' ||
      mime == 'application/vnd.ms-powerpoint';
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event_codec.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/dispatch/read_media_capture.dart';
import 'package:cc_infra/src/messaging/transcript_folder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late BlobStore store;
  late List<AgentProcessEvent> events;
  late ReadMediaCapture capture;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('read-media-test-');
    store = BlobStore(workspaceDir: (id) => p.join(root.path, id));
    events = [];
    capture = ReadMediaCapture(
      emit: events.add,
      workingDirectory: root.path,
      workspaceId: 'workspace',
      store: store,
    );
  });
  tearDown(() async {
    await capture.drained;
    await root.delete(recursive: true);
  });

  test('read media survives source deletion and transcript transport', () async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
    );
    final source = File(p.join(root.path, 'frame.png'));
    await source.writeAsBytes(bytes);
    capture.add(
      ToolCallEvent(
        toolName: 'Read',
        toolCallId: 'read-frame',
        inputs: {'file_path': 'frame.png'},
      ),
    );
    capture.add(ToolResultEvent(toolCallId: 'read-frame', outputs: '[image]'));
    capture.add(DoneEvent());
    await capture.drained;
    await source.delete();

    final result = events.whereType<ToolResultEvent>().single;
    final attachment = result.attachments.single;
    expect(attachment.name, 'frame.png');
    expect(attachment.mediaType, 'image/png');
    expect(
      await store.fileFor('workspace', attachment.blobHash!)!.readAsBytes(),
      bytes,
    );
    final folder = TranscriptFolder(onUpdate: (_, {required structural}) {});
    for (final event in events) {
      folder.add(
        AgentProcessEventCodec.fromWire(AgentProcessEventCodec.toWire(event)),
      );
    }
    final restored =
        TranscriptSegment.fromJson(folder.segments.single.toJson())
            as ToolSegment;
    expect(restored.attachments.single, attachment);
    expect(restored.status, ToolSegmentStatus.ok);
    expect(events.last, isA<DoneEvent>());
  });

  test(
    'denied, partial and unpaired results never expose a source file',
    () async {
      await File(
        p.join(root.path, 'private.pdf'),
      ).writeAsString('%PDF-1.4\nprivate');
      capture.add(
        ToolCallEvent(
          toolName: 'Read',
          toolCallId: 'denied',
          inputs: {'file_path': 'private.pdf'},
        ),
      );
      capture.add(
        ToolResultEvent(
          toolCallId: 'denied',
          outputs: 'working',
          isPartial: true,
        ),
      );
      capture.add(
        ToolResultEvent(toolCallId: 'denied', outputs: 'denied', isError: true),
      );
      capture.add(ToolResultEvent(toolCallId: 'unknown', outputs: 'done'));
      await capture.drained;
      expect(
        events.whereType<ToolResultEvent>().every(
          (event) => event.attachments.isEmpty,
        ),
        isTrue,
      );
      expect(Directory(store.directoryFor('workspace')).existsSync(), isFalse);
    },
  );

  test('completion cannot overtake a media save', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    store = BlobStore(
      workspaceDir: (id) => p.join(root.path, id),
      onArtifactStored: (_, _, _) async {
        entered.complete();
        await release.future;
      },
    );
    capture = ReadMediaCapture(
      emit: events.add,
      workingDirectory: root.path,
      workspaceId: 'workspace',
      store: store,
    );
    await File(
      p.join(root.path, 'clip.mp4'),
    ).writeAsBytes([0, 0, 0, 24, 102, 116, 121, 112]);
    capture.add(
      ToolCallEvent(
        toolName: 'read',
        toolCallId: 'clip',
        inputs: {'path': 'clip.mp4'},
      ),
    );
    capture.add(ToolResultEvent(toolCallId: 'clip', outputs: 'video frames'));
    capture.add(TextEvent(content: 'finished'));
    capture.add(DoneEvent());
    await entered.future;
    expect(events.map((event) => event.type), [AgentProcessEventType.toolCall]);
    release.complete();
    await capture.drained;
    expect(events.map((event) => event.type), [
      AgentProcessEventType.toolCall,
      AgentProcessEventType.toolResult,
      AgentProcessEventType.text,
      AgentProcessEventType.done,
    ]);
    expect(
      events.whereType<ToolResultEvent>().single.attachments.single.mediaType,
      'video/mp4',
    );
  });

  test('SVG preview waits for scoped render and retains the original', () async {
    final entered = Completer<MediaRenderRequest>();
    final release = Completer<void>();
    final original = File(p.join(root.path, 'drawing.svg'));
    await original.writeAsString('<svg xmlns="http://www.w3.org/2000/svg"/>');
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
    );
    capture = ReadMediaCapture(
      emit: events.add,
      workingDirectory: root.path,
      workspaceId: 'workspace',
      agentId: 'agent',
      spaceId: 'space',
      conversationId: 'conversation',
      store: store,
      renderer: _TestRenderer((request) async {
        entered.complete(request);
        await release.future;
        final blob = await store.put('workspace', png, mediaType: 'image/png');
        return MediaRenderResult(
          source: 'image',
          images: [
            RenderedMediaImage(
              bytes: Uint8List.fromList(png),
              image: ToolImageRef(ref: blob!.ref),
            ),
          ],
        );
      }),
    );
    capture.add(
      ToolCallEvent(
        toolName: 'Read',
        toolCallId: 'svg',
        inputs: {'path': 'drawing.svg'},
      ),
    );
    capture.add(ToolResultEvent(toolCallId: 'svg', outputs: '[image]'));
    capture.add(DoneEvent());
    final request = await entered.future;
    expect(request.workspaceId, 'workspace');
    expect(request.agentId, 'agent');
    expect(request.spaceId, 'space');
    expect(request.conversationId, 'conversation');
    expect(request.path, 'drawing.svg');
    expect(events.map((event) => event.type), [AgentProcessEventType.toolCall]);
    release.complete();
    await capture.drained;
    await original.delete();
    final result = events.whereType<ToolResultEvent>().single;
    expect(result.attachments.single.mediaType, 'image/svg+xml');
    expect(
      utf8.decode(
        await store
            .fileFor('workspace', result.attachments.single.blobHash!)!
            .readAsBytes(),
      ),
      contains('<svg'),
    );
    expect(
      await store
          .fileFor('workspace', blobHashOf(result.images.single.ref)!)!
          .readAsBytes(),
      png,
    );
    expect(events.last, isA<DoneEvent>());
  });

  test(
    'failed render retains the original without a broken image ref',
    () async {
      await File(p.join(root.path, 'portrait.heic')).writeAsBytes([1, 2, 3]);
      capture = ReadMediaCapture(
        emit: events.add,
        workingDirectory: root.path,
        workspaceId: 'workspace',
        agentId: 'agent',
        store: store,
        renderer: _TestRenderer((_) async {
          throw const MediaRenderException('unsupported');
        }),
      );
      capture.add(
        ToolCallEvent(
          toolName: 'Read',
          toolCallId: 'heic',
          inputs: {'path': 'portrait.heic'},
        ),
      );
      capture.add(ToolResultEvent(toolCallId: 'heic', outputs: '[image]'));
      await capture.drained;
      final result = events.whereType<ToolResultEvent>().single;
      expect(result.images, isEmpty);
      expect(result.attachments.single.mediaType, 'image/heic');
      expect(result.attachments.single.blobHash, isNotNull);
    },
  );

  test('PDF-compatible AI uses PDF MIME, legacy AI stays a file', () async {
    await File(p.join(root.path, 'pdf.ai')).writeAsString('%PDF-1.7\n');
    await File(
      p.join(root.path, 'legacy.ai'),
    ).writeAsString('%!PS-Adobe-3.0\n');
    for (final name in ['pdf.ai', 'legacy.ai']) {
      capture.add(
        ToolCallEvent(
          toolName: 'Read',
          toolCallId: name,
          inputs: {'file_path': name},
        ),
      );
      capture.add(ToolResultEvent(toolCallId: name, outputs: 'read'));
    }
    await capture.drained;
    final results = events.whereType<ToolResultEvent>().toList();
    expect(results[0].attachments.single.mediaType, 'application/pdf');
    expect(results[1].attachments.single.mediaType, 'application/postscript');
    expect(results.every((result) => result.images.isEmpty), isTrue);
  });

  test(
    'animated GIF and APNG keep original bytes for inline playback',
    () async {
      for (final (name, bytes) in [
        ('animated.gif', [71, 73, 70, 56, 57, 97]),
        ('animated.apng', [137, 80, 78, 71, 13, 10, 26, 10]),
        (
          'animated.png',
          [
            137,
            80,
            78,
            71,
            13,
            10,
            26,
            10,
            0,
            0,
            0,
            8,
            97,
            99,
            84,
            76,
            0,
            0,
            0,
            2,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
          ],
        ),
      ]) {
        await File(p.join(root.path, name)).writeAsBytes(bytes);
        capture.add(
          ToolCallEvent(
            toolName: 'Read',
            toolCallId: name,
            inputs: {'path': name},
          ),
        );
        capture.add(
          ToolResultEvent(
            toolCallId: name,
            outputs: '[image]',
            images: const [ToolImageRef(ref: 'blob:sha256:placeholder')],
          ),
        );
      }
      await capture.drained;
      final results = events.whereType<ToolResultEvent>().toList();
      expect(results.map((result) => result.attachments.single.mediaType), [
        'image/gif',
        'image/apng',
        'image/apng',
      ]);
      expect(
        results.every((result) => result.attachments.single.isImage),
        isTrue,
      );
      expect(results.every((result) => result.images.isEmpty), isTrue);
    },
  );
}

class _TestRenderer implements MediaRenderPort {
  _TestRenderer(this.onRender);
  final Future<MediaRenderResult> Function(MediaRenderRequest) onRender;

  @override
  Future<MediaRenderResult> render(MediaRenderRequest request) =>
      onRender(request);
}

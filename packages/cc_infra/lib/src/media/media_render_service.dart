import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/media/bundled_media_tools.dart';
import 'package:cc_infra/src/media/media_read_scope.dart';
import 'package:cc_infra/src/media/media_render_process.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

// Below the MCP bridge's 5 MiB base64 ceiling, with room for result metadata.
const _maxImageBytes = 3 * 1024 * 1024;
const _maxSourcePixels = 64 * 1024 * 1024;
const _imageFormats = {
  'png_pipe',
  'jpeg_pipe',
  'webp_pipe',
  'bmp_pipe',
  'tiff_pipe',
  'jxl_pipe',
  'gif',
  'apng',
};
const _heifBrands = {
  'heic',
  'heix',
  'hevc',
  'hevx',
  'mif1',
  'msf1',
  'avif',
  'avis',
};
final _visualFormats =
    'mov,matroska,webm,avi,mpegts,mpeg,ogg,asf,flv,mxf,${_imageFormats.join(',')}';
final _frameTimestamp = RegExp(r'\bpts_time:([-+\d.eE]+)');

/// Executes the shared render_media operation with application-owned decoders.
class MediaRenderService implements MediaRenderPort {
  /// Resolves read authority from live dispatches, not model-supplied roots.
  MediaRenderService({
    required BlobStore blobStore,
    required this._resolveScope,
    required this._appSupportRoot,
    this._tools,
    this._timeout = const Duration(seconds: 45),
  }) : _blobs = blobStore;

  final BlobStore _blobs;
  final MediaReadScope? Function(MediaRenderRequest request) _resolveScope;
  final String _appSupportRoot;
  final Duration _timeout;
  final Pool _renders = Pool(2);
  BundledMediaTools? _tools;

  @override
  Future<MediaRenderResult> render(MediaRenderRequest request) async {
    request.validate();
    final scope = _resolveScope(request);
    if (scope == null) {
      throw const MediaRenderException(
        'No unique active dispatch matches this media request. The tool can only read its own running agent workspace.',
      );
    }
    final source = resolveInsideWorkspace(
      scope.workingDirectory,
      request.path,
      sharedRoots: scope.sharedRoots,
    );
    if (source == null) {
      throw MediaRenderException(
        outsideWorkspaceMessage(
          'render media',
          request.path,
          workspaceRoot: scope.workingDirectory,
          sharedRoots: scope.sharedRoots,
        ),
      );
    }
    final sourceFile = File(source);
    if (sourceFile.statSync().type != FileSystemEntityType.file) {
      throw MediaRenderException(
        'Media source is not a regular file: ${request.path}',
      );
    }
    final canonicalSource = sourceFile.resolveSymbolicLinksSync();
    if (!resolvesInsideRoots(canonicalSource, [
      scope.workingDirectory,
      ...scope.sharedRoots,
    ])) {
      throw const MediaRenderException(
        'Media source escapes the workspace through a symbolic link.',
      );
    }
    final tools = _tools ??= BundledMediaTools.locate(
      appSupportRoot: _appSupportRoot,
    );
    final operation = MediaRenderProcess(
      timeout: _timeout,
      abandoned: [request.abandoned, scope.abandoned],
    );
    try {
      return await operation.guard(
        _renders.withResource(() async {
          operation.checkActive();
          final extension = p.extension(source).toLowerCase();
          if (extension == '.svg') {
            if (request.pages.isNotEmpty ||
                request.timestampsSeconds.isNotEmpty) {
              throw const MediaRenderException(
                'SVG is a still image. Supply path without page or timestamp selectors.',
              );
            }
            return _renderSvg(
              request: request,
              path: canonicalSource,
              tools: tools,
              operation: operation,
            );
          }
          if (const {'.ai', '.eps', '.ps'}.contains(extension)) {
            final file = await File(canonicalSource).open();
            try {
              if (latin1.decode(await file.read(5)) != '%PDF-') {
                throw const MediaRenderException(
                  'Legacy Illustrator, EPS and PostScript cannot be previewed. Export as PDF or SVG; only PDF-compatible AI files are supported.',
                );
              }
            } finally {
              await file.close();
            }
            if (request.pages.isEmpty) {
              throw const MediaRenderException(
                'PDF-compatible vector files require one-based pages, for example pages: [1].',
              );
            }
          }
          return request.pages.isNotEmpty
              ? _renderPdf(
                  request: request,
                  path: canonicalSource,
                  tools: tools,
                  operation: operation,
                )
              : _renderVisual(
                  request: request,
                  path: canonicalSource,
                  tools: tools,
                  operation: operation,
                );
        }),
      );
    } on MediaRenderException {
      rethrow;
    } on Object catch (error) {
      throw MediaRenderException('Unable to render media: $error');
    } finally {
      operation.dispose();
    }
  }

  Future<MediaRenderResult> _renderVisual({
    required MediaRenderRequest request,
    required String path,
    required BundledMediaTools tools,
    required MediaRenderProcess operation,
  }) async {
    final probe = await operation.run(
      executable: tools.ffprobe,
      arguments: [
        '-v',
        'error',
        '-max_alloc',
        '67108864',
        '-protocol_whitelist',
        'file,pipe',
        '-format_whitelist',
        _visualFormats,
        '-show_entries',
        'format=format_name,duration,start_time:format_tags=major_brand:stream=index,codec_type,width,height,duration:stream_disposition=attached_pic',
        '-of',
        'json',
        path,
      ],
      maxOutputBytes: 1024 * 1024,
    );
    final metadata =
        jsonDecode(utf8.decode(probe.bytes)) as Map<String, dynamic>;
    final streams = metadata['streams'] as List? ?? const [];
    Map<String, dynamic>? video;
    for (final raw in streams) {
      if (raw is Map<String, dynamic> &&
          raw['codec_type'] == 'video' &&
          (raw['disposition'] as Map?)?['attached_pic'] != 1) {
        video = raw;
        break;
      }
    }
    if (video == null) {
      throw const MediaRenderException(
        'The source does not contain a video stream.',
      );
    }
    final width = (video['width'] as num?)?.toInt() ?? 0;
    final height = (video['height'] as num?)?.toInt() ?? 0;
    if (width <= 0 || height <= 0 || width * height > _maxSourcePixels) {
      throw const MediaRenderException(
        'Video dimensions are invalid or exceed the decoder pixel limit.',
      );
    }
    final format = metadata['format'] as Map?;
    final formats = (format?['format_name'] as String? ?? '').split(',');
    if (request.timestampsSeconds.isEmpty) {
      final brand = ((format?['tags'] as Map?)?['major_brand'] as String? ?? '')
          .trim();
      if (!formats.any(_imageFormats.contains) &&
          !_heifBrands.contains(brand)) {
        throw const MediaRenderException(
          'Video inputs require timestamps_seconds. Omit selectors only for still images.',
        );
      }
      return _renderImage(
        request: request,
        path: path,
        streamIndex: (video['index'] as num).toInt(),
        tools: tools,
        operation: operation,
      );
    }
    final duration = _number(format?['duration']) ?? _number(video['duration']);
    final origin = _number(format?['start_time']) ?? 0;
    final animation = formats.contains('gif') || formats.contains('apng');
    for (final timestamp in request.timestampsSeconds) {
      if (duration != null && timestamp >= duration) {
        throw MediaRenderException(
          'Timestamp $timestamp is outside this ${duration}s video.',
        );
      }
    }
    final selected = <RenderedMediaImage>[];
    final rendered = <double, RenderedMediaImage>{};
    for (final timestamp in request.timestampsSeconds) {
      final existing = rendered[timestamp];
      if (existing != null) {
        selected.add(existing);
        continue;
      }
      final frameTime = (timestamp + origin).toStringAsFixed(6);
      // Retain the displayed frame at microsecond precision, then stop the
      // filter graph itself: an output limit alone can queue millions of frames.
      final frameFilter =
          'showinfo=checksum=0,'
          'fps=fps=1000000:start_time=$frameTime:round=up:eof_action=pass,'
          'trim=end_frame=1,'
          '${_scaleFilter(request.maxDimension)}';
      final frame = await operation.run(
        executable: tools.ffmpeg,
        arguments: [
          '-hide_banner',
          '-nostdin',
          '-loglevel',
          'info',
          '-max_alloc',
          '67108864',
          '-threads',
          '2',
          '-copyts',
          if (animation) ...[
            '-ignore_loop',
            '1',
          ] else ...[
            '-noaccurate_seek',
            '-ss',
            timestamp.toStringAsFixed(6),
          ],
          '-protocol_whitelist',
          'file,pipe',
          '-format_whitelist',
          _visualFormats,
          '-i',
          path,
          '-map',
          '0:${video['index']}',
          '-an',
          '-sn',
          '-dn',
          '-vf',
          frameFilter,
          '-frames:v',
          '1',
          '-fps_mode',
          'passthrough',
          '-c:v',
          'mjpeg',
          '-q:v',
          '5',
          '-pix_fmt',
          'yuvj444p',
          '-threads',
          '1',
          '-f',
          'image2pipe',
          'pipe:1',
        ],
        maxOutputBytes: _maxImageBytes,
      );
      final target = double.parse(frameTime);
      double? pts;
      for (final match in _frameTimestamp.allMatches(frame.diagnostics)) {
        final candidate = _number(match.group(1));
        if (candidate != null && (pts == null || candidate <= target)) {
          pts = candidate;
        }
      }
      if (frame.bytes.isEmpty || pts == null) {
        throw MediaRenderException(
          'No video frame could be decoded at ${timestamp}s.',
        );
      }
      final ref = await _storeImage(
        request: request,
        operation: operation,
        bytes: frame.bytes,
        mediaType: 'image/jpeg',
      );
      final result = RenderedMediaImage(
        bytes: frame.bytes,
        image: ref,
        timestampSeconds: pts - origin,
        requestedTimestampSeconds: timestamp,
      );
      selected.add(result);
      rendered[timestamp] = result;
    }
    return MediaRenderResult(
      source: 'video',
      durationSeconds: duration,
      images: selected,
    );
  }

  Future<MediaRenderResult> _renderImage({
    required MediaRenderRequest request,
    required String path,
    required int streamIndex,
    required BundledMediaTools tools,
    required MediaRenderProcess operation,
  }) async {
    final decoded = await operation.run(
      executable: tools.ffmpeg,
      arguments: [
        '-hide_banner',
        '-nostdin',
        '-loglevel',
        'error',
        '-max_alloc',
        '67108864',
        '-threads',
        '2',
        '-protocol_whitelist',
        'file,pipe',
        '-format_whitelist',
        _visualFormats,
        '-i',
        path,
        '-map',
        '0:$streamIndex',
        '-an',
        '-sn',
        '-dn',
        '-vf',
        _scaleFilter(request.maxDimension),
        '-frames:v',
        '1',
        '-c:v',
        'png',
        '-pix_fmt',
        'rgba',
        '-threads',
        '1',
        '-f',
        'image2pipe',
        'pipe:1',
      ],
      maxOutputBytes: request.maxDimension * request.maxDimension * 4 + 65536,
    );
    return _storeStillImage(
      request: request,
      tools: tools,
      operation: operation,
      png: decoded.bytes,
    );
  }

  Future<MediaRenderResult> _storeStillImage({
    required MediaRenderRequest request,
    required BundledMediaTools tools,
    required MediaRenderProcess operation,
    required Uint8List png,
  }) async {
    var bytes = png;
    var mediaType = 'image/png';
    if (bytes.length > _maxImageBytes) {
      bytes = await _encodeImage(
        tools: tools,
        operation: operation,
        input: bytes,
        inputCodec: 'png',
        jpeg: true,
        maxOutputBytes: _maxImageBytes,
      );
      mediaType = 'image/jpeg';
    }
    final ref = await _storeImage(
      request: request,
      operation: operation,
      bytes: bytes,
      mediaType: mediaType,
    );
    return MediaRenderResult(
      source: 'image',
      images: [RenderedMediaImage(bytes: bytes, image: ref)],
    );
  }

  Future<MediaRenderResult> _renderSvg({
    required MediaRenderRequest request,
    required String path,
    required BundledMediaTools tools,
    required MediaRenderProcess operation,
  }) async {
    final rendered = await operation.run(
      executable: tools.svgRenderer,
      arguments: ['render', path, '${request.maxDimension}'],
      maxOutputBytes: request.maxDimension * request.maxDimension * 4 + 65536,
    );
    return _storeStillImage(
      request: request,
      tools: tools,
      operation: operation,
      png: rendered.bytes,
    );
  }

  Future<MediaRenderResult> _renderPdf({
    required MediaRenderRequest request,
    required String path,
    required BundledMediaTools tools,
    required MediaRenderProcess operation,
  }) async {
    final probe = await operation.run(
      executable: tools.pdfRenderer,
      arguments: ['info', path],
      maxOutputBytes: 4096,
    );
    final metadata =
        jsonDecode(utf8.decode(probe.bytes)) as Map<String, dynamic>;
    final pageCount = (metadata['page_count'] as num?)?.toInt() ?? 0;
    if (pageCount < 1) {
      throw const MediaRenderException('The PDF contains no readable pages.');
    }
    for (final page in request.pages) {
      if (page > pageCount) {
        throw MediaRenderException(
          'Page $page is outside this $pageCount-page PDF. Pages are one-based.',
        );
      }
    }
    final selected = <RenderedMediaImage>[];
    final rendered = <int, RenderedMediaImage>{};
    for (final page in request.pages) {
      final existing = rendered[page];
      if (existing != null) {
        selected.add(existing);
        continue;
      }
      final ppm = await operation.run(
        executable: tools.pdfRenderer,
        arguments: ['render', path, '$page', '${request.maxDimension}'],
        maxOutputBytes: request.maxDimension * request.maxDimension * 3 + 128,
      );
      var encoded = await _encodeImage(
        tools: tools,
        operation: operation,
        input: ppm.bytes,
        jpeg: false,
        maxOutputBytes: request.maxDimension * request.maxDimension * 3 + 65536,
      );
      var mediaType = 'image/png';
      if (encoded.length > _maxImageBytes) {
        encoded = await _encodeImage(
          tools: tools,
          operation: operation,
          input: ppm.bytes,
          jpeg: true,
          maxOutputBytes: _maxImageBytes,
        );
        mediaType = 'image/jpeg';
      }
      final ref = await _storeImage(
        request: request,
        operation: operation,
        bytes: encoded,
        mediaType: mediaType,
      );
      final result = RenderedMediaImage(bytes: encoded, image: ref, page: page);
      selected.add(result);
      rendered[page] = result;
    }
    return MediaRenderResult(
      source: 'pdf',
      pageCount: pageCount,
      images: selected,
    );
  }

  Future<Uint8List> _encodeImage({
    required BundledMediaTools tools,
    required MediaRenderProcess operation,
    required Uint8List input,
    required bool jpeg,
    required int maxOutputBytes,
    String inputCodec = 'ppm',
  }) async {
    final output = await operation.run(
      executable: tools.ffmpeg,
      arguments: [
        '-hide_banner',
        '-nostdin',
        '-loglevel',
        'error',
        '-max_alloc',
        '67108864',
        '-protocol_whitelist',
        'pipe',
        '-f',
        'image2pipe',
        '-c:v',
        inputCodec,
        '-i',
        'pipe:0',
        '-frames:v',
        '1',
        '-threads',
        '1',
        '-c:v',
        if (jpeg) 'mjpeg' else 'png',
        if (jpeg) ...['-q:v', '5', '-pix_fmt', 'yuvj444p'],
        '-f',
        'image2pipe',
        'pipe:1',
      ],
      input: input,
      maxOutputBytes: maxOutputBytes,
    );
    return output.bytes;
  }

  Future<ToolImageRef> _storeImage({
    required MediaRenderRequest request,
    required MediaRenderProcess operation,
    required Uint8List bytes,
    required String mediaType,
  }) async {
    operation.checkActive();
    if (bytes.isEmpty || bytes.length > _maxImageBytes) {
      throw const MediaRenderException(
        'The rendered image is empty or exceeds the model image limit.',
      );
    }
    final info = mediaType == 'image/png'
        ? image.PngDecoder().startDecode(bytes)
        : image.JpegDecoder().startDecode(bytes);
    if (info == null ||
        info.width < 1 ||
        info.height < 1 ||
        info.width > request.maxDimension ||
        info.height > request.maxDimension) {
      throw const MediaRenderException(
        'The media renderer returned invalid image dimensions.',
      );
    }
    final blob = await _blobs.put(
      request.workspaceId,
      bytes,
      mediaType: mediaType,
      creatorId: request.agentId,
    );
    operation.checkActive();
    if (blob == null) {
      throw const MediaRenderException(
        'Unable to retain the rendered image in workspace storage.',
      );
    }
    return ToolImageRef(
      ref: blob.ref,
      mediaType: mediaType,
      bytes: bytes.length,
      width: info.width,
      height: info.height,
    );
  }

  static double? _number(Object? value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number != null && number.isFinite ? number : null;
  }

  static String _scaleFilter(int maxDimension) =>
      'scale=w=min(iw\\,$maxDimension):h=min(ih\\,$maxDimension):'
      'force_original_aspect_ratio=decrease:reset_sar=1';
}

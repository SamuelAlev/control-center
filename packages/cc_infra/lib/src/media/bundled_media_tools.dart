import 'dart:io';

import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:path/path.dart' as p;

/// The private media executables shipped with the server, never searched on PATH.
class BundledMediaTools {
  /// Uses explicit absolute paths, including for isolated runtime checks.
  const BundledMediaTools({
    required this.ffmpeg,
    required this.ffprobe,
    required this.pdfRenderer,
    required this.svgRenderer,
  });

  /// Bundled video decoder and image encoder.
  final String ffmpeg;

  /// Bundled video metadata reader.
  final String ffprobe;

  /// Bundled PDFium page renderer.
  final String pdfRenderer;

  /// Bundled SVG rasterizer with external resources disabled.
  final String svgRenderer;

  /// Resolves a complete managed bundle or fails without a system-tool fallback.
  static BundledMediaTools locate({
    required String appSupportRoot,
    String? directory,
  }) {
    final explicit = directory ?? Platform.environment['CC_MEDIA_TOOLS_DIR'];
    final executableDirectory = File(Platform.resolvedExecutable).parent.path;
    final nativeDirectory = Platform.environment['CC_NATIVE_LIB_DIR'];
    final candidates = explicit != null && explicit.isNotEmpty
        ? [explicit]
        : [
            p.join(executableDirectory, 'media'),
            if (nativeDirectory != null && nativeDirectory.isNotEmpty)
              p.join(nativeDirectory, 'media'),
            p.join(appSupportRoot, 'media'),
          ];
    for (final candidate in candidates) {
      if (!p.isAbsolute(candidate)) {
        throw const MediaRenderException(
          'The managed media directory must be an absolute path.',
        );
      }
      final root = Directory(candidate);
      if (!root.existsSync()) {
        continue;
      }
      final suffix = Platform.isWindows ? '.exe' : '';
      String executable(String name) {
        final file = File(p.join(root.path, '$name$suffix'));
        if (!file.existsSync() ||
            file.statSync().type != FileSystemEntityType.file) {
          throw MediaRenderException(
            'Control Center\'s media bundle is incomplete: ${file.path}. Reinstall the application or server bundle.',
          );
        }
        return file.resolveSymbolicLinksSync();
      }

      return BundledMediaTools(
        ffmpeg: executable('ffmpeg'),
        ffprobe: executable('ffprobe'),
        pdfRenderer: executable('cc_pdf_render'),
        svgRenderer: executable('cc_svg_render'),
      );
    }
    throw MediaRenderException(
      'Control Center\'s bundled media tools are missing. Reinstall the application or server bundle. Searched: ${candidates.join(', ')}.',
    );
  }
}

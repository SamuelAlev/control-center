import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One indexable chunk of code: a contiguous line range of a file.
class CodeChunk {
  /// Creates a [CodeChunk].
  CodeChunk({
    required this.filePath,
    required this.startLine,
    required this.endLine,
    required this.content,
    required this.fileHash,
  }) : segmentHash = _segmentHash(filePath, startLine, endLine, content);

  /// Repo-relative file path.
  final String filePath;

  /// 1-based first line (inclusive).
  final int startLine;

  /// 1-based last line (inclusive).
  final int endLine;

  /// The chunk's source text.
  final String content;

  /// Hash of the whole file the chunk came from (used by the overlay to detect
  /// divergence from the shared baseline).
  final String fileHash;

  /// Stable identity of this chunk — `filePath-startLine-endLine-len-preview`
  /// hashed. Lets re-indexing skip unchanged chunks.
  final String segmentHash;

  static String _segmentHash(
    String filePath,
    int startLine,
    int endLine,
    String content,
  ) {
    final preview = content.length <= 100 ? content : content.substring(0, 100);
    final material = '$filePath-$startLine-$endLine-${content.length}-$preview';
    return sha256.convert(utf8.encode(material)).toString();
  }
}

/// Splits source files into [CodeChunk]s for embedding.
///
/// Tree-sitter-aware chunkers (CC ships tree-sitter grammars in `cc_natives`)
/// can implement this; the bundled [LineCodeChunker] is a pure-Dart line-based
/// fallback with the same size discipline the upstream `kilo-indexing` uses
/// (`MIN_BLOCK_CHARS = 50`, `MAX_BLOCK_CHARS = 1000`, merge a trailing remainder
/// smaller than `MIN_CHUNK_REMAINDER_CHARS = 200`).
abstract interface class CodeChunker {
  /// Chunks [content] of the file at [filePath].
  List<CodeChunk> chunk(String filePath, String content);
}

/// Line-based chunker used when no language grammar is available.
class LineCodeChunker implements CodeChunker {
  /// Creates a [LineCodeChunker].
  const LineCodeChunker();

  /// Minimum chunk size in characters; smaller leaf blocks are merged forward.
  static const int minBlockChars = 50;

  /// Maximum chunk size in characters before a split.
  static const int maxBlockChars = 1000;

  /// A trailing remainder smaller than this is merged into the previous chunk.
  static const int minChunkRemainderChars = 200;

  @override
  List<CodeChunk> chunk(String filePath, String content) {
    if (content.trim().isEmpty) {
      return const [];
    }
    final fileHash = sha256.convert(utf8.encode(content)).toString();
    final lines = const LineSplitter().convert(content);
    final chunks = <CodeChunk>[];

    final buffer = StringBuffer();
    var bufferStart = 1;

    void flush(int endLine) {
      final text = buffer.toString();
      if (text.trim().isEmpty) {
        return;
      }
      // Merge a too-small trailing chunk into the previous one.
      if (text.length < minChunkRemainderChars && chunks.isNotEmpty) {
        final prev = chunks.removeLast();
        chunks.add(
          CodeChunk(
            filePath: filePath,
            startLine: prev.startLine,
            endLine: endLine,
            content: '${prev.content}\n$text',
            fileHash: fileHash,
          ),
        );
      } else {
        chunks.add(
          CodeChunk(
            filePath: filePath,
            startLine: bufferStart,
            endLine: endLine,
            content: text,
            fileHash: fileHash,
          ),
        );
      }
      buffer.clear();
    }

    for (var i = 0; i < lines.length; i++) {
      final lineNumber = i + 1;
      if (buffer.isEmpty) {
        bufferStart = lineNumber;
      }
      if (buffer.isNotEmpty) {
        buffer.write('\n');
      }
      buffer.write(lines[i]);
      if (buffer.length >= maxBlockChars) {
        flush(lineNumber);
      }
    }
    // Final remainder.
    if (buffer.toString().trim().isNotEmpty) {
      flush(lines.length);
    }
    // Guard: drop chunks below the minimum unless they're the only chunk.
    if (chunks.length > 1) {
      chunks.removeWhere((c) => c.content.trim().length < minBlockChars);
    }
    return chunks;
  }
}

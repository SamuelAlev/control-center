import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// Streams the `.tar.bz2` at [archivePath] into [destinationPath].
///
/// The compressed file is decoded as it is read ([BZip2Decoder.decodeLazy]
/// over an [InputFileStream]) and the tar decoder hands each entry to a
/// callback with `keepEntries: false`, so neither the compressed archive nor
/// the decoded tar is ever held in memory and the entries are not retained
/// either. Each entry's content is written straight to disk as it is reached
/// and dropped again, so memory is bounded by codec and file buffers rather
/// than the unpacked tree. The old whole-buffer path retained the compressed
/// file, decoded tar and archive entries together.
///
/// Entries retain their tar names under [destinationPath]; directories are
/// created as needed. The caller extracts into a staging directory and owns
/// the atomic rename into the final location.
///
/// [onProgress] receives the fraction of the compressed input consumed so
/// far, in `[0..1]`. Only the container is measurable — the bzip2 decode of a
/// single block is opaque — so it advances per entry, then reaches 1 at EOF.
void extractTarBz2Streamed(
  String archivePath,
  String destinationPath, {
  void Function(double progress)? onProgress,
}) {
  final input = _Bzip2InputFileStream(archivePath);
  final decoded = BZip2Decoder().decodeLazy(input);
  try {
    // `length` is the bytes still unread, so this is the compressed size.
    final total = input.length;
    TarDecoder().decodeStream(
      decoded,
      keepEntries: false,
      callback: (entry) {
        _writeEntry(destinationPath, entry);
        final remaining = input.length;
        if (onProgress != null && total > 0 && remaining > 0) {
          onProgress(((total - remaining) / total).clamp(0.0, 1.0));
        }
      },
    );
    // TAR ends before the compression trailer. Consume the remaining stream
    // without materializing it, so truncated trailers still fail and progress
    // reaches completion only after the whole container was read.
    while (!decoded.isEOS) {
      decoded.skip(1024 * 1024);
    }
    onProgress?.call(1.0);
  } finally {
    decoded.closeSync();
    input.closeSync();
  }
}

// InputFileStream zero-fills byte reads past EOF, unlike InputMemoryStream.
// BZip2 must fail on a missing trailer byte rather than silently read a zero.
class _Bzip2InputFileStream extends InputFileStream {
  _Bzip2InputFileStream(String path) : super.withFileHandle(FileHandle(path));

  @override
  int readByte() {
    if (isEOS) {
      throw ArchiveException('Truncated bzip2 stream');
    }
    return super.readByte();
  }
}

/// Writes one tar [entry] under [destinationPath], streaming its content.
void _writeEntry(String destinationPath, ArchiveFile entry) {
  final outPath = p.join(destinationPath, entry.name);
  if (!entry.isFile) {
    Directory(outPath).createSync(recursive: true);
    return;
  }
  final out = File(outPath);
  out.parent.createSync(recursive: true);
  final output = OutputFileStream(out.path);
  try {
    entry.writeContent(output);
  } catch (_) {
    // A partial file would pass for the whole of it.
    output.closeSync();
    if (out.existsSync()) {
      out.deleteSync();
    }
    rethrow;
  }
  output.closeSync();
}

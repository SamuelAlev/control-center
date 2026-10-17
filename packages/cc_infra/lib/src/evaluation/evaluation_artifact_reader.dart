import 'dart:io';

/// Reads only regular, bounded evaluation artifacts. The stream limit is
/// enforced even if a file grows after the size preflight.
Future<List<int>> readEvaluationArtifact(File file, int maxBytes) async {
  if (maxBytes < 0 ||
      FileSystemEntity.typeSync(file.path, followLinks: false) !=
          FileSystemEntityType.file) {
    throw StateError('evaluation artifact is not a regular file');
  }
  if (await file.length() > maxBytes) {
    throw StateError('evaluation artifact exceeds size limit');
  }
  final bytes = <int>[];
  await for (final chunk in file.openRead()) {
    if (chunk.length > maxBytes - bytes.length) {
      throw StateError('evaluation artifact exceeds size limit');
    }
    bytes.addAll(chunk);
  }
  return bytes;
}

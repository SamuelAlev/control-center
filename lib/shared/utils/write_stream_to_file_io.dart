import 'dart:io';

/// Pipes [stream] into the file at [path], creating or truncating it.
///
/// Streamed rather than collected: the callers are backup downloads, where the
/// body is an entire workspace database or a whole-install archive. Buffering
/// one to write it out again would put it in the client's heap first, which on
/// a phone is the difference between a download and a crash.
Future<void> writeStreamToFileImpl(Stream<List<int>> stream, String path) async {
  final sink = File(path).openWrite();
  try {
    await sink.addStream(stream);
    await sink.flush();
  } finally {
    await sink.close();
  }
}

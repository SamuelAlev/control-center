import 'package:control_center/shared/utils/write_stream_to_file_io.dart'
    if (dart.library.js_interop) 'package:control_center/shared/utils/write_stream_to_file_web.dart';

/// Writes [stream] to the file at [path].
///
/// Routes through a conditional-import seam for the same reason `open_url` does:
/// the implementation needs `dart:io`, and the web build must not pull it in.
Future<void> writeStreamToFile(Stream<List<int>> stream, String path) =>
    writeStreamToFileImpl(stream, path);

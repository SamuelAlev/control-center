/// Platform seam for writing an exported meeting file to disk.
///
/// The desktop "export → Save as" path writes the markdown to the chosen file
/// (`dart:io`); on web there is no local filesystem, so the screen's Save-as
/// dialog never yields a path (it falls back to the clipboard) — but the call
/// site still has to COMPILE, so the web variant throws [UnsupportedError]
/// instead of pulling `dart:io` into the web graph.
library;

export 'meeting_file_export_io.dart'
    if (dart.library.js_interop) 'meeting_file_export_web.dart';

/// Writes an exported file on web — unreachable.
///
/// On web the Save-as dialog never returns a local path (there is no local
/// filesystem), so the meeting-export call site falls back to the clipboard and
/// never reaches this. It exists only so the shared screen compiles without
/// pulling `dart:io` into the web graph; if ever called it fails loudly.
Future<void> writeStringToFile(String path, String contents) =>
    throw UnsupportedError('Writing files to disk is not available on web.');

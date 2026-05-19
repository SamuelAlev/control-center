import 'dart:io';

/// Writes [contents] to the file at [path] (desktop "export → Save as").
Future<void> writeStringToFile(String path, String contents) =>
    File(path).writeAsString(contents);

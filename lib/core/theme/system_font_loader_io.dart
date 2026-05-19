import 'dart:io';

import 'package:flutter/services.dart';

/// Desktop: whether a user-selected system-font file still exists on disk.
bool systemFontFileExists(String filePath) => File(filePath).existsSync();

/// Desktop: reads a system-font file from disk and registers it with Flutter's
/// [FontLoader]. Returns true on success, false if the file is missing.
Future<bool> loadSystemFontFromFile(String family, String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    return false;
  }
  final bytes = await file.readAsBytes();
  final fontLoader = FontLoader(family);
  fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
  await fontLoader.load();
  return true;
}

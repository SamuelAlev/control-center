import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Writes the export into the user's Documents directory.
///
/// Documents rather than a temp dir or the app-support dir: an export exists to
/// be opened, mailed or attached, and a file under `Application Support` is one
/// nobody finds again.
Future<String> writeConversationExport({
  required String conversationId,
  required String html,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory(p.join(dir.path, 'ControlCenter', 'exports'));
  await folder.create(recursive: true);
  // Timestamped, so exporting the same conversation twice keeps both — the
  // second export is usually the interesting one and overwriting the first
  // silently loses the comparison.
  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final file = File(p.join(folder.path, '$conversationId-$stamp.html'));
  await file.writeAsString(html);
  return file.path;
}

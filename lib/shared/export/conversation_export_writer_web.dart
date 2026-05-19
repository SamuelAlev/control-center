import 'dart:convert';

import 'package:web/web.dart' as web;

/// Triggers a browser download.
///
/// There is no filesystem to write to on web, so the honest equivalent of
/// "saved to a path" is handing the browser the bytes and letting the person
/// choose. The returned string names the file rather than a path, because a
/// path would be a fiction.
Future<String> writeConversationExport({
  required String conversationId,
  required String html,
}) async {
  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final name = '$conversationId-$stamp.html';
  // A data: URL rather than a Blob URL: a Blob needs revoking to avoid holding
  // the whole transcript in memory for the tab's lifetime, and the anchor is
  // gone before we could.
  final href =
      'data:text/html;charset=utf-8;base64,${base64Encode(utf8.encode(html))}';
  final anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = href
        ..download = name;
  anchor.click();
  return name;
}

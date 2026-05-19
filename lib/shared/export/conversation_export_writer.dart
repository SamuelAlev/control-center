import 'package:control_center/shared/export/conversation_export_writer_io.dart'
    if (dart.library.js_interop) 'package:control_center/shared/export/conversation_export_writer_web.dart'
    as impl;

/// Writes an exported conversation and returns where it went.
///
/// **Split by platform because "where a file goes" has no shared answer.** On
/// desktop it is a path the person can open; on web there is no filesystem at
/// all and the only equivalent is a download. Pretending otherwise would mean
/// one of the two silently doing nothing.
Future<String> writeConversationExport({
  required String conversationId,
  required String html,
}) => impl.writeConversationExport(
  conversationId: conversationId,
  html: html,
);

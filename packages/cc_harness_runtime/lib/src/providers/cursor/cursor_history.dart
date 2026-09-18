import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_harness/messages.dart';
import 'package:crypto/crypto.dart';

/// Packed prior-turn blobs for Cursor's `rootPromptMessagesJson`.
class CursorPackedHistory {
  /// Creates a packed history.
  const CursorPackedHistory({
    required this.blobIds,
    required this.store,
    this.liveUserText,
  });

  /// SHA-256 blob ids, in prompt order (system first).
  final List<Uint8List> blobIds;

  /// Hex(id) → UTF-8 JSON bytes. Served on KV getBlob.
  final Map<String, Uint8List> store;

  /// Current user turn, sent as `userMessageAction`. Null on a resume
  /// (tool-result follow-up), where the full history stays in blobs.
  final String? liveUserText;
}

final _toolCallIdSafe = RegExp(r'[^a-zA-Z0-9_-]');

/// Cursor rejects tool-call ids outside `^[a-zA-Z0-9_-]+$` as
/// `resource_exhausted`.
String normalizeCursorToolCallId(String id) {
  final trimmed = id.trim();
  if (trimmed.isEmpty) {
    return 'tool';
  }
  return trimmed.replaceAll(_toolCallIdSafe, '_');
}

/// Hex-encodes a SHA-256 blob id for the KV store key.
String blobIdHex(List<int> blobId) {
  final out = StringBuffer();
  for (final b in blobId) {
    out.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return out.toString();
}

/// Encodes [messages] plus optional [systemPrompt] as SHA-256 blobs.
///
/// A trailing user turn is omitted from the blobs and returned as
/// [CursorPackedHistory.liveUserText] — Cursor wants it on the action, not
/// in history. A trailing tool-result turn is a resume: everything stays in
/// the blobs.
CursorPackedHistory packCursorHistory(
  List<HarnessMessage> messages, {
  String? systemPrompt,
}) {
  final store = <String, Uint8List>{};
  final ids = <Uint8List>[];

  void pushJson(Object value) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(value)));
    final digest = Uint8List.fromList(sha256.convert(bytes).bytes);
    store[blobIdHex(digest)] = bytes;
    ids.add(digest);
  }

  final system = systemPrompt?.trim() ?? '';
  if (system.isNotEmpty) {
    pushJson({'role': 'system', 'content': system});
  } else {
    pushJson({
      'role': 'system',
      'content': 'You are a helpful assistant.',
    });
  }

  final last = messages.isEmpty ? null : messages.last;
  final sendingUser =
      last != null &&
      last.role == HarnessRole.user &&
      last.textContent.trim().isNotEmpty;
  final historyEnd = sendingUser ? messages.length - 1 : messages.length;

  for (var i = 0; i < historyEnd; i++) {
    final message = messages[i];
    switch (message.role) {
      case HarnessRole.system:
        final text = message.textContent.trim();
        if (text.isNotEmpty) {
          pushJson({'role': 'system', 'content': text});
        }
      case HarnessRole.user:
        final content = _userContent(message);
        if (content.isNotEmpty) {
          pushJson({'role': 'user', 'content': content});
        }
      case HarnessRole.assistant:
        final content = _assistantContent(message);
        if (content.isNotEmpty) {
          pushJson({'role': 'assistant', 'content': content});
        }
      case HarnessRole.tool:
        for (final block in message.content.whereType<HarnessToolResultBlock>()) {
          final toolCallId = normalizeCursorToolCallId(block.toolUseId);
          pushJson({
            'role': 'tool',
            'id': toolCallId,
            'content': [
              {
                'type': 'tool-result',
                'toolName': '',
                'toolCallId': toolCallId,
                'result': block.content,
                if (block.isError) 'isError': true,
              },
            ],
          });
        }
    }
  }

  return CursorPackedHistory(
    blobIds: ids,
    store: store,
    liveUserText: sendingUser ? messages.last.textContent.trim() : null,
  );
}

List<Map<String, Object?>> _userContent(HarnessMessage message) {
  final parts = <Map<String, Object?>>[];
  for (final block in message.content) {
    switch (block) {
      case HarnessTextBlock(:final text):
        final trimmed = text.trim();
        if (trimmed.isNotEmpty) {
          parts.add({'type': 'text', 'text': trimmed});
        }
      case HarnessImageBlock(:final data, :final mediaType):
        parts.add({
          'type': 'image',
          'image': 'data:$mediaType;base64,$data',
          'mediaType': mediaType,
        });
      case _:
        break;
    }
  }
  return parts;
}

List<Map<String, Object?>> _assistantContent(HarnessMessage message) {
  final parts = <Map<String, Object?>>[];
  for (final block in message.content) {
    switch (block) {
      case HarnessTextBlock(:final text):
        if (text.isNotEmpty) {
          parts.add({'type': 'text', 'text': text});
        }
      case HarnessThinkingBlock(:final thinking):
        if (thinking.isNotEmpty) {
          parts.add({'type': 'reasoning', 'text': thinking});
        }
      case HarnessToolUseBlock(:final id, :final name, :final input):
        parts.add({
          'type': 'tool-call',
          'toolCallId': normalizeCursorToolCallId(id),
          'toolName': name,
          'args': input,
        });
      case _:
        break;
    }
  }
  return parts;
}

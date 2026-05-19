
import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/ports/embedding_port.dart';
import 'package:control_center/core/domain/services/cosine_similarity.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter/foundation.dart';

/// Builds conversation context for an agent dispatch by gathering recent
/// messages, summaries, and semantically-relevant history from a channel.
class BuildConversationContextUseCase {
  /// Creates a [BuildConversationContextUseCase].
  BuildConversationContextUseCase({
    required MessagingRepository messagingRepository,
    EmbeddingPort? embeddingPort,
  })  : _messagingRepository = messagingRepository,
        _embeddingPort = embeddingPort;

  final MessagingRepository _messagingRepository;
  final EmbeddingPort? _embeddingPort;

  void _log(String message) {
    if (kDebugMode) {
      AppLog.d('BuildConversationContextUseCase', message);
    }
  }

  /// Executes the use case, returning a formatted conversation context string.
  Future<String> execute({
    required String channelId,
    required String selfAgentId,
    required String selfAgentName,
    required String taskDescription,
    required int characterBudget,
  }) async {
    final allMessages = await _messagingRepository.getMessages(channelId);
    if (allMessages.isEmpty) {
      return '';
    }

    final summaries = <ChannelMessage>[];
    final verbatimCandidates = <ChannelMessage>[];

    for (final m in allMessages) {
      if (m.isThinking) {
        continue;
      }

      if (m.isSystem && m.metadata?['compacted'] == true) {
        summaries.add(m);
        continue;
      }

      if (m.isSystem || m.isTicket || m.isReviewNode) {
        continue;
      }
      if (m.compacted) {
        continue;
      }

      verbatimCandidates.add(m);
    }

    final verbatimWindow = <ChannelMessage>[];
    var usedBudget = 0;
    for (final m in verbatimCandidates.reversed) {
      if (usedBudget + m.content.length > characterBudget) {
        break;
      }
      usedBudget += m.content.length;
      verbatimWindow.insert(0, m);
    }

    final verbatimIds = verbatimWindow.map((m) => m.id).toSet();
    final summaryIds = summaries.map((m) => m.id).toSet();

    List<ChannelMessage> semanticHits = const [];
    if (_embeddingPort != null &&
        _embeddingPort.isReady &&
        taskDescription.isNotEmpty) {
      try {
        final queryVec = await _embeddingPort.embed(taskDescription);
        final embeddedRows =
            await _messagingRepository.getMessagesWithEmbedding(channelId);

        final archive = embeddedRows
            .where(
              (r) =>
                  !verbatimIds.contains(r.message.id) &&
                  !summaryIds.contains(r.message.id) &&
                  !r.message.isThinking &&
                  !r.message.compacted,
            )
            .toList();

        final scored = <({ChannelMessage msg, double score})>[];
        for (final r in archive) {
          final vec = Float32List.view(r.embedding.buffer);
          final score = cosineSimilarity(queryVec, vec);
          scored.add((msg: r.message, score: score));
        }
        scored.sort((a, b) => b.score.compareTo(a.score));
        semanticHits = scored.take(5).map((s) => s.msg).toList();

        _log('semantic hits: ${semanticHits.length} from ${archive.length} archive entries');
      } catch (e) {
        _log('semantic retrieval failed: $e');
      }
    }

    return buildConversationContextPure(
      channelId: channelId,
      selfAgentId: selfAgentId,
      selfAgentName: selfAgentName,
      messages: allMessages,
      verbatimWindow: verbatimWindow,
      summaries: summaries,
      semanticHits: semanticHits,
    );
  }
}

/// Pure-function version of conversation context building for testability.
String buildConversationContextPure({
  required String channelId,
  required String selfAgentId,
  required String selfAgentName,
  required List<ChannelMessage> messages,
  required List<ChannelMessage> verbatimWindow,
  required List<ChannelMessage> summaries,
  required List<ChannelMessage> semanticHits,
}) {
  final blocks = <String>[];

  if (summaries.isNotEmpty) {
    final buf = StringBuffer('### Earlier (summary)\n');
    for (final m in summaries) {
      buf.writeln(m.content.trimRight());
    }
    blocks.add(buf.toString().trimRight());
  }

  if (semanticHits.isNotEmpty) {
    final buf = StringBuffer('### Possibly relevant earlier messages\n');
    for (final m in semanticHits) {
      buf.writeln(
        '- [${_senderLabel(m, selfAgentId, selfAgentName)} · ${_fmtTime(m.createdAt)}] ${m.content.trimRight()}',
      );
    }
    blocks.add(buf.toString().trimRight());
  }

  if (verbatimWindow.isNotEmpty) {
    final buf = StringBuffer('### Recent messages\n');
    for (final m in verbatimWindow) {
      buf.writeln(
        '- [${_senderLabel(m, selfAgentId, selfAgentName)} · ${_fmtTime(m.createdAt)}] ${m.content.trimRight()}',
      );
    }
    blocks.add(buf.toString().trimRight());
  }

  if (blocks.isEmpty) {
    return '';
  }
  return '## Conversation History\n\n${blocks.join('\n\n')}';
}

String _senderLabel(ChannelMessage m, String selfAgentId, String selfAgentName) {
  if (m.senderId == selfAgentId) {
    return 'you';
  }
  if (m.isUser) {
    return 'user';
  }
  return selfAgentName;
}

String _fmtTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

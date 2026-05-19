import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/services/cosine_similarity.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Builds conversation context for an agent dispatch by gathering recent
/// messages, summaries, and semantically-relevant history from a channel.
class BuildConversationContextUseCase {
  /// Creates a [BuildConversationContextUseCase].
  BuildConversationContextUseCase({
    required MessagingRepository messagingRepository,
    EmbeddingPort? embeddingPort,
  }) : _messagingRepository = messagingRepository,
       _embeddingPort = embeddingPort;

  final MessagingRepository _messagingRepository;
  final EmbeddingPort? _embeddingPort;

  void _log(String message) =>
      CcDomainLog.info('BuildConversationContextUseCase: $message');

  /// Executes the use case, returning a formatted conversation context string.
  ///
  /// [workspaceId] is the workspace owning [channelId]; it scopes every read, so
  /// a channel id from another workspace yields no history rather than leaking.
  /// [conversationId] scopes the history to a single conversation (stream) —
  /// an agent run in a parenthesis only ever sees that parenthesis's history.
  /// Defaults to the channel's `main` conversation.
  Future<String> execute({
    required String workspaceId,
    required String channelId,
    required String selfAgentId,
    required String selfAgentName,
    required String taskDescription,
    required int characterBudget,
    String? conversationId,
  }) async {
    final allMessages = await _messagingRepository.getMessages(
      workspaceId,
      channelId,
      conversationId: conversationId,
    );
    if (allMessages.isEmpty) {
      return '';
    }

    final summaries = <ChannelMessage>[];
    final verbatimCandidates = <ChannelMessage>[];

    for (final m in allMessages) {
      // First-class compaction summaries (and legacy compacted system
      // summaries) stand in for the older history they replaced.
      if (m.isContextSummary) {
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
        final embeddedRows = await _messagingRepository
            .getMessagesWithEmbedding(workspaceId, channelId);

        final archive = embeddedRows
            .where(
              (r) =>
                  !verbatimIds.contains(r.message.id) &&
                  !summaryIds.contains(r.message.id) &&
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

        _log(
          'semantic hits: ${semanticHits.length} from ${archive.length} archive entries',
        );
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
      lastRunDigest: buildLastRunDigest(allMessages),
    );
  }
}

/// A compact digest of the LAST agent turn's persisted trace (PRD 16 §10):
/// what it did (tools), how it ended (outcome), and what it cost — so the
/// next run (any agent, any human's dispatch) bootstraps from the prior
/// run's trace instead of only its prose. Returns '' when the channel has no
/// agent turn yet. Budget-capped: this is a digest, not the transcript.
String buildLastRunDigest(List<ChannelMessage> messages) {
  ChannelMessage? last;
  for (final m in messages.reversed) {
    if (m.messageType == ChannelMessageType.agentTurn && !m.compacted) {
      last = m;
      break;
    }
  }
  if (last == null) {
    return '';
  }
  final meta = last.metadata ?? const <String, dynamic>{};
  final agentName = meta['agentName'] as String? ?? last.senderId;
  final outcome = meta['outcome'] as String? ?? 'completed';
  final tools = <String, int>{};
  try {
    for (final segment in last.transcript) {
      if (segment is ToolSegment) {
        tools.update(segment.toolName, (n) => n + 1, ifAbsent: () => 1);
      }
    }
  } catch (_) {
    // A trace that fails to decode still yields the outcome line.
  }
  final buf = StringBuffer()
    ..write('Agent $agentName\'s last run ended: $outcome.');
  if (tools.isNotEmpty) {
    final parts = tools.entries
        .map((e) => e.value > 1 ? '${e.key}×${e.value}' : e.key)
        .take(12)
        .join(', ');
    buf.write(' Tools used: $parts.');
  }
  final turn = meta['turn'];
  if (turn is Map && turn['costCents'] is num) {
    buf.write(
      ' Cost: \$${((turn['costCents'] as num) / 100).toStringAsFixed(2)}.',
    );
  }
  final digest = buf.toString();
  return digest.length > 700 ? digest.substring(0, 700) : digest;
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
  String lastRunDigest = '',
}) {
  final blocks = <String>[];

  if (lastRunDigest.isNotEmpty) {
    blocks.add('### Previous run\n$lastRunDigest');
  }

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

String _senderLabel(
  ChannelMessage m,
  String selfAgentId,
  String selfAgentName,
) {
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

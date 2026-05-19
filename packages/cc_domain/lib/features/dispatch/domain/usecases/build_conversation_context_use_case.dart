import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/services/cosine_similarity.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Builds conversation context for an agent dispatch by gathering recent
/// messages, summaries and semantically-relevant history from a space.
class BuildConversationContextUseCase {
  /// Creates a [BuildConversationContextUseCase].
  BuildConversationContextUseCase({
    required MessagingRepository messagingRepository,
    ConversationRepository? conversationRepository,
    EmbeddingPort? embeddingPort,
  }) : _messagingRepository = messagingRepository,
       _conversationRepository = conversationRepository,
       _embeddingPort = embeddingPort;

  final MessagingRepository _messagingRepository;
  final ConversationRepository? _conversationRepository;
  final EmbeddingPort? _embeddingPort;

  void _log(String message) =>
      CcDomainLog.info('BuildConversationContextUseCase: $message');

  /// Executes the use case, returning a formatted conversation context string.
  ///
  /// [workspaceId] is the workspace owning [spaceId]; it scopes every read, so
  /// a space id from another workspace yields no history rather than leaking.
  /// [conversationId] scopes the history to a single conversation (stream) —
  /// an agent run in a thread or side conversation only ever sees that
  /// stream's history. When the conversation is a THREAD (anchored to a
  /// message of a sibling conversation) and the anchor is not already in the
  /// fetched rows, one seed line is prepended; the parent stream's history is
  /// never copied.
  Future<String> execute({
    required String workspaceId,
    required String spaceId,
    required String selfAgentId,
    required String selfAgentName,
    required String taskDescription,
    required int characterBudget,
    String? conversationId,
  }) async {
    final allMessages = await _messagingRepository.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversationId,
    );

    // Thread seed: the anchor message is the thread's whole parent context.
    String threadSeed = '';
    final conversations = _conversationRepository;
    if (conversationId != null && conversations != null) {
      final conv = await conversations.getById(
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
      final anchorId = conv?.anchorMessageId;
      if (anchorId != null && !allMessages.any((m) => m.id == anchorId)) {
        final anchor = await _messagingRepository.getMessageById(
          workspaceId,
          anchorId,
        );
        if (anchor != null) {
          final parent = await conversations.getById(
            workspaceId: workspaceId,
            conversationId: anchor.conversationId,
          );
          threadSeed =
              'Replying to ${_anchorSenderLabel(anchor, selfAgentId, selfAgentName)} in '
              '"${parent?.title ?? 'conversation'}": ${anchor.content}';
        }
      }
    }

    if (allMessages.isEmpty) {
      return threadSeed;
    }

    final summaries = <Message>[];
    final verbatimCandidates = <Message>[];

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
      // A QUEUED steering row has not reached any agent yet — it renders in
      // the steering queue strip and is delivered by injection (or converted
      // to a real message at run end). Letting it into a new run's prompt
      // here would both leak it ahead of its turn and, for a harness run,
      // double it: the harness-start flush injects the same row.
      if (m.isSteeringQueued) {
        continue;
      }
      if (m.compacted) {
        continue;
      }

      verbatimCandidates.add(m);
    }

    final verbatimWindow = <Message>[];
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

    List<Message> semanticHits = const [];
    if (_embeddingPort != null &&
        _embeddingPort.isReady &&
        taskDescription.isNotEmpty) {
      try {
        final queryVec = await _embeddingPort.embed(taskDescription);
        final embeddedRows = await _messagingRepository
            .getMessagesWithEmbedding(workspaceId, spaceId);

        final archive = embeddedRows
            .where(
              (r) =>
                  // Embeddings are stored per SPACE, so this read spans every
                  // conversation in it. Narrow to this run's own stream: a
                  // thread that pulled semantic hits out of its parent would
                  // be copying the very history the anchor seed exists to
                  // replace.
                  (conversationId == null ||
                      r.message.conversationId == conversationId) &&
                  !verbatimIds.contains(r.message.id) &&
                  !summaryIds.contains(r.message.id) &&
                  !r.message.compacted,
            )
            .toList();

        final scored = <({Message msg, double score})>[];
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

    final built = buildConversationContextPure(
      spaceId: spaceId,
      selfAgentId: selfAgentId,
      selfAgentName: selfAgentName,
      messages: allMessages,
      verbatimWindow: verbatimWindow,
      summaries: summaries,
      semanticHits: semanticHits,
      lastRunDigest: buildLastRunDigest(allMessages),
    );
    return threadSeed.isEmpty ? built : '$threadSeed\n\n$built';
  }
}

/// A compact digest of the LAST agent turn's persisted trace (PRD 16 §10):
/// what it did (tools), how it ended (outcome) and what it cost — so the
/// next run (any agent, any human's dispatch) bootstraps from the prior
/// run's trace instead of only its prose. Returns '' when the space has no
/// agent turn yet. Budget-capped: this is a digest, not the transcript.
String buildLastRunDigest(List<Message> messages) {
  Message? last;
  for (final m in messages.reversed) {
    if (m.messageType == MessageType.agentTurn && !m.compacted) {
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
  required String spaceId,
  required String selfAgentId,
  required String selfAgentName,
  required List<Message> messages,
  required List<Message> verbatimWindow,
  required List<Message> summaries,
  required List<Message> semanticHits,
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

/// The name to put in a thread's anchor seed line.
///
/// Falls back through the same sources the transcript renderer uses — the
/// running agent's own name, "the user", the turn's recorded `agentName` —
/// before it will show a raw id, because "Replying to
/// 3f9c1a20-…" tells the model nothing about who it is answering.
String _anchorSenderLabel(Message m, String selfAgentId, String selfAgentName) {
  if (m.senderId == selfAgentId) {
    return selfAgentName;
  }
  if (m.isUser) {
    return 'the user';
  }
  final name = (m.metadata ?? const <String, dynamic>{})['agentName'];
  return (name is String && name.isNotEmpty) ? name : m.senderId;
}

String _senderLabel(Message m, String selfAgentId, String selfAgentName) {
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

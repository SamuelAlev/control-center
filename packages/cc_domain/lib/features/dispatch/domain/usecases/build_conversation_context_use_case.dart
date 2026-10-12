import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/services/cosine_similarity.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart'
    show PromptBuilder, PromptConversationEntry, PromptConversationProvenance;
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_context_history.dart';

/// Builds conversation context for an agent dispatch by gathering recent
/// messages, summaries and semantically-relevant history from a space.
class BuildConversationContextUseCase {
  /// Creates a [BuildConversationContextUseCase].
  BuildConversationContextUseCase({
    required this._messagingRepository,
    this._conversationRepository,
    this._embeddingPort,
    this._contextHistory,
  });

  final MessagingRepository _messagingRepository;
  final ConversationRepository? _conversationRepository;
  final EmbeddingPort? _embeddingPort;

  /// Paged history for [execute]. Null keeps the full-conversation scan,
  /// which tests and hosts without the fast query use.
  final Future<ConversationContextHistory> Function({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required int characterBudget,
  })?
  _contextHistory;

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
  }) async => (await executeStructured(
    workspaceId: workspaceId,
    spaceId: spaceId,
    selfAgentId: selfAgentId,
    selfAgentName: selfAgentName,
    taskDescription: taskDescription,
    characterBudget: characterBudget,
    conversationId: conversationId,
  )).text;

  /// [execute], returning the structured entries as well as the rendered text.
  ///
  /// The entries carry stable keys and provenance so a native-resumed turn can
  /// be told only what is genuinely new or edited.
  Future<ConversationContextParts> executeStructured({
    required String workspaceId,
    required String spaceId,
    required String selfAgentId,
    required String selfAgentName,
    required String taskDescription,
    required int characterBudget,
    String? conversationId,
  }) async {
    final loadHistory = _contextHistory;
    final history = loadHistory == null
        ? null
        : await loadHistory(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
            characterBudget: characterBudget,
          );
    final allMessages =
        history?.messages ??
        await _messagingRepository.getMessages(
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

    // Summaries from the paged loader are already complete, including ones
    // older than the tail. The full scan collects them while it walks.
    final summaries = <Message>[...?history?.summaries];
    if (allMessages.isEmpty && summaries.isEmpty) {
      if (threadSeed.isEmpty) {
        return ConversationContextParts.empty;
      }
      return ConversationContextParts(
        text: threadSeed,
        entries: [
          PromptConversationEntry(
            key: 'thread:${PromptBuilder.promptRevisionOf(threadSeed)}',
            text: threadSeed,
            provenance: PromptConversationProvenance.system,
          ),
        ],
      );
    }

    final verbatimCandidates = <Message>[];

    for (final m in allMessages) {
      if (history == null && m.isContextSummary) {
        summaries.add(m);
        continue;
      }
      // See [messageCountsTowardContextBudget]: summaries, system, ticket,
      // review, queued steering, and compacted rows stay out of the window.
      if (messageCountsTowardContextBudget(m)) {
        verbatimCandidates.add(m);
      }
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

    final built = buildConversationContextParts(
      spaceId: spaceId,
      selfAgentId: selfAgentId,
      selfAgentName: selfAgentName,
      messages: allMessages,
      verbatimWindow: verbatimWindow,
      summaries: summaries,
      semanticHits: semanticHits,
      lastRunDigest: buildLastRunDigest(switch (history) {
        null => allMessages,
        ConversationContextHistory(:final lastAgentTurn?) => [lastAgentTurn],
        _ => const <Message>[],
      }),
    );
    if (threadSeed.isEmpty) {
      return built;
    }
    // The thread seed is harness framing, not a participant message.
    return ConversationContextParts(
      text: '$threadSeed\n\n${built.text}',
      entries: [
        PromptConversationEntry(
          key: 'thread:${PromptBuilder.promptRevisionOf(threadSeed)}',
          text: threadSeed,
          provenance: PromptConversationProvenance.system,
        ),
        ...built.entries,
      ],
    );
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

/// The assembled conversation context: its rendered window plus the structured
/// entries it was rendered from.
///
/// The entries are what a native resume needs — stable revision-bearing keys and
/// provenance — so a resuming agent can be told only what is genuinely new or
/// edited instead of the whole window.
class ConversationContextParts {
  /// Creates a [ConversationContextParts].
  const ConversationContextParts({required this.text, required this.entries});

  /// The rendered window, exactly what [buildConversationContextPure] returns.
  final String text;

  /// The entries [text] was rendered from, in order.
  final List<PromptConversationEntry> entries;

  /// Empty parts.
  static const empty = ConversationContextParts(text: '', entries: []);
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
}) => buildConversationContextParts(
  spaceId: spaceId,
  selfAgentId: selfAgentId,
  selfAgentName: selfAgentName,
  messages: messages,
  verbatimWindow: verbatimWindow,
  summaries: summaries,
  semanticHits: semanticHits,
  lastRunDigest: lastRunDigest,
).text;

/// The structured form of [buildConversationContextPure]: the same rendered
/// text, plus one entry per message/section with a stable key and provenance.
///
/// Keys are `"<kind>:<message id>#<digest of the rendered line>"`: an edit
/// changes the digest (so the entry is re-delivered) while an untouched message
/// keeps its key forever (so it is not).
ConversationContextParts buildConversationContextParts({
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
  final entries = <PromptConversationEntry>[];

  PromptConversationProvenance provenanceOf(Message m) =>
      m.senderId == selfAgentId
      ? PromptConversationProvenance.self
      : PromptConversationProvenance.other;

  // The run that produced a message, from its own metadata: the lineage that
  // proves a session produced it (sender identity alone does not).
  String? runIdOf(Message m) {
    final runId = (m.metadata ?? const <String, dynamic>{})['runId'];
    return runId is String && runId.isNotEmpty ? runId : null;
  }

  if (lastRunDigest.isNotEmpty) {
    blocks.add('### Previous run\n$lastRunDigest');
    entries.add(
      PromptConversationEntry(
        key: 'run:${PromptBuilder.promptRevisionOf(lastRunDigest)}',
        text: '### Previous run\n$lastRunDigest',
        provenance: PromptConversationProvenance.system,
      ),
    );
  }

  if (summaries.isNotEmpty) {
    final buf = StringBuffer('### Earlier (summary)\n');
    for (final m in summaries) {
      final line = m.content.trimRight();
      buf.writeln(line);
      entries.add(
        PromptConversationEntry(
          key: 'summary:${m.id}#${PromptBuilder.promptRevisionOf(line)}',
          text: line,
          provenance: provenanceOf(m),
          runId: runIdOf(m),
        ),
      );
    }
    blocks.add(buf.toString().trimRight());
  }

  if (semanticHits.isNotEmpty) {
    final buf = StringBuffer('### Possibly relevant earlier messages\n');
    for (final m in semanticHits) {
      final line =
          '- [${_senderLabel(m, selfAgentId, selfAgentName)} · ${_fmtTime(m.createdAt)}] ${m.content.trimRight()}';
      buf.writeln(line);
      entries.add(
        PromptConversationEntry(
          key: 'semantic:${m.id}#${PromptBuilder.promptRevisionOf(line)}',
          text: line,
          provenance: provenanceOf(m),
          runId: runIdOf(m),
        ),
      );
    }
    blocks.add(buf.toString().trimRight());
  }

  if (verbatimWindow.isNotEmpty) {
    final buf = StringBuffer('### Recent messages\n');
    for (final m in verbatimWindow) {
      final line =
          '- [${_senderLabel(m, selfAgentId, selfAgentName)} · ${_fmtTime(m.createdAt)}] ${m.content.trimRight()}';
      buf.writeln(line);
      entries.add(
        PromptConversationEntry(
          key: 'recent:${m.id}#${PromptBuilder.promptRevisionOf(line)}',
          text: line,
          provenance: provenanceOf(m),
          runId: runIdOf(m),
        ),
      );
    }
    blocks.add(buf.toString().trimRight());
  }

  if (blocks.isEmpty) {
    return ConversationContextParts.empty;
  }
  return ConversationContextParts(
    text: '## Conversation History\n\n${blocks.join('\n\n')}',
    entries: entries,
  );
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

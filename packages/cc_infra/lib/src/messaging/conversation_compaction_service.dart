import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/context/compaction_config.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_compactor.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_summarizer.dart';
import 'package:cc_domain/features/dispatch/domain/context/token_estimator.dart';
import 'package:cc_domain/features/dispatch/domain/context/tool_output_pruning.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// The outcome of a context-maintenance pass.
class CompactionOutcome {
  /// Creates a [CompactionOutcome].
  const CompactionOutcome({
    this.compactionMessageId,
    this.prunedTokens = 0,
    this.compactedMessageCount = 0,
  });

  /// Id of the inserted compaction summary message, or null if none was made.
  final String? compactionMessageId;

  /// Tokens reclaimed by the pruning pass.
  final int prunedTokens;

  /// Number of messages folded into the summary.
  final int compactedMessageCount;

  /// Whether the pass changed anything.
  bool get didSomething => compactionMessageId != null || prunedTokens > 0;

  /// An outcome where nothing happened.
  static const CompactionOutcome none = CompactionOutcome();
}

/// Orchestrates the anchored-compaction + tool-pruning context-maintenance pass
/// for a channel. Pure planning lives in the domain ([ConversationCompactor],
/// [ConversationPruner]); this service wires it to persistence, the summarizer
/// backend, and the embedding index.
///
/// Replaces the old lossy 120-char-excerpt `MessageCompactor`.
class ConversationCompactionService {
  /// Creates a [ConversationCompactionService].
  ConversationCompactionService({
    required MessagingRepository repo,
    required ConversationSummarizerPort summarizer,
    EmbeddingPort? embeddingPort,
    ConversationCompactor compactor = const ConversationCompactor(),
    ConversationPruner pruner = const ConversationPruner(),
    TokenEstimator estimator = TokenEstimator.instance,
    CompactionConfig config = CompactionConfig.defaults,
    DateTime Function() now = DateTime.now,
  })  : _repo = repo,
        _summarizer = summarizer,
        _embeddingPort = embeddingPort,
        _compactor = compactor,
        _pruner = pruner,
        _estimator = estimator,
        _config = config,
        _now = now;

  final MessagingRepository _repo;
  final ConversationSummarizerPort _summarizer;
  final EmbeddingPort? _embeddingPort;
  final ConversationCompactor _compactor;
  final ConversationPruner _pruner;
  final TokenEstimator _estimator;
  final CompactionConfig _config;
  final DateTime Function() _now;

  /// The active compaction configuration.
  CompactionConfig get config => _config;

  /// Runs a context-maintenance pass for [channelId] against a model with a
  /// [contextWindowTokens] window. Under pressure (or when [force]) it first
  /// prunes fat tool output, then — if still over budget — folds the older
  /// region into an anchored summary. Returns what it did.
  Future<CompactionOutcome> maintain({
    required String channelId,
    required int contextWindowTokens,
    required String selfAgentName,
    bool force = false,
  }) async {
    var messages = await _repo.getMessages(channelId);
    if (messages.isEmpty) {
      return CompactionOutcome.none;
    }

    final liveTokens = _liveTokens(messages);
    final underPressure = liveTokens + _config.buffer >= contextWindowTokens;
    if (!force && (!_config.auto || !underPressure)) {
      return CompactionOutcome.none;
    }

    var prunedTokens = 0;
    // 1. Pruning pass — reclaim fat tool output, possibly deferring compaction.
    if (_config.prune) {
      final plan = _pruner.plan(messages, now: _now(), gate: CachePruneGate.always);
      if (!plan.isEmpty) {
        await _applyPrunePlan(plan);
        prunedTokens = plan.reclaimedTokens;
        messages = await _repo.getMessages(channelId);
        // Did pruning relieve the pressure? If so, stop (preserve more cache).
        if (!force && _liveTokens(messages) + _config.buffer < contextWindowTokens) {
          return CompactionOutcome(prunedTokens: prunedTokens);
        }
      }
    }

    // 2. Compaction pass — fold the older region into an anchored summary.
    final plan = _compactor.plan(
      messages: messages,
      contextWindowTokens: contextWindowTokens,
      config: _config,
      force: force,
    );
    if (plan == null) {
      return CompactionOutcome(prunedTokens: prunedTokens);
    }

    final summary = await _summarizer.summarize(
      CompactionInput(
        messages: plan.messagesToCompact,
        previousSummary: plan.previousSummary,
        selfAgentName: selfAgentName,
      ),
    );
    if (summary.trim().isEmpty) {
      return CompactionOutcome(prunedTokens: prunedTokens);
    }

    await _repo.markCompacted(plan.idsToCompact);
    final messageId = await _repo.sendMessage(
      channelId: channelId,
      content: summary,
      senderId: 'system',
      senderType: 'agent',
      messageType: 'compaction',
      metadata: {
        // `compacted: true` keeps legacy summary-detection paths working.
        'compacted': true,
        'compactionReason': plan.reason == CompactionReason.manual
            ? 'manual'
            : 'auto',
        'tailStartId': plan.tailStartId,
        'compactedIds': plan.idsToCompact,
        if (plan.previousSummaryId != null)
          'previousSummaryId': plan.previousSummaryId,
      },
    );

    _embed(messageId, summary);

    return CompactionOutcome(
      compactionMessageId: messageId,
      prunedTokens: prunedTokens,
      compactedMessageCount: plan.idsToCompact.length,
    );
  }

  /// Live (non-compacted) token estimate for [messages], counting the prior
  /// summary plus everything after it that has not yet been compacted.
  int _liveTokens(List<ChannelMessage> messages) {
    var total = 0;
    for (final m in messages) {
      if (m.compacted) {
        continue;
      }
      total += _estimator.estimateMessage(m);
    }
    return total;
  }

  Future<void> _applyPrunePlan(PrunePlan plan) async {
    for (final entry in plan.updatedSegmentsByMessageId.entries) {
      final message = await _repo.getMessageById(entry.key);
      if (message == null) {
        continue;
      }
      final metadata = <String, dynamic>{
        ...?message.metadata,
        'segments': encodeTranscript(entry.value),
      };
      await _repo.updateMessage(entry.key, metadata: metadata);
    }
  }

  void _embed(String messageId, String content) {
    final port = _embeddingPort;
    if (port == null || !port.isReady) {
      return;
    }
    unawaited(() async {
      try {
        final vec = await port.embed(content);
        await _repo.updateMessageEmbedding(messageId, Uint8List.view(vec.buffer));
      } catch (_) {}
    }());
  }
}

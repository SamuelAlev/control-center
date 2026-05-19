import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_compactor.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_summarizer.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_token_estimator.dart';
import 'package:cc_domain/features/dispatch/domain/context/tool_output_pruning.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/context.dart';

/// What a `/shake` pass may drop.
enum ShakeTarget {
  /// Heavy tool output only, keeping every image.
  toolOutput,

  /// Images only, keeping every word of text.
  images,

  /// Both.
  all,
}

/// What a `/shake` pass actually dropped.
class ShakeOutcome {
  /// Creates a [ShakeOutcome].
  const ShakeOutcome({
    this.tokensReclaimed = 0,
    this.messagesTouched = 0,
    this.imagesDropped = 0,
  });

  /// Estimated tokens freed.
  final int tokensReclaimed;

  /// How many messages were rewritten.
  final int messagesTouched;

  /// How many image references were dropped from the model's view.
  final int imagesDropped;

  /// Whether anything changed.
  bool get isEmpty => messagesTouched == 0 && imagesDropped == 0;
}

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
/// for a space. Pure planning lives in the domain ([ConversationCompactor],
/// [ConversationPruner]); this service wires it to persistence, the summarizer
/// backend and the embedding index.
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
  }) : _repo = repo,
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

  /// Runs a context-maintenance pass for [spaceId] within [workspaceId],
  /// against a model with a [contextWindowTokens] window. Under pressure (or when [force]) it first
  /// prunes fat tool output, then — if still over budget — folds the older
  /// region into an anchored summary. Returns what it did.
  ///
  /// [conversationId] selects the stream within the space (defaults to the
  /// space's STANDING conversation); a manual `/compact` fired from a thread
  /// must fold that thread, not the standing transcript.
  Future<CompactionOutcome> maintain({
    required String workspaceId,
    required String spaceId,
    required int contextWindowTokens,
    required String selfAgentName,
    String? conversationId,
    bool force = false,
  }) async {
    var messages = await _repo.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversationId,
    );
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
      final plan = _pruner.plan(
        messages,
        now: _now(),
        gate: CachePruneGate.always,
      );
      if (!plan.isEmpty) {
        await _applyPrunePlan(workspaceId, plan);
        prunedTokens = plan.reclaimedTokens;
        messages = await _repo.getMessages(
          workspaceId,
          spaceId,
          conversationId: conversationId,
        );
        // Did pruning relieve the pressure? If so, stop (preserve more cache).
        if (!force &&
            _liveTokens(messages) + _config.buffer < contextWindowTokens) {
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

    await _repo.markCompacted(workspaceId, plan.idsToCompact);
    final messageId = await _repo.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: summary,
      senderId: 'system',
      senderType: 'agent',
      messageType: 'compaction',
      conversationId: conversationId,
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

    _embed(workspaceId, messageId, summary);

    return CompactionOutcome(
      compactionMessageId: messageId,
      prunedTokens: prunedTokens,
      compactedMessageCount: plan.idsToCompact.length,
    );
  }

  /// Live (non-compacted) token estimate for [messages], counting the prior
  /// summary plus everything after it that has not yet been compacted.
  int _liveTokens(List<Message> messages) {
    var total = 0;
    for (final m in messages) {
      if (m.compacted) {
        continue;
      }
      total += _estimator.estimateMessage(m);
    }
    return total;
  }

  /// Drops heavy content from a conversation WITHOUT summarizing it.
  ///
  /// The escape hatch between doing nothing and compacting. Compaction spends
  /// a model call and rewrites the narrative into a summary; shaking spends
  /// nothing, keeps every word the agent and the user wrote, and only blanks
  /// the bulk that was never going to be re-read — a 40 KB command dump from
  /// twenty turns ago, a screenshot already acted on.
  ///
  /// Unlike the automatic prune this runs UNCONDITIONALLY (a deliberate human
  /// action needs no budget justification) and ignores the minimum-benefit
  /// floor, but it still protects the most recent turns: the newest tool
  /// result is usually what the agent is mid-way through reasoning about.
  Future<ShakeOutcome> shake({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    ShakeTarget target = ShakeTarget.toolOutput,
  }) async {
    final messages = await _repo.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversationId,
    );
    if (messages.isEmpty) {
      return const ShakeOutcome();
    }

    var reclaimed = 0;
    var elided = 0;
    var images = 0;

    if (target == ShakeTarget.toolOutput || target == ShakeTarget.all) {
      final plan = _pruner.plan(
        messages,
        now: _now(),
        // No gate: the user asked for this, so it is not the cache's decision.
        gate: CachePruneGate.always,
      );
      if (!plan.isEmpty) {
        await _applyPrunePlan(workspaceId, plan);
        reclaimed += plan.reclaimedTokens;
        elided += plan.updatedSegmentsByMessageId.length;
      }
    }

    if (target == ShakeTarget.images || target == ShakeTarget.all) {
      images = await _stripImages(workspaceId, spaceId, conversationId);
      // Images bill a flat block each, so their saving is per-image and not a
      // function of any character count.
      reclaimed += images * kImageTokenCost;
    }

    return ShakeOutcome(
      tokensReclaimed: reclaimed,
      messagesTouched: elided,
      imagesDropped: images,
    );
  }

  /// Removes tool-result image references outside the protected recent turns.
  ///
  /// The blob itself is left on disk: a person shaking their context is
  /// managing the model's window, not asking to destroy evidence, and the
  /// transcript can still show the picture. Only the MODEL stops paying for
  /// it — which is the entire cost being complained about.
  Future<int> _stripImages(
    String workspaceId,
    String spaceId,
    String? conversationId,
  ) async {
    final messages = await _repo.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversationId,
    );
    // Protect the newest agent turn, for the same reason the pruner does.
    final protectedIds = <String>{};
    for (final m in messages.reversed) {
      if (m.isAgentTurn) {
        protectedIds.add(m.id);
        break;
      }
    }
    var dropped = 0;
    for (final message in messages) {
      if (!message.isAgentTurn || protectedIds.contains(message.id)) {
        continue;
      }
      final segments = message.transcript;
      if (segments.isEmpty) {
        continue;
      }
      var changed = false;
      final rewritten = <TranscriptSegment>[];
      for (final segment in segments) {
        if (segment is ToolSegment && segment.images.isNotEmpty) {
          dropped += segment.images.length;
          changed = true;
          rewritten.add(
            ToolSegment(
              toolName: segment.toolName,
              toolCallId: segment.toolCallId,
              inputs: segment.inputs,
              outputs: segment.outputs,
              status: segment.status,
              startedAt: segment.startedAt,
              durationMs: segment.durationMs,
              prunedAt: segment.prunedAt,
            ),
          );
        } else {
          rewritten.add(segment);
        }
      }
      if (!changed) {
        continue;
      }
      await _repo.updateMessage(
        workspaceId,
        message.id,
        metadata: <String, dynamic>{
          ...?message.metadata,
          'segments': encodeTranscript(rewritten),
        },
      );
    }
    return dropped;
  }

  Future<void> _applyPrunePlan(String workspaceId, PrunePlan plan) async {
    for (final entry in plan.updatedSegmentsByMessageId.entries) {
      final message = await _repo.getMessageById(workspaceId, entry.key);
      if (message == null) {
        continue;
      }
      final metadata = <String, dynamic>{
        ...?message.metadata,
        'segments': encodeTranscript(entry.value),
      };
      await _repo.updateMessage(workspaceId, entry.key, metadata: metadata);
    }
  }

  void _embed(String workspaceId, String messageId, String content) {
    final port = _embeddingPort;
    if (port == null || !port.isReady) {
      return;
    }
    unawaited(() async {
      try {
        final vec = await port.embed(content);
        await _repo.updateMessageEmbedding(
          workspaceId,
          messageId,
          Uint8List.view(vec.buffer),
        );
      } catch (_) {}
    }());
  }
}

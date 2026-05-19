/// Anchored context compaction for the built-in harness loop.
///
/// Reuses the shared PRD-03 context leaves — [TokenEstimator], [CompactionConfig],
/// [ToolResultElision] + its markers and [compactionSystemPrompt] — but plans
/// over the harness's own [HarnessMessage] type (the shared compactor operates
/// on `Message`, a different shape). Pure Dart: the LLM-backed summarizer
/// lives in the infrastructure layer; here we only define the contract and a
/// deterministic fallback.
library;

import 'package:cc_harness/src/context/compaction_config.dart';
import 'package:cc_harness/src/context/compaction_prompt.dart';
import 'package:cc_harness/src/context/harness_token_accounting.dart';
import 'package:cc_harness/src/context/token_estimator.dart'
    show TokenEstimator;
import 'package:cc_harness/src/context/tool_result_elision.dart';
import 'package:cc_harness/src/messages.dart';

/// Re-exported so infrastructure summarizers can build the system prompt without
/// importing the dispatch context module directly.
const String harnessCompactionSystemPrompt = compactionSystemPrompt;

/// Marks the injected anchored-summary user message so a later compaction pass
/// recognizes it and re-anchors (updates) rather than re-summarizing.
const String harnessSummaryMarker = '[conversation-summary]';

/// Input to a harness summarizer: the span of messages to fold plus the prior
/// anchored summary (if the conversation was compacted before).
class HarnessCompactionInput {
  /// Creates a [HarnessCompactionInput].
  const HarnessCompactionInput({
    required this.messages,
    this.previousSummary,
    this.selfAgentName = 'assistant',
  });

  /// The messages (ascending) being folded.
  final List<HarnessMessage> messages;

  /// The prior anchored summary text, if any.
  final String? previousSummary;

  /// Display name for the agent's turns in the rendered history.
  final String selfAgentName;
}

/// Produces an anchored summary standing in for a folded span of harness turns.
abstract interface class HarnessSummarizerPort {
  /// Returns the anchored summary text for [input].
  Future<String> summarize(HarnessCompactionInput input);
}

/// Renders a harness message span into a compact, summarizer-friendly transcript
/// (user turns verbatim; assistant answer text + a thin tool-action trail;
/// reasoning and fat tool outputs dropped). Mirrors the shared
/// `serializeCompactionHistory` for [HarnessMessage].
String serializeHarnessHistory(
  List<HarnessMessage> messages, {
  String selfAgentName = 'assistant',
}) {
  final buf = StringBuffer();
  for (final m in messages) {
    switch (m.role) {
      case HarnessRole.user:
        final text = m.textContent.trim();
        if (text.isEmpty || text.startsWith(harnessSummaryMarker)) {
          continue;
        }
        buf
          ..writeln('# User')
          ..writeln(text)
          ..writeln();
      case HarnessRole.assistant:
        final answer = m.textContent.trim();
        final actions = <String>[];
        for (final b in m.content) {
          if (b is HarnessToolUseBlock && !actions.contains(b.name)) {
            actions.add(b.name);
          }
        }
        buf.writeln('# $selfAgentName');
        if (answer.isNotEmpty) {
          buf.writeln(answer);
        }
        if (actions.isNotEmpty) {
          buf.writeln('(actions: ${actions.take(12).join(', ')})');
        }
        buf.writeln();
      case HarnessRole.system:
      case HarnessRole.tool:
        // System steering and raw tool results carry little durable signal.
        break;
    }
  }
  return buf.toString().trim();
}

/// A deterministic, LLM-free harness summarizer. Carries the prior summary
/// forward and appends a structured digest of the folded turns; reclaim comes
/// from dropping reasoning + fat tool outputs. The default so compaction works
/// with no summarizer model configured.
class StructuralHarnessSummarizer implements HarnessSummarizerPort {
  /// Creates a [StructuralHarnessSummarizer].
  const StructuralHarnessSummarizer();

  @override
  Future<String> summarize(HarnessCompactionInput input) async {
    final buf = StringBuffer('## Conversation summary (compacted)');
    final prev = input.previousSummary?.trim();
    if (prev != null && prev.isNotEmpty) {
      buf
        ..writeln()
        ..writeln()
        ..writeln('### Established context')
        ..writeln(_strip(prev));
    }
    final digest = serializeHarnessHistory(
      input.messages,
      selfAgentName: input.selfAgentName,
    );
    if (digest.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('### Newly compacted')
        ..writeln(digest);
    }
    return buf.toString().trimRight();
  }

  String _strip(String summary) {
    final lines = summary.split('\n');
    if (lines.isNotEmpty && lines.first.trimLeft().startsWith('#')) {
      return lines.skip(1).join('\n').trim();
    }
    return summary;
  }
}

/// The outcome of a compaction / prune pass.
class HarnessCompactionResult {
  /// Creates a [HarnessCompactionResult].
  const HarnessCompactionResult({
    required this.changed,
    required this.summarized,
    required this.messagesFolded,
    required this.tokensBefore,
    required this.tokensAfter,
  });

  /// A no-op result (history unchanged).
  const HarnessCompactionResult.unchanged(int tokens)
    : changed = false,
      summarized = false,
      messagesFolded = 0,
      tokensBefore = tokens,
      tokensAfter = tokens;

  /// Whether the history was modified.
  final bool changed;

  /// True when a summary was produced; false for a prune-only pass.
  final bool summarized;

  /// Number of messages folded into the summary.
  final int messagesFolded;

  /// Estimated live tokens before the pass.
  final int tokensBefore;

  /// Estimated live tokens after the pass.
  final int tokensAfter;
}

/// Compacts a harness history in place when it approaches the context window.
abstract interface class HarnessCompactor {
  /// Compacts [history] (mutating it in place) when
  /// `estimate + overheadTokens + buffer >= contextWindow`. Returns what
  /// happened. A null [contextWindow] disables compaction.
  ///
  /// When [force] is true the threshold gate is bypassed and the fold runs
  /// unconditionally with a tighter recent-region budget — used for reactive
  /// recovery after the provider itself rejects the request as too large (the
  /// heuristic estimate can under-count what the provider actually measured).
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens,
    String selfAgentName,
    bool force,
  });

  /// Reclaims context cheaply by eliding uneventful older tool results, without
  /// a summary/cache rewrite. Returns the number of results elided.
  /// Elides uneventful older tool results in place, returning how many were
  /// elided.
  ///
  /// [force] skips the "is this worth the cache it breaks?" threshold. Set it
  /// only where the cached prefix is being rewritten anyway — i.e. alongside a
  /// compaction — so the pass rides a rewrite that has already been paid for.
  int pruneToolResults(List<HarnessMessage> history, {bool force = false});
}

/// The default [HarnessCompactor]: reuses [CompactionConfig] tunables, folds on
/// user-turn boundaries keeping the newest turns verbatim and delegates the
/// summary text to a [HarnessSummarizerPort].
class DefaultHarnessCompactor implements HarnessCompactor {
  /// Creates a [DefaultHarnessCompactor].
  const DefaultHarnessCompactor({
    this.summarizer = const StructuralHarnessSummarizer(),
    this.config = CompactionConfig.defaults,
    this.elision = const ToolResultElision(),
  });

  /// Produces the anchored summary text.
  final HarnessSummarizerPort summarizer;

  /// Compaction tunables (keepTurns / buffer / prune).
  final CompactionConfig config;

  /// Classifier for uneventful tool results.
  final ToolResultElision elision;

  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
  }) async {
    if (contextWindow == null) {
      return HarnessCompactionResult.unchanged(estimateHarnessHistory(history));
    }
    final before = estimateHarnessHistory(history) + overheadTokens;
    if (!force && before + config.buffer < contextWindow) {
      return HarnessCompactionResult.unchanged(before);
    }

    // Recent region kept verbatim. Bounded so the folded result actually fits
    // under the window (tail + summary + overhead + output reservation). Under
    // [force] (the provider already rejected the request) keep the region
    // tighter so the fold reclaims meaningfully more.
    final headroom = contextWindow - overheadTokens - config.buffer - 4096;
    final baseKeep = config.keepTokens ?? (contextWindow ~/ 4);
    final keepRecentTokens = (force ? baseKeep ~/ 2 : baseKeep).clamp(
      2000,
      headroom < 2000 ? 2000 : headroom,
    );

    final cut = _planCut(history, keepRecentTokens: keepRecentTokens);
    if (cut <= 0) {
      return HarnessCompactionResult.unchanged(before);
    }
    final fold = history.sublist(0, cut);
    final tail = history.sublist(cut);
    final previousSummary = _extractPreviousSummary(fold);

    final summaryText = await summarizer.summarize(
      HarnessCompactionInput(
        messages: fold,
        previousSummary: previousSummary,
        selfAgentName: selfAgentName,
      ),
    );

    history
      ..clear()
      ..add(
        HarnessMessage(
          role: HarnessRole.user,
          content: [HarnessTextBlock('$harnessSummaryMarker\n$summaryText')],
        ),
      )
      ..addAll(tail);

    final after = estimateHarnessHistory(history) + overheadTokens;
    return HarnessCompactionResult(
      changed: true,
      summarized: true,
      messagesFolded: fold.length,
      tokensBefore: before,
      tokensAfter: after,
    );
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) {
    if (!config.prune) {
      return 0;
    }
    // Protect the newest tool-results turn from pruning (recent context).
    final lastToolIdx = history.lastIndexWhere(
      (m) => m.role == HarnessRole.tool,
    );
    // One pass over the assistant turns builds the id→name index. Resolving
    // each result by re-scanning history from 0 made this O(n²) per turn, and
    // it runs on every tool-bearing turn for the whole life of a session.
    final toolNames = _toolNameIndex(history);
    // Pass 1: how much is there to reclaim? Pruning rewrites messages in
    // place, and any byte change costs the provider's cached prefix from that
    // point forward — so the pass has to be worth more than the cache it
    // breaks. Under the threshold, leave history alone and let the reclaimable
    // total keep accruing until one deep rewrite pays for itself.
    if (!force && config.pruneThresholdTokens > 0) {
      var reclaimable = 0;
      for (
        var i = 0;
        i < history.length && reclaimable < config.pruneThresholdTokens;
        i++
      ) {
        if (i == lastToolIdx || history[i].role != HarnessRole.tool) {
          continue;
        }
        for (final b in history[i].content) {
          if (b is! HarnessToolResultBlock) {
            continue;
          }
          if (b.content != elidedResultMarker &&
              elision.isUseless(
                toolName: toolNames[b.toolUseId] ?? '',
                outputs: b.content,
                isError: b.isError,
              )) {
            reclaimable += TokenEstimator.instance.estimate(b.content);
          }
          reclaimable += b.images.length * kImageTokenCost;
        }
      }
      if (reclaimable < config.pruneThresholdTokens) {
        return 0;
      }
    }
    var elided = 0;
    for (var i = 0; i < history.length; i++) {
      if (i == lastToolIdx) {
        continue;
      }
      final m = history[i];
      if (m.role != HarnessRole.tool) {
        continue;
      }
      final rebuilt = <HarnessContentBlock>[];
      var changed = false;
      for (final b in m.content) {
        if (b is HarnessToolResultBlock &&
            b.content != elidedResultMarker &&
            elision.isUseless(
              toolName: toolNames[b.toolUseId] ?? '',
              outputs: b.content,
              isError: b.isError,
            )) {
          rebuilt.add(
            HarnessToolResultBlock(
              toolUseId: b.toolUseId,
              content: elidedResultMarker,
              isError: b.isError,
            ),
          );
          changed = true;
          elided++;
        } else if (b is HarnessToolResultBlock && b.images.isNotEmpty) {
          // Stale screenshot, useful text: shed the image, keep the words.
          // Summarization shrinks text but cannot shrink an image, so without
          // this a run that screenshots every turn accumulates ~1200 tokens
          // per frame forever. The tool's text description is what carries
          // the finding past this point; only the newest tool turn (skipped
          // above) still needs to be looked at.
          rebuilt.add(
            HarnessToolResultBlock(
              toolUseId: b.toolUseId,
              content: b.content,
              isError: b.isError,
            ),
          );
          changed = true;
        } else {
          rebuilt.add(b);
        }
      }
      if (changed) {
        history[i] = HarnessMessage(role: m.role, content: rebuilt);
      }
    }
    return elided;
  }

  /// `toolUseId` → tool name, built in one pass over the assistant turns.
  Map<String, String> _toolNameIndex(List<HarnessMessage> history) {
    final index = <String, String>{};
    for (final m in history) {
      if (m.role != HarnessRole.assistant) {
        continue;
      }
      for (final b in m.content) {
        if (b is HarnessToolUseBlock) {
          // First writer wins, matching the old first-match-from-index-0 scan.
          index.putIfAbsent(b.id, () => b.name);
        }
      }
    }
    return index;
  }

  /// The index to cut at: everything in `history[0:cut)` is folded into the
  /// summary. Returns 0 when there is nothing worth folding.
  ///
  /// Two regimes:
  /// - **Multi-turn chat** (more than `keepTurns` user turns): fold everything
  ///   before the newest `keepTurns` user turns — the cut lands on a
  ///   user-message boundary, so the kept tail never starts on a tool turn.
  /// - **Single-/few-turn autonomous run** (`/goal`, `/loop`: one user message
  ///   then a long assistant↔tool exchange): the user-boundary rule can never
  ///   fold anything, so instead keep the newest [keepRecentTokens] verbatim and
  ///   fold the older assistant/tool messages. The cut is snapped to a safe
  ///   boundary so a `tool_result` is never left without its `tool_use`.
  int _planCut(List<HarnessMessage> history, {required int keepRecentTokens}) {
    final userIdx = <int>[
      for (var i = 0; i < history.length; i++)
        if (history[i].role == HarnessRole.user) i,
    ];
    if (userIdx.length > config.keepTurns) {
      return userIdx[userIdx.length - config.keepTurns];
    }
    return _tokenBudgetCut(history, keepRecentTokens);
  }

  /// Folds older messages within a single user turn, keeping the newest
  /// [keepRecentTokens] verbatim. The returned cut never starts the kept tail on
  /// a `tool` (tool-result) message, so no `tool_use`/`tool_result` pair is
  /// split across the fold boundary.
  int _tokenBudgetCut(List<HarnessMessage> history, int keepRecentTokens) {
    var kept = 0;
    var cut = 0;
    for (var i = history.length - 1; i >= 0; i--) {
      kept += estimateHarnessMessage(history[i]);
      if (kept >= keepRecentTokens) {
        cut = i;
        break;
      }
    }
    if (cut <= 0) {
      return 0;
    }
    // Snap forward so the tail cannot begin with an orphaned tool result.
    while (cut < history.length && history[cut].role == HarnessRole.tool) {
      cut++;
    }
    return cut >= history.length ? 0 : cut;
  }

  /// Pulls the prior summary text out of a folded span, if its first user
  /// message is a summary marker.
  String? _extractPreviousSummary(List<HarnessMessage> fold) {
    for (final m in fold) {
      if (m.role == HarnessRole.user) {
        final text = m.textContent.trimLeft();
        if (text.startsWith(harnessSummaryMarker)) {
          return text.substring(harnessSummaryMarker.length).trim();
        }
        return null;
      }
    }
    return null;
  }
}

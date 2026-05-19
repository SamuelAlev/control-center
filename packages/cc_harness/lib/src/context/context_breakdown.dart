import 'package:cc_harness/src/context/harness_token_accounting.dart';
import 'package:cc_harness/src/context/token_estimator.dart';
import 'package:cc_harness/src/context/tool_result_elision.dart';
import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart';

/// One line of a context report: a category and what it costs.
class ContextCategory {
  /// Creates a [ContextCategory].
  const ContextCategory({
    required this.label,
    required this.tokens,
    this.count,
  });

  /// Human-readable category name.
  final String label;

  /// Estimated tokens.
  final int tokens;

  /// How many items make it up (messages, images, tools), when meaningful.
  final int? count;
}

/// Where a conversation's context is actually going.
///
/// The question this answers is the one a person asks right before deciding
/// whether to compact: *what is eating my window?* "68% used" tells you to act
/// but not what to act on — twelve stale screenshots and one enormous tool
/// result call for completely different moves (`/shake images` versus
/// `/compact`), and without a breakdown both look identical.
class ContextBreakdown {
  /// Creates a [ContextBreakdown].
  const ContextBreakdown({
    required this.categories,
    required this.totalTokens,
    required this.contextWindow,
  });

  /// Per-category costs, largest first.
  final List<ContextCategory> categories;

  /// Estimated total, including overhead.
  final int totalTokens;

  /// The model's window, for the percentage.
  final int contextWindow;

  /// Fraction of the window in use, 0–1 (can exceed 1 before compaction).
  double get fraction =>
      contextWindow <= 0 ? 0 : totalTokens / contextWindow;

  /// Percentage of the window in use.
  int get percent => (fraction * 100).round();

  /// A compact, model- and human-readable rendering.
  String render() {
    final buffer = StringBuffer()
      ..writeln(
        'Context: $totalTokens / $contextWindow tokens ($percent%)',
      );
    for (final category in categories) {
      if (category.tokens <= 0) {
        continue;
      }
      final share = totalTokens <= 0
          ? 0
          : (category.tokens * 100 / totalTokens).round();
      final count = category.count == null ? '' : ' (${category.count})';
      buffer.writeln(
        '  ${category.label}$count: ${category.tokens} tokens · $share%',
      );
    }
    return buffer.toString().trimRight();
  }
}

/// Builds a [ContextBreakdown] for the current conversation state.
///
/// Categories are chosen to map onto an ACTION. "Tool results" and "Images"
/// are separate lines because `/shake` can drop either independently; system
/// prompt and tool schemas are separate because they are fixed costs a
/// compaction cannot touch, and seeing that they are 30% of a small window is
/// what tells you the model is the problem, not the conversation.
ContextBreakdown buildContextBreakdown({
  required List<HarnessMessage> history,
  required int contextWindow,
  String? systemPrompt,
  List<LlmToolSchema> toolSchemas = const [],
}) {
  final systemTokens = systemPrompt == null
      ? 0
      : TokenEstimator.instance.estimate(systemPrompt);
  var toolSchemaTokens = 0;
  for (final schema in toolSchemas) {
    toolSchemaTokens += TokenEstimator.instance.estimate(
      '${schema.name}${schema.description}${schema.inputSchema}',
    );
  }

  var userTokens = 0;
  var userCount = 0;
  var assistantTokens = 0;
  var assistantCount = 0;
  var thinkingTokens = 0;
  var toolCallTokens = 0;
  var toolCallCount = 0;
  var toolResultTokens = 0;
  var toolResultCount = 0;
  var imageTokens = 0;
  var imageCount = 0;
  var elidedCount = 0;
  var summaryTokens = 0;

  for (final message in history) {
    final isSummary =
        message.role == HarnessRole.user &&
        message.content.any(
          (b) =>
              b is HarnessTextBlock &&
              b.text.startsWith('[conversation-summary]'),
        );
    for (final block in message.content) {
      switch (block) {
        case HarnessTextBlock(:final text):
          final tokens = TokenEstimator.instance.estimate(text);
          if (isSummary) {
            summaryTokens += tokens;
          } else if (message.role == HarnessRole.user) {
            userTokens += tokens;
          } else {
            assistantTokens += tokens;
          }
        case HarnessThinkingBlock():
          thinkingTokens += estimateHarnessBlock(block);
        case HarnessToolUseBlock():
          toolCallTokens += estimateHarnessBlock(block);
          toolCallCount++;
        case HarnessToolResultBlock(:final content, :final images):
          toolResultTokens += TokenEstimator.instance.estimate(content);
          toolResultCount++;
          if (content.trim() == elidedResultMarker) {
            elidedCount++;
          }
          imageCount += images.length;
          imageTokens += images.length * kImageTokenCost;
        case HarnessImageBlock():
          imageCount++;
          imageTokens += kImageTokenCost;
      }
    }
    if (!isSummary) {
      if (message.role == HarnessRole.user) {
        userCount++;
      } else if (message.role == HarnessRole.assistant) {
        assistantCount++;
      }
    }
  }

  final categories = <ContextCategory>[
    ContextCategory(label: 'System prompt', tokens: systemTokens),
    ContextCategory(
      label: 'Tool schemas',
      tokens: toolSchemaTokens,
      count: toolSchemas.length,
    ),
    ContextCategory(label: 'Summaries', tokens: summaryTokens),
    ContextCategory(
      label: 'User messages',
      tokens: userTokens,
      count: userCount,
    ),
    ContextCategory(
      label: 'Assistant messages',
      tokens: assistantTokens,
      count: assistantCount,
    ),
    ContextCategory(label: 'Thinking', tokens: thinkingTokens),
    ContextCategory(
      label: 'Tool calls',
      tokens: toolCallTokens,
      count: toolCallCount,
    ),
    ContextCategory(
      // Naming how many are ALREADY blanked is the signal that shaking has
      // happened here: a second `/shake` will free nothing and `/compact` is
      // the move.
      label: elidedCount > 0
          ? 'Tool results ($elidedCount already elided)'
          : 'Tool results',
      tokens: toolResultTokens,
      count: toolResultCount,
    ),
    ContextCategory(label: 'Images', tokens: imageTokens, count: imageCount),
  ]..sort((a, b) => b.tokens.compareTo(a.tokens));

  final total = categories.fold<int>(0, (sum, c) => sum + c.tokens);
  return ContextBreakdown(
    categories: categories,
    totalTokens: total,
    contextWindow: contextWindow,
  );
}

/// What a `/shake` pass removed.
class ShakeResult {
  /// Creates a [ShakeResult].
  const ShakeResult({
    required this.messages,
    required this.tokensReclaimed,
    required this.toolResultsElided,
    required this.imagesDropped,
  });

  /// The rewritten history.
  final List<HarnessMessage> messages;

  /// Estimated tokens freed.
  final int tokensReclaimed;

  /// How many tool results were blanked.
  final int toolResultsElided;

  /// How many images were dropped.
  final int imagesDropped;

  /// Whether anything changed.
  bool get isEmpty => toolResultsElided == 0 && imagesDropped == 0;

  /// A one-line summary.
  String render() {
    if (isEmpty) {
      return 'Nothing to shake: no heavy tool results or images outside the '
          'protected recent turns.';
    }
    final parts = <String>[];
    if (toolResultsElided > 0) {
      parts.add('$toolResultsElided tool result(s)');
    }
    if (imagesDropped > 0) {
      parts.add('$imagesDropped image(s)');
    }
    return 'Shook out ${parts.join(' and ')}, '
        'reclaiming ~$tokensReclaimed tokens.';
  }
}

/// What `/shake` should drop.
enum ShakeMode {
  /// Heavy tool results (and their images).
  elide,

  /// Images only, keeping every word of text.
  images,

  /// Both.
  all,
}

/// Drops heavy content from [history] WITHOUT summarizing it.
///
/// The escape hatch between "do nothing" and "compact". Compaction spends a
/// model call and rewrites the narrative; shaking spends nothing and keeps
/// every word — it only blanks the bulk that was never going to be re-read: a
/// 40 KB `bash` dump from twenty turns ago, a screenshot the agent has long
/// since acted on.
///
/// [keepRecentTurns] protects the newest turns, because the most recent tool
/// result is usually what the agent is mid-way through reasoning about.
/// [minTokens] skips results too small to be worth a placeholder — blanking a
/// 20-token result to insert an 8-token marker churns the prompt cache for
/// nothing.
ShakeResult shakeHistory(
  List<HarnessMessage> history, {
  ShakeMode mode = ShakeMode.elide,
  int keepRecentTurns = 2,
  int minTokens = 50,
}) {
  // Find the index after which everything is protected: the last
  // `keepRecentTurns` user turns and everything following them.
  var protectedFrom = history.length;
  var seenUserTurns = 0;
  for (var i = history.length - 1; i >= 0; i--) {
    if (history[i].role == HarnessRole.user) {
      seenUserTurns++;
      if (seenUserTurns > keepRecentTurns) {
        break;
      }
      protectedFrom = i;
    }
  }

  final dropText = mode == ShakeMode.elide || mode == ShakeMode.all;
  final dropImages = mode == ShakeMode.images || mode == ShakeMode.all;

  var reclaimed = 0;
  var elided = 0;
  var droppedImages = 0;
  final out = <HarnessMessage>[];

  for (var i = 0; i < history.length; i++) {
    final message = history[i];
    if (i >= protectedFrom) {
      out.add(message);
      continue;
    }
    var changed = false;
    final blocks = <HarnessContentBlock>[];
    for (final block in message.content) {
      switch (block) {
        case HarnessToolResultBlock():
          final tokens = TokenEstimator.instance.estimate(block.content);
          final shouldElide =
              dropText &&
              tokens >= minTokens &&
              block.content.trim() != elidedResultMarker;
          final shouldDropImages = dropImages && block.images.isNotEmpty;
          if (!shouldElide && !shouldDropImages) {
            blocks.add(block);
            continue;
          }
          changed = true;
          if (shouldElide) {
            reclaimed += tokens;
            elided++;
          }
          if (shouldDropImages) {
            reclaimed += block.images.length * kImageTokenCost;
            droppedImages += block.images.length;
          }
          blocks.add(
            HarnessToolResultBlock(
              toolUseId: block.toolUseId,
              content: shouldElide ? shakenResultMarker : block.content,
              isError: block.isError,
              images: shouldDropImages ? const [] : block.images,
            ),
          );
        case HarnessImageBlock():
          if (!dropImages) {
            blocks.add(block);
            continue;
          }
          changed = true;
          droppedImages++;
          reclaimed += kImageTokenCost;
          blocks.add(const HarnessTextBlock(shakenImageMarker));
        default:
          blocks.add(block);
      }
    }
    out.add(
      changed ? HarnessMessage(role: message.role, content: blocks) : message,
    );
  }

  return ShakeResult(
    messages: out,
    tokensReclaimed: reclaimed,
    toolResultsElided: elided,
    imagesDropped: droppedImages,
  );
}

/// Replaces a tool result's body when `/shake` drops it.
///
/// Distinct wording from the automatic elision marker on purpose: this one was
/// a deliberate human action, and an agent that reads "elided" learns nothing
/// while one that reads "dropped to free context" knows it can re-run the tool
/// if it genuinely needs the output back.
const String shakenResultMarker =
    '[Output dropped to free context — re-run the tool if you need it]';

/// Replaces an image block when `/shake` drops it.
const String shakenImageMarker = '[Image dropped to free context]';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/observability/domain/friction_analyzer.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── User-friction analytics providers (PRD 06, feature #5) ───────────────────
//
// Extracts frustration signals (yelling, profanity, anguish, negation,
// repetition, blame) from the user's own messages across the workspace's
// conversations and aggregates them. Lazy: only computed while the Behavior tab
// is mounted.

/// The pure-domain friction analyzer.
final frictionAnalyzerProvider = Provider<FrictionAnalyzer>(
  (ref) => const FrictionAnalyzer(),
);

/// Aggregated friction for one conversation.
class ConversationFriction {
  /// Creates a [ConversationFriction].
  const ConversationFriction({
    required this.spaceId,
    required this.spaceName,
    required this.metrics,
    required this.messageCount,
  });

  /// The conversation id.
  final String spaceId;

  /// The conversation's display name.
  final String spaceName;

  /// Summed friction signals over the conversation's user messages.
  final FrictionMetrics metrics;

  /// Number of user messages analyzed.
  final int messageCount;
}

/// A workspace-wide friction report: overall totals plus a per-conversation
/// breakdown (most-frustrated first).
class WorkspaceFrictionReport {
  /// Creates a [WorkspaceFrictionReport].
  const WorkspaceFrictionReport({
    required this.totals,
    required this.messageCount,
    required this.byConversation,
  });

  /// Empty report.
  static const empty = WorkspaceFrictionReport(
    totals: FrictionMetrics.empty,
    messageCount: 0,
    byConversation: [],
  );

  /// Summed signals over every analyzed user message in the workspace.
  final FrictionMetrics totals;

  /// Total user messages analyzed.
  final int messageCount;

  /// Per-conversation breakdown, sorted by total signals descending.
  final List<ConversationFriction> byConversation;
}

/// Mutable-free totals accumulator for friction signals across many messages
/// (FrictionMetrics itself is per-message and has no `+`).
class _FrictionTotals {
  const _FrictionTotals({
    required this.chars,
    required this.words,
    required this.yelling,
    required this.profanity,
    required this.anguish,
    required this.negation,
    required this.repetition,
    required this.blame,
  });

  final int chars;
  final int words;
  final int yelling;
  final int profanity;
  final int anguish;
  final int negation;
  final int repetition;
  final int blame;

  int get totalSignals =>
      yelling + profanity + anguish + negation + repetition + blame;

  _FrictionTotals plus(FrictionMetrics m) => _FrictionTotals(
    chars: chars + m.chars,
    words: words + m.words,
    yelling: yelling + m.yelling,
    profanity: profanity + m.profanity,
    anguish: anguish + m.anguish,
    negation: negation + m.negation,
    repetition: repetition + m.repetition,
    blame: blame + m.blame,
  );

  FrictionMetrics toMetrics() => FrictionMetrics(
    chars: chars,
    words: words,
    yelling: yelling,
    profanity: profanity,
    anguish: anguish,
    negation: negation,
    repetition: repetition,
    blame: blame,
  );
}

const _zeroTotals = _FrictionTotals(
  chars: 0,
  words: 0,
  yelling: 0,
  profanity: 0,
  anguish: 0,
  negation: 0,
  repetition: 0,
  blame: 0,
);

/// The active workspace's friction report, aggregated across its conversations.
///
/// `autoDispose` is load-bearing: this provider watches the FULL message list
/// of every space in the workspace. Were it kept alive, one visit to the
/// Behavior tab would pin every conversation's history in memory (and keep
/// the underlying RPC subscriptions live) for the rest of the session.
final workspaceFrictionProvider = Provider.autoDispose<WorkspaceFrictionReport>(
  (ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return WorkspaceFrictionReport.empty;
    }
    final spaces =
        ref.watch(workspaceSpacesProvider(workspaceId)).asData?.value ??
        const [];
    final analyzer = ref.watch(frictionAnalyzerProvider);

    var totals = _zeroTotals;
    var totalMessages = 0;
    final perConversation = <ConversationFriction>[];

    for (final space in spaces) {
      final messages =
          ref.watch(spaceMessagesProvider(space.id)).asData?.value ??
          const <Message>[];
      var convTotals = _zeroTotals;
      var convCount = 0;
      for (final message in messages) {
        if (!message.isUser || message.content.trim().isEmpty) {
          continue;
        }
        final metrics = analyzer.analyze(message.content);
        convTotals = convTotals.plus(metrics);
        totals = totals.plus(metrics);
        convCount++;
        totalMessages++;
      }
      if (convCount > 0) {
        perConversation.add(
          ConversationFriction(
            spaceId: space.id,
            spaceName: space.name,
            metrics: convTotals.toMetrics(),
            messageCount: convCount,
          ),
        );
      }
    }

    perConversation.sort(
      (a, b) => b.metrics.totalSignals.compareTo(a.metrics.totalSignals),
    );

    return WorkspaceFrictionReport(
      totals: totals.toMetrics(),
      messageCount: totalMessages,
      byConversation: perConversation,
    );
  },
);

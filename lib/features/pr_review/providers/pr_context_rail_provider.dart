import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Context data pre-loaded for a PR's right-rail panel.
class PrContextData {
  /// Creates [PrContextData].
  const PrContextData({
    required this.authorRecentPrs,
    required this.relatedMessages,
  });

  /// Up to 3 recent open PRs by the same author (excluding the current PR).
  final List<PullRequest> authorRecentPrs;

  /// Channel messages mentioning any of the PR's touched module paths.
  final List<({Channel channel, ChannelMessage message})> relatedMessages;
}

/// Provider for [PrContextData] for a given PR number.
final prContextRailProvider = FutureProvider.autoDispose
    .family<PrContextData, int>((ref, prNumber) async {
      final pr = await ref.watch(prDetailProvider(prNumber).future);
      if (pr == null) {
        return const PrContextData(authorRecentPrs: [], relatedMessages: []);
      }

      final authorLogin = pr.author?.login;

      // Author's recent PRs from the already-loaded list — no extra API call.
      final allPrData = ref.watch(prListDataProvider).value;
      final authorRecentPrs = <PullRequest>[];
      if (authorLogin != null && allPrData != null) {
        outer:
        for (final repo in allPrData.byRepo) {
          for (final p in repo.prs) {
            if (p.author?.login == authorLogin && p.number != prNumber) {
              authorRecentPrs.add(p);
              if (authorRecentPrs.length >= 3) {
                break outer;
              }
            }
          }
        }
      }

      final keywords = _extractKeywords(pr.title);

      // Scan loaded channel messages for keyword mentions (at most 5 results).
      final wsId = ref.watch(activeWorkspaceIdProvider);
      final channels = wsId != null
          ? ref.watch(workspaceChannelsProvider(wsId)).value ?? const []
          : ref.watch(channelsProvider).value ?? const [];
      final relatedMessages = <({Channel channel, ChannelMessage message})>[];
      outer:
      for (final channel in channels) {
        final messages =
            ref.watch(channelMessagesProvider(channel.id)).value ?? const [];
        final recent = messages.length > 100
            ? messages.sublist(messages.length - 100)
            : messages;
        for (var i = recent.length - 1; i >= 0; i--) {
          final msg = recent[i];
          final lower = msg.content.toLowerCase();
          if (keywords.any(lower.contains)) {
            relatedMessages.add((channel: channel, message: msg));
            if (relatedMessages.length >= 5) {
              break outer;
            }
          }
        }
      }

      return PrContextData(
        authorRecentPrs: authorRecentPrs,
        relatedMessages: relatedMessages,
      );
    });

/// Extracts meaningful keywords from a PR title — words ≥ 5 characters,
/// lower-cased, excluding very common developer stop-words.
List<String> _extractKeywords(String title) {
  const stopWords = {
    'update',
    'fixes',
    'added',
    'removes',
    'refactor',
    'chore',
    'tests',
    'merge',
    'branch',
    'initial',
    'cleanup',
    'feature',
    'bumps',
    'change',
    'changes',
    'improve',
    'revert',
  };
  return title
      .toLowerCase()
      .split(RegExp(r'[\s/\-_:()[\]{}.,]+'))
      .where((w) => w.length >= 5 && !stopWords.contains(w))
      .toSet()
      .take(5)
      .toList();
}

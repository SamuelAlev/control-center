import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/pr_thread_providers.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_remote/widgets/pr_detail/pr_conversation.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'pr_review_thread_card.dart';

/// Groups replies by their root comment, preferring the forge's thread ID.
/// A root outside the current page still gets its replies rendered.
List<List<PrCodeReviewComment>> groupReviewThreads(
  List<PrCodeReviewComment> comments,
) {
  final byId = {for (final c in comments) c.id: c};
  final rootById = <int, int>{};
  final threadIdByRoot = <int, String>{};
  for (final comment in comments) {
    var root = comment;
    final seen = <int>{comment.id};
    while (root.inReplyToId != null &&
        seen.add(root.inReplyToId!) &&
        byId.containsKey(root.inReplyToId)) {
      root = byId[root.inReplyToId]!;
    }
    rootById[comment.id] = root.id;
    if (comment.threadId != null) {
      threadIdByRoot[root.id] = comment.threadId!;
    }
  }
  final groups = <String, List<PrCodeReviewComment>>{};
  for (final comment in comments) {
    final rootId = rootById[comment.id]!;
    final key = threadIdByRoot[rootId] ?? 'comment:$rootId';
    groups.putIfAbsent(key, () => []).add(comment);
  }
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final threads = groups.values.toList();
  for (final thread in threads) {
    thread.sort(
      (a, b) => (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch),
    );
  }
  threads.sort(
    (a, b) =>
        (a.first.createdAt ?? epoch).compareTo(b.first.createdAt ?? epoch),
  );
  return threads;
}

/// All inline review conversations, including outdated files and anchors.
class PrReviewThreads extends ConsumerWidget {
  const PrReviewThreads({super.key, required this.coords, required this.pr});

  final PrCoords coords;
  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(prThreadCommentsProvider(coords));
    final comments = async.value;
    if (comments == null) {
      if (async.hasError) {
        return Column(
          children: [
            Text(
              l10n.mobilePrThreadsLoadFailed,
              style: TextStyle(color: t.textErrorPrimary),
            ),
            Text('${async.error}', style: TextStyle(color: t.textTertiary)),
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => ref.invalidate(prThreadCommentsProvider(coords)),
              child: Text(l10n.retry),
            ),
          ],
        );
      }
      return const Center(child: CcSpinner(size: 20));
    }
    final permission = ref.watch(prThreadPermissionProvider(coords));
    final canComment = permission.hasValue && permission.value != 'none';
    final repo = ref.watch(prRepoProvider(coords));
    final login = repo == null
        ? null
        : ref.watch(viewerLoginsProvider).value?[repo.forge];
    final isAuthor =
        login != null &&
        login.isNotEmpty &&
        pr.author?.login.toLowerCase() == login;
    final canResolve =
        permission.hasValue &&
        (permission.value == 'write' ||
            permission.value == 'admin' ||
            isAuthor);
    final threads = groupReviewThreads(comments);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mobilePrReviewThreads,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (permission.hasValue && permission.value == 'none')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.mobilePrCommentPermissionDenied,
              style: TextStyle(color: t.textTertiary),
            ),
          ),
        if (permission.hasError) ...[
          Text(
            '${permission.error}',
            style: TextStyle(color: t.textErrorPrimary),
          ),
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => ref.invalidate(prThreadPermissionProvider(coords)),
            child: Text(l10n.retry),
          ),
        ],
        if (async.hasError)
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => ref.invalidate(prThreadCommentsProvider(coords)),
            child: Text(l10n.retry),
          ),
        if (threads.isEmpty && !async.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.mobilePrNoReviewThreads,
              style: TextStyle(color: t.textTertiary),
            ),
          )
        else
          for (final thread in threads) ...[
            _ReviewThreadCard(
              key: ValueKey(thread.first.threadId ?? thread.first.id),
              coords: coords,
              comments: thread,
              canReply: canComment,
              canResolve: canResolve,
              permissionKnown: permission.hasValue,
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 12),
      ],
    );
  }
}

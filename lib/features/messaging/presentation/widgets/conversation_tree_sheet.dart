import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/conversation_tree_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigates a conversation's branches.
///
/// **What it is for.** Once a conversation is a tree, the path you are reading
/// is one of several and nothing on screen says so. This is the only surface
/// that shows the others — where the conversation forked, which path it is
/// currently on, and how to get back to one you left.
///
/// **It draws indentation, not a graph.** A conversation branches at a handful
/// of points, in a list people already read top to bottom; a node-and-edge
/// canvas would be a second navigation model to learn for something an indent
/// already says. Depth is the fork depth, so a straight conversation renders as
/// a flat list and looks like nothing changed.
class ConversationTreeSheet extends ConsumerWidget {
  /// Creates a [ConversationTreeSheet].
  const ConversationTreeSheet({
    required this.spaceId,
    required this.conversationId,
    super.key,
  });

  /// The space the conversation lives in.
  final String spaceId;

  /// The conversation whose tree this is.
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.ds;
    final tree = ref.watch(
      conversationTreeProvider((
        workspaceId: ref.requireWorkspaceId(),
        conversationId: conversationId,
      )),
    );

    return CcDialog(
      title: l10n.conversationTreeTitle,
      maxWidth: 640,
      content: SizedBox(
        width: 600,
        child: tree.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: CcSpinner(),
          ),
          error: (error, _) => Text(
            '$error',
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
          data: (data) => data.nodes.isEmpty
              ? Text(
                  l10n.conversationTreeEmpty,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.conversationTreeBranches(data.branchCount),
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final entry in _layout(data))
                              _TreeRow(
                                node: entry.node,
                                depth: entry.depth,
                                spaceId: spaceId,
                                conversationId: conversationId,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Orders the tree depth-first with a fork depth per node.
  ///
  /// Depth counts FORKS, not messages: a straight conversation is depth 0
  /// throughout and renders as the flat list it always was, so the navigator
  /// costs nothing to look at until there is actually something to navigate.
  static List<({ConversationTreeNode node, int depth})> _layout(
    ConversationTree tree,
  ) {
    final children = <String?, List<ConversationTreeNode>>{};
    for (final node in tree.nodes) {
      children.putIfAbsent(node.parentMessageId, () => []).add(node);
    }
    final out = <({ConversationTreeNode node, int depth})>[];
    void walk(String? parent, int depth) {
      final kids = children[parent] ?? const [];
      for (final kid in kids) {
        out.add((node: kid, depth: depth));
        // Only a real fork deepens the indent.
        walk(kid.messageId, kids.length > 1 ? depth + 1 : depth);
      }
    }

    walk(null, 0);
    return out;
  }
}

class _TreeRow extends ConsumerWidget {
  const _TreeRow({
    required this.node,
    required this.depth,
    required this.spaceId,
    required this.conversationId,
  });

  final ConversationTreeNode node;
  final int depth;
  final String spaceId;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.ds;
    final controller = ref.read(conversationBranchControllerProvider);
    final toast = CcToastScope.maybeOf(context);

    return Padding(
      padding: EdgeInsets.only(
        left: depth * AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      node.senderType,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppTimestamp.relative(node.createdAt),
                    if (node.onCurrentBranch) ...[
                      const SizedBox(width: AppSpacing.sm),
                      // Named rather than coloured: status by colour alone
                      // fails the accessibility bar, and "which path am I on"
                      // is the one thing this sheet exists to answer.
                      Text(
                        l10n.conversationTreeCurrent,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textBrandPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  node.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.body,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.ghost,
            onPressed: () async {
              await controller.continueFrom(
                conversationId: conversationId,
                messageId: node.messageId,
              );
              toast?.show(l10n.conversationTreeSwitched);
            },
            child: Text(l10n.conversationTreeSwitch),
          ),
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.ghost,
            onPressed: () async {
              await controller.fork(
                spaceId: spaceId,
                conversationId: conversationId,
                messageId: node.messageId,
              );
              toast?.show(
                l10n.conversationTreeForked,
                variant: CcToastVariant.success,
              );
            },
            child: Text(l10n.conversationTreeFork),
          ),
        ],
      ),
    );
  }
}

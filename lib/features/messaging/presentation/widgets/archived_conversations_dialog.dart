import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens the archive belonging to the specified workspace and space. Capture
/// the router here: the dialog lives in the root overlay, outside route scope.
Future<void> showArchivedConversationsDialog(
  BuildContext context, {
  required String workspaceId,
  required String spaceId,
}) {
  final router = GoRouter.of(context);
  return showCcDialog<void>(
    context: context,
    builder: (_) => ArchivedConversationsDialog(
      workspaceId: workspaceId,
      spaceId: spaceId,
      router: router,
    ),
  );
}

/// Archived streams in one space, with an action to reopen a stream's tab.
class ArchivedConversationsDialog extends ConsumerStatefulWidget {
  /// Creates a dialog for an already verified workspace and space.
  const ArchivedConversationsDialog({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.router,
  });

  /// Workspace resolved from the owning space's sidebar context.
  final String workspaceId;

  /// Space whose archived conversations are shown.
  final String spaceId;

  /// Router captured outside the root overlay.
  final GoRouter router;

  @override
  ConsumerState<ArchivedConversationsDialog> createState() =>
      _ArchivedConversationsDialogState();
}

class _ArchivedConversationsDialogState
    extends ConsumerState<ArchivedConversationsDialog> {
  String? _restoringId;
  Object? _restoreError;
  Completer<Object?>? _activeWatch;

  @override
  void dispose() {
    final waiting = _activeWatch;
    if (waiting != null && !waiting.isCompleted) {
      waiting.complete(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The overlay outlives route changes. Do not present (or act on) an old
    // workspace's archive after the operator changes workspaces.
    ref.listen(activeWorkspaceIdProvider, (_, current) {
      if (current != widget.workspaceId &&
          context.mounted &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    });
    final currentWorkspaceId = ref.watch(activeWorkspaceIdProvider);
    final conversations = currentWorkspaceId == widget.workspaceId
        ? ref.watch(spaceConversationsProvider(widget.spaceId))
        : const AsyncValue<List<Conversation>>.data([]);
    return CcDialog(
      title: l10n.archivedConversations,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            conversations.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CcSpinner()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.failedWithError('$error')),
              ),
              data: (all) {
                final archived = all
                    .where(
                      (conversation) =>
                          conversation.isArchived &&
                          conversation.workspaceId == widget.workspaceId &&
                          conversation.spaceId == widget.spaceId,
                    )
                    .toList();
                if (archived.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.archivedConversationsEmpty,
                      style: CcTypography.caption.copyWith(
                        color: context.designSystem?.textTertiary,
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final conversation in archived)
                        CcTile(
                          leadingIcon: AppIcons.archive,
                          title: conversationDisplayName(conversation, l10n),
                          trailing: CcIconButton(
                            icon: AppIcons.archiveRestore,
                            size: CcButtonSize.sm,
                            variant: CcButtonVariant.ghost,
                            tooltip: l10n.restoreConversation,
                            onPressed: _restoringId == null
                                ? () => unawaited(_restore(conversation))
                                : null,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (_restoreError case final error?)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 12),
                child: Text(l10n.failedWithError('$error')),
              ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _restore(Conversation conversation) async {
    if (_restoringId != null ||
        ref.read(activeWorkspaceIdProvider) != widget.workspaceId ||
        conversation.workspaceId != widget.workspaceId ||
        conversation.spaceId != widget.spaceId ||
        !conversation.isArchived) {
      return;
    }
    setState(() {
      _restoringId = conversation.id;
      _restoreError = null;
    });
    final restored = Completer<Object?>();
    _activeWatch = restored;
    void accept(AsyncValue<List<Conversation>> value) {
      if (restored.isCompleted) {
        return;
      }
      if (value.hasError) {
        restored.complete(value.error);
      } else if (value.asData?.value.any(
            (item) =>
                item.id == conversation.id &&
                item.workspaceId == widget.workspaceId &&
                item.spaceId == widget.spaceId &&
                !item.isArchived,
          ) ??
          false) {
        restored.complete(null);
      }
    }

    // Subscribe before mutating so a fast stream emission cannot slip past
    // the dialog. The editor only focuses active conversations.
    final subscription = ref.listenManual(
      spaceConversationsProvider(widget.spaceId),
      (_, next) => accept(next),
    );
    try {
      await ref
          .read(conversationRepositoryProvider)
          .setStatus(
            workspaceId: widget.workspaceId,
            conversationId: conversation.id,
            status: ConversationStatus.active,
          );
      if (!mounted ||
          ref.read(activeWorkspaceIdProvider) != widget.workspaceId) {
        return;
      }
      accept(ref.read(spaceConversationsProvider(widget.spaceId)));
      final error = await restored.future;
      if (error != null) {
        throw error;
      }
      if (mounted &&
          ref.read(activeWorkspaceIdProvider) == widget.workspaceId) {
        Navigator.of(context).pop();
        widget.router.go(
          spaceRoute(
            widget.workspaceId,
            widget.spaceId,
            tab: conversationTabKey(conversation.id),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _restoreError = error);
      }
    } finally {
      subscription.close();
      _activeWatch = null;
      if (mounted) {
        setState(() => _restoringId = null);
      }
    }
  }
}

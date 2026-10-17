import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_content.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Focused conversation progress. All subscriptions are scoped to the route's
/// workspace, space, and conversation rather than the standing conversation.
class ConversationProgressScreen extends ConsumerWidget {
  const ConversationProgressScreen({
    required this.spaceId,
    required this.conversationId,
    super.key,
  });

  final String spaceId;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspace = ref.watch(activeWorkspaceIdProvider);
    final workspaceId = workspace.value;
    final routeWorkspace = GoRouterState.of(
      context,
    ).uri.queryParameters['workspace_id'];
    final spaces = ref.watch(spacesProvider);
    final inSpace =
        workspaceId != null &&
        spaces.value?.any(
              (space) =>
                  space.id == spaceId && space.workspaceId == workspaceId,
            ) ==
            true;
    final scope = workspaceId == null
        ? null
        : (
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
          );
    final validRoute =
        routeWorkspace == workspaceId && inSpace && scope != null;
    final conversation = validRoute
        ? ref.watch(progressConversationProvider(scope))
        : null;

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            DetailHeader(title: l.progressTitle),
            Expanded(
              child:
                  workspace.isLoading ||
                      spaces.isLoading ||
                      (validRoute && conversation?.isLoading == true)
                  ? const Center(child: CcSpinner(size: 24))
                  : workspace.hasError ||
                        spaces.hasError ||
                        conversation?.hasError == true
                  ? CcEmptyState(
                      icon: AppIcons.triangleAlert,
                      message: l.progressLoadFailed,
                      description:
                          '${workspace.error ?? spaces.error ?? conversation?.error}',
                      action: CcButton(
                        size: CcButtonSize.lg,
                        onPressed: () {
                          ref.invalidate(activeWorkspaceIdProvider);
                          ref.invalidate(spacesProvider);
                          if (scope != null) {
                            ref.invalidate(progressConversationProvider(scope));
                          }
                        },
                        child: Text(l.retry),
                      ),
                    )
                  : !validRoute || conversation?.value == null
                  ? CcEmptyState(
                      icon: AppIcons.triangleAlert,
                      message: l.progressUnavailable,
                      description: l.progressUnavailableDescription,
                    )
                  : ProgressContent(
                      key: ValueKey(scope),
                      scope: scope,
                      space: spaces.value!.firstWhere(
                        (space) =>
                            space.id == spaceId &&
                            space.workspaceId == workspaceId,
                      ),
                      conversation: conversation!.value!,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

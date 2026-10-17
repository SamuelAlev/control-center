import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/requests_activity_providers.dart';
import 'package:cc_remote/widgets/activity/activity_item_card.dart';
import 'package:cc_remote/widgets/activity/activity_presentation.dart';
import 'package:cc_remote/widgets/plan_goal/confirm_operation.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The server's durable notification feed and the caller's per-item read state.
/// This is history, separate from actionable requests in the Inbox.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  bool _working = false;
  String? _error;

  Future<bool> _run(
    Future<void> Function(ActivityActions) action, {
    String? itemWorkspaceId,
  }) async {
    if (_working) return false;
    final scope = ref.read(activityActionsProvider);
    if (scope == null) {
      setState(() => _error = AppLocalizations.of(context).requestUnavailable);
      return false;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      if (scope.workspaceId != ref.read(activeWorkspaceIdProvider).value ||
          (itemWorkspaceId != null && itemWorkspaceId != scope.workspaceId)) {
        throw StateError(AppLocalizations.of(context).requestUnavailable);
      }
      await action(scope);
      return mounted &&
          scope.workspaceId == ref.read(activeWorkspaceIdProvider).value;
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
      return false;
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _markAll() async {
    final scope = ref.read(activityActionsProvider);
    if (scope == null) return;
    final l = AppLocalizations.of(context);
    if (!await confirmOperation(
      context,
      title: l.activityMarkAllRead,
      description: l.activityMarkAllConfirm,
      action: l.activityMarkAllRead,
    )) {
      return;
    }
    if (!mounted ||
        scope.workspaceId != ref.read(activeWorkspaceIdProvider).value) {
      return;
    }
    await _run((actions) async {
      if (actions.workspaceId != scope.workspaceId) {
        throw StateError(l.requestUnavailable);
      }
      await actions.markAll();
    });
  }

  Future<void> _clear() async {
    final scope = ref.read(activityActionsProvider);
    if (scope == null) return;
    final l = AppLocalizations.of(context);
    if (!await confirmOperation(
      context,
      title: l.activityClearAll,
      description: l.activityClearConfirm,
      action: l.activityClearAll,
      destructive: true,
    )) {
      return;
    }
    if (!mounted ||
        scope.workspaceId != ref.read(activeWorkspaceIdProvider).value) {
      return;
    }
    await _run((actions) async {
      if (actions.workspaceId != scope.workspaceId) {
        throw StateError(l.requestUnavailable);
      }
      await actions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final feed = ref.watch(activityFeedProvider);
    final mark = ref.watch(activityReadMarkProvider);
    final states = ref.watch(activityItemStatesProvider);
    final entries = ref.watch(activityEntriesProvider);
    final repos = ref.watch(workspaceReposProvider).value ?? const <Repo>[];
    final unread = ref.watch(unreadActivityCountProvider);
    final loading = feed.isLoading || mark.isLoading || states.isLoading;
    final failure = feed.error ?? mark.error ?? states.error;
    return ColoredBox(
      color: t.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                PhoneIconButton(
                  icon: AppIcons.arrowLeft,
                  semanticLabel: l.back,
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/inbox'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.activityTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                if (entries.isNotEmpty)
                  CcButton(
                    size: CcButtonSize.lg,
                    variant: CcButtonVariant.ghost,
                    onPressed: _working || unread == 0 ? null : _markAll,
                    child: Text(l.activityMarkAllRead),
                  ),
              ],
            ),
          ),
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 16,
                end: 16,
                bottom: 8,
              ),
              child: CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.secondary,
                fullWidth: true,
                onPressed: _working ? null : _clear,
                child: Text(l.activityClearAll),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: TextStyle(color: t.textErrorPrimary)),
            ),
          Expanded(
            child: loading
                ? const Center(child: CcSpinner(size: 24))
                : failure != null
                ? CcEmptyState(
                    icon: AppIcons.triangleAlert,
                    message: l.activityLoadFailed,
                    description: '$failure',
                  )
                : entries.isEmpty
                ? CcEmptyState(icon: AppIcons.inbox, message: l.activityEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final item = entry.item;
                      final destination = activityDestination(item, repos);
                      return ActivityItemCard(
                        item: item,
                        read: entry.read,
                        working: _working,
                        onOpen: destination == null
                            ? null
                            : () async {
                                if (!entry.read &&
                                    !await _run(
                                      (actions) =>
                                          actions.read(item.id, value: true),
                                      itemWorkspaceId: item.workspaceId,
                                    )) {
                                  return;
                                }
                                if (context.mounted) {
                                  await context.push(destination);
                                }
                              },
                        onToggleRead: () => _run(
                          (actions) =>
                              actions.read(item.id, value: !entry.read),
                          itemWorkspaceId: item.workspaceId,
                        ),
                        onDismiss: () => _run(
                          (actions) => actions.dismiss(item.id),
                          itemWorkspaceId: item.workspaceId,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

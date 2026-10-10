part of 'conversations_sidebar_section.dart';

/// Opens the archived-spaces dialog (the trigger left of the sidebar's `+`):
/// every archived space of the current workspace, most-recently-archived
/// first. Restore returns a space to the sidebar and opens it; the per-row
/// delete is the one remaining path to permanent deletion, behind a
/// confirmation — archiving itself never destroys anything.
Future<void> showArchivedSpacesDialog(BuildContext context) {
  // Resolved in the SIDEBAR's context, under the router: the dialog mounts in
  // the root overlay, where `GoRouterState.of` — and so `currentWorkspaceId` —
  // has no route above it (same reason [showNewSpaceDialog] reads the id
  // before opening).
  final workspaceId = routeWorkspaceIdOf(context)!;
  final router = GoRouter.of(context);
  return showCcDialog<void>(
    context: context,
    builder: (_) =>
        _ArchivedSpacesDialog(workspaceId: workspaceId, router: router),
  );
}

class _ArchivedSpacesDialog extends ConsumerWidget {
  const _ArchivedSpacesDialog({
    required this.workspaceId,
    required this.router,
  });

  /// The workspace whose archived spaces are listed (resolved by the caller,
  /// never from the dialog's overlay context).
  final String workspaceId;

  /// The app's router, captured by the caller for the same reason — restore
  /// navigates to the reopened space.
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final archived = ref.watch(archivedSpacesProvider(workspaceId));
    return CcDialog(
      title: l10n.archivedSpaces,
      content: SizedBox(
        width: 360,
        child: archived.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.archivedSpacesEmpty,
                  style: CcTypography.caption.copyWith(
                    color: context.designSystem?.textTertiary,
                  ),
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final space in archived)
                      CcTile(
                        leadingIcon: AppIcons.archive,
                        title: space.name.isNotEmpty
                            ? space.name
                            : l10n.spaceLabel,
                        subtitle: Text(
                          l10n.archivedWhen(
                            formatRelativeTime(context, space.archivedAt),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CcIconButton(
                              icon: AppIcons.archiveRestore,
                              size: CcButtonSize.sm,
                              variant: CcButtonVariant.ghost,
                              tooltip: l10n.restoreSpace,
                              onPressed: () =>
                                  unawaited(_restore(context, ref, space)),
                            ),
                            CcIconButton(
                              icon: AppIcons.trash2,
                              size: CcButtonSize.sm,
                              variant: CcButtonVariant.ghost,
                              tooltip: l10n.deleteSpacePermanently,
                              onPressed: () => unawaited(
                                _confirmDeletePermanently(context, ref, space),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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

  /// Restores [space] to the sidebar and opens it — the visible proof the
  /// archive kept everything (messages, participants, worktrees) intact.
  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Space space,
  ) async {
    await ref
        .read(messagingServiceProvider)
        .unarchiveSpace(workspaceId, space.id);
    if (context.mounted) {
      Navigator.of(context).pop();
      router.go(spaceRoute(workspaceId, space.id));
    }
  }

  Future<void> _confirmDeletePermanently(
    BuildContext context,
    WidgetRef ref,
    Space space,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteSpace,
        content: Text(l10n.deleteSpaceConfirm),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(messagingServiceProvider).deleteSpace(workspaceId, space.id);
    // No navigation handling: the row drops out of the dialog's watched list
    // on its own, and an archived space cannot be the open route space.
  }
}

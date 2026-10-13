import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_route_selection.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_folder_providers.dart';
import 'package:control_center/features/messaging/providers/space_merge_archive_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// An actionable notice on the open space, independent of its selected IDE tab.
class MergedSpaceArchivePrompt extends ConsumerStatefulWidget {
  /// Creates the notice for an explicitly scoped space.
  const MergedSpaceArchivePrompt({
    super.key,
    required this.workspaceId,
    required this.spaceId,
  });

  /// Workspace owning the open space.
  final String workspaceId;

  /// The open space, not an implicitly selected conversation.
  final String spaceId;

  @override
  ConsumerState<MergedSpaceArchivePrompt> createState() =>
      _MergedSpaceArchivePromptState();
}

class _MergedSpaceArchivePromptState
    extends ConsumerState<MergedSpaceArchivePrompt> {
  bool _busy = false;
  Object? _error;

  SpaceMergeArchiveKey get _space =>
      (workspaceId: widget.workspaceId, spaceId: widget.spaceId);

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(
      workspaceSpacesProvider(widget.workspaceId).select(
        (spaces) =>
            spaces.value?.any(
              (space) =>
                  space.id == widget.spaceId &&
                  space.workspaceId == widget.workspaceId &&
                  !space.isArchived,
            ) ??
            false,
      ),
    );
    final allMerged = ref.watch(spaceAllPrsMergedProvider(widget.spaceId));
    final choice = ref.watch(spaceMergeArchiveChoiceProvider(_space));
    if (!active ||
        !allMerged ||
        !choice.hasValue ||
        choice.hasError ||
        choice.requireValue != null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: MergedSpaceArchiveNotice(
        onArchive: _busy
            ? null
            : () => unawaited(_respond(SpaceMergeArchiveChoice.archive)),
        onKeep: _busy
            ? null
            : () => unawaited(_respond(SpaceMergeArchiveChoice.keep)),
        error: _error,
      ),
    );
  }

  Future<void> _respond(SpaceMergeArchiveChoice choice) async {
    if (_busy) {
      return;
    }
    final key = _space;
    final decisions = ref.read(spaceMergeArchiveChoiceProvider(key).notifier);
    final router = GoRouter.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (choice == SpaceMergeArchiveChoice.archive) {
        await archiveSpaceAndUnlink(ref, key.workspaceId, key.spaceId);
      }
      await decisions.choose(choice);
      // Archiving may unmount the prompt. Never redirect a newer selection.
      if (choice == SpaceMergeArchiveChoice.archive &&
          selectedSpaceIdFromLocation(
                router.routeInformationProvider.value.uri.path,
                key.workspaceId,
              ) ==
              key.spaceId) {
        router.go(spacesRoute(key.workspaceId));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

/// The shared notice surface, also rendered by interactive widget previews.
class MergedSpaceArchiveNotice extends StatelessWidget {
  /// Creates the notice; null callbacks disable actions while saving.
  const MergedSpaceArchiveNotice({
    super.key,
    required this.onArchive,
    required this.onKeep,
    this.error,
  });

  /// Archives the space through its existing soft-archive action.
  final VoidCallback? onArchive;

  /// Records a durable decline, without changing the space itself.
  final VoidCallback? onKeep;

  /// A failed action stays visible and can be retried.
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcAlert(
      title: l10n.spaceAllPrsMerged,
      icon: AppIcons.gitMerge,
      description: error == null ? null : Text(l10n.errorWithDetail('$error')),
      action: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          CcButton(
            onPressed: onArchive,
            icon: AppIcons.archive,
            child: Text(l10n.archiveSpace),
          ),
          CcTooltip(
            message: l10n.spaceKeepAfterMergeHint,
            child: CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: onKeep,
              child: Text(l10n.spaceKeepAfterMerge),
            ),
          ),
        ],
      ),
    );
  }
}

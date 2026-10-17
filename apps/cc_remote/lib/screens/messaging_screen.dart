import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/space_folders.dart';
import 'package:cc_remote/space_management_providers.dart';
import 'package:cc_remote/widgets/messaging/space_folder_rows.dart';
import 'package:cc_remote/widgets/messaging/space_folders_list.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Live, workspace-scoped spaces with personal folder arrangement preserved.
class MessagingScreen extends ConsumerStatefulWidget {
  const MessagingScreen({super.key});

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  String _query = '';
  bool _archived = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
    final role = ref.watch(workspaceRoleProvider).value;
    final spaces = ref.watch(spacesProvider);
    final prefs = ref.watch(ownServerPrefsProvider);
    final activities = workspaceId == null
        ? const AsyncValue<List<SpaceActivity>>.loading()
        : ref.watch(remoteSpaceActivityProvider(workspaceId));
    final reads = workspaceId == null
        ? const AsyncValue<Map<String, DateTime>>.loading()
        : ref.watch(remoteSpaceReadProvider(workspaceId));
    final running = workspaceId == null
        ? const AsyncValue<Set<String>>.loading()
        : ref.watch(remoteRunningSpacesProvider(workspaceId));

    return ColoredBox(
      color: t.canvas,
      child: workspaceId == null
          ? const Center(child: CcSpinner(size: 24))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (role?.canWrite == true) ...[
                        CcButton(
                          size: CcButtonSize.lg,
                          icon: AppIcons.plus,
                          onPressed: () => context.push(
                            remoteWorkspaceLocation('/spaces/new', workspaceId),
                          ),
                          child: Text(l10n.mobileSpacesNew),
                        ),
                        const SizedBox(height: 12),
                      ],
                      CcTextField(
                        label: l10n.mobileSpacesSearch,
                        onChanged: (value) =>
                            setState(() => _query = value.trim().toLowerCase()),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CcButton(
                              size: CcButtonSize.lg,
                              variant: _archived
                                  ? CcButtonVariant.secondary
                                  : CcButtonVariant.primary,
                              onPressed: () =>
                                  setState(() => _archived = false),
                              child: Text(l10n.mobileSpacesActive),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CcButton(
                              size: CcButtonSize.lg,
                              variant: _archived
                                  ? CcButtonVariant.primary
                                  : CcButtonVariant.secondary,
                              onPressed: () => setState(() => _archived = true),
                              child: Text(l10n.mobileSpacesArchived),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (activities.hasError || reads.hasError || running.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CcAlert(
                      variant: CcAlertVariant.danger,
                      title: l10n.mobileSpacesOperationFailed,
                      action: CcButton(
                        size: CcButtonSize.sm,
                        onPressed: () {
                          ref.invalidate(
                            remoteSpaceActivityProvider(workspaceId),
                          );
                          ref.invalidate(remoteSpaceReadProvider(workspaceId));
                          ref.invalidate(
                            remoteRunningSpacesProvider(workspaceId),
                          );
                        },
                        child: Text(l10n.mobileSpacesRetry),
                      ),
                    ),
                  ),
                Expanded(
                  child: spaces.when(
                    loading: () => const Center(child: CcSpinner(size: 24)),
                    error: (e, _) => Column(
                      children: [
                        Expanded(
                          child: CcEmptyState(
                            icon: AppIcons.triangleAlert,
                            message: l10n.spacesLoadFailed,
                            description: e.toString(),
                          ),
                        ),
                        CcButton(
                          size: CcButtonSize.lg,
                          onPressed: () => ref.invalidate(spacesProvider),
                          child: Text(l10n.mobileSpacesRetry),
                        ),
                      ],
                    ),
                    data: (items) {
                      final visible = [
                        for (final space in items)
                          if (space.workspaceId == workspaceId &&
                              (space.archivedAt != null) == _archived &&
                              space.name.toLowerCase().contains(_query))
                            space,
                      ];
                      if (_archived) {
                        return visible.isEmpty
                            ? CcEmptyState(
                                icon: AppIcons.folder,
                                message: _query.isEmpty
                                    ? l10n.mobileSpacesArchivedEmpty
                                    : l10n.mobileSpacesNoMatches,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: visible.length,
                                itemBuilder: (context, index) =>
                                    RemoteSpaceCard(
                                      space: visible[index],
                                      workspaceId: workspaceId,
                                      inFolder: false,
                                      showMove: false,
                                      onMove: () {},
                                    ),
                              );
                      }
                      if (_query.isNotEmpty && visible.isEmpty) {
                        return CcEmptyState(
                          icon: AppIcons.hash,
                          message: l10n.mobileSpacesNoMatches,
                        );
                      }
                      return prefs.when(
                        loading: () => const Center(child: CcSpinner(size: 24)),
                        error: (e, _) => Column(
                          children: [
                            Expanded(
                              child: CcEmptyState(
                                icon: AppIcons.triangleAlert,
                                message: l10n.spacesLoadFailed,
                                description: e.toString(),
                              ),
                            ),
                            CcButton(
                              size: CcButtonSize.lg,
                              onPressed: () =>
                                  ref.invalidate(ownServerPrefsProvider),
                              child: Text(l10n.mobileSpacesRetry),
                            ),
                          ],
                        ),
                        data: (_) => RemoteSpaceFoldersList(
                          key: ValueKey(workspaceId),
                          workspaceId: workspaceId,
                          spaces: visible,
                          folders: ref.watch(spaceFoldersProvider(workspaceId)),
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

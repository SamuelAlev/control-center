import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/import_hold_entry.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/import_hold_wording.dart';
import 'package:control_center/features/settings/providers/backup_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Backup & restore: the grants restored copies carried,
/// waiting for the server owner.
///
/// A restored file is somebody's bytes, not authority, so the server strips
/// every grant it carried (allow rules, sandbox exec grants, elevated roles
/// and repository grants, invites to them) and keeps each here. The page
/// shows this card only while [heldGrantsProvider] has something, which is
/// only ever for the server owner.
class ImportHoldsSection extends ConsumerWidget {
  /// Creates the section.
  const ImportHoldsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final held = ref.watch(heldGrantsProvider);
    if (held.isEmpty) {
      return const SizedBox.shrink();
    }
    final users = ref.watch(usersByIdProvider).value ?? const {};

    return SectionCard(
      label: l10n.importHoldsLabel,
      count: held.fold<int>(0, (sum, group) => sum + group.holds.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.importHoldsExplainer,
            style: CcTypography.bodySm.copyWith(color: tokens.textTertiary),
          ),
          for (final group in held)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg),
              child: SettingsGroup(
                title: group.workspace.name,
                separator: SettingsGroupSeparator.rule,
                gap: 0,
                children: [
                  if (group.error case final error?)
                    Text(
                      failureMessage(l10n, error),
                      style: CcTypography.caption.copyWith(
                        color: tokens.textErrorPrimary,
                      ),
                    ),
                  for (final hold in group.holds)
                    ImportHoldEntry(
                      key: ValueKey(hold.id),
                      workspaceId: group.workspace.id,
                      hold: hold,
                      sentence: importHoldSentence(l10n, hold, (
                        person: (id) => switch (users[id]) {
                          final user? when user.displayName.isNotEmpty =>
                            user.displayName,
                          final user? when user.handle.isNotEmpty =>
                            user.handle,
                          _ => null,
                        },
                        repo: (id) => _repoName(ref, group.workspace.id, id),
                      )),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The name of [repoId] among [workspaceId]'s linked repositories, when
  /// the client has them.
  static String? _repoName(WidgetRef ref, String workspaceId, String repoId) {
    final repos =
        ref.watch(reposForWorkspaceProvider(workspaceId)).value ??
        const <Repo>[];
    for (final repo in repos) {
      if (repo.id == repoId) {
        return repo.name;
      }
    }
    return null;
  }
}

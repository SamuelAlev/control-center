import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The repository list's empty state: no repos in this workspace yet.
///
/// Someone who may not add one (adding browses the server's folders, which
/// only its owner may do) is told who can, instead of how.
class ReposEmptyState extends StatelessWidget {
  /// Creates a [ReposEmptyState].
  const ReposEmptyState({super.key, this.canAdd = true});

  /// Whether the reader may add a repository here.
  final bool canAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.gitBranch, size: 32, color: tokens.fgTertiary),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).noReposInWorkspaceYet,
              style: CcTypography.body.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              canAdd
                  ? AppLocalizations.of(context).addLocalCheckoutDescription
                  : AppLocalizations.of(context).reposEmptyAskOwner,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings → Repositories with no active workspace to list repos for.
class ReposNoWorkspaceState extends StatelessWidget {
  /// Creates a [ReposNoWorkspaceState].
  const ReposNoWorkspaceState({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.layoutGrid, size: 32, color: tokens.fgTertiary),
            const SizedBox(height: 12),
            Text(
              l10n.noActiveWorkspaceCreate,
              style: CcTypography.body.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.createOrSelectWorkspace,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

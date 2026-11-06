import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why a terminal opened by itself: a start stopped for a person, and this is
/// where it finishes.
///
/// Follows the environment rather than the tab, so it goes once the start has
/// carried on and stays away from a tab restored after that.
class EnvironmentSetupBanner extends ConsumerWidget {
  /// Creates an [EnvironmentSetupBanner].
  const EnvironmentSetupBanner({
    super.key,
    required this.workspaceId,
    required this.spaceId,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The terminal's space.
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(
      spaceEnvironmentProvider((workspaceId: workspaceId, spaceId: spaceId)),
    );
    final error = environment?.lastError;
    if (environment?.status != EnvironmentStatus.failed ||
        error == null ||
        !error.needsHostSetup) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SizedBox(
        width: double.infinity,
        child: CcAlert(
          variant: CcAlertVariant.warning,
          title: l10n.environmentSetupTabReason,
          description: Text('${error.message}\n${l10n.environmentSetupHint}'),
        ),
      ),
    );
  }
}

/// A one-line note on a terminal that started before its space's environment.
///
/// The server hands a shell the environment's variables when it spawns, so
/// such a terminal has none of them: `docker compose ps` there targets nothing.
/// The fix is a fresh shell, which [onOpenFresh] opens.
class EnvironmentTerminalBanner extends ConsumerWidget {
  /// Creates an [EnvironmentTerminalBanner].
  const EnvironmentTerminalBanner({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.startedAt,
    required this.onOpenFresh,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The terminal's space.
  final String spaceId;

  /// When the shell started, or null before it has.
  final DateTime? startedAt;

  /// Opens a new terminal in the same space.
  final VoidCallback onOpenFresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final started = startedAt;
    if (started == null || workspaceId.isEmpty || spaceId.isEmpty) {
      return const SizedBox.shrink();
    }
    final environment = ref.watch(
      spaceEnvironmentProvider((workspaceId: workspaceId, spaceId: spaceId)),
    );
    if (environment == null || !environment.createdAt.isAfter(started)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        end: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        border: Border(bottom: BorderSide(color: t.borderSecondary)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.environmentTerminalStale,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: onOpenFresh,
            child: Text(l10n.environmentTerminalFresh),
          ),
        ],
      ),
    );
  }
}

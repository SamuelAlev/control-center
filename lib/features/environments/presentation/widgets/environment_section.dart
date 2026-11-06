import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_controls.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_live_panel.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_start.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A space's environment: one row per component rather than one status for the
/// whole stack.
///
/// Absent when the space has nothing it could start, so a repo with no
/// definition costs the sidebar nothing, and absent in a demo, which has no
/// execution surface.
class EnvironmentSection extends ConsumerWidget {
  /// Creates an [EnvironmentSection].
  const EnvironmentSection({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    this.onOpenPanel,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The space whose environment this shows.
  final String spaceId;

  /// Opens the full Environment panel, when the surface has one.
  final VoidCallback? onOpenPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isDemoServerProvider)) {
      return const SizedBox.shrink();
    }
    final key = (workspaceId: workspaceId, spaceId: spaceId);
    final eligibleAsync = ref.watch(eligibleDefinitionsProvider(key));
    if (eligibleAsync.error is EnvironmentsUnsupported ||
        ref.watch(spaceEnvironmentsProvider(key)).error
            is EnvironmentsUnsupported) {
      return EnvironmentSectionShell(
        onOpenPanel: onOpenPanel,
        child: const EnvironmentsUnsupportedNote(),
      );
    }
    final environment = ref.watch(spaceEnvironmentProvider(key));
    final eligible =
        eligibleAsync.value ?? const <EnvironmentDefinitionRecord>[];
    if (environment == null && eligible.isEmpty) {
      return const SizedBox.shrink();
    }
    final starting = ref
        .watch(environmentActionsProvider(key))
        .contains('start');
    return EnvironmentSectionShell(
      environment: environment,
      spaceKey: key,
      onOpenPanel: onOpenPanel,
      child: environment == null
          ? EnvironmentStartPanel(
              definitions: eligible,
              onStart: (context, definitionId, options) => forwardEnsure(
                context,
                ref,
                key,
                definitionId: definitionId,
                options: options,
              ),
              workspaceId: workspaceId,
              busy: starting,
            )
          : EnvironmentLivePanel(spaceKey: key, environment: environment),
    );
  }
}

/// The one notice a server without environments gets, in place of raw errors.
class EnvironmentsUnsupportedNote extends StatelessWidget {
  /// Creates an [EnvironmentsUnsupportedNote].
  const EnvironmentsUnsupportedNote({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      AppLocalizations.of(context).environmentsUnsupported,
      style: CcTypography.caption.copyWith(color: t.textTertiary),
    );
  }
}

/// The collapsible shell every environment body sits in.
class EnvironmentSectionShell extends StatelessWidget {
  /// Creates an [EnvironmentSectionShell].
  const EnvironmentSectionShell({
    super.key,
    required this.child,
    this.environment,
    this.spaceKey,
    this.onOpenPanel,
  });

  /// Opens the full Environment panel, when the surface has one.
  final VoidCallback? onOpenPanel;

  /// The running environment, when there is one to offer actions on.
  final SpaceEnvironment? environment;

  /// The space acted on.
  final EnvironmentSpaceKey? spaceKey;

  /// The body.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final environment = this.environment;
    final spaceKey = this.spaceKey;
    return CollapsibleSidebarSection(
      icon: AppIcons.boxes,
      label: AppLocalizations.of(context).environmentSectionTitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onOpenPanel != null)
            CcIconButton(
              icon: AppIcons.maximize2,
              size: CcButtonSize.sm,
              tooltip: AppLocalizations.of(context).environmentOpenPanel,
              onPressed: onOpenPanel,
            ),
          if (environment != null && spaceKey != null)
            EnvironmentOverflowMenu(
              spaceKey: spaceKey,
              environment: environment,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: child,
      ),
    );
  }
}

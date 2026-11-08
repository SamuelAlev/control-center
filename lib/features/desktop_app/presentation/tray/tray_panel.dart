import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_actions.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_header.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_needs_you.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_rows.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_spaces.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_usage.dart';
import 'package:control_center/features/desktop_app/providers/tray_status_providers.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tray panel: where the workspace stands, at a glance, without the app.
///
/// Header (the workspace switcher and one status line), what waits on the
/// operator, the spaces with their live conversations, plan usage, and the
/// app's quick actions. Everything opens the main window on the right page.
class TrayPanel extends ConsumerStatefulWidget {
  /// Creates a [TrayPanel].
  const TrayPanel({super.key});

  @override
  ConsumerState<TrayPanel> createState() => _TrayPanelState();
}

class _TrayPanelState extends ConsumerState<TrayPanel> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fresh numbers each time it opens, as the title-bar pill does; the last
    // reading stays up while the fetch runs.
    unawaited(ref.read(subscriptionUsageProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(trayStatusProvider);
    final workspaceId = status.workspaceId;
    // macOS draws the panel's rounded edge and shadow itself; elsewhere the
    // window is a plain rectangle and needs the hairline to sit off the
    // desktop behind it.
    final hairline = defaultTargetPlatform != TargetPlatform.macOS;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.panel,
        border: hairline ? Border.all(color: t.borderSecondary) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrayPanelHeader(status: status),
          CcDivider(color: t.borderSecondary),
          Expanded(
            child: CcScrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (workspaceId == null)
                      TrayPanelNote(text: l10n.trayPanelNoWorkspace)
                    else ...[
                      TrayNeedsYouSection(status: status),
                      TraySpacesSection(
                        workspaceId: workspaceId,
                        status: status,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Pinned rather than scrolled: how much room is left is the one
          // reading that should never sit below the fold.
          TrayUsageSection(workspaceId: workspaceId),
          CcDivider(color: t.borderSecondary),
          const _Footer(),
        ],
      ),
    );
  }
}

/// Opening the app, a focus session and the settings. Quitting stays in the
/// icon's menu, a deliberate right-click away from the panel's clicks.
class _Footer extends ConsumerWidget {
  const _Footer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final actions = TrayPanelScope.of(context);
    final focus = ref.watch(focusModeProvider);
    void toggleFocus() =>
        unawaited(ref.read(focusModeProvider.notifier).toggle());
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              fullWidth: true,
              icon: AppIcons.appWindow,
              onPressed: actions.openApp,
              child: Text(l10n.trayPanelOpenApp),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // During a session the glyph gives way to the minutes left, in
          // the accent, as the sidebar's focus entry does: the panel's one
          // accent.
          if (focus.active)
            CcTooltip(
              message: l10n.focusModeEnd,
              child: CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                semanticLabel: l10n.focusModeRemaining(focus.minutesRemaining),
                onPressed: toggleFocus,
                child: Text(
                  l10n.focusModeRemaining(focus.minutesRemaining),
                  maxLines: 1,
                  style: CcTypography.caption.copyWith(
                    color: t.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            CcIconButton(
              icon: AppIcons.focus,
              size: CcButtonSize.sm,
              tooltip: l10n.focusModeStart,
              onPressed: toggleFocus,
            ),
          CcIconButton(
            icon: AppIcons.settings,
            size: CcButtonSize.sm,
            tooltip: l10n.trayPanelSettings,
            onPressed: actions.openSettings,
          ),
        ],
      ),
    );
  }
}

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/update/desktop_update_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The manual update action and status shown in Settings → About.
class DesktopUpdateAction extends ConsumerWidget {
  /// Creates the update action in the surrounding provider scope.
  const DesktopUpdateAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final update = ref.watch(desktopUpdateProvider);
    final tokens = context.designSystem;
    final checking = update.status == DesktopUpdateStatus.checking;
    final message = switch (update.status) {
      DesktopUpdateStatus.idle => null,
      DesktopUpdateStatus.checking => l10n.updateChecking,
      DesktopUpdateStatus.available =>
        update.version == null
            ? null
            : l10n.updateAvailableVersion(update.version!),
      DesktopUpdateStatus.upToDate => l10n.updateUpToDate,
      DesktopUpdateStatus.deferred => l10n.updateDeferredBusy,
      DesktopUpdateStatus.openedReleasesPage => l10n.updateOpenedReleasesPage,
      DesktopUpdateStatus.error =>
        update.errorMessage ?? l10n.updateCheckFailed,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcButton(
          onPressed: checking
              ? null
              : () => ref.read(desktopUpdateProvider.notifier).checkNow(),
          loading: checking,
          variant: CcButtonVariant.secondary,
          child: Text(l10n.updateCheckButton),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: CcTypography.bodySm.copyWith(color: tokens?.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

/// Interactive preview of the manual update control in Settings → About.
@Preview(name: 'Desktop update', group: 'Settings', size: Size(390, 160))
Widget desktopUpdateActionPreview() {
  final theme = CcThemeData.light();
  return ProviderScope(
    child: CcTheme(
      data: theme,
      child: WidgetsApp(
        color: theme.tokens.bgPrimary,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        textStyle: CcFonts.ui(textStyle: CcTypography.body).copyWith(
          color: theme.tokens.textPrimary,
          decoration: TextDecoration.none,
        ),
        builder: (context, _) => ColoredBox(
          color: theme.tokens.bgPrimary,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: DesktopUpdateAction(),
            ),
          ),
        ),
      ),
    ),
  );
}

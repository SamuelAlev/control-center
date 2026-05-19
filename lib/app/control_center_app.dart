import 'package:cc_ui/cc_ui.dart' show CcTheme, CcThemeData, CcToastScope;
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/rpc_client_workspace_sync_provider.dart';
import 'package:control_center/core/theme/app_theme.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_workspace_chip.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_url_sync_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/app_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget: the global shortcut layer wrapping
/// `MaterialApp.router`, the design-system theme channel and the app-wide toast
/// overlay.
///
/// Web-safe by construction — it depends only on Flutter, Riverpod and app
/// providers, never on the internal windowing library or nativeapi. The desktop
/// multi-window root (`AppWindows`) wraps this in a `RegularWindow`; the web
/// bootstrap renders it directly into the single browser view.
class ControlCenterApp extends ConsumerWidget {
  /// Creates the root application widget.
  const ControlCenterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep the URL → active-workspace sync alive for the app's lifetime so the
    // route's `:workspaceId` stays the source of truth for workspace context.
    ref.watch(workspaceUrlSyncProvider);
    // Keep the active workspace mirrored onto the RPC client so every stateless
    // request carries the right `workspace_id` (the server holds no workspace).
    ref.watch(rpcClientWorkspaceSyncProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localeOverride = ref.watch(localeProvider);
    final fontSettings = ref.watch(fontSettingsProvider);
    final appFontFamily = fontSettings.appFontSelection.family;

    return AppShortcuts(
      commandBuilder: buildGlobalCommands,
      onToggleWorkspaceSwitcher: () {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) {
          toggleWorkspaceSwitcher(ctx);
        }
      },
      onCycleWorkspace: (delta) {
        final workspaces = ref.read(workspacesProvider).value ?? const [];
        if (workspaces.length < 2) {
          return;
        }
        final currentId = ref.read(activeWorkspaceIdProvider);
        final currentIndex = workspaces.indexWhere((w) => w.id == currentId);
        final base = currentIndex < 0 ? 0 : currentIndex;
        var nextIndex = (base + delta) % workspaces.length;
        if (nextIndex < 0) {
          nextIndex += workspaces.length;
        }
        // Switching workspaces is a navigation: the URL drives the active id.
        ref.read(routerProvider).go(dashboardRoute(workspaces[nextIndex].id));
      },
      onSelectWorkspaceByIndex: (index) {
        final workspaces = ref.read(workspacesProvider).value ?? const [];
        if (index < 0 || index >= workspaces.length) {
          return;
        }
        ref.read(routerProvider).go(dashboardRoute(workspaces[index].id));
      },
      onToggleFocusMode: () {
        ref.read(focusModeProvider.notifier).toggle();
      },
      child: MaterialApp.router(
        title: 'Control Center',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.light(appFontFamily: appFontFamily),
        darkTheme: AppTheme.dark(appFontFamily: appFontFamily),
        themeMode: themeMode,
        locale: localeOverride,
        supportedLocales: [
          ...AppLocalizations.supportedLocales,
          const Locale('en', 'US'),
          const Locale('fr', 'FR'),
          const Locale('es', 'ES'),
          const Locale('it', 'IT'),
          const Locale('de', 'DE'),
          const Locale('pt', 'BR'),
          const Locale('nl', 'NL'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          // CcTheme is the purist token-delivery channel (replacing the Material
          // ThemeExtension). It wraps the whole navigator so every route and
          // overlay can resolve `context.designSystem`. CcToastScope hosts the
          // app-wide toast overlay — it needs an Overlay ancestor to insert
          // into, and `MaterialApp.builder` sits *above* the router's own
          // overlay, so we provide a root Overlay here for it to mount toasts on
          // top of every route.
          return CcTheme(
            data: isDark
                ? CcThemeData.dark(fontFamily: appFontFamily)
                : CcThemeData.light(fontFamily: appFontFamily),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) =>
                      CcToastScope(child: child ?? const SizedBox.shrink()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:cc_ui/cc_ui.dart'
    show CcScrollBehavior, CcTheme, CcThemeData, CcToastScope;
import 'package:control_center/core/keybindings/text_undo_shortcuts.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/theme/app_theme.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/features/auth/providers/credential_migration.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/presence/providers/follow_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/shell/presentation/widgets/route_title.dart';
import 'package:control_center/features/shell/presentation/widgets/server_shutdown_overlay.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_workspace_chip.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/features/workspaces/providers/rpc_client_workspace_sync_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_switch_gc_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_url_sync_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/app_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget: the global shortcut layer wrapping
/// `MaterialApp.router`, the design-system theme space and the app-wide toast
/// overlay.
///
/// Web-safe by construction — it depends only on Flutter, Riverpod and app
/// providers, never on the internal windowing library or nativeapi. The desktop
/// multi-window root (`AppWindows`) wraps this in a `Window`; the web
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
    // Two-way per-user preference sync (theme follows the user across
    // desktop/web/phone).
    ref.watch(userPreferencesSyncProvider);
    // One-shot: hand any credential still in THIS machine's keychain to the
    // server, then delete it locally. Provider credentials are the user's, not
    // the machine's.
    ref.watch(legacyCredentialMigrationProvider);
    // Presence lane (PRD 16 §1–§5): mirrors the route onto my own locus,
    // drives follow-mode navigation and auto-navigates to an active
    // spotlight. All three are pure side-effect sinks kept alive for the
    // app's lifetime, mirroring `rpcClientWorkspaceSyncProvider` above.
    ref.watch(presenceLocusSyncProvider);
    ref.watch(followSyncProvider);
    ref.watch(spotlightSyncProvider);
    // Reclaims the previous workspace's synced-store row mirrors on switch.
    ref.watch(workspaceSwitchGcProvider);
    // Write-through cache of the active workspace's display info, so the
    // title-bar chip renders the right name/logo on a cold start instead of
    // flashing "no workspace". Watched from the ROOT on purpose: it is the one
    // permanent (never ticker-paused) listener on `activeWorkspaceProvider`, so
    // that derived provider always counts as active and Riverpod's scheduler
    // refreshes it at end-of-frame. Without a permanent listener it could go
    // dirty-but-unflushed while every widget listener was paused/unmounted (the
    // splash → inbox hop) and then the first descendant to `watch` it
    // flushed it *during* its own build — marking other subtrees
    // dirty mid-build.
    ref.watch(workspaceDisplayCacheProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localeOverride = ref.watch(localeProvider);
    final fontSettings = ref.watch(fontSettingsProvider);
    final appFontFamily = fontSettings.appFontSelection.family;

    return AppShortcuts(
      commandBuilder: buildGlobalCommands,
      readActiveWorkspaceId: () => ref.read(activeWorkspaceIdProvider),
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
        ref.read(routerProvider).go(inboxRoute(workspaces[nextIndex].id));
      },
      onSelectWorkspaceByIndex: (index) {
        final workspaces = ref.read(workspacesProvider).value ?? const [];
        if (index < 0 || index >= workspaces.length) {
          return;
        }
        ref.read(routerProvider).go(inboxRoute(workspaces[index].id));
      },
      onToggleFocusMode: () {
        ref.read(focusModeProvider.notifier).toggle();
      },
      child: MaterialApp.router(
        title: 'Control Center',
        debugShowCheckedModeBanner: false,
        // Every desktop scrollable gets the design-system scrollbar (angular,
        // token-colored) instead of Material's rounded one. Surfaces needing
        // explicit control wrap their scrollable in [CcScrollbar] themselves.
        scrollBehavior: const CcScrollBehavior(),
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
          // CcTheme is the purist token-delivery space (replacing the Material
          // ThemeExtension). It wraps the whole navigator so every route and
          // overlay can resolve `context.designSystem`. CcToastScope hosts the
          // app-wide toast overlay — it needs an Overlay ancestor to insert
          // into and `MaterialApp.builder` sits *above* the router's own
          // overlay, so we provide a root Overlay here for it to mount toasts on
          // top of every route.
          // RouteTitle wraps the whole navigator so the browser-tab title
          // follows the active page (it re-resolves on every navigation) rather
          // than the static `MaterialApp.title` every page would share. It sits
          // inside CcTheme so token lookups in its subtree resolve.
          return installTextUndoShadow(
            // Undo/redo strokes are owned by the [KeybindingDispatcher], which
            // bridges them to the focused field's UndoHistory (see
            // `_bridgeTextUndoRedo` in keybinding_dispatcher.dart). The shadow
            // sits INSIDE WidgetsApp's DefaultTextEditingShortcuts
            // (MaterialApp.builder wraps the router), so it shadows the
            // framework's own undo/redo mapping — see text_undo_shortcuts.dart
            // for why it reports the key handled over real fields.
            RouteTitle(
              child: CcTheme(
                data: isDark
                    ? CcThemeData.dark(fontFamily: appFontFamily)
                    : CcThemeData.light(fontFamily: appFontFamily),
                child: Stack(
                  children: [
                    Overlay(
                      initialEntries: [
                        OverlayEntry(
                          builder: (context) => CcToastScope(
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                    // App-wide shutdown overlay (above every route + toasts),
                    // driven by server-fed progress during a local-server quit.
                    const Positioned.fill(child: ServerShutdownOverlay()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registers the application-wide command handlers (navigation, system
/// actions, and the command palette) with the central [KeybindingDispatcher].
///
/// These handlers stay registered for the app's lifetime, so global shortcuts
/// like ⌘K or ⌘1 fire from anywhere — they no longer depend on this subtree
/// holding keyboard focus. Per-screen shortcuts are contributed by
/// `ScopedShortcuts`; settings shortcuts by `SettingsShortcuts`.
class AppShortcuts extends ConsumerStatefulWidget {
  /// Creates the global shortcut registrar.
  const AppShortcuts({
    super.key,
    required this.child,
    required this.commandBuilder,
    this.onToggleWorkspaceSwitcher,
    this.onCycleWorkspace,
    this.onToggleFocusMode,
    this.onSelectWorkspaceByIndex,
  });

  /// The subtree to wrap.
  final Widget child;

  /// Builds the list of available commands for the palette.
  final List<CommandItem> Function(BuildContext context, WidgetRef ref)
      commandBuilder;

  /// Toggles the workspace-switcher popover. When null, the
  /// `sys.workspace-switcher` binding is a no-op.
  final VoidCallback? onToggleWorkspaceSwitcher;

  /// Cycles the active workspace by `delta` (e.g. +1 / -1). When null,
  /// `sys.workspace-next` / `sys.workspace-prev` are no-ops.
  final void Function(int delta)? onCycleWorkspace;

  /// Toggles focus mode. When null, `sys.focus-mode` is a no-op.
  final VoidCallback? onToggleFocusMode;

  /// Selects the workspace at the given 0-based `index`. When null,
  /// `sys.workspace-N` bindings are no-ops.
  final void Function(int index)? onSelectWorkspaceByIndex;

  @override
  ConsumerState<AppShortcuts> createState() => _AppShortcutsState();
}

class _AppShortcutsState extends ConsumerState<AppShortcuts> {
  KeybindingScopeHandle? _handle;

  @override
  void initState() {
    super.initState();
    final dispatcher = ref.read(keybindingDispatcherProvider);
    _handle = dispatcher.registerScope(_buildHandlers());
  }

  @override
  void didUpdateWidget(covariant AppShortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The workspace/focus callbacks are recreated each parent build; refresh
    // so the handlers always close over the latest ones.
    _handle?.update(_buildHandlers());
  }

  @override
  void dispose() {
    _handle?.dispose();
    _handle = null;
    super.dispose();
  }

  Map<String, VoidCallback> _buildHandlers() {
    final router = ref.read(routerProvider);

    void selectWorkspace(int index) => widget.onSelectWorkspaceByIndex?.call(index);

    return {
      'nav.dashboard': () => router.go(dashboardRoute),
      'nav.tickets': () => router.go(ticketsRoute),
      'nav.pull-requests': () => router.go(pullRequestsRoute),
      'nav.pipelines': () => router.go(pipelinesRoute),
      'nav.agents': () => router.go(agentsRoute),
      'nav.analytics': () => router.go(analyticsRoute),
      'nav.memory': () => router.go(memoryRoute),
      'nav.newsfeed': () => router.go(newsfeedRoute),
      'sys.command-palette': _openCommandPalette,
      'sys.toggle-theme': () {
        final current = ref.read(themeModeProvider);
        ref.read(themeModeProvider.notifier).setThemeMode(
              current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
            );
      },
      'sys.settings': () => router.go(settingsRoute),
      if (widget.onToggleFocusMode != null)
        'sys.focus-mode': widget.onToggleFocusMode!,
      if (widget.onToggleWorkspaceSwitcher != null)
        'sys.workspace-switcher': widget.onToggleWorkspaceSwitcher!,
      if (widget.onCycleWorkspace != null) ...{
        'sys.workspace-next': () => widget.onCycleWorkspace!(1),
        'sys.workspace-prev': () => widget.onCycleWorkspace!(-1),
      },
      if (widget.onSelectWorkspaceByIndex != null) ...{
        for (var n = 1; n <= 9; n++) 'sys.workspace-$n': () => selectWorkspace(n - 1),
      },
    };
  }

  void _openCommandPalette() {
    final paletteContext = rootNavigatorKey.currentContext ?? context;
    showCommandPalette(paletteContext, widget.commandBuilder);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

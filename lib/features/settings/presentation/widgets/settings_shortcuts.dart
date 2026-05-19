import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contributes the settings sub-page navigation shortcuts (J / K to cycle
/// through the sidebar) plus any page-specific [extraBindings] (e.g.
/// `settings.adapters-refresh`, `settings.agents-new`) to the central
/// [KeybindingDispatcher].
///
/// While a settings page is mounted these bindings are active; the dispatcher
/// resolves the J / K clash with other screen shortcuts via the
/// `route =~ /^\/settings/` when clause, so they only fire inside settings.
class SettingsShortcuts extends ConsumerStatefulWidget {
  /// Creates a [SettingsShortcuts].
  const SettingsShortcuts({
    super.key,
    required this.child,
    this.extraBindings = const {},
  });

  /// The settings sub-page content.
  final Widget child;

  /// Optional sub-page-specific bindings keyed by `Keybinding.id`.
  final Map<String, VoidCallback> extraBindings;

  @override
  ConsumerState<SettingsShortcuts> createState() => _SettingsShortcutsState();
}

class _SettingsShortcutsState extends ConsumerState<SettingsShortcuts> {
  KeybindingScopeHandle? _handle;

  @override
  void initState() {
    super.initState();
    _handle = ref.read(keybindingDispatcherProvider).registerScope(_buildHandlers());
  }

  @override
  void didUpdateWidget(covariant SettingsShortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handle?.update(_buildHandlers());
  }

  @override
  void dispose() {
    _handle?.dispose();
    _handle = null;
    super.dispose();
  }

  static const _settingsRoutes = [
    settingsAppearanceRoute,
    settingsNotificationsRoute,
    settingsKeybindingsRoute,
    settingsAdvancedRoute,
    settingsAgentsRoute,
    settingsAdaptersRoute,
    settingsSkillsRoute,
    settingsPipelinesRoute,
    settingsSandboxingRoute,
    teamsRoute,
    settingsReposRoute,
    settingsIntegrationsRoute,
  ];

  Map<String, VoidCallback> _buildHandlers() {
    final router = ref.read(routerProvider);

    void cycle(int delta) {
      final dispatcher = ref.read(keybindingDispatcherProvider);
      final location = dispatcher.debugContext['route'] as String?;
      if (location == null) {
        return;
      }
      final index = _settingsRoutes.indexOf(location);
      if (index == -1) {
        return;
      }
      var next = (index + delta) % _settingsRoutes.length;
      if (next < 0) {
        next += _settingsRoutes.length;
      }
      router.go(_settingsRoutes[next]);
    }

    return {
      'settings.next': () => cycle(1),
      'settings.prev': () => cycle(-1),
      ...widget.extraBindings,
    };
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

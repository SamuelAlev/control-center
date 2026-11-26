// Uses Flutter's experimental windowing API (unlocked via the `windowing`
// feature flag). Confined to the window wrapper; the UI below is ordinary.
// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:async';
import 'dart:ui' show ViewFocusEvent;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/app/native_window_handle.dart';
import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/app/window_placement.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/theme/cc_strings_l10n.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/core/theme/theme_choice.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_actions.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/widgets/_window.dart' show Window, WindowController;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tray panel's window: a popover against the tray icon, in the session's
/// isolate like the HUDs, so it reads the session's providers directly.
///
/// Created when the panel opens and destroyed when it closes. It closes when
/// it loses focus, as a menu-bar popover does, and on Escape.
///
/// Losing focus is read from the window's activation on every report of it:
/// Windows and Linux notify the controller, macOS sends only a view focus
/// event (its controller notifies on resize and close alone).
class TrayPanelWindow extends ConsumerStatefulWidget {
  /// Creates a [TrayPanelWindow].
  const TrayPanelWindow({required this.actions, super.key});

  /// The presenter's actions.
  final TrayPanelActions actions;

  @override
  ConsumerState<TrayPanelWindow> createState() => _TrayPanelWindowState();
}

class _TrayPanelWindowState extends ConsumerState<TrayPanelWindow>
    with WidgetsBindingObserver {
  final WindowController _controller = WindowController(
    size: trayPanelSize,
    // Loose: a short display gets a shorter panel (see `_styleTrayPanel`).
    constraints: BoxConstraints(
      maxWidth: trayPanelSize.width,
      maxHeight: trayPanelSize.height,
    ),
    title: trayPanelWindowTitle,
  );
  final FocusNode _panelFocus = FocusNode(debugLabel: 'Tray panel');
  bool _wasActive = false;

  /// Set once the panel is on its way out. The blur and hide that close it
  /// report a focus loss of their own, which must not count as the operator
  /// clicking away (that would swallow the next click on the icon).
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onActivationChanged);
    WidgetsBinding.instance.addObserver(this);
    // Now, not on the first frame: frames are off while the main window is
    // hidden in the tray, and showing also activates the app, which a click
    // on a status item does not.
    showNativeWindowNow(_controller);
    _wasActive = _controller.isActivated;
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) => _onActivationChanged();

  void _onActivationChanged() {
    if (_closing || !mounted) {
      return;
    }
    final active = _controller.isActivated;
    if (_wasActive && !active) {
      _closing = true;
      widget.actions.dismiss();
      return;
    }
    _wasActive = active;
    if (active) {
      // Activating the app also reports the main window's focus, and its
      // view takes the keyboard into its own tree (or parks it) when it
      // handles that, after the panel's autofocus. The panel is the key
      // window, so take the keyboard back once that handling has run, or
      // Escape lands in the main window.
      scheduleMicrotask(_reclaimFocus);
    }
  }

  void _reclaimFocus() {
    if (!mounted ||
        _closing ||
        _panelFocus.context == null ||
        _panelFocus.hasFocus) {
      return;
    }
    _panelFocus.requestFocus();
  }

  void _dismissWithKeyboard() {
    _closing = true;
    // Hand the keyboard back to whichever app had it before the panel.
    final window = nativeWindowOf(_controller);
    if (window != null) {
      try {
        window.blur();
      } finally {
        window.dispose();
      }
    }
    widget.actions.dismiss(returnFocus: true);
  }

  @override
  void dispose() {
    _closing = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onActivationChanged);
    final controller = _controller;
    // Gone at once; destroyed after the frame, when focus teardown is
    // allowed again (see `PrimaryWindow.dispose`).
    final window = nativeWindowOf(controller);
    if (window != null) {
      try {
        window.hide();
      } finally {
        window.dispose();
      }
    }
    SchedulerBinding.instance.addPostFrameCallback((_) => controller.destroy());
    _panelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Window(
    controller: _controller,
    child: _TrayPanelApp(
      actions: widget.actions,
      focusNode: _panelFocus,
      onEscape: _dismissWithKeyboard,
    ),
  );
}

/// The panel's app shell: the session's locale, theme and fonts, and a
/// single route that ignores the engine's shared platform route (the main
/// window's deep link).
class _TrayPanelApp extends ConsumerWidget {
  const _TrayPanelApp({
    required this.actions,
    required this.focusNode,
    required this.onEscape,
  });

  final TrayPanelActions actions;
  final FocusNode focusNode;
  final VoidCallback onEscape;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeChoice = ref.watch(themeModeProvider.select((m) => m.choice));
    final fontFamily = ref.watch(
      fontSettingsProvider.select((f) => f.appFontSelection.family),
    );
    final panel = Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            onEscape();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: focusNode,
        autofocus: true,
        // Only the Escape host: an invisible Tab stop would swallow a press.
        skipTraversal: true,
        child: const TrayPanel(),
      ),
    );
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: const Color(0xFF000000),
      title: trayPanelWindowTitle,
      locale: locale,
      supportedLocales: kSupportedAppLocales,
      localeResolutionCallback: resolveAppLocale,
      localizationsDelegates: appLocalizationsDelegates,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      onGenerateInitialRoutes: (_) => [
        PageRouteBuilder<void>(
          settings: const RouteSettings(name: '/'),
          pageBuilder: (context, _, _) => panel,
        ),
      ],
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, _, _) => panel,
      ),
      builder: (context, child) {
        final dark = switch (themeChoice) {
          ThemeChoice.dark => true,
          ThemeChoice.light => false,
          ThemeChoice.system =>
            MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        };
        final strings = ccStringsFor(AppLocalizations.of(context));
        final theme = dark
            ? CcThemeData.dark(fontFamily: fontFamily, strings: strings)
            : CcThemeData.light(fontFamily: fontFamily, strings: strings);
        return CcTheme(
          data: theme,
          child: DefaultTextStyle(
            style:
                CcFonts.ui(
                  textStyle: CcTypography.bodySm,
                  family: fontFamily,
                ).copyWith(
                  color: theme.tokens.textPrimary,
                  decoration: TextDecoration.none,
                ),
            child: TrayPanelScope(
              actions: actions,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

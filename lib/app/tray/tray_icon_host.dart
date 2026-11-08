import 'dart:async';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:nativeapi/nativeapi.dart' as na;
import 'package:nativeapi_flutter/nativeapi_flutter.dart'
    show DisplayManager, ImageAsset, RectangleToRect;

/// Autosave name of the macOS status item, so the menu-bar position the
/// operator ⌘-drags it to survives relaunches.
const String _trayIdentifier = 'com.controlcenter.tray';

/// The tray (menu bar) icon: one per process, outliving every session.
///
/// Owns the native status item, its context menu and the glyph images, and
/// turns the platform's events into [TrayPointerEvent]s and menu selections.
/// Every update is diffed first: the session pushes a spec on every status
/// change, and rebuilding a native menu while it is open closes it.
///
/// The glyph is the monochrome figure on every platform, like the system's
/// own tray icons: a template image whose alpha the platform inks for the
/// bar it sits on. AppKit does it for the menu bar; nativeapi does it for
/// the Windows taskbar (its light/dark and high-contrast settings) and for
/// the StatusNotifierItem host (its panel's foreground), and follows their
/// theme changes, so the glyph never needs choosing or reloading here.
class TrayIconHost {
  TrayIconHost._();

  /// The process-wide instance.
  static final TrayIconHost instance = TrayIconHost._();

  na.TrayIcon? _icon;
  na.ListenerId? _iconListener;
  TrayIconSpec? _spec;
  List<TrayMenuEntry>? _entries;
  final List<(na.MenuItem, na.ListenerId?)> _items = [];
  final Map<TrayIconTone, na.Image?> _images = {};
  final StreamController<TrayPointerEvent> _events =
      StreamController.broadcast();
  final StreamController<String> _selections = StreamController.broadcast();

  /// Where the icon was when it was last clicked, in the global top-left
  /// coordinates window frames use. A zero-size rect at the pointer where the
  /// host cannot say (StatusNotifierItem has no geometry), null before any
  /// click.
  Rect? lastAnchor;

  /// Whether this platform build has a tray at all.
  bool get supported {
    try {
      return na.TrayManager.instance.isSupported();
    } on Object catch (e) {
      AppLog.w('tray', 'tray support probe failed: $e');
      return false;
    }
  }

  /// Pointer gestures on the icon.
  Stream<TrayPointerEvent> get events => _events.stream;

  /// Ids of selected context-menu lines.
  Stream<String> get selections => _selections.stream;

  /// Shows the icon, or updates what changed of it.
  void show(TrayIconSpec spec, List<TrayMenuEntry> menu) {
    final icon = _icon ?? _create();
    if (icon == null) {
      return;
    }
    if (spec != _spec) {
      _apply(icon, spec);
      _spec = spec;
    }
    if (!listEquals(menu, _entries)) {
      _setMenu(icon, menu);
      _entries = List.unmodifiable(menu);
    }
  }

  /// Removes the icon from the tray.
  void remove() {
    final icon = _icon;
    if (icon == null) {
      return;
    }
    final listener = _iconListener;
    if (listener != null) {
      icon.removeListener(listener);
    }
    icon.setContextMenu(null);
    _disposeItems();
    icon
      ..setVisible(false)
      ..dispose();
    _icon = null;
    _iconListener = null;
    _spec = null;
    _entries = null;
  }

  na.TrayIcon? _create() {
    final na.TrayIcon? icon;
    try {
      icon = na.TrayIcon.createWithIdentifier(_trayIdentifier);
    } on Object catch (e) {
      AppLog.w('tray', 'creating the tray icon failed: $e');
      return null;
    }
    if (icon == null) {
      AppLog.w('tray', 'the platform refused a tray icon');
      return null;
    }
    // The menu opens itself on a secondary click (and, on GNOME's AppIndicator
    // host, on a primary one too). A primary click is ours: the panel.
    icon.setContextMenuTrigger(na.ContextMenuTrigger.rightClicked);
    _iconListener = icon.addListener(_onEvent);
    icon.setVisible(true);
    return _icon = icon;
  }

  void _onEvent(na.TrayIconEvent event) {
    switch (event) {
      case na.TrayIconClickedEvent():
        _captureAnchor();
        _events.add(TrayPointerEvent.primary);
      case na.TrayIconDoubleClickedEvent():
        _events.add(TrayPointerEvent.double);
      case na.TrayIconRightClickedEvent():
        // The native menu handles this; reported for hosts without one.
        _events.add(TrayPointerEvent.secondary);
    }
  }

  void _captureAnchor() {
    final bounds = _icon?.getBounds().toRect();
    if (bounds != null && !bounds.isEmpty) {
      lastAnchor = bounds;
      return;
    }
    try {
      final pointer = DisplayManager.instance.getCursorPosition();
      lastAnchor = Rect.fromLTWH(pointer.x, pointer.y, 0, 0);
    } on Object {
      lastAnchor = null;
    }
  }

  void _apply(na.TrayIcon icon, TrayIconSpec spec) {
    if (spec.tone != _spec?.tone) {
      _setImage(icon, spec.tone);
    }
    icon.setTooltip(spec.tooltip);
    if (Platform.isMacOS) {
      icon.setTitle(spec.badge);
    }
  }

  void _setImage(na.TrayIcon icon, TrayIconTone tone) {
    final image = _images.putIfAbsent(tone, () => _load(tone));
    if (image == null) {
      return;
    }
    icon
      ..icon = image
      ..isIconTemplate = true;
    if (Platform.isMacOS) {
      // Points: 36px of the 64px glyph on a Retina menu bar.
      icon.iconSize = const na.Size(width: 18, height: 18);
    }
  }

  na.Image? _load(TrayIconTone tone) {
    final name = switch (tone) {
      TrayIconTone.normal => 'tray',
      TrayIconTone.attention => 'tray_attention',
      TrayIconTone.offline => 'tray_offline',
    };
    final image = ImageAsset.fromAsset('assets/tray/$name.png');
    if (image == null) {
      AppLog.w('tray', 'tray glyph $name missing from the bundle');
    }
    return image;
  }

  void _setMenu(na.TrayIcon icon, List<TrayMenuEntry> entries) {
    final menu = na.Menu.create();
    if (menu == null) {
      return;
    }
    final next = <(na.MenuItem, na.ListenerId?)>[];
    for (final entry in entries) {
      final item = switch (entry) {
        TrayMenuAction(:final label) => na.MenuItem.createWithLabelAndType(
          label,
          na.MenuItemType.normal,
        ),
        TrayMenuCaption(:final label) => na.MenuItem.createWithLabelAndType(
          label,
          na.MenuItemType.normal,
        )?..isEnabled = false,
        TrayMenuSeparator() => na.MenuItem.createWithLabelAndType(
          '',
          na.MenuItemType.separator,
        ),
      };
      if (item == null) {
        continue;
      }
      na.ListenerId? listener;
      if (entry case TrayMenuAction(:final id)) {
        listener = item.addListener((event) {
          if (event is na.MenuItemClickedEvent) {
            _selections.add(id);
          }
        });
      }
      menu.addItem(item);
      next.add((item, listener));
    }
    icon.setContextMenu(menu);
    // Only now: the old menu is no longer attached to anything.
    _disposeItems();
    _items.addAll(next);
  }

  void _disposeItems() {
    for (final (item, listener) in _items) {
      if (listener != null) {
        item.removeListener(listener);
      }
      item.dispose();
    }
    _items.clear();
  }
}

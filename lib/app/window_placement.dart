/// Where a window should open, given what was saved last session and which
/// displays exist right now.
///
/// Deliberately pure — plain geometry over [Rect]s, with no `nativeapi` import
/// and no preference reads — so the rules below can be unit-tested without an
/// FFI-backed window server. `window_chrome.dart` supplies the real display
/// work areas and the saved frame; this file only decides the answer.
///
/// The problem it solves: a saved frame is a promise about a display
/// arrangement that may no longer exist. Restoring `(3200, 400, 2560x1440)`
/// verbatim onto a laptop whose external monitor went home for the weekend puts
/// the window somewhere the operator cannot see or reach, and nothing in the
/// app can recover it — the window is off-screen, so there is no title bar to
/// grab and no menu item to fix it.
library;

import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

/// Size the main window opens at on a machine that has never run the app.
///
/// Clamped to the display before it is used, so a 13" laptop does not get a
/// window taller than its screen. `PrimaryWindow` creates its controller at
/// this size too, so the creation default and the restore default cannot drift
/// apart.
const Size defaultMainWindowSize = Size(1440, 900);

/// Smallest frame the app's layout is designed for (matches the primary
/// window's `BoxConstraints`).
///
/// Acts as a floor when clamping to a display: on a work area smaller than
/// this the window overflows rather than shrinking below the size at which the
/// shell (sidebar + content + inspector) stops fitting. No shipping Mac
/// display is that small; the case exists so the maths has a defined answer.
const Size mainWindowMinSize = Size(1024, 600);

/// Size the pre-app server-setup window opens at.
///
/// Room for the landing and for the connect dialog over it, with its pairing
/// fields unfolded. Clamped to the display like [defaultMainWindowSize], so a
/// small laptop still gets a window that fits; both scroll below that.
const Size serverSetupWindowSize = Size(720, 680);

/// Smallest frame the server-setup window can be resized to (matches its
/// `BoxConstraints`).
const Size serverSetupWindowMinSize = Size(460, 520);

/// How much of the main window must land on a display for that display to be
/// considered the one it was saved on. Below this the saved position is
/// treated as belonging to a display that is gone.
const Size _mainWindowMinVisible = Size(100, 32);

/// The same threshold for the small HUD windows, which are ~52px tall and
/// would never clear the main window's bar.
const Size _hudMinVisible = Size(40, 20);

/// The frame the main window should open with.
/// [saved] is last session's frame (null on a first launch), [workAreas] are the current
/// displays' usable areas (menu bar and Dock excluded) and [primaryWorkArea] is the
/// fallback display.
Rect resolveMainWindowBounds({
  required Rect? saved,
  required List<Rect> workAreas,
  required Rect primaryWorkArea,
  Size defaultSize = defaultMainWindowSize,
  Size minSize = mainWindowMinSize,
}) {
  if (saved != null) {
    if (_isFullyVisible(saved, workAreas)) {
      return saved;
    }
    final host = _hostFor(saved, workAreas, _mainWindowMinVisible);
    if (host != null) {
      return _fitInto(saved.size, saved.topLeft, host, minSize);
    }
  }
  final size = _clampSize(saved?.size ?? defaultSize, primaryWorkArea, minSize);
  return _centerIn(size, primaryWorkArea);
}

/// The top-left corner a fixed-size HUD window should open at.
///
/// Same rules as [resolveMainWindowBounds], with a smaller visibility
/// threshold ([_hudMinVisible]) because the HUDs are ~52px tall, and no size
/// clamping — their size is locked by the window's own `minimumSize` ==
/// `maximumSize`. [fallback] (the HUD's designed default spot) is itself
/// clamped, since a hardcoded `Offset(700, 30)` is off-screen on a narrow
/// display.
Offset resolveHudPosition({
  required Offset? saved,
  required Offset fallback,
  required Size hudSize,
  required List<Rect> workAreas,
  required Rect primaryWorkArea,
}) {
  if (saved != null) {
    final host = _hostFor(saved & hudSize, workAreas, _hudMinVisible);
    if (host != null) {
      return _fitInto(hudSize, saved, host, Size.zero).topLeft;
    }
  }
  return _fitInto(hudSize, fallback, primaryWorkArea, Size.zero).topLeft;
}

/// Whether every part of [rect] lands on some display.
///
/// Compares [rect]'s area against the total area it shares with the work
/// areas. That sum is the covered area exactly — never an over-count — because
/// displays tile rather than overlap: macOS's arrangement UI cannot place one
/// screen on top of another. The tolerance absorbs the sub-pixel error of a
/// frame that was stored as text and parsed back.
bool _isFullyVisible(Rect rect, List<Rect> workAreas) {
  var covered = 0.0;
  for (final area in workAreas) {
    final overlap = rect.intersect(area);
    if (overlap.width > 0 && overlap.height > 0) {
      covered += overlap.width * overlap.height;
    }
  }
  return covered >= rect.width * rect.height - 1.0;
}

/// The work area [rect] belongs to: the one it overlaps most, provided that
/// overlap is at least [minVisible]. Null when the window would be effectively
/// off-screen — a sliver hanging off the edge of a display is not "on" it.
///
/// Ties (a window straddling two displays evenly) go to the display whose
/// centre is nearest, then to list order, so the result is deterministic
/// rather than dependent on how the OS happened to enumerate the screens.
Rect? _hostFor(Rect rect, List<Rect> workAreas, Size minVisible) {
  Rect? best;
  var bestArea = 0.0;
  for (final area in workAreas) {
    final overlap = rect.intersect(area);
    // A disjoint intersection has negative extents, so this rejects it too.
    if (overlap.width < minVisible.width || overlap.height < minVisible.height) {
      continue;
    }
    final overlapArea = overlap.width * overlap.height;
    if (best == null ||
        overlapArea > bestArea ||
        (overlapArea == bestArea &&
            _centerDistance(rect, area) < _centerDistance(rect, best))) {
      best = area;
      bestArea = overlapArea;
    }
  }
  return best;
}

double _centerDistance(Rect a, Rect b) => (a.center - b.center).distance;

/// [desired] sized and positioned to sit entirely inside [area].
Rect _fitInto(Size desired, Offset topLeft, Rect area, Size minSize) {
  final size = _clampSize(desired, area, minSize);
  return Rect.fromLTWH(
    _clampAxis(topLeft.dx, area.left, area.right, size.width),
    _clampAxis(topLeft.dy, area.top, area.bottom, size.height),
    size.width,
    size.height,
  );
}

Size _clampSize(Size desired, Rect area, Size minSize) => Size(
  math.max(minSize.width, math.min(desired.width, area.width)),
  math.max(minSize.height, math.min(desired.height, area.height)),
);

/// [desired] moved into `[start, end - extent]`. When the window is wider (or
/// taller) than the display — only possible once [_clampSize]'s minimum floor
/// bites — it is pinned to [start] rather than centred on the overflow, which
/// on the vertical axis is what keeps the title bar on screen.
double _clampAxis(double desired, double start, double end, double extent) {
  final last = math.max(start, end - extent);
  return math.min(math.max(desired, start), last);
}

Rect _centerIn(Size size, Rect area) => Rect.fromLTWH(
  math.max(area.left, area.left + (area.width - size.width) / 2),
  math.max(area.top, area.top + (area.height - size.height) / 2),
  size.width,
  size.height,
);

/// Size of the tray (menu bar) panel. Fixed: it is a popover, not a window
/// the operator arranges.
const Size trayPanelSize = Size(360, 560);

/// Breathing room between the panel and the tray icon or the display edge.
const double _trayPanelGap = 6;

/// Where the tray panel opens, given where the tray icon is.
///
/// [anchor] is the icon's frame in the global top-left space window frames
/// use, or a zero-size rect at the pointer on hosts that cannot report the
/// icon (Linux's StatusNotifierItem), or null when nothing is known. The
/// icon sits in a bar the work areas exclude, so which side of its display's
/// work area it lies on says where that bar is:
///
/// - above it (the macOS menu bar, a top panel): the panel hangs below,
///   centered on the icon;
/// - below it (the Windows taskbar, a bottom panel): it stands above;
/// - beside it (a vertical taskbar): it opens toward the screen.
///
/// An anchor inside the work area (the pointer, or Windows' overflow
/// flyout) opens toward the larger free space around it. With no anchor the
/// panel takes the primary display's top-end corner on [preferTop] desktops,
/// else its bottom-end one. Every answer is clamped into one work area.
Rect resolveTrayPanelBounds({
  required Rect? anchor,
  required List<Rect> workAreas,
  required Rect primaryWorkArea,
  required bool preferTop,
  Size size = trayPanelSize,
}) {
  final w = math.min(size.width, primaryWorkArea.width);
  if (anchor == null) {
    final area = primaryWorkArea;
    final h = math.min(size.height, area.height - 2 * _trayPanelGap);
    final left = area.right - w - _trayPanelGap;
    final top = preferTop
        ? area.top + _trayPanelGap
        : area.bottom - h - _trayPanelGap;
    return Rect.fromLTWH(left, top, w, h);
  }
  final area = _workAreaNearest(anchor, workAreas) ?? primaryWorkArea;
  final h = math.min(size.height, area.height - 2 * _trayPanelGap);
  final width = math.min(w, area.width - 2 * _trayPanelGap);

  double centeredX() => _clampAxis(
    anchor.center.dx - width / 2,
    area.left + _trayPanelGap,
    area.right - _trayPanelGap,
    width,
  );
  double centeredY() => _clampAxis(
    anchor.center.dy - h / 2,
    area.top + _trayPanelGap,
    area.bottom - _trayPanelGap,
    h,
  );

  final Offset topLeft;
  if (anchor.bottom <= area.top + 1) {
    topLeft = Offset(centeredX(), area.top + _trayPanelGap);
  } else if (anchor.top >= area.bottom - 1) {
    topLeft = Offset(centeredX(), area.bottom - h - _trayPanelGap);
  } else if (anchor.left >= area.right - 1) {
    topLeft = Offset(area.right - width - _trayPanelGap, centeredY());
  } else if (anchor.right <= area.left + 1) {
    topLeft = Offset(area.left + _trayPanelGap, centeredY());
  } else {
    // Inside the work area: open below the point when there is more room
    // below it, else above, and keep it on screen sideways.
    final below = area.bottom - anchor.bottom >= anchor.top - area.top;
    final y = below
        ? anchor.bottom + _trayPanelGap
        : anchor.top - h - _trayPanelGap;
    topLeft = Offset(
      centeredX(),
      _clampAxis(y, area.top + _trayPanelGap, area.bottom - _trayPanelGap, h),
    );
  }
  return Rect.fromLTWH(topLeft.dx, topLeft.dy, width, h);
}

/// The work area [anchor] belongs to: the one containing its center, else
/// the nearest — the tray icon sits just outside every work area.
Rect? _workAreaNearest(Rect anchor, List<Rect> workAreas) {
  Rect? best;
  var bestDistance = double.infinity;
  for (final area in workAreas) {
    if (area.contains(anchor.center)) {
      return area;
    }
    final dx = math.max(
      0.0,
      math.max(area.left - anchor.center.dx, anchor.center.dx - area.right),
    );
    final dy = math.max(
      0.0,
      math.max(area.top - anchor.center.dy, anchor.center.dy - area.bottom),
    );
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance < bestDistance) {
      best = area;
      bestDistance = distance;
    }
  }
  return best;
}

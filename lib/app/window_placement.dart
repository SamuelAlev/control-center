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

/// How much of the main window must land on a display for that display to be
/// considered the one it was saved on. Below this the saved position is
/// treated as belonging to a display that is gone.
const Size _mainWindowMinVisible = Size(100, 32);

/// The same threshold for the small HUD windows, which are ~52px tall and
/// would never clear the main window's bar.
const Size _hudMinVisible = Size(40, 20);

/// The frame the main window should open with.
///
/// [saved] is last session's frame (null on a first launch), [workAreas] are
/// the current displays' usable areas (menu bar and Dock excluded) and
/// [primaryWorkArea] is the fallback display. All rects share one global
/// top-left coordinate space, so displays left of or above the primary one
/// have negative coordinates — that is normal and the maths handles it.
///
/// Resolution order:
///  1. Saved frame is still entirely on screen → restored verbatim. This is
///     the ordinary "nothing changed since last time" case, and it is also
///     what lets a window the operator deliberately spread across two
///     displays come back spread across them.
///  2. Saved frame still overlaps a live display → clamp it fully inside that
///     display (size first, then position), so an arrangement that merely
///     shrank keeps the window roughly where the operator left it.
///  3. Otherwise (first launch, or the saved display is gone) → the saved size
///     if there was one, else [defaultSize], clamped to [primaryWorkArea] and
///     centred there. Keeping the size honours "I like a big window" even when
///     the display it was sized for is unplugged.
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

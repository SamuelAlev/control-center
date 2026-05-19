import 'dart:ui' show Offset, Rect, Size;

import 'package:control_center/app/window_placement.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 15" laptop's usable area: the built-in display with the menu bar taken
/// off the top. Always the primary in these tests.
const Rect kLaptop = Rect.fromLTWH(0, 25, 1512, 907);

/// A 27" external display sitting to the RIGHT of the laptop.
const Rect kExternalRight = Rect.fromLTWH(1512, 25, 2560, 1415);

/// The same display placed to the LEFT of and ABOVE the primary one, which is
/// what puts negative coordinates into the maths.
const Rect kExternalLeft = Rect.fromLTWH(-2560, 25, 2560, 1415);
const Rect kExternalAbove = Rect.fromLTWH(0, -1415, 2560, 1415);

void main() {
  group('resolveMainWindowBounds', () {
    test('leaves a window that is still fully on a live display alone', () {
      const saved = Rect.fromLTWH(120, 80, 1280, 800);
      expect(
        resolveMainWindowBounds(
          saved: saved,
          workAreas: const [kLaptop],
          primaryWorkArea: kLaptop,
        ),
        saved,
      );
    });

    test('restores onto a secondary display it was saved on', () {
      const saved = Rect.fromLTWH(2000, 300, 1600, 1000);
      expect(
        resolveMainWindowBounds(
          saved: saved,
          workAreas: const [kLaptop, kExternalRight],
          primaryWorkArea: kLaptop,
        ),
        saved,
      );
    });

    test('centres on the primary display when the saved one is gone', () {
      // Saved on the external monitor; only the laptop is attached now. The
      // window must not be restored at x=2000, where nothing can reach it.
      const saved = Rect.fromLTWH(2000, 300, 1440, 900);
      final bounds = resolveMainWindowBounds(
        saved: saved,
        workAreas: const [kLaptop],
        primaryWorkArea: kLaptop,
      );
      expect(kLaptop.contains(bounds.topLeft), isTrue);
      expect(kLaptop.contains(bounds.bottomRight - const Offset(1, 1)), isTrue);
      // The size the operator chose survives; only the position changed.
      expect(bounds.size, const Size(1440, 900));
      expect(bounds.center.dx, closeTo(kLaptop.center.dx, 0.01));
      expect(bounds.center.dy, closeTo(kLaptop.center.dy, 0.01));
    });

    test('shrinks a window saved on a bigger display to fit the smaller one', () {
      // Full-screen-sized on the 27", now restoring onto the laptop.
      const saved = Rect.fromLTWH(0, 25, 2560, 1415);
      final bounds = resolveMainWindowBounds(
        saved: saved,
        workAreas: const [kLaptop],
        primaryWorkArea: kLaptop,
      );
      expect(bounds.size, Size(kLaptop.width, kLaptop.height));
      expect(bounds, kLaptop);
    });

    test('pulls a partly off-screen window fully back on', () {
      // Hanging off the right edge by 440px, but still well within the
      // "this is where it lived" threshold.
      const saved = Rect.fromLTWH(1000, 100, 1200, 700);
      final bounds = resolveMainWindowBounds(
        saved: saved,
        workAreas: const [kLaptop],
        primaryWorkArea: kLaptop,
      );
      expect(bounds.size, const Size(1200, 700));
      expect(bounds.right, kLaptop.right);
      // Moved the minimum distance: only the axis that overflowed changed.
      expect(bounds.top, saved.top);
    });

    test('treats a sliver of overlap as off-screen and re-centres', () {
      // Only 40px of the window's width is on the laptop — below the 100px
      // threshold, so this is a window on a display that went away, not a
      // window the operator nudged off the edge.
      const saved = Rect.fromLTWH(1472, 100, 1440, 900);
      final bounds = resolveMainWindowBounds(
        saved: saved,
        workAreas: const [kLaptop],
        primaryWorkArea: kLaptop,
      );
      expect(bounds.center.dx, closeTo(kLaptop.center.dx, 0.01));
    });

    test('first launch clamps the default size to the display and centres', () {
      const small = Rect.fromLTWH(0, 25, 1280, 775);
      final bounds = resolveMainWindowBounds(
        saved: null,
        workAreas: const [small],
        primaryWorkArea: small,
      );
      // 1440x900 does not fit a 1280x775 work area, so it opens filling it
      // rather than overflowing off the bottom-right.
      expect(bounds, small);
    });

    test('first launch on a roomy display uses the default size, centred', () {
      final bounds = resolveMainWindowBounds(
        saved: null,
        workAreas: const [kLaptop],
        primaryWorkArea: kLaptop,
      );
      expect(bounds.size, defaultMainWindowSize);
      expect(bounds.center.dx, closeTo(kLaptop.center.dx, 0.01));
      expect(bounds.center.dy, closeTo(kLaptop.center.dy, 0.01));
    });

    test('never goes below the minimum size, even on a tiny work area', () {
      const tiny = Rect.fromLTWH(0, 25, 800, 500);
      final bounds = resolveMainWindowBounds(
        saved: null,
        workAreas: const [tiny],
        primaryWorkArea: tiny,
      );
      // The app's layout stops working below this, so it overflows instead of
      // shrinking — and pins to the top-left so the title bar stays reachable.
      expect(bounds.size, mainWindowMinSize);
      expect(bounds.topLeft, tiny.topLeft);
    });

    test('handles a display to the left of the primary (negative x)', () {
      const saved = Rect.fromLTWH(-2000, 200, 1440, 900);
      expect(
        resolveMainWindowBounds(
          saved: saved,
          workAreas: const [kLaptop, kExternalLeft],
          primaryWorkArea: kLaptop,
        ),
        saved,
      );
    });

    test('handles a display above the primary (negative y)', () {
      const saved = Rect.fromLTWH(300, -1200, 1440, 900);
      expect(
        resolveMainWindowBounds(
          saved: saved,
          workAreas: const [kLaptop, kExternalAbove],
          primaryWorkArea: kLaptop,
        ),
        saved,
      );
    });

    test('clamps into a negative-coordinate display that shrank', () {
      const shrunkLeft = Rect.fromLTWH(-1280, 25, 1280, 775);
      const saved = Rect.fromLTWH(-1200, 100, 1440, 900);
      final bounds = resolveMainWindowBounds(
        saved: saved,
        workAreas: const [kLaptop, shrunkLeft],
        primaryWorkArea: kLaptop,
      );
      expect(shrunkLeft.contains(bounds.topLeft), isTrue);
      expect(bounds.width, lessThanOrEqualTo(shrunkLeft.width));
      expect(bounds.left, greaterThanOrEqualTo(shrunkLeft.left));
    });

    test('a window spread across two live displays is left alone', () {
      // Straddling the seam between the laptop and the external monitor. Every
      // pixel of it is on some screen, so there is nothing to correct.
      const saved = Rect.fromLTWH(1212, 100, 1440, 700);
      expect(
        resolveMainWindowBounds(
          saved: saved,
          workAreas: const [kLaptop, kExternalRight],
          primaryWorkArea: kLaptop,
        ),
        saved,
      );
    });

    test('a straddling window follows the display it overlaps most when the '
        'other one is unplugged', () {
      // 300px was on the laptop, 1140px on the external — with the laptop
      // alone it no longer fits where it was, and the external is gone.
      const saved = Rect.fromLTWH(1212, 100, 1440, 700);
      final bounds = resolveMainWindowBounds(
        saved: saved,
        workAreas: const [kExternalRight],
        primaryWorkArea: kExternalRight,
      );
      // The external is the only display left, so it is clamped onto it.
      expect(bounds, const Rect.fromLTWH(1512, 100, 1440, 700));
    });

    test('an empty display list falls back to the primary work area', () {
      const saved = Rect.fromLTWH(2000, 300, 1440, 900);
      final bounds = resolveMainWindowBounds(
        saved: saved,
        workAreas: const [],
        primaryWorkArea: kLaptop,
      );
      expect(bounds.center.dx, closeTo(kLaptop.center.dx, 0.01));
    });
  });

  group('resolveHudPosition', () {
    const hudSize = Size(420, 52);
    const fallback = Offset(700, 30);

    test('keeps a saved position that is still on a display', () {
      expect(
        resolveHudPosition(
          saved: const Offset(300, 200),
          fallback: fallback,
          hudSize: hudSize,
          workAreas: const [kLaptop],
          primaryWorkArea: kLaptop,
        ),
        const Offset(300, 200),
      );
    });

    test('falls back when the display it was saved on is gone', () {
      final position = resolveHudPosition(
        saved: const Offset(3000, 300),
        fallback: fallback,
        hudSize: hudSize,
        workAreas: const [kLaptop],
        primaryWorkArea: kLaptop,
      );
      expect(position, fallback);
    });

    test('clamps the fallback itself on a narrow display', () {
      // A hardcoded default of x=700 would put most of a 420px-wide HUD off
      // the right edge of a 900px-wide work area.
      const narrow = Rect.fromLTWH(0, 25, 900, 600);
      final position = resolveHudPosition(
        saved: null,
        fallback: fallback,
        hudSize: hudSize,
        workAreas: const [narrow],
        primaryWorkArea: narrow,
      );
      expect(position.dx + hudSize.width, lessThanOrEqualTo(narrow.right));
      expect(position.dx, narrow.right - hudSize.width);
    });

    test('pulls a HUD dragged half off the edge back on', () {
      final position = resolveHudPosition(
        saved: const Offset(1400, 500),
        fallback: fallback,
        hudSize: hudSize,
        workAreas: const [kLaptop],
        primaryWorkArea: kLaptop,
      );
      expect(position, Offset(kLaptop.right - hudSize.width, 500));
    });

    test('keeps a HUD saved on a live secondary display', () {
      expect(
        resolveHudPosition(
          saved: const Offset(2200, 400),
          fallback: fallback,
          hudSize: hudSize,
          workAreas: const [kLaptop, kExternalRight],
          primaryWorkArea: kLaptop,
        ),
        const Offset(2200, 400),
      );
    });
  });
}

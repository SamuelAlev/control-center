import 'dart:ui';

import 'package:control_center/app/window_placement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A 1440×900 display. macOS: the menu bar takes the top 25px.
  const display = Rect.fromLTWH(0, 0, 1440, 900);
  const belowMenuBar = Rect.fromLTRB(0, 25, 1440, 900);
  // Windows: a 48px taskbar along the bottom.
  const aboveTaskbar = Rect.fromLTRB(0, 0, 1440, 852);

  group('resolveTrayPanelBounds', () {
    test('opens under a menu-bar icon, centred on it', () {
      final bounds = resolveTrayPanelBounds(
        anchor: const Rect.fromLTWH(1000, 0, 24, 24),
        workAreas: const [belowMenuBar],
        primaryWorkArea: belowMenuBar,
        preferTop: true,
      );
      expect(bounds.size, trayPanelSize);
      expect(bounds.top, greaterThanOrEqualTo(belowMenuBar.top));
      expect(bounds.center.dx, closeTo(1012, 0.01));
    });

    test('opens above a taskbar icon', () {
      final bounds = resolveTrayPanelBounds(
        anchor: const Rect.fromLTWH(1300, 860, 24, 24),
        workAreas: const [aboveTaskbar],
        primaryWorkArea: aboveTaskbar,
        preferTop: false,
      );
      expect(bounds.bottom, lessThanOrEqualTo(aboveTaskbar.bottom));
      expect(bounds.bottom, greaterThan(aboveTaskbar.bottom - 20));
    });

    test('keeps a panel for an icon at the screen edge on screen', () {
      final bounds = resolveTrayPanelBounds(
        anchor: const Rect.fromLTWH(1420, 0, 20, 24),
        workAreas: const [belowMenuBar],
        primaryWorkArea: belowMenuBar,
        preferTop: true,
      );
      expect(bounds.right, lessThanOrEqualTo(display.right));
      expect(bounds.left, greaterThanOrEqualTo(display.left));
    });

    test('opens beside a vertical taskbar', () {
      // Taskbar docked on the right, 60px wide.
      const area = Rect.fromLTRB(0, 0, 1380, 900);
      final bounds = resolveTrayPanelBounds(
        anchor: const Rect.fromLTWH(1400, 800, 24, 24),
        workAreas: const [area],
        primaryWorkArea: area,
        preferTop: false,
      );
      expect(bounds.right, lessThanOrEqualTo(area.right));
      expect(bounds.bottom, lessThanOrEqualTo(area.bottom));
    });

    test('opens toward the larger free space from a point inside', () {
      // Linux reports no icon bounds; the anchor is the cursor.
      final fromTop = resolveTrayPanelBounds(
        anchor: const Rect.fromLTWH(700, 40, 0, 0),
        workAreas: const [display],
        primaryWorkArea: display,
        preferTop: true,
      );
      expect(fromTop.top, greaterThan(40));

      final fromBottom = resolveTrayPanelBounds(
        anchor: const Rect.fromLTWH(700, 880, 0, 0),
        workAreas: const [display],
        primaryWorkArea: display,
        preferTop: false,
      );
      expect(fromBottom.bottom, lessThan(880));
    });

    test('picks the display the icon is on', () {
      const left = Rect.fromLTRB(-1920, 25, 0, 1080);
      final bounds = resolveTrayPanelBounds(
        anchor: const Rect.fromLTWH(-300, 0, 24, 24),
        workAreas: const [belowMenuBar, left],
        primaryWorkArea: belowMenuBar,
        preferTop: true,
      );
      expect(left.contains(bounds.center), isTrue);
    });

    test('shrinks to a short display', () {
      const short = Rect.fromLTRB(0, 25, 1280, 400);
      final bounds = resolveTrayPanelBounds(
        anchor: const Rect.fromLTWH(1000, 0, 24, 24),
        workAreas: const [short],
        primaryWorkArea: short,
        preferTop: true,
      );
      expect(bounds.height, lessThan(trayPanelSize.height));
      expect(bounds.bottom, lessThanOrEqualTo(short.bottom));
    });

    test('without an anchor, takes the primary display corner', () {
      final top = resolveTrayPanelBounds(
        anchor: null,
        workAreas: const [belowMenuBar],
        primaryWorkArea: belowMenuBar,
        preferTop: true,
      );
      expect(top.top, lessThan(belowMenuBar.top + 20));
      expect(top.right, greaterThan(belowMenuBar.right - 20));

      final bottom = resolveTrayPanelBounds(
        anchor: null,
        workAreas: const [aboveTaskbar],
        primaryWorkArea: aboveTaskbar,
        preferTop: false,
      );
      expect(bottom.bottom, greaterThan(aboveTaskbar.bottom - 20));
    });
  });
}

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Height of the caption-button strip: the app-drawn title bar's height
/// (`ShellTitleBar`), so the buttons fill that row from edge to edge.
const double kWindowCaptionHeight = 40;

/// Width of one caption button — Windows' own are 46 wide.
const double _buttonWidth = 46;

/// Side of the square each glyph is drawn in, the size of Windows' own.
const double _glyphSize = 10;

/// What the app-drawn caption buttons act on: the platform window hosting this
/// subtree. Notifies its listeners when that window's state changes.
abstract interface class WindowCaptionActions implements Listenable {
  /// Whether the window is maximized; the middle button restores it then.
  bool get isMaximized;

  /// Whether the window is the active one. An inactive window's buttons dim,
  /// as the native ones do.
  bool get isActive;

  /// Minimizes the window.
  void minimize();

  /// Maximizes the window, or restores it when it already is.
  void toggleMaximize();

  /// Closes the window exactly as its native close button would.
  void close();
}

/// Gives a window whose title bar the app hides — and whose native window
/// controls went with it — the [WindowCaptionActions] the app draws its own
/// with. Absent wherever the platform keeps its controls (macOS, the web), so
/// [WindowCaptionButtons] render nothing there and nothing reserves room.
class WindowCaptionScope extends InheritedWidget {
  /// Creates a [WindowCaptionScope].
  const WindowCaptionScope({
    required this.actions,
    required super.child,
    super.key,
  });

  /// The window the caption buttons act on.
  final WindowCaptionActions actions;

  /// The nearest scope's actions, or null when the window keeps native
  /// controls.
  static WindowCaptionActions? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WindowCaptionScope>()?.actions;

  /// How much of the window's top-end corner the caption buttons cover, for
  /// content that would otherwise sit under them: zero without a scope.
  static double reservedWidthOf(BuildContext context) =>
      maybeOf(context) == null ? 0 : _buttonWidth * 3;

  @override
  bool updateShouldNotify(WindowCaptionScope oldWidget) =>
      actions != oldWidget.actions;
}

/// The minimize, maximize-or-restore and close buttons, drawn by the app for a
/// window whose native ones are gone. Lives in the app's root overlay, at the
/// window's top-end corner, so every surface — the shell, onboarding, the
/// splash — can be closed; [WindowCaptionScope.reservedWidthOf] keeps content
/// out from under it. Renders nothing without a [WindowCaptionScope].
class WindowCaptionButtons extends StatelessWidget {
  /// Creates the [WindowCaptionButtons].
  const WindowCaptionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = WindowCaptionScope.maybeOf(context);
    if (actions == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: actions,
      builder: (context, _) {
        final maximized = actions.isMaximized;
        final active = actions.isActive;
        // Trailing in reading order, as Windows lays out the caption of a
        // mirrored (RTL) window: close sits at the outer edge either way.
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CaptionButton(
              glyph: _CaptionGlyph.minimize,
              label: l10n.windowMinimize,
              windowActive: active,
              onPressed: actions.minimize,
            ),
            _CaptionButton(
              glyph: maximized ? _CaptionGlyph.restore : _CaptionGlyph.maximize,
              label: maximized ? l10n.windowRestore : l10n.windowMaximize,
              windowActive: active,
              onPressed: actions.toggleMaximize,
            ),
            _CaptionButton(
              glyph: _CaptionGlyph.close,
              label: l10n.close,
              windowActive: active,
              onPressed: actions.close,
            ),
          ],
        );
      },
    );
  }
}

/// Places [child] in a [Stack]'s top corner without colliding with the
/// window's controls: level with the caption buttons and just inside them
/// where the app draws those (at the top-end), [margin] in from the physical
/// top-right where it does not.
class WindowCaptionCorner extends StatelessWidget {
  /// Creates a [WindowCaptionCorner].
  const WindowCaptionCorner({required this.child, this.margin = 16, super.key});

  /// The corner control.
  final Widget child;

  /// The inset from the top and end edges when there are no caption buttons.
  final double margin;

  @override
  Widget build(BuildContext context) {
    final reserved = WindowCaptionScope.reservedWidthOf(context);
    if (reserved == 0) {
      // RTL carve-out: without app-drawn caption buttons this corner stays
      // the physical top-right in either direction. macOS pins its traffic
      // lights to the physical top-left whatever the app's text direction,
      // so a mirrored corner would land underneath them.
      return Positioned(top: margin, right: margin, child: child);
    }
    return PositionedDirectional(
      top: 0,
      end: reserved,
      child: SizedBox(
        height: kWindowCaptionHeight,
        child: Center(child: child),
      ),
    );
  }
}

enum _CaptionGlyph { minimize, maximize, restore, close }

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.glyph,
    required this.label,
    required this.windowActive,
    required this.onPressed,
  });

  final _CaptionGlyph glyph;
  final String label;
  final bool windowActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final isClose = glyph == _CaptionGlyph.close;
    return CcTooltip(
      message: label,
      child: CcTappable(
        onPressed: onPressed,
        // Window chrome, not content: the native buttons sit outside the Tab
        // order and keep the arrow cursor.
        canRequestFocus: false,
        mouseCursor: SystemMouseCursors.basic,
        semanticLabel: label,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          final pressed = states.contains(WidgetState.pressed);
          // Close turns red under the pointer, as everywhere on Windows. Idle
          // fills are alpha-0 of the hover color so the fade lerps alpha only.
          final hoverFill = isClose ? t.bgErrorSolid : t.hover;
          final Color fill;
          if (pressed) {
            fill = isClose ? t.bgErrorSolidHover : t.hoverStrong;
          } else if (hovered) {
            fill = hoverFill;
          } else {
            fill = hoverFill.withValues(alpha: 0);
          }
          final Color ink;
          if (isClose && (hovered || pressed)) {
            ink = t.fgWhite;
          } else {
            ink = windowActive ? t.textPrimary : t.textTertiary;
          }
          return AnimatedContainer(
            duration: CcMotion.resolveFade(context, CcMotion.fast),
            curve: CcMotion.standard,
            width: _buttonWidth,
            height: kWindowCaptionHeight,
            alignment: Alignment.center,
            color: fill,
            child: CustomPaint(
              size: const Size.square(_glyphSize),
              painter: _CaptionGlyphPainter(glyph, ink),
            ),
          );
        },
      ),
    );
  }
}

/// Windows' caption glyphs: hairline strokes in a 10px square. Physical
/// painter coordinates — like the native glyphs, these do not mirror.
class _CaptionGlyphPainter extends CustomPainter {
  const _CaptionGlyphPainter(this.glyph, this.color);

  final _CaptionGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Strokes run on half-pixel coordinates: a 1px line centred on a whole
    // one straddles two pixel rows and paints both at half strength.
    const lo = 0.5;
    const hi = _glyphSize - 0.5;
    switch (glyph) {
      case _CaptionGlyph.minimize:
        canvas.drawLine(
          const Offset(0, _glyphSize / 2 + 0.5),
          const Offset(_glyphSize, _glyphSize / 2 + 0.5),
          paint,
        );
      case _CaptionGlyph.maximize:
        canvas.drawRect(const Rect.fromLTRB(lo, lo, hi, hi), paint);
      case _CaptionGlyph.restore:
        // The restored window in front, and the corner of the one behind.
        canvas
          ..drawRect(const Rect.fromLTRB(lo, lo + 2, hi - 2, hi), paint)
          ..drawPath(
            Path()
              ..moveTo(lo + 2, lo + 2)
              ..lineTo(lo + 2, lo)
              ..lineTo(hi, lo)
              ..lineTo(hi, hi - 2)
              ..lineTo(hi - 2, hi - 2),
            paint,
          );
      case _CaptionGlyph.close:
        canvas
          ..drawLine(const Offset(lo, lo), const Offset(hi, hi), paint)
          ..drawLine(const Offset(hi, lo), const Offset(lo, hi), paint);
    }
  }

  @override
  bool shouldRepaint(_CaptionGlyphPainter oldDelegate) =>
      glyph != oldDelegate.glyph || color != oldDelegate.color;
}

import 'dart:async';

import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// Severity of a [CcToast], driving its accent color plus a leading status
/// shape so the meaning never relies on color alone (DESIGN.md).
enum CcToastVariant {
  /// Informational, no strong connotation.
  neutral,

  /// Positive outcome.
  success,

  /// Caution / non-blocking issue.
  warning,

  /// Failure / blocking error.
  danger,
}

/// All toasts share one fixed width so a stack reads as one designed surface
/// and the close control sits in a predictable spot.
const double _toastWidth = 360;

/// Hosts an [Overlay]-backed queue of transient toasts.
///
/// Place a [CcToastScope] near the app root (inside an [Overlay] ancestor).
/// Descendants call `CcToastScope.of(context).show(message, variant)` to
/// enqueue a toast; concurrent toasts stack toward [alignment] with the newest
/// nearest the anchored edge. Each toast animates in, waits [duration] (paused
/// while hovered, so it can be read), then animates out — or dismisses
/// immediately via its close control. The handle is self-contained — no
/// Riverpod or other state-management dependency.
class CcToastScope extends StatefulWidget {
  /// Creates a [CcToastScope] wrapping [child].
  const CcToastScope({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 5),
    this.alignment = Alignment.bottomRight,
  });

  /// The subtree that can surface toasts.
  final Widget child;

  /// How long each toast stays before auto-dismissing (per-toast overridable
  /// via `show(duration: …)`). Hovering a toast pauses the countdown.
  final Duration duration;

  /// Where the toast stack sits within the overlay.
  final Alignment alignment;

  /// The nearest [CcToastHandle], or null when there is no [CcToastScope]
  /// ancestor.
  static CcToastHandle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CcToastScopeMarker>()?.handle;

  /// The nearest [CcToastHandle]. Asserts a [CcToastScope] ancestor exists.
  static CcToastHandle of(BuildContext context) {
    final handle = maybeOf(context);
    assert(handle != null, 'No CcToastScope found in context.');
    return handle!;
  }

  @override
  State<CcToastScope> createState() => _CcToastScopeState();
}

/// Imperative entry point exposed by [CcToastScope.of].
abstract class CcToastHandle {
  /// Enqueues a toast with [message] and [variant], returning its dismisser.
  ///
  /// [title] renders as a semibold headline above the message, for toasts
  /// where the outcome and its detail read better apart ("Pipeline failed" /
  /// "The build step exited with code 1"). [duration] overrides the scope's
  /// dwell time for this toast only.
  VoidCallback show(
    String message, {
    CcToastVariant variant = CcToastVariant.neutral,
    String? title,
    Duration? duration,
  });
}

class _CcToastScopeState extends State<CcToastScope> implements CcToastHandle {
  final List<_ToastEntry> _entries = [];
  OverlayEntry? _overlayEntry;

  @override
  void didUpdateWidget(CcToastScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alignment != widget.alignment) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.timer?.cancel();
      entry.timer = null;
    }
    _entries.clear();
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  VoidCallback show(
    String message, {
    CcToastVariant variant = CcToastVariant.neutral,
    String? title,
    Duration? duration,
  }) {
    final entry = _ToastEntry(
      message: message,
      title: title,
      variant: variant,
      duration: duration ?? widget.duration,
    );
    _entries.add(entry);

    final existing = _overlayEntry;
    if (existing == null) {
      final overlayEntry = OverlayEntry(builder: _buildStack);
      _overlayEntry = overlayEntry;
      Overlay.of(context, rootOverlay: true).insert(overlayEntry);
    } else {
      existing.markNeedsBuild();
    }

    entry.timer = Timer(entry.duration, () => _dismiss(entry));
    return () => _dismiss(entry);
  }

  Widget _buildStack(BuildContext context) {
    final theme = context.ccTheme;
    final t = theme?.tokens ?? DesignSystemTokens.light();

    // The stack lives in the root overlay, outside any route's `Material`/text
    // theme. The only ambient `DefaultTextStyle` there is `WidgetsApp`'s error
    // fallback — 48px red text with a double yellow underline — and `copyWith`
    // on the per-Text styles leaves `decoration` unset, so the underline would
    // bleed through. Supply a complete design-system base style (concrete
    // size + token color + `decoration: none`), same as `showCcDialog`.
    final baseStyle = CcFonts.ui(
      family: theme?.fontFamily,
      textStyle: CcTypography.bodySm.copyWith(
        color: t.textPrimary,
        decoration: TextDecoration.none,
      ),
    );

    // Newest toast enters at the anchored edge and pushes the others away
    // from it; a top-anchored stack therefore lists newest-first.
    final bottomAnchored = widget.alignment.y >= 0;
    final ordered = bottomAnchored
        ? _entries
        : _entries.reversed.toList(growable: false);

    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Align(
            alignment: widget.alignment,
            child: DefaultTextStyle(
              style: baseStyle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _toastWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in ordered)
                      _CcToast(
                        key: entry.key,
                        entry: entry,
                        gapAbove: bottomAnchored,
                        slideFromBelow: bottomAnchored,
                        onDismissed: () => _remove(entry),
                        onDismissRequested: () => _dismiss(entry),
                        onHoverChanged: (hovering) =>
                            hovering ? _pause(entry) : _resume(entry),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss(_ToastEntry entry) {
    if (!_entries.contains(entry)) {
      return;
    }
    entry.timer?.cancel();
    entry.timer = null;
    entry.controller.dismiss();
  }

  /// Holds the auto-dismiss countdown while the pointer rests on the toast.
  void _pause(_ToastEntry entry) {
    entry.timer?.cancel();
    entry.timer = null;
  }

  /// Re-arms the countdown (a full dwell, so the toast stays readable after a
  /// hover) unless the toast is already on its way out.
  void _resume(_ToastEntry entry) {
    if (!_entries.contains(entry) || entry.controller.dismissing) {
      return;
    }
    entry.timer ??= Timer(entry.duration, () => _dismiss(entry));
  }

  void _remove(_ToastEntry entry) {
    if (!_entries.remove(entry)) {
      return;
    }
    entry.timer?.cancel();
    entry.timer = null;
    if (_entries.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry?.dispose();
      _overlayEntry = null;
    } else {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CcToastScopeMarker(handle: this, child: widget.child);
  }
}

class _ToastEntry {
  _ToastEntry({
    required this.message,
    required this.title,
    required this.variant,
    required this.duration,
  });

  /// Keys the toast's widget so its State survives stack rebuilds.
  final Key key = UniqueKey();
  final String message;
  final String? title;
  final CcToastVariant variant;
  final Duration duration;
  final _ToastDismissController controller = _ToastDismissController();
  Timer? timer;
}

/// Lets the scope ask a mounted toast to play its exit animation.
class _ToastDismissController extends ChangeNotifier {
  bool _dismissing = false;

  bool get dismissing => _dismissing;

  void dismiss() {
    if (!_dismissing) {
      _dismissing = true;
      notifyListeners();
    }
  }
}

class _CcToastScopeMarker extends InheritedWidget {
  const _CcToastScopeMarker({required this.handle, required super.child});

  final CcToastHandle handle;

  @override
  bool updateShouldNotify(_CcToastScopeMarker oldWidget) =>
      handle != oldWidget.handle;
}

/// A single floating toast card. Animates in on mount (rising toward the
/// anchored edge while its slot expands, nudging older toasts along) and out
/// when its [entry]'s controller requests dismissal, then calls [onDismissed].
class _CcToast extends StatefulWidget {
  const _CcToast({
    super.key,
    required this.entry,
    required this.gapAbove,
    required this.slideFromBelow,
    required this.onDismissed,
    required this.onDismissRequested,
    required this.onHoverChanged,
  });

  final _ToastEntry entry;

  /// Whether the stacking gap sits above (bottom-anchored stacks) or below
  /// (top-anchored) this toast. Inside the animated slot so it collapses too.
  final bool gapAbove;

  /// Entry slide direction — toward the anchored edge.
  final bool slideFromBelow;

  final VoidCallback onDismissed;
  final VoidCallback onDismissRequested;
  final ValueChanged<bool> onHoverChanged;

  @override
  State<_CcToast> createState() => _CcToastState();
}

class _CcToastState extends State<_CcToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _animation, curve: CcMotion.standard);
    widget.entry.controller.addListener(_onControllerChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playIn());
  }

  @override
  void dispose() {
    widget.entry.controller.removeListener(_onControllerChange);
    _animation.dispose();
    super.dispose();
  }

  void _playIn() {
    if (!mounted) {
      return;
    }
    _animation.duration = CcMotion.resolve(context, CcMotion.normal);
    _animation.forward();
  }

  void _onControllerChange() {
    if (widget.entry.controller.dismissing) {
      _playOut();
    }
  }

  Future<void> _playOut() async {
    if (!mounted) {
      widget.onDismissed();
      return;
    }
    _animation.duration = CcMotion.resolve(context, CcMotion.fast);
    await _animation.reverse();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final accent = _accentColor(t);
    final title = widget.entry.title;
    final message = widget.entry.message;

    final statusIcon = switch (widget.entry.variant) {
      CcToastVariant.neutral => CcIcons.info,
      CcToastVariant.success => CcIcons.circleCheck,
      CcToastVariant.warning => CcIcons.triangleAlert,
      CcToastVariant.danger => CcIcons.circleX,
    };

    // Status rides the border like agent/PR cards (mixed into the hairline,
    // never the fill) so a stack of outcomes stays scannable; neutral keeps
    // the plain hairline and never spends the orange accent on its edge.
    final borderColor = widget.entry.variant == CcToastVariant.neutral
        ? t.borderPrimary
        : Color.lerp(t.borderPrimary, accent, 0.35)!;

    return Semantics(
      container: true,
      liveRegion: true,
      label: title == null ? message : '$title. $message',
      child: AnimatedBuilder(
        animation: _curve,
        // `Align.heightFactor` grows the slot without clipping (a
        // SizeTransition's ClipRect would shear off the golden-float shadow),
        // so entering/leaving toasts smoothly push or release their neighbors.
        builder: (context, child) => Align(
          alignment: widget.slideFromBelow
              ? Alignment.bottomCenter
              : Alignment.topCenter,
          heightFactor: _curve.value.clamp(0.0, 1.0),
          child: child,
        ),
        child: FadeTransition(
          opacity: _curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, widget.slideFromBelow ? 0.12 : -0.12),
              end: Offset.zero,
            ).animate(_curve),
            child: Padding(
              padding: EdgeInsets.only(
                top: widget.gapAbove ? AppSpacing.sm : 0,
                bottom: widget.gapAbove ? 0 : AppSpacing.sm,
              ),
              child: MouseRegion(
                onEnter: (_) => widget.onHoverChanged(true),
                onExit: (_) => widget.onHoverChanged(false),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.panel,
                    borderRadius: AppRadii.brSm,
                    border: Border.all(color: borderColor),
                    boxShadow: CcElevation.floating,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status glyph — meaning is color + shape + text,
                        // never color alone.
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xxs,
                            right: AppSpacing.sm,
                          ),
                          child: Icon(statusIcon, size: 16, color: accent),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null) ...[
                                Text(
                                  title,
                                  style: CcTypography.bodySm.copyWith(
                                    color: t.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                              ],
                              Text(
                                message,
                                style: CcTypography.bodySm.copyWith(
                                  color: title == null
                                      ? t.textPrimary
                                      : t.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _ToastCloseButton(
                          onClose: widget.onDismissRequested,
                          color: t.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(DesignSystemTokens t) {
    switch (widget.entry.variant) {
      case CcToastVariant.neutral:
        return t.accent;
      case CcToastVariant.success:
        return t.success;
      case CcToastVariant.warning:
        return t.warn;
      case CcToastVariant.danger:
        return t.danger;
    }
  }
}

/// The toast's dismiss control, mirroring [CcAlert]'s close affordance.
class _ToastCloseButton extends StatelessWidget {
  const _ToastCloseButton({required this.onClose, required this.color});

  final VoidCallback onClose;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CcTappable(
      onPressed: onClose,
      semanticLabel: 'Dismiss',
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(
            CcIcons.x,
            size: 14,
            color: hovered ? color : color.withValues(alpha: 0.8),
          ),
        );
      },
    );
  }
}

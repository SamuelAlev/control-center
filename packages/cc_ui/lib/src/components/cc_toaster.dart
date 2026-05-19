import 'dart:async';

import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
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

/// Hosts an [Overlay]-backed queue of transient toasts.
///
/// Place a [CcToastScope] near the app root (inside an [Overlay] ancestor).
/// Descendants call `CcToastScope.of(context).show(message, variant)` to enqueue
/// a toast; each is inserted as an [OverlayEntry] that animates in, waits
/// [CcToastScope.duration], then animates out and removes itself. The handle is
/// self-contained — no Riverpod or other state-management dependency.
class CcToastScope extends StatefulWidget {
  /// Creates a [CcToastScope] wrapping [child].
  const CcToastScope({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.alignment = Alignment.bottomRight,
  });

  /// The subtree that can surface toasts.
  final Widget child;

  /// How long each toast stays before auto-dismissing.
  final Duration duration;

  /// Where the toast stack sits within the overlay.
  final Alignment alignment;

  /// The nearest [CcToastHandle], or null when there is no [CcToastScope]
  /// ancestor.
  static CcToastHandle? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_CcToastScopeMarker>()
          ?.handle;

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
  VoidCallback show(
    String message, {
    CcToastVariant variant = CcToastVariant.neutral,
  });
}

class _CcToastScopeState extends State<CcToastScope> implements CcToastHandle {
  final List<_ToastEntry> _entries = [];

  @override
  void dispose() {
    for (final entry in List<_ToastEntry>.of(_entries)) {
      entry.timer?.cancel();
      entry.overlayEntry.remove();
    }
    _entries.clear();
    super.dispose();
  }

  @override
  VoidCallback show(
    String message, {
    CcToastVariant variant = CcToastVariant.neutral,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final controller = _ToastDismissController();
    late final _ToastEntry entry;

    final overlayEntry = OverlayEntry(
      builder: (context) {
        return _ToastStack(
          alignment: widget.alignment,
          child: _CcToast(
            message: message,
            variant: variant,
            controller: controller,
            onDismissed: () => _remove(entry),
            onDismissRequested: () => _dismiss(entry),
          ),
        );
      },
    );

    entry = _ToastEntry(overlayEntry: overlayEntry, controller: controller);
    _entries.add(entry);
    overlay.insert(overlayEntry);

    entry.timer = Timer(widget.duration, () => _dismiss(entry));
    return () => _dismiss(entry);
  }

  void _dismiss(_ToastEntry entry) {
    if (!_entries.contains(entry)) {
      return;
    }
    entry.timer?.cancel();
    entry.timer = null;
    entry.controller.dismiss();
  }

  void _remove(_ToastEntry entry) {
    if (!_entries.remove(entry)) {
      return;
    }
    entry.timer?.cancel();
    if (entry.overlayEntry.mounted) {
      entry.overlayEntry.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CcToastScopeMarker(handle: this, child: widget.child);
  }
}

class _ToastEntry {
  _ToastEntry({required this.overlayEntry, required this.controller});

  final OverlayEntry overlayEntry;
  final _ToastDismissController controller;
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

/// Aligns a single toast within the overlay with a small inset.
class _ToastStack extends StatelessWidget {
  const _ToastStack({required this.alignment, required this.child});

  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Align(alignment: alignment, child: child),
          ),
        ),
      ),
    );
  }
}

/// A single floating toast card. Animates in on mount and out when its
/// [controller] requests dismissal, then calls [onDismissed].
class _CcToast extends StatefulWidget {
  const _CcToast({
    required this.message,
    required this.variant,
    required this.controller,
    required this.onDismissed,
    required this.onDismissRequested,
  });

  final String message;
  final CcToastVariant variant;
  final _ToastDismissController controller;
  final VoidCallback onDismissed;
  final VoidCallback onDismissRequested;

  @override
  State<_CcToast> createState() => _CcToastState();
}

class _CcToastState extends State<_CcToast> with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _animation, curve: CcMotion.standard);
    widget.controller.addListener(_onControllerChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playIn());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
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
    if (widget.controller.dismissing) {
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
    final t = context.designSystem ?? DesignSystemTokens.light();
    final accent = _accentColor(t);

    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(_curve),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.panel,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: t.borderPrimary),
              boxShadow: CcElevation.floating,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status shape — a small bar so meaning isn't color-only.
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(
                      top: AppSpacing.xxs,
                      right: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(DesignSystemTokens t) {
    switch (widget.variant) {
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

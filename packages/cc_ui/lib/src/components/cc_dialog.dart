import 'dart:ui' as ui;

import 'package:cc_ui/src/components/cc_button.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_text_field.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A flat, floating modal dialog surface for the design system.
///
/// Renders a centered panel (`t.panel` background, [AppRadii.brLg] corners, the
/// signature warm [CcElevation.floating] shadow, hairline border) with an
/// optional [title], a required [content], an optional right-aligned [actions]
/// row and an optional [onClose] close (×) control. Pair with [showCcDialog]
/// to present it over a scrim; [showCcDialog] owns the modal focus lifecycle
/// (focus trap, initial focus, focus restore, Escape) and the dialog role.
class CcDialog extends StatelessWidget {
  /// Creates a [CcDialog].
  const CcDialog({
    super.key,
    required this.content,
    this.title,
    this.actions,
    this.onClose,
    this.maxWidth = 480,
  });

  /// Optional heading shown above the [content].
  final String? title;

  /// The dialog body.
  final Widget content;

  /// Optional action buttons, laid out in a right-aligned row.
  final List<Widget>? actions;

  /// Optional close handler. When set, a close (×) control renders at the
  /// top-right of the header (standard modal anatomy).
  final VoidCallback? onClose;

  /// Maximum width of the dialog panel.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final actions = this.actions;
    final title = this.title;
    final showHeader = title != null || onClose != null;

    return Semantics(
      // Announce the dialog as a route scope to assistive tech.
      scopesRoute: true,
      explicitChildNodes: true,
      label: title ?? 'Dialog',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.panel,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: t.borderPrimary),
            boxShadow: CcElevation.floating,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header + body share the padded region; the footer button bar
              // is full-bleed beneath a hairline divider (a clean split
              // between reading the dialog and acting on it).
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showHeader) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Expanded(
                              child: Text(
                                title,
                                style: CcTypography.title.copyWith(
                                  color: t.textPrimary,
                                ),
                              ),
                            ),
                          if (onClose != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _DialogCloseButton(onClose: onClose!),
                          ],
                        ],
                      ),
                      AppSpacing.vGapMd,
                    ],
                    DefaultTextStyle.merge(
                      style: CcTypography.body.copyWith(color: t.textSecondary),
                      child: content,
                    ),
                  ],
                ),
              ),
              if (actions != null && actions.isNotEmpty)
                _DialogFooter(actions: actions),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full-bleed action bar beneath a [CcDialog] body.
///
/// A top hairline divider separates the reading region from the acting region;
/// actions sit in a padded, right-aligned row. Keeping the bar as its own
/// full-width band (rather than an inline row inside the body padding) is what
/// gives the modal its considered, split anatomy.
class _DialogFooter extends StatelessWidget {
  const _DialogFooter({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.borderPrimary)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        // A Wrap, not a Row: the panel is a fixed 480 and a Row overflows into
        // the yellow-and-black stripe as soon as three actions carry real
        // words ("Cancel · Shut down · Keep running" misses by 52px). Wrapping
        // is identical while they fit — same gap, same right alignment — and
        // degrades to a second line instead of a rendering error when they do
        // not, which is what a dialog in seven languages has to survive.
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: actions,
        ),
      ),
    );
  }
}

/// The small dismiss control for a [CcDialog] header.
class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return CcTappable(
      onPressed: onClose,
      semanticLabel: 'Close',
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            CcIcons.x,
            size: 16,
            color: hovered ? t.textSecondary : t.textTertiary,
          ),
        );
      },
    );
  }
}

/// Presents a confirmation dialog for a consequential action and resolves to
/// whether the user confirmed.
///
/// This encodes the common-actions ladder for destructive/irreversible
/// operations — match the friction to the blast radius:
///
/// * **Low impact** (trivially undone or recreated): don't confirm at all;
///   act immediately and offer undo instead of calling this.
/// * **Moderate impact** (bulk changes, hard-to-recreate data): call with
///   [danger] and a [message] that spells out the consequences — what is
///   destroyed, what survives, whether it can be recovered.
/// * **High impact** (expensive or large-scale loss): additionally pass
///   [typeToConfirm] (usually the resource's name); the confirm button stays
///   disabled until the user types it back exactly.
///
/// The cancel action is always the quiet secondary button, the confirm action
/// carries the weight ([CcButtonVariant.destructive] when [danger], primary
/// otherwise) and its [confirmLabel] should name the specific action
/// ("Delete workspace"), never a bare "OK"/"Yes". Danger dialogs are not
/// dismissed by Escape or a scrim tap — they demand an explicit choice. The
/// caller localizes every string.
Future<bool> showCcConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool danger = false,
  String? typeToConfirm,
  String? typeToConfirmLabel,
}) async {
  final confirmed = await showCcDialog<bool>(
    context: context,
    barrierDismissible: !danger,
    builder: (context) => _CcConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
      typeToConfirm: typeToConfirm,
      typeToConfirmLabel: typeToConfirmLabel,
    ),
  );
  return confirmed ?? false;
}

class _CcConfirmDialog extends StatefulWidget {
  const _CcConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
    required this.typeToConfirm,
    required this.typeToConfirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final String? typeToConfirm;
  final String? typeToConfirmLabel;

  @override
  State<_CcConfirmDialog> createState() => _CcConfirmDialogState();
}

class _CcConfirmDialogState extends State<_CcConfirmDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _armed =>
      widget.typeToConfirm == null ||
      _controller.text.trim() == widget.typeToConfirm;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return CcDialog(
      title: widget.title,
      onClose: () => navigator.pop(false),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          if (widget.typeToConfirm != null) ...[
            AppSpacing.vGapMd,
            CcTextField(
              controller: _controller,
              label: widget.typeToConfirmLabel,
              hintText: widget.typeToConfirm,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_armed) {
                  navigator.pop(true);
                }
              },
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => navigator.pop(false),
          child: Text(widget.cancelLabel),
        ),
        CcButton(
          variant: widget.danger
              ? CcButtonVariant.destructive
              : CcButtonVariant.primary,
          onPressed: _armed ? () => navigator.pop(true) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Owns the modal focus lifecycle for a [showCcDialog] route.
///
/// On mount it captures the currently focused node (to restore it on close),
/// moves initial focus into the dialog and traps Tab/Shift-Tab inside it via
/// [FocusTrap]. Escape dismisses the dialog when [onDismiss] is provided
/// (which [showCcDialog] gates on `barrierDismissible`, so danger/confirmation
/// dialogs that set it false are not Esc-dismissable). Implements the
/// dialog-pattern accessibility requirements (#1–4: shift focus in, initial
/// focus on first focusable, trap focus, restore focus on close).
class _DialogFocusScope extends StatefulWidget {
  const _DialogFocusScope({required this.child, this.onDismiss});

  final Widget child;

  /// Called on Escape. Null disables Escape dismissal (danger modals).
  final VoidCallback? onDismiss;

  @override
  State<_DialogFocusScope> createState() => _DialogFocusScopeState();
}

class _DialogFocusScopeState extends State<_DialogFocusScope> {
  final FocusScopeNode _scopeNode = FocusScopeNode(
    // Trap Tab/Shift-Tab inside the dialog: at the focusable edge the focus
    // wraps to the other end instead of escaping to the background route.
    // (The dialog route's own scope defaults to `parentScope`, which is why an
    // un-trapped dialog lets Tab leak out — a fresh nested scope with
    // `closedLoop` is the genuine Flutter focus trap.)
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  FocusNode? _previousFocus;

  @override
  void initState() {
    super.initState();
    // Capture the focus owner before the dialog took over so it can be
    // restored when the dialog closes.
    _previousFocus = FocusManager.instance.primaryFocus;
  }

  @override
  void dispose() {
    _scopeNode.dispose();
    // Restore focus to whatever opened the dialog — but only while that node is
    // still in the focus tree.
    //
    // `context != null` is NOT a liveness test: a [FocusNode] keeps the context
    // it was attached with after it detaches, so a trigger that unmounted while
    // the dialog was up (a popover closing behind it, the page below rebuilding,
    // a list item recycling) still passes it. `parent != null` is the real test
    // — a detached node has no parent — and it also skips the root scope, where
    // there is nothing to restore anyway.
    //
    // Focusing a detached node is not a harmless no-op. [FocusNode] defers such
    // a request to its next reparent, but [FocusScopeNode] (the popover/menu
    // panel case, where the panel's own scope holds the focus) overrides
    // `_doRequestFocus` without that guard: it walks its *stale* ancestors cache
    // and re-registers the dead node as the route scope's `focusedChild`. That
    // trips `_focusedChildren.last.enclosingScope == this` inside
    // `FocusScopeNode.focusedChild` — thrown from the focus microtask via the
    // next pending autofocus, so the report lands far from this line — and in
    // release parks the primary focus on a detached subtree, which silently
    // breaks keyboard input until something else takes focus.
    final previous = _previousFocus;
    if (previous != null &&
        previous.parent != null &&
        previous.context != null) {
      previous.requestFocus();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bindings = widget.onDismiss == null
        ? const <ShortcutActivator, VoidCallback>{}
        : {const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss!};
    return CallbackShortcuts(
      bindings: bindings,
      child: FocusScope(
        node: _scopeNode,
        // Move initial focus into the dialog on mount.
        autofocus: true,
        child: widget.child,
      ),
    );
  }
}

/// Presents a modal dialog built by [builder], centered over a warm scrim.
///
/// Implemented with [showGeneralDialog] (part of `package:flutter/widgets.dart`)
/// so cc_ui stays off the Material layer. The scrim is a translucent
/// `bgOverlay` wash over a [BackdropFilter] blur, so the surface beneath stays
/// legible-but-defocused (frosted glass) instead of being fully obscured. The
/// entrance is a quick fade + scale on the panel that collapses to an instant
/// cut when motion is reduced (via [CcMotion.resolve]). Returns the value the
/// dialog is popped with, or null if dismissed.
///
/// Owns the modal accessibility lifecycle: focus is moved into the dialog on
/// open, trapped inside it (Tab/Shift-Tab cannot reach the background),
/// restored to the trigger on close and Escape dismisses — unless
/// `barrierDismissible` is false (danger/confirmation dialogs).
Future<T?> showCcDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final theme = context.ccTheme;
  final t = theme?.tokens ?? DesignSystemTokens.light();
  final duration = CcMotion.resolve(context, CcMotion.normal);

  // `showGeneralDialog` presents into the root overlay, outside any route's
  // `Material`/text theme. The only ambient `DefaultTextStyle` there is
  // `WidgetsApp`'s error fallback — 48px red text with a double yellow
  // underline — which every dialog `Text` would otherwise inherit (and
  // bleed the underline through, since copyWith leaves `decoration` unset).
  // Supply a complete design-system base style here so dialog text renders
  // correctly without dragging cc_ui onto the Material layer.
  final dialogTextStyle = CcFonts.ui(
    family: theme?.fontFamily,
    textStyle: CcTypography.body.copyWith(
      color: t.textPrimary,
      decoration: TextDecoration.none,
    ),
  );

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    // The scrim lives in the page content (so it can blur); keep the route's
    // own barrier transparent but still dismissible.
    barrierColor: const Color(0x00000000),
    transitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) {
      final navigator = Navigator.of(context);
      return DefaultTextStyle(
        style: dialogTextStyle,
        child: _DialogFocusScope(
          // Escape (and scrim tap) dismiss only when allowed; danger dialogs
          // set barrierDismissible false so they require an explicit choice.
          onDismiss: barrierDismissible ? navigator.pop : null,
          child: builder(context),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: CcMotion.emphasized,
      );
      return Stack(
        children: [
          // Frosted scrim over the content beneath. `IgnorePointer` lets taps
          // fall through to the route barrier (dismiss) and to the panel on
          // top. The [BackdropFilter] must never sit inside an
          // `Opacity`/`FadeTransition`: the save-layer boundary blanks its
          // backdrop, so only the tint alpha and blur radius are animated here.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: curved,
                builder: (context, _) {
                  final v = curved.value;
                  return BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 6 * v, sigmaY: 6 * v),
                    child: ColoredBox(
                      color: t.bgOverlay.withValues(alpha: 0.5 * v),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: child,
              ),
            ),
          ),
        ],
      );
    },
  );
}

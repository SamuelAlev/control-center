import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cc_infra/cc_infra_web.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';

final _emojiParser = EmojiParser();

/// Returns true if [status] has any visible content (emoji, message, or busy flag).
bool statusHasContent(GitHubUserStatus status) =>
    status.isBusy ||
    status.message?.isNotEmpty == true ||
    status.emoji?.isNotEmpty == true;

/// Resolves GitHub's `:shortcode:` emoji form to the glyph, or null when the
/// status carries no emoji.
String? resolveStatusEmoji(GitHubUserStatus status) {
  final raw = status.emoji;
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final emojified = _emojiParser.emojify(raw);
  return emojified.isEmpty ? null : emojified;
}

/// The status text without its emoji: the busy flag and the message, in the
/// order GitHub reads them.
String statusText(GitHubUserStatus status, AppLocalizations l10n) {
  final message = status.message?.trim();
  return <String>[
    if (status.isBusy) l10n.userStatusBusy,
    if (message != null && message.isNotEmpty) message,
  ].join(' · ');
}

/// A pill badge that mirrors GitHub's user status display.
/// Shows an orange border when `status.isBusy` is true, neutral otherwise.
class GitHubUserStatusBadge extends StatelessWidget {
  /// Creates a [GitHubUserStatusBadge].
  const GitHubUserStatusBadge({super.key, required this.status});

  /// The GitHub user status to display.
  final GitHubUserStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    final resolvedEmoji = resolveStatusEmoji(status);
    final text = statusText(status, l10n);

    final label = <String>[?resolvedEmoji, if (text.isNotEmpty) text].join(' ');

    final orange = tokens.accent;
    final isBusy = status.isBusy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBusy ? orange.withValues(alpha: 0.08) : tokens.bgSecondary,
        border: isBusy
            ? Border.all(color: orange.withValues(alpha: 0.6))
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: CcTypography.caption.copyWith(
          color: isBusy ? orange : tokens.textTertiary,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Pins a small circular status badge to the bottom-right of an avatar, the way
/// GitHub does, and grows it rightwards into a pill carrying the full status
/// text on hover.
///
/// The text is deliberately NOT inline. A status is free-form and often long
/// ("I didn't have time to write a short status, so I wrote a long one
/// instead."); rendered beside the display name it either overflows the header
/// or squeezes the name out of it. Only the emoji is spent on the resting
/// layout — the message is one hover away, and a screen reader gets it from the
/// badge's semantic label without hovering anything.
///
/// The hover panel is not a tooltip: it is the badge itself, extended. It opens
/// at the badge's exact size and position and animates its width (and, when the
/// text has to wrap, its height) out to the right, so the circle reads as
/// unrolling into the pill rather than a second surface appearing over it.
class GitHubUserStatusAvatarBadge extends StatefulWidget {
  /// Creates a [GitHubUserStatusAvatarBadge] over [child].
  const GitHubUserStatusAvatarBadge({
    super.key,
    required this.status,
    required this.avatarSize,
    required this.child,
    this.showDelay = const Duration(milliseconds: 120),
  });

  /// The status the badge stands for.
  final GitHubUserStatus status;

  /// Diameter of the avatar the badge is pinned to; drives the badge's size and
  /// keeps it proportional across the call sites.
  final double avatarSize;

  /// The avatar the badge overlays.
  final Widget child;

  /// Hover dwell before the pill unrolls.
  final Duration showDelay;

  @override
  State<GitHubUserStatusAvatarBadge> createState() =>
      _GitHubUserStatusAvatarBadgeState();
}

class _GitHubUserStatusAvatarBadgeState
    extends State<GitHubUserStatusAvatarBadge> {
  final CcOverlayController _overlay = CcOverlayController();
  // Drives the unroll. Owned here (not by the panel) so the pill can roll back
  // up on exit before the overlay is torn down — a panel rebuilt on show can
  // only animate in.
  final ValueNotifier<bool> _expanded = ValueNotifier(false);
  final GlobalKey _badgeKey = GlobalKey();

  Timer? _showTimer;
  Timer? _hideTimer;

  // Room to the right of the badge at open time, so the pill only wraps when it
  // genuinely cannot fit on one line.
  double _room = _kMaxPillWidth;

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _overlay.dispose();
    _expanded.dispose();
    super.dispose();
  }

  void _onEnter() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_overlay.isOpen) {
      // Re-entered mid-rollback: unroll again rather than finish closing.
      _expanded.value = true;
      return;
    }
    _showTimer?.cancel();
    _showTimer = Timer(widget.showDelay, _show);
  }

  void _show() {
    if (!mounted) {
      return;
    }
    _measureRoom();
    _expanded.value = true;
    _overlay.show();
  }

  void _onExit() {
    _showTimer?.cancel();
    _showTimer = null;
    if (!_overlay.isOpen) {
      return;
    }
    // Grace before rolling back, so a pointer that grazes the boundary does not
    // toggle the pill.
    _hideTimer?.cancel();
    _hideTimer = Timer(_kHoverGrace, _collapse);
  }

  void _collapse() {
    _expanded.value = false;
    // Tear the overlay down only once the pill has finished rolling back.
    _hideTimer = Timer(CcMotion.resolve(context, kStatusPillMotion), () {
      if (mounted) {
        _overlay.hide();
      }
    });
  }

  void _measureRoom() {
    final box = _badgeKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final left = box.localToGlobal(Offset.zero).dx;
    final screen = MediaQuery.sizeOf(context).width;
    _room = (screen - left - kCcOverlayMargin).clamp(
      _kMinPillWidth,
      _kMaxPillWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    if (!statusHasContent(widget.status)) {
      return widget.child;
    }

    final emoji = resolveStatusEmoji(widget.status);
    final text = statusText(widget.status, l10n);
    final isBusy = widget.status.isBusy;

    // Roughly GitHub's proportion, floored so the emoji stays legible on the
    // small avatars (40px) the hover card and rows use.
    final badgeSize = (widget.avatarSize * 0.4).clamp(22.0, 34.0);
    final glyphSize = badgeSize * 0.55;
    final glyph = _StatusGlyph(
      emoji: emoji,
      size: glyphSize,
      color: isBusy ? tokens.accent : tokens.textTertiary,
    );

    final badge = Container(
      key: _badgeKey,
      width: badgeSize,
      height: badgeSize,
      alignment: Alignment.center,
      decoration: _pillFill(tokens, badgeSize),
      foregroundDecoration: _pillBorder(tokens, isBusy, badgeSize),
      child: glyph,
    );

    // The WHOLE AVATAR is the hover target, not the badge. A 25px disc in the
    // corner of a 64px avatar is a target a pointer straddles: a few pixels of
    // drift crossed the boundary and the pill toggled open/closed under a hand
    // that had not moved. The status belongs to the person the avatar depicts,
    // so hovering them is the honest trigger — and the pill, anchored to the
    // badge, still reads as unrolling out of it.
    //
    // The badge itself sits INSIDE the avatar's box (its outer edge crosses the
    // circle) rather than hanging off it: a Stack does not hit-test children
    // painted outside its own bounds, so an overhanging badge would take no
    // pointer either.
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: SizedBox(
        width: widget.avatarSize,
        height: widget.avatarSize,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned(
              right: 0,
              bottom: 0,
              child: Semantics(
                label: text.isEmpty ? null : text,
                child: CcOverlayAnchor(
                  controller: _overlay,
                  // Left cap over left cap: the pill opens exactly on top of
                  // the badge and every later frame grows to the right of it.
                  targetAnchor: Alignment.centerLeft,
                  followerAnchor: Alignment.centerLeft,
                  offset: Offset.zero,
                  barrierDismissible: false,
                  target: badge,
                  overlayBuilder: (context, _) => _StatusPill(
                    emoji: emoji,
                    text: text,
                    isBusy: isBusy,
                    badgeSize: badgeSize,
                    glyphSize: glyphSize,
                    room: _room,
                    expanded: _expanded,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Identifies the animated pill box so a test can watch it unroll.
@visibleForTesting
const Key kStatusPillKey = Key('github-user-status-pill');

/// How long the pointer may be off the avatar before the pill rolls back.
const Duration _kHoverGrace = Duration(milliseconds: 90);

/// The unroll's total duration — the box growth and the text fade share it.
///
/// Exposed so the badge can hold the overlay open for exactly as long as the
/// panel takes to roll back up; a shorter teardown cuts the animation off.
@visibleForTesting
const Duration kStatusPillMotion = CcMotion.slow;

/// The share of [kStatusPillMotion] the box growth takes; the text fades in
/// over what is left.
const double _kPillGrowShare = 0.65;

/// Widest the pill ever gets, however much room the window has: past this a
/// single line stops scanning as one thought.
const double _kMaxPillWidth = 620;

/// Narrowest the pill is allowed to plan for before it starts wrapping.
const double _kMinPillWidth = 200;

/// Space between the leading glyph's box and the status text.
const double _kPillGap = 2;

/// Padding after the text, mirroring the glyph box's optical inset.
const double _kPillTrailing = 14;

/// The capsule's fill. Its border is deliberately NOT here: a
/// [BoxDecoration.border] insets a [Container]'s child by its own width, which
/// pushed the pill's leading glyph a pixel to the right of the cap it is meant
/// to sit in the middle of — measurable at 4x, and visible at 1x as the emoji
/// stepping sideways the moment the badge unrolled. The border rides
/// [_pillBorder] as a FOREGROUND decoration instead: painted over the child
/// rather than moving it.
BoxDecoration _pillFill(DesignSystemTokens tokens, double height) =>
    BoxDecoration(
      color: tokens.bgPrimary,
      borderRadius: BorderRadius.circular(height / 2),
    );

BoxDecoration _pillBorder(
  DesignSystemTokens tokens,
  bool isBusy,
  double height,
) => BoxDecoration(
  borderRadius: BorderRadius.circular(height / 2),
  border: Border.all(
    color: isBusy
        ? tokens.accent.withValues(alpha: 0.7)
        : tokens.borderSecondary,
  ),
);

/// The badge's emoji, or a fallback icon for a status that carries a message
/// but no emoji.
///
/// Centring an emoji is not `Alignment.center`, and both axes had to be paid
/// for separately. Measured against the real Apple Color Emoji (CoreText, at
/// 100pt): the ink is the em SQUARE — `[0, 1em]` from the pen horizontally and
/// `[-0.125em, +0.875em]` about the baseline — while the ADVANCE the run is
/// laid out to is 1.275em. So:
///
///  * **Horizontally**, centring the text BOX puts half of that trailing air —
///    0.1375em — on the wrong side, and the ink sits left of centre by it
///    (measured at 4px inside a 50px badge on a 2x display). The glyph is
///    shifted back by half the overhang, taken from the painter rather than
///    hardcoded, so a font whose advance IS its em is shifted by nothing.
///  * **Vertically**, the correction is to stop overriding the line height at
///    all. A single-line box is `ascent + descent` tall with its baseline at
///    `ascent`, which centres the font's em box in it by construction. Forcing
///    `height: 1` collapses that box to one em and moves the baseline, and the
///    descent-sized nudge that used to compensate over-corrected by ~0.125em —
///    the glyph rode visibly low in the circle.
///
/// [TextStyle.inherit] is false on purpose. [Text] merges the ambient
/// [DefaultTextStyle], so the widget rendered with `fontFamily: Manrope` (the
/// emoji reached only through the fallback list) while the [TextPainter] beside
/// it measured with the emoji font as PRIMARY — two different sets of line
/// metrics, which is what made the old vertical correction wrong. Opting out of
/// the merge makes the measurement and the render the same layout, and keeps
/// the overlay's error-fallback style off the glyph for free.
///
/// The glyph is an icon, not text: it does not take the text scaler, because
/// the circle it sits in is sized from the avatar and cannot grow with it.
class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({
    required this.emoji,
    required this.size,
    required this.color,
  });

  final String? emoji;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final emoji = this.emoji;
    if (emoji == null) {
      return Icon(AppIcons.messageCircle, size: size, color: color);
    }

    final families = AppFonts.emojiFallback;
    final style = TextStyle(
      inherit: false,
      fontSize: size,
      color: color,
      fontFamily: families.first,
      fontFamilyFallback: families.length > 1 ? families.sublist(1) : null,
    );
    final painter = TextPainter(
      text: TextSpan(text: emoji, style: style),
      textDirection: Directionality.of(context),
      textScaler: TextScaler.noScaling,
    )..layout();
    // Whatever the advance carries beyond the em square is trailing air the ink
    // never occupies; half of it is what pulls the glyph off centre.
    final overhang = math.max(0.0, painter.width - size);
    painter.dispose();

    return Transform.translate(
      offset: Offset(overhang / 2, 0),
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
        style: style,
      ),
    );
  }
}

/// The hover panel: the badge, unrolled.
///
/// Laid out once at its final size and then revealed by animating the
/// container's box, never by re-laying-out the text — a text that reflowed on
/// every frame of the growth would visibly re-wrap as the pill widened.
class _StatusPill extends StatefulWidget {
  const _StatusPill({
    required this.emoji,
    required this.text,
    required this.isBusy,
    required this.badgeSize,
    required this.glyphSize,
    required this.room,
    required this.expanded,
  });

  final String? emoji;
  final String text;
  final bool isBusy;
  final double badgeSize;
  final double glyphSize;
  final double room;
  final ValueListenable<bool> expanded;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> {
  // The panel's own first frame. The unroll must start from the badge whatever
  // frame the overlay lands on, so t = 0 is owned here and only the *rollback*
  // is taken from the parent's notifier.
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _entered = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.emoji;
    final text = widget.text;
    final isBusy = widget.isBusy;
    final badgeSize = widget.badgeSize;
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    // Measured in the style the text will actually RENDER in, which means
    // resolving the ambient one first. `CcTypography` sets no family on
    // purpose, so a painter handed the bare token measures the platform font
    // while the widget draws Manrope — and the pill comes out visibly wider
    // than its sentence. `decoration: none` is the overlay rule: nothing here
    // may inherit `WidgetsApp`'s error fallback.
    final textStyle = DefaultTextStyle.of(context).style
        .merge(CcTypography.caption)
        .copyWith(
          color: tokens.textPrimary,
          fontWeight: FontWeight.w500,
          height: 1.35,
          decoration: TextDecoration.none,
        );

    // The leading glyph keeps the badge's own footprint so the circle under the
    // pill's left cap lines up exactly.
    final maxTextWidth = widget.room - badgeSize - _kPillGap - _kPillTrailing;
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxTextWidth.clamp(80.0, _kMaxPillWidth));

    // The longest LINE, not the layout box: `width` keeps the whole wrapping
    // constraint once the text runs to more than one line, which would leave
    // the pill far wider than its own sentence.
    final lines = painter.computeLineMetrics();
    final longestLine = lines.isEmpty
        ? painter.width
        : lines.map((l) => l.width).reduce(math.max);
    final textWidth = math.min(painter.width, longestLine).ceilToDouble();
    final textHeight = painter.height.ceilToDouble();
    painter.dispose();

    final width = badgeSize + _kPillGap + textWidth + _kPillTrailing;
    // A one-line pill is EXACTLY the badge's height, so its left cap is the
    // badge rather than a slightly larger disc drawn over it. Only a wrapped
    // status makes it taller.
    final height = math.max(badgeSize, textHeight + 8);

    // The leading glyph is deliberately OUTSIDE the fade below. It is not part
    // of the reveal: it is the badge's own emoji, still standing where it stood
    // — and the pill is opaque, so fading it left the circle it covers looking
    // empty. The emoji blinked out the moment the pointer landed, stayed gone
    // for the whole growth, and blinked out again on the way back.
    final glyph = SizedBox(
      width: badgeSize,
      child: Center(
        child: _StatusGlyph(
          emoji: emoji,
          size: widget.glyphSize,
          color: isBusy ? tokens.accent : tokens.textTertiary,
        ),
      ),
    );

    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.expanded,
        builder: (context, open, _) => TweenAnimationBuilder<double>(
          // A null `begin` holds the first build at `end`, so the opening frame
          // is the badge itself (t = 0) and only the later flips animate.
          tween: Tween<double>(end: open && _entered ? 1 : 0),
          duration: CcMotion.resolve(context, kStatusPillMotion),
          // Linear: the two stages below carry their own curves, and the phase
          // split has to hold on the way back out as well as in.
          curve: Curves.linear,
          builder: (context, t, child) {
            // The box opens first and the text only lands once there is a pill
            // to land in. Simultaneous, the sentence was fully lit while the
            // edge was still travelling through it, so the growth read as a
            // shutter sliding over finished text rather than a pill unrolling.
            // Reversed, the same split reads correctly too: the text leaves
            // before the box it sat in.
            final boxT = CcMotion.standard.transform(
              (t / _kPillGrowShare).clamp(0.0, 1.0),
            );
            final textT = Curves.easeOut.transform(
              ((t - _kPillGrowShare) / (1 - _kPillGrowShare)).clamp(0.0, 1.0),
            );
            final w = ui.lerpDouble(badgeSize, width, boxT)!;
            final h = ui.lerpDouble(badgeSize, height, boxT)!;
            return Container(
              key: kStatusPillKey,
              width: w,
              height: h,
              decoration: _pillFill(tokens, h),
              foregroundDecoration: _pillBorder(tokens, isBusy, h),
              clipBehavior: Clip.antiAlias,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: width,
                maxWidth: width,
                minHeight: height,
                maxHeight: height,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    glyph,
                    const SizedBox(width: _kPillGap),
                    Opacity(opacity: textT, child: child),
                  ],
                ),
              ),
            );
          },
          child: SizedBox(
            width: textWidth,
            child: Text(text, style: textStyle),
          ),
        ),
      ),
    );
  }
}

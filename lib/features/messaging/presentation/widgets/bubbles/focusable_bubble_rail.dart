part of 'focusable_bubble.dart';

/// The action rail: one row of icons directly under the message.
///
/// Its height is reserved unconditionally — the strip occupies the same
/// [_railItemExtent] whether or not the pointer is on the message, so revealing
/// it moves nothing in the feed. That is the whole reason it is laid out here
/// rather than floated beside the message in the app Overlay, which is what it
/// used to be: an overlay costs no space, but it also has to be chased across
/// scroll ticks, kept alive while the cursor crosses the dead pixels between
/// the message and the icons, and de-duplicated against every other rail. In
/// flow, inside the message's own hover region, none of that exists.
///
/// The icons themselves are built on the first reveal and kept from then on.
/// Up to seven tooltips, tappables and focus nodes per row, for every row the
/// feed builds, were the bulk of a row's element count — for a toolbar most
/// rows never show. The reserved box is what keeps the layout still, not the
/// icons inside it.
class _Rail extends StatefulWidget {
  const _Rail({required this.revealed, required this.actions});

  /// Whether the icons are showing. Only this subtree listens, so a hover never
  /// rebuilds the message body.
  final ValueListenable<bool> revealed;

  final List<Widget> actions;

  @override
  State<_Rail> createState() => _RailState();
}

class _RailState extends State<_Rail> {
  /// Whether the icons have been built (first reveal onward).
  bool _materialized = false;

  /// True for the single frame the icons are first laid down transparent, so
  /// the first reveal fades in like every later one.
  bool _priming = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: _railTopGap),
      child: SizedBox(
        height: _railItemExtent,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.revealed,
          builder: (context, revealed, _) {
            if (!_materialized) {
              if (!revealed) {
                return const SizedBox.shrink();
              }
              _materialized = true;
              _priming = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _priming = false);
                }
              });
            }
            final shown = revealed && !_priming;
            return ExcludeSemantics(
              excluding: !shown,
              // A hidden rail must not be clickable and must not add a tab
              // stop: seven invisible buttons per message would otherwise put
              // hundreds of them between a keyboard user and the composer.
              child: ExcludeFocus(
                excluding: !shown,
                child: IgnorePointer(
                  ignoring: !shown,
                  child: AnimatedOpacity(
                    opacity: shown ? 1 : 0,
                    duration: CcMotion.resolve(context, CcMotion.fast),
                    curve: CcMotion.standard,
                    // The same action instances every reveal, so a reveal
                    // rebuilds the opacity wrappers alone, never the icons or
                    // their hit regions.
                    child: RepaintBoundary(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.actions,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

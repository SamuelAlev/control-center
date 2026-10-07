import 'dart:math';

import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Single-line text that churns through random characters while [scrambling],
/// then reveals [text] character by character once it stops — the "still
/// being named" state of a label whose real value is on its way (a
/// conversation title a model is generating).
///
/// Every [speed], each character not yet revealed is re-rolled from
/// [characterSet]. When [scrambling] turns false the reveal runs over
/// [duration], left to right, and [onScrambleComplete] fires once [text]
/// stands on its own. Spaces in [text] stay put, so the churn keeps the word
/// shape, and the box is always sized by [text] itself: the churn never
/// resizes the row it sits in.
///
/// Reduced motion (see [CcMotion.reduced]) shows [text] as is, with no churn
/// and no reveal. Assistive technology always reads [text], never the churn.
class CcScrambleText extends StatefulWidget {
  /// Creates a [CcScrambleText].
  const CcScrambleText(
    this.text, {
    super.key,
    required this.scrambling,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.speed = const Duration(milliseconds: 40),
    this.characterSet = defaultCharacterSet,
    this.onScrambleComplete,
    this.child,
  }) : assert(characterSet != '');

  /// The characters the churn draws from by default.
  static const defaultCharacterSet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  /// The label: what the box is sized by while scrambling, and what the
  /// reveal spells out once [scrambling] turns false.
  final String text;

  /// Whether the characters are churning. Turning it false starts the reveal.
  final bool scrambling;

  /// Text style, merged over the ambient [DefaultTextStyle] (like [Text]).
  final TextStyle? style;

  /// How long the reveal takes, first character to last.
  final Duration duration;

  /// How often the unrevealed characters re-roll.
  final Duration speed;

  /// What the churn draws from.
  final String characterSet;

  /// Called when a reveal finishes. Not called under reduced motion, where
  /// there is no reveal.
  final VoidCallback? onScrambleComplete;

  /// What to show once settled. Defaults to a single-line, ellipsized [Text]
  /// of [text]; pass the surface's own label widget (a [CcTruncatedText]) to
  /// keep its behaviour outside the scramble.
  final Widget? child;

  @override
  State<CcScrambleText> createState() => _CcScrambleTextState();
}

enum _Phase { settled, scrambling, revealing }

class _CcScrambleTextState extends State<CcScrambleText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _random = Random();

  bool _reduced = false;
  _Phase _phase = _Phase.settled;

  /// The churn, one character per rune of [CcScrambleText.text].
  String _scrambled = '';

  /// The ticker frame the reveal started on; null until its first frame.
  int? _revealFrom;

  /// How far through the reveal it is, 0 to 1; 0 while scrambling.
  double _progress = 0;

  int _lastFrame = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = CcMotion.reduced(context);
    _sync();
  }

  @override
  void didUpdateWidget(CcScrambleText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrambling != widget.scrambling ||
        oldWidget.text != widget.text ||
        oldWidget.characterSet != widget.characterSet) {
      _sync();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _sync() {
    if (_reduced) {
      _stop();
      return;
    }
    if (widget.scrambling) {
      _phase = _Phase.scrambling;
      _revealFrom = null;
      _progress = 0;
    } else if (_phase == _Phase.scrambling) {
      // Stopped churning: reveal whatever the label is now (the generated
      // title, or the unchanged placeholder when generation gave up).
      _phase = _Phase.revealing;
    }
    if (_phase == _Phase.settled) {
      return;
    }
    // Re-roll at once (at the reveal's current progress, so a title landing
    // mid-reveal keeps what is already spelled out), so the first frame after
    // a change never flashes the bare label.
    _roll();
    if (!_ticker.isActive) {
      _lastFrame = -1;
      _ticker.start();
    }
  }

  void _stop() {
    _phase = _Phase.settled;
    _revealFrom = null;
    _progress = 0;
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final frame = elapsed.inMicroseconds ~/ widget.speed.inMicroseconds;
    if (frame == _lastFrame) {
      return;
    }
    _lastFrame = frame;
    if (_phase == _Phase.scrambling) {
      setState(_roll);
      return;
    }
    final step = frame - (_revealFrom ??= frame);
    final steps = widget.duration.inMicroseconds / widget.speed.inMicroseconds;
    if (step > steps) {
      setState(_stop);
      widget.onScrambleComplete?.call();
      return;
    }
    setState(() {
      _progress = step / steps;
      _roll();
    });
  }

  /// Re-rolls every character the reveal has not reached.
  void _roll() {
    final runes = widget.text.runes.toList(growable: false);
    final set = widget.characterSet;
    final out = StringBuffer();
    for (var i = 0; i < runes.length; i++) {
      final rune = runes[i];
      if (_isSpace(rune) || _progress * runes.length > i) {
        out.writeCharCode(rune);
      } else {
        out.write(set[_random.nextInt(set.length)]);
      }
    }
    _scrambled = out.toString();
  }

  static bool _isSpace(int rune) =>
      rune == 0x20 || rune == 0x09 || rune == 0xA0 || rune == 0x3000;

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.settled) {
      return widget.child ??
          Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          );
    }
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              // Sizes the box by the real label so the churn never moves
              // its neighbours.
              Opacity(
                opacity: 0,
                child: Text(
                  widget.text,
                  style: widget.style,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Positioned.fill(
                child: Text(
                  _scrambled,
                  style: widget.style,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foveated layout planner for the vision compaction renderer.
///
/// [planArchive] decides how to split normalized source text across at most
/// `maxFrames` frames using two quality tiers: high-quality (HQ) frames at the
/// chronological edges (where the oldest and newest history live), and a denser
/// low-quality (LQ) tier packing the less-important middle. When the source
/// fits, everything is HQ; when it overflows, the oldest middle characters are
/// dropped (the newest are always kept) and [VisionPlan.truncatedRegions] is
/// incremented. Ported from oh-my-pi's `snapcompact.planArchive`.
library;

import 'dart:math' as math;

import 'package:cc_infra/src/messaging/vision/vision_shapes.dart';

/// High-quality (legible) frames rendered at each chronological edge of a
/// foveated archive — the oldest head and the newest tail.
const int hqEdgeFrames = 3;

/// How much denser the low-quality tier packs relative to high-quality. The LQ
/// cell is half the HQ cell on each axis, so an LQ frame holds roughly four
/// times as many characters as an HQ frame at the same frame size.
const int lqDensityFactor = 4;

/// One planned frame slice: the source text plus its quality tier.
class VisionFrameSlice {
  /// Creates a [VisionFrameSlice].
  const VisionFrameSlice({required this.text, required this.highQuality});

  /// The slice of normalized source text rendered onto this frame.
  final String text;

  /// `true` for a high-quality (legible) frame, `false` for the dense
  /// low-quality middle tier.
  final bool highQuality;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionFrameSlice &&
          text == other.text &&
          highQuality == other.highQuality;

  @override
  int get hashCode => Object.hash(text, highQuality);
}

/// A foveated archive layout: ordered frame slices plus a count of dropped
/// regions.
class VisionPlan {
  /// Creates a [VisionPlan].
  const VisionPlan({required this.slices, required this.truncatedRegions});

  /// Frame slices ordered oldest → newest (HQ head, LQ middle, HQ tail).
  final List<VisionFrameSlice> slices;

  /// How many middle regions were dropped this round to fit `maxFrames`.
  final int truncatedRegions;
}

/// HQ characters that fit one frame at [shape]'s cell pitch.
int _capHi(VisionShape shape) => shape.capacity;

/// LQ characters that fit one frame: the HQ capacity scaled by
/// [lqDensityFactor] (half the cell on each axis ⇒ ~4x the chars).
int _capLo(VisionShape shape) => shape.capacity * lqDensityFactor;

/// Plans the foveated frame layout for [sourceText] at [shape].
///
/// - If the text fits within `maxFrames` HQ frames, it is split into
///   `ceil(len / capHi)` all-HQ frames.
/// - Otherwise the first and last `edgeFrames * capHi` characters render at HQ;
///   the remaining middle renders at LQ. `edgeFrames` is
///   `min(hqEdgeFrames, max(0, (maxFrames - 1) ~/ 2))`. If the middle exceeds
///   the LQ budget `(maxFrames - 2*edgeFrames) * capLo`, its oldest characters
///   are dropped (newest kept) and [VisionPlan.truncatedRegions] is set to 1.
///
/// Empty / whitespace-only [sourceText] yields an empty plan.
VisionPlan planArchive({
  required String sourceText,
  required VisionShape shape,
  required int maxFrames,
}) {
  if (sourceText.isEmpty) {
    return const VisionPlan(slices: <VisionFrameSlice>[], truncatedRegions: 0);
  }
  final frames = math.max(1, maxFrames);
  final capHi = _capHi(shape);
  final capLo = _capLo(shape);

  // Single HQ tier when the whole text fits within the HQ budget.
  if (sourceText.length <= frames * capHi) {
    return VisionPlan(
      slices: _sliceFrames(sourceText, capHi, highQuality: true),
      truncatedRegions: 0,
    );
  }

  // Foveate: HQ edges, LQ middle.
  final edgeFrames = math.min(hqEdgeFrames, math.max(0, (frames - 1) ~/ 2));
  if (edgeFrames == 0) {
    // No room for HQ edges; render the newest chars as a single LQ tier and
    // drop the oldest overflow.
    final capacity = frames * capLo;
    if (sourceText.length <= capacity) {
      return VisionPlan(
        slices: _sliceFrames(sourceText, capLo, highQuality: false),
        truncatedRegions: 0,
      );
    }
    final kept = sourceText.substring(sourceText.length - capacity);
    return VisionPlan(
      slices: _sliceFrames(kept, capLo, highQuality: false),
      truncatedRegions: 1,
    );
  }

  final edgeCap = edgeFrames * capHi;
  final headText = sourceText.substring(0, edgeCap);
  final tailText = sourceText.substring(sourceText.length - edgeCap);
  var middleText =
      sourceText.substring(edgeCap, sourceText.length - edgeCap);

  var truncatedRegions = 0;
  final middleCapacity = (frames - 2 * edgeFrames) * capLo;
  if (middleText.length > middleCapacity) {
    // Drop the OLDEST middle chars, keep the newest.
    middleText = middleText.substring(middleText.length - middleCapacity);
    truncatedRegions = 1;
  }

  return VisionPlan(
    slices: <VisionFrameSlice>[
      ..._sliceFrames(headText, capHi, highQuality: true),
      ..._sliceFrames(middleText, capLo, highQuality: false),
      ..._sliceFrames(tailText, capHi, highQuality: true),
    ],
    truncatedRegions: truncatedRegions,
  );
}

/// Slices [text] into [capacity]-character frame slices at one quality tier.
List<VisionFrameSlice> _sliceFrames(
  String text,
  int capacity, {
  required bool highQuality,
}) {
  if (text.isEmpty) {
    return const <VisionFrameSlice>[];
  }
  final slices = <VisionFrameSlice>[];
  for (var offset = 0; offset < text.length; offset += capacity) {
    final end = math.min(offset + capacity, text.length);
    slices.add(
      VisionFrameSlice(
        text: text.substring(offset, end),
        highQuality: highQuality,
      ),
    );
  }
  return slices;
}

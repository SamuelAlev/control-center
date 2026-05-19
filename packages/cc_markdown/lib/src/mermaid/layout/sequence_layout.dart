/// The sequence-diagram layout: lifelines across, time down.
///
/// Lane spacing is CONTENT-DRIVEN, not fixed: lanes start at their box widths,
/// then every message widens the gaps it spans until its label fits between the
/// two lifelines. That is why a diagram with one long message doesn't overlap
/// its neighbors and a diagram of short ones stays compact.
///
/// Frames (`loop`, `alt`/`else`, `opt`, `par`/`and`, `critical`, `break`,
/// `rect`) are laid out by walking their contents first and INSERTING the frame
/// behind them afterwards, so a frame always matches what it actually contains.
library;

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/layout/scene_ops.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:flutter/widgets.dart';

/// Minimum lifeline gap.
const double _kMinLaneGap = 44;

/// Clearance a message label needs beyond its own width.
const double _kLabelClearance = 26;

/// Width of an activation bar.
const double _kActivationWidth = 10;

/// Horizontal reach of a self-message loop.
const double _kSelfLoopWidth = 42;

/// Vertical drop of a self-message loop.
const double _kSelfLoopHeight = 26;

/// Gap below a message before the next step.
const double _kStepGap = 16;

/// Inset applied per nesting level so nested frames stay visible.
const double _kFrameInset = 7;

/// Lays [sequence] out into a paint-ready scene.
CcMermaidScene layoutMermaidSequence(
  CcMermaidSequence sequence, {
  required CcMermaidStyle style,
  required CcMermaidTextRuler ruler,
}) {
  return _SequenceLayout(sequence: sequence, style: style, ruler: ruler).run();
}

class _Lane {
  _Lane({required this.participant, required this.lines, required this.size});

  final CcMermaidParticipant participant;
  final List<String> lines;
  Size size;
  double center = 0;

  /// Open activations, innermost last (each entry is the y it started at).
  final List<double> activations = [];
}

class _SequenceLayout {
  _SequenceLayout({
    required this.sequence,
    required this.style,
    required this.ruler,
  });

  final CcMermaidSequence sequence;
  final CcMermaidStyle style;
  final CcMermaidTextRuler ruler;

  final List<_Lane> _lanes = [];
  final Map<String, int> _laneIndex = {};
  final List<CcMermaidPrimitive> _primitives = [];
  final List<CcMermaidPrimitive> _activationBars = [];
  final List<CcMermaidPrimitive> _lifelines = [];

  double _cursor = 0;
  double _headerBottom = 0;
  int _messageNumber = 0;

  CcMermaidScene run() {
    _buildLanes();
    if (_lanes.isEmpty) {
      return CcMermaidScene.empty;
    }
    _spaceLanes();
    _emitHeader();
    _walk(sequence.steps, depth: 0);
    _closeOpenActivations();
    _emitLifelines();

    // Paint order is deliberate: lifelines at the back, then activation bars
    // over them, then everything else (headers, messages, notes, frames).
    final ordered = <CcMermaidPrimitive>[
      ..._lifelines,
      ..._activationBars,
      ..._primitives,
    ];
    return finalizeScene(
      prependSceneTitle(ordered, sequence.title, ruler),
      padding: style.canvasPadding,
    );
  }

  // ── lanes ─────────────────────────────────────────────────────────────────

  void _buildLanes() {
    for (final participant in sequence.participants) {
      final lines = wrapMermaidLines(
        participant.displayLines,
        CcMermaidTextRole.label,
        ruler,
        maxWidth: 160,
      );
      final text = measureMermaidLines(
        lines,
        CcMermaidTextRole.label,
        ruler,
        lineSpacing: style.lineSpacing,
      );
      final size = Size(
        math.max(text.width + style.nodePadding.horizontal, 72),
        math.max(text.height + style.nodePadding.vertical, 32) +
            (participant.isActor ? 26 : 0),
      );
      _laneIndex[participant.id] = _lanes.length;
      _lanes.add(_Lane(participant: participant, lines: lines, size: size));
    }
  }

  /// Positions lifelines, widening gaps until every message label fits.
  void _spaceLanes() {
    final gaps = List<double>.filled(
      math.max(_lanes.length - 1, 0),
      _kMinLaneGap,
    );

    void reposition() {
      var cursor = 0.0;
      for (var i = 0; i < _lanes.length; i++) {
        if (i > 0) {
          cursor += gaps[i - 1];
        }
        _lanes[i].center = cursor + _lanes[i].size.width / 2;
        cursor = _lanes[i].center + _lanes[i].size.width / 2;
      }
    }

    reposition();
    // Two passes converge: the first widens for every demand, the second picks
    // up demands whose span grew because of the first.
    for (var pass = 0; pass < 2; pass++) {
      for (final demand in _spanDemands(sequence.steps)) {
        final (from, to, required_) = demand;
        if (from == to) {
          continue;
        }
        final low = math.min(from, to);
        final high = math.max(from, to);
        final span = _lanes[high].center - _lanes[low].center;
        final deficit = required_ - span;
        if (deficit <= 0) {
          continue;
        }
        final share = deficit / (high - low);
        for (var i = low; i < high; i++) {
          gaps[i] += share;
        }
        reposition();
      }
    }

    // A self-message or right-side note needs room outside the lane itself.
    for (final demand in _sideDemands(sequence.steps)) {
      final (index, required_) = demand;
      if (index >= _lanes.length - 1) {
        continue;
      }
      final available =
          _lanes[index + 1].center -
          _lanes[index].center -
          _lanes[index].size.width / 2;
      if (available < required_) {
        gaps[index] += required_ - available;
        reposition();
      }
    }
  }

  /// (fromLane, toLane, requiredSpan) for everything with a horizontal extent.
  List<(int, int, double)> _spanDemands(List<CcMermaidSequenceStep> steps) {
    final out = <(int, int, double)>[];
    for (final step in steps) {
      switch (step) {
        case CcMermaidMessage(:final fromId, :final toId, :final lines):
          final from = _laneIndex[fromId];
          final to = _laneIndex[toId];
          if (from == null || to == null || from == to) {
            continue;
          }
          final size = measureMermaidLines(
            lines,
            CcMermaidTextRole.edgeLabel,
            ruler,
            lineSpacing: style.lineSpacing,
          );
          out.add((from, to, size.width + _kLabelClearance));
        case CcMermaidNote(
              :final placement,
              :final participantIds,
              :final lines,
            )
            when placement == CcMermaidNotePlacement.over &&
                participantIds.length > 1:
          final from = _laneIndex[participantIds.first];
          final to = _laneIndex[participantIds.last];
          if (from == null || to == null) {
            continue;
          }
          final size = measureMermaidLines(
            lines,
            CcMermaidTextRole.note,
            ruler,
            lineSpacing: style.lineSpacing,
          );
          out.add((from, to, size.width * 0.7));
        case CcMermaidBlock(:final sections):
          for (final section in sections) {
            out.addAll(_spanDemands(section.steps));
          }
        default:
          continue;
      }
    }
    return out;
  }

  /// (laneIndex, requiredRightRoom) for self-messages and right-side notes.
  List<(int, double)> _sideDemands(List<CcMermaidSequenceStep> steps) {
    final out = <(int, double)>[];
    for (final step in steps) {
      switch (step) {
        case CcMermaidMessage(:final fromId, :final toId, :final lines)
            when fromId == toId:
          final index = _laneIndex[fromId];
          if (index == null) {
            continue;
          }
          final size = measureMermaidLines(
            lines,
            CcMermaidTextRole.edgeLabel,
            ruler,
            lineSpacing: style.lineSpacing,
          );
          out.add((index, _kSelfLoopWidth + size.width + 18));
        case CcMermaidNote(
              :final placement,
              :final participantIds,
              :final lines,
            )
            when placement == CcMermaidNotePlacement.right:
          final index = _laneIndex[participantIds.first];
          if (index == null) {
            continue;
          }
          final size = measureMermaidLines(
            lines,
            CcMermaidTextRole.note,
            ruler,
            lineSpacing: style.lineSpacing,
          );
          out.add((index, size.width + style.nodePadding.horizontal + 24));
        case CcMermaidBlock(:final sections):
          for (final section in sections) {
            out.addAll(_sideDemands(section.steps));
          }
        default:
          continue;
      }
    }
    return out;
  }

  // ── header + lifelines ────────────────────────────────────────────────────

  void _emitHeader() {
    var height = 0.0;
    for (final lane in _lanes) {
      height = math.max(height, lane.size.height);
    }
    for (final lane in _lanes) {
      final box = Rect.fromCenter(
        center: Offset(lane.center, height / 2),
        width: lane.size.width,
        height: lane.size.height - (lane.participant.isActor ? 26 : 0),
      );
      if (lane.participant.isActor) {
        final figure = Rect.fromCenter(
          center: Offset(lane.center, box.top - 15),
          width: 22,
          height: 26,
        );
        _primitives.add(CcMermaidActorPrim(figure));
      }
      _primitives.add(
        CcMermaidShapePrim(
          rect: box,
          shape: CcMermaidNodeShape.roundRect,
          role: CcMermaidPaintRole.node,
        ),
      );
      _primitives.addAll(
        stackTextLines(
          lane.lines,
          CcMermaidTextRole.label,
          ruler,
          box: box,
          lineSpacing: style.lineSpacing,
        ),
      );
    }
    _headerBottom = height;
    _cursor = height + 24;
  }

  void _emitLifelines() {
    final bottom = _cursor + 8;
    for (final lane in _lanes) {
      _lifelines.add(
        CcMermaidPathPrim(
          points: [
            Offset(lane.center, _headerBottom),
            Offset(lane.center, bottom),
          ],
          stroke: CcMermaidEdgeStroke.dotted,
          role: CcMermaidPaintRole.edge,
        ),
      );
    }
  }

  void _closeOpenActivations() {
    for (final lane in _lanes) {
      while (lane.activations.isNotEmpty) {
        _closeActivation(lane);
      }
    }
  }

  // ── steps ─────────────────────────────────────────────────────────────────

  void _walk(List<CcMermaidSequenceStep> steps, {required int depth}) {
    for (final step in steps) {
      switch (step) {
        case final CcMermaidMessage message:
          _emitMessage(message);
        case final CcMermaidNote note:
          _emitNote(note);
        case final CcMermaidActivation activation:
          final lane = _lane(activation.participantId);
          if (lane == null) {
            continue;
          }
          if (activation.active) {
            lane.activations.add(_cursor - 6);
          } else {
            _closeActivation(lane);
          }
        case final CcMermaidDivider divider:
          _emitDivider(divider);
        case final CcMermaidBlock block:
          _emitBlock(block, depth: depth);
      }
    }
  }

  _Lane? _lane(String id) {
    final index = _laneIndex[id];
    return index == null ? null : _lanes[index];
  }

  /// The x a connector attaches at: outside the activation bar when the lane is
  /// active, on the lifeline otherwise.
  double _attachX(_Lane lane, {required bool toRight}) {
    if (lane.activations.isEmpty) {
      return lane.center;
    }
    final offset = _kActivationWidth / 2 + 4 * (lane.activations.length - 1);
    return lane.center + (toRight ? offset : -offset);
  }

  void _emitMessage(CcMermaidMessage message) {
    final from = _lane(message.fromId);
    final to = _lane(message.toId);
    if (from == null || to == null) {
      return;
    }
    var lines = message.lines;
    if (sequence.autonumber) {
      _messageNumber++;
      lines = [
        if (lines.isEmpty)
          '$_messageNumber.'
        else
          '$_messageNumber. ${lines.first}',
        ...lines.skip(1),
      ];
    }
    final labelSize = measureMermaidLines(
      lines,
      CcMermaidTextRole.edgeLabel,
      ruler,
      lineSpacing: style.lineSpacing,
    );

    if (message.activates) {
      to.activations.add(_cursor + labelSize.height + 2);
    }

    if (from == to) {
      final top = _cursor + labelSize.height + 4;
      final x = _attachX(from, toRight: true);
      final points = [
        Offset(x, top),
        Offset(x + _kSelfLoopWidth, top),
        Offset(x + _kSelfLoopWidth, top + _kSelfLoopHeight),
        Offset(x, top + _kSelfLoopHeight),
      ];
      _primitives.add(
        CcMermaidPathPrim(
          points: points,
          stroke: message.stroke,
          endMarker: message.marker,
          cornerRadius: 5,
        ),
      );
      if (lines.isNotEmpty) {
        _primitives.addAll(
          stackTextLines(
            lines,
            CcMermaidTextRole.edgeLabel,
            ruler,
            box: Rect.fromLTWH(
              x + _kSelfLoopWidth + 8,
              top + _kSelfLoopHeight / 2 - labelSize.height / 2,
              labelSize.width,
              labelSize.height,
            ),
            lineSpacing: style.lineSpacing,
            align: CcMermaidTextAlign.left,
          ),
        );
      }
      _cursor = top + _kSelfLoopHeight + _kStepGap;
    } else {
      final toRight = to.center > from.center;
      final startX = _attachX(from, toRight: toRight);
      final endX = _attachX(to, toRight: !toRight);
      final y = _cursor + labelSize.height + 4;
      _primitives.add(
        CcMermaidPathPrim(
          points: [Offset(startX, y), Offset(endX, y)],
          stroke: message.stroke,
          endMarker: message.marker,
        ),
      );
      if (lines.isNotEmpty) {
        final center = (startX + endX) / 2;
        _primitives.addAll(
          stackTextLines(
            lines,
            CcMermaidTextRole.edgeLabel,
            ruler,
            box: Rect.fromLTWH(
              center - labelSize.width / 2,
              _cursor,
              labelSize.width,
              labelSize.height,
            ),
            lineSpacing: style.lineSpacing,
          ),
        );
      }
      _cursor = y + _kStepGap;
    }

    if (message.deactivates) {
      _closeActivation(from);
    }
  }

  void _closeActivation(_Lane lane) {
    if (lane.activations.isEmpty) {
      return;
    }
    final start = lane.activations.removeLast();
    final offset = 4.0 * lane.activations.length;
    _activationBars.add(
      CcMermaidShapePrim(
        rect: Rect.fromLTWH(
          lane.center - _kActivationWidth / 2 + offset,
          start,
          _kActivationWidth,
          math.max(_cursor - start, 14),
        ),
        shape: CcMermaidNodeShape.rect,
        role: CcMermaidPaintRole.activation,
      ),
    );
  }

  void _emitNote(CcMermaidNote note) {
    final anchors = [
      for (final id in note.participantIds)
        if (_lane(id) != null) _lane(id)!,
    ];
    if (anchors.isEmpty) {
      return;
    }
    final lines = wrapMermaidLines(
      note.lines,
      CcMermaidTextRole.note,
      ruler,
      maxWidth: 220,
    );
    final text = measureMermaidLines(
      lines,
      CcMermaidTextRole.note,
      ruler,
      lineSpacing: style.lineSpacing,
    );
    final width = text.width + style.nodePadding.horizontal;
    final height = text.height + style.nodePadding.vertical;

    final Rect box;
    switch (note.placement) {
      case CcMermaidNotePlacement.right:
        box = Rect.fromLTWH(anchors.first.center + 14, _cursor, width, height);
      case CcMermaidNotePlacement.left:
        box = Rect.fromLTWH(
          anchors.first.center - 14 - width,
          _cursor,
          width,
          height,
        );
      case CcMermaidNotePlacement.over:
        final left = anchors.first.center;
        final right = anchors.last.center;
        final center = (left + right) / 2;
        final span = math.max((right - left).abs() + 40, width);
        box = Rect.fromLTWH(center - span / 2, _cursor, span, height);
    }
    _primitives.add(
      CcMermaidShapePrim(
        rect: box,
        shape: CcMermaidNodeShape.note,
        role: CcMermaidPaintRole.note,
      ),
    );
    _primitives.addAll(
      stackTextLines(
        lines,
        CcMermaidTextRole.note,
        ruler,
        box: box,
        lineSpacing: style.lineSpacing,
      ),
    );
    _cursor = box.bottom + _kStepGap;
  }

  void _emitDivider(CcMermaidDivider divider) {
    final left = _lanes.first.center - _lanes.first.size.width / 2 - 10;
    final right = _lanes.last.center + _lanes.last.size.width / 2 + 10;
    final size = ruler.measure(divider.label, CcMermaidTextRole.legend);
    final y = _cursor + size.height / 2 + 4;
    _primitives.add(
      CcMermaidPathPrim(
        points: [Offset(left, y), Offset(right, y)],
        role: CcMermaidPaintRole.divider,
      ),
    );
    if (divider.label.isNotEmpty) {
      final center = (left + right) / 2;
      final chip = Rect.fromCenter(
        center: Offset(center, y),
        width: size.width + 16,
        height: size.height + 6,
      );
      _primitives.add(
        CcMermaidShapePrim(
          rect: chip,
          shape: CcMermaidNodeShape.stadium,
          role: CcMermaidPaintRole.node,
        ),
      );
      _primitives.add(
        CcMermaidTextPrim(
          text: divider.label,
          rect: chip,
          role: CcMermaidTextRole.legend,
          muted: true,
        ),
      );
      _cursor = chip.bottom + _kStepGap;
    } else {
      _cursor = y + _kStepGap;
    }
  }

  void _emitBlock(CcMermaidBlock block, {required int depth}) {
    // A transparent `box` grouping has no frame of its own.
    if (block.kind == CcMermaidBlockKind.box) {
      for (final section in block.sections) {
        _walk(section.steps, depth: depth);
      }
      return;
    }

    final headerSize = ruler.measure(
      '${block.keyword} ${block.label}'.trim(),
      CcMermaidTextRole.cluster,
    );
    final top = _cursor;
    final frameIndex = _primitives.length;
    _cursor = top + headerSize.height + 12;

    final sectionMarkers = <(double, String)>[];
    for (var i = 0; i < block.sections.length; i++) {
      if (i > 0) {
        sectionMarkers.add((_cursor, block.sections[i].label));
        _cursor += ruler.lineHeight(CcMermaidTextRole.legend) + 10;
      }
      _walk(block.sections[i].steps, depth: depth + 1);
    }

    final bottom = _cursor;
    final involved = _involvedLanes(block);
    final inset = _kFrameInset * depth;
    double left;
    double right;
    if (involved.isEmpty) {
      left = _lanes.first.center - _lanes.first.size.width / 2 - 12;
      right = _lanes.last.center + _lanes.last.size.width / 2 + 12;
    } else {
      final lowest = involved.reduce(math.min);
      final highest = involved.reduce(math.max);
      left =
          _lanes[lowest].center -
          math.max(_lanes[lowest].size.width / 2, 30) -
          12;
      right =
          _lanes[highest].center +
          math.max(_lanes[highest].size.width / 2, 30) +
          12;
    }
    final frame = Rect.fromLTRB(left + inset, top, right - inset, bottom);

    final frameParts = <CcMermaidPrimitive>[
      CcMermaidShapePrim(
        rect: frame,
        shape: CcMermaidNodeShape.rect,
        role: CcMermaidPaintRole.frame,
      ),
      // The keyword tab.
      CcMermaidShapePrim(
        rect: Rect.fromLTWH(
          frame.left,
          frame.top,
          ruler.measure(block.keyword, CcMermaidTextRole.cluster).width + 18,
          headerSize.height + 8,
        ),
        shape: CcMermaidNodeShape.rect,
        role: CcMermaidPaintRole.frame,
      ),
      CcMermaidTextPrim(
        text: block.keyword,
        rect: Rect.fromLTWH(
          frame.left,
          frame.top,
          ruler.measure(block.keyword, CcMermaidTextRole.cluster).width + 18,
          headerSize.height + 8,
        ),
        role: CcMermaidTextRole.cluster,
        muted: true,
      ),
      if (block.label.isNotEmpty)
        CcMermaidTextPrim(
          text: '[${block.label}]',
          rect: Rect.fromLTWH(
            frame.left +
                ruler.measure(block.keyword, CcMermaidTextRole.cluster).width +
                26,
            frame.top,
            frame.width -
                ruler.measure(block.keyword, CcMermaidTextRole.cluster).width -
                30,
            headerSize.height + 8,
          ),
          role: CcMermaidTextRole.cluster,
          align: CcMermaidTextAlign.left,
        ),
      for (final (y, label) in sectionMarkers) ...[
        CcMermaidPathPrim(
          points: [Offset(frame.left, y), Offset(frame.right, y)],
          stroke: CcMermaidEdgeStroke.dotted,
          role: CcMermaidPaintRole.divider,
        ),
        if (label.isNotEmpty)
          CcMermaidTextPrim(
            text: '[$label]',
            rect: Rect.fromLTWH(
              frame.left + 10,
              y + 2,
              frame.width - 20,
              ruler.lineHeight(CcMermaidTextRole.legend),
            ),
            role: CcMermaidTextRole.legend,
            align: CcMermaidTextAlign.left,
            muted: true,
          ),
      ],
    ];
    _primitives.insertAll(frameIndex, frameParts);
    _cursor = bottom + _kStepGap;
  }

  /// Lane indices touched anywhere inside [block] (recursively).
  Set<int> _involvedLanes(CcMermaidBlock block) {
    final out = <int>{};
    void visit(List<CcMermaidSequenceStep> steps) {
      for (final step in steps) {
        switch (step) {
          case CcMermaidMessage(:final fromId, :final toId):
            final from = _laneIndex[fromId];
            final to = _laneIndex[toId];
            if (from != null) {
              out.add(from);
            }
            if (to != null) {
              out.add(to);
            }
          case CcMermaidNote(:final participantIds):
            for (final id in participantIds) {
              final index = _laneIndex[id];
              if (index != null) {
                out.add(index);
              }
            }
          case CcMermaidActivation(:final participantId):
            final index = _laneIndex[participantId];
            if (index != null) {
              out.add(index);
            }
          case CcMermaidBlock(:final sections):
            for (final section in sections) {
              visit(section.steps);
            }
          case CcMermaidDivider():
            continue;
        }
      }
    }

    for (final section in block.sections) {
      visit(section.steps);
    }
    return out;
  }
}

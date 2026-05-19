import 'dart:math' as math;

import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// One message (arrow) in a [CcSequenceDiagram].
///
/// [verified] drives the honest rendering: an unverified edge (one the code
/// graph did not corroborate) is drawn dashed and labelled, never as fact.
class CcSequenceMessage {
  /// Creates a [CcSequenceMessage].
  const CcSequenceMessage({
    required this.from,
    required this.to,
    required this.label,
    this.verified = true,
  });

  /// Source participant.
  final String from;

  /// Destination participant.
  final String to;

  /// Message/call label.
  final String label;

  /// Whether the code graph corroborates this edge.
  final bool verified;
}

/// A sequence diagram of a call flow (PRD 18 §3), rendered natively — no
/// mermaid. Participants are vertical lifelines; messages are arrows in order.
/// Unverified messages render dashed with an "unverified" tag.
class CcSequenceDiagram extends StatelessWidget {
  /// Creates a [CcSequenceDiagram].
  const CcSequenceDiagram({
    super.key,
    required this.participants,
    required this.messages,
  });

  /// Participant lanes, left to right.
  final List<String> participants;

  /// Ordered messages.
  final List<CcSequenceMessage> messages;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }
    const rowHeight = 44.0;
    const headerHeight = 34.0;
    final height = headerHeight + messages.length * rowHeight + 24;
    final width = math.max(participants.length * 150.0, 260.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.borderSoft),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _SequencePainter(
              participants: participants,
              messages: messages,
              tokens: t,
              rowHeight: rowHeight,
              headerHeight: headerHeight,
              fontFamily: context.ccTheme?.fontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

class _SequencePainter extends CustomPainter {
  _SequencePainter({
    required this.participants,
    required this.messages,
    required this.tokens,
    required this.rowHeight,
    required this.headerHeight,
    required this.fontFamily,
  });

  final List<String> participants;
  final List<CcSequenceMessage> messages;
  final DesignSystemTokens tokens;
  final double rowHeight;
  final double headerHeight;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final laneCount = participants.length;
    final laneWidth = size.width / laneCount;
    final laneX = <String, double>{};
    for (var i = 0; i < laneCount; i++) {
      laneX[participants[i]] = laneWidth * (i + 0.5);
    }

    // Lifelines + participant headers.
    final linePaint = Paint()
      ..color = tokens.lineStrong
      ..strokeWidth = 1;
    for (var i = 0; i < laneCount; i++) {
      final x = laneWidth * (i + 0.5);
      canvas.drawLine(
        Offset(x, headerHeight),
        Offset(x, size.height),
        linePaint,
      );
      final box = Rect.fromCenter(
        center: Offset(x, headerHeight / 2),
        width: math.min(laneWidth - 12, 140),
        height: 26,
      );
      final boxPaint = Paint()..color = tokens.panel;
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(6)),
        boxPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(6)),
        Paint()
          ..color = tokens.borderSoft
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      _text(canvas, participants[i], box, tokens.fg, 12, center: true);
    }

    // Messages.
    for (var m = 0; m < messages.length; m++) {
      final msg = messages[m];
      final y = headerHeight + rowHeight * (m + 0.5) + 8;
      final fromX = laneX[msg.from];
      final toX = laneX[msg.to];
      if (fromX == null || toX == null) {
        continue;
      }
      final color = msg.verified ? tokens.accent : tokens.warn;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.5;
      if (msg.verified) {
        canvas.drawLine(Offset(fromX, y), Offset(toX, y), paint);
      } else {
        _dashedLine(canvas, Offset(fromX, y), Offset(toX, y), paint);
      }
      // Arrow head.
      final dir = toX >= fromX ? 1 : -1;
      final path = Path()
        ..moveTo(toX, y)
        ..lineTo(toX - dir * 7, y - 4)
        ..lineTo(toX - dir * 7, y + 4)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      // Label above the arrow.
      final labelRect = Rect.fromLTRB(
        math.min(fromX, toX),
        y - 20,
        math.max(fromX, toX),
        y - 4,
      );
      final label = msg.verified ? msg.label : '${msg.label} (unverified)';
      _text(canvas, label, labelRect, tokens.muted, 11, center: true);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final start = a + dir * drawn;
      final end = a + dir * math.min(drawn + dash, total);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Rect rect,
    Color color,
    double size, {
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontFamily: fontFamily),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: rect.width);
    final dx = center ? rect.left + (rect.width - tp.width) / 2 : rect.left;
    final dy = rect.top + (rect.height - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_SequencePainter old) =>
      old.messages != messages ||
      old.participants != participants ||
      old.tokens != tokens;
}

/// A transition in a [CcStateMachineDiagram].
class CcStateTransition {
  /// Creates a [CcStateTransition].
  const CcStateTransition({
    required this.from,
    required this.to,
    this.label = '',
    this.verified = true,
  });

  /// Source state.
  final String from;

  /// Destination state.
  final String to;

  /// Transition label.
  final String label;

  /// Whether the code graph corroborates this transition.
  final bool verified;
}

/// A state-machine diagram (PRD 18 §3). States render as pills in flow order;
/// transitions render as labelled rows with a directional glyph (a legible,
/// deterministic layout that avoids fragile arbitrary-graph routing).
class CcStateMachineDiagram extends StatelessWidget {
  /// Creates a [CcStateMachineDiagram].
  const CcStateMachineDiagram({
    super.key,
    required this.states,
    required this.transitions,
    this.initialState,
  });

  /// Ordered states.
  final List<String> states;

  /// Transitions.
  final List<CcStateTransition> transitions;

  /// The initial state, if any.
  final String? initialState;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in states)
                  _statePill(t, s, isInitial: s == initialState),
              ],
            ),
            if (transitions.isNotEmpty) const SizedBox(height: 12),
            for (final tr in transitions) _transitionRow(context, t, tr),
          ],
        ),
      ),
    );
  }

  Widget _statePill(
    DesignSystemTokens t,
    String label, {
    required bool isInitial,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isInitial ? t.accentSoft : t.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isInitial ? t.accent : t.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(label, style: TextStyle(color: t.fg, fontSize: 12)),
      ),
    );
  }

  Widget _transitionRow(
    BuildContext context,
    DesignSystemTokens t,
    CcStateTransition tr,
  ) {
    final color = tr.verified ? t.fg : t.warn;
    final suffix = tr.verified ? '' : '  (unverified)';
    final label = tr.label.isEmpty ? '' : ' : ${tr.label}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '${tr.from}  →  ${tr.to}$label$suffix',
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

/// A field of a [CcErEntity].
class CcErField {
  /// Creates a [CcErField].
  const CcErField({required this.name, required this.type, this.isKey = false});

  /// Field name.
  final String name;

  /// Field type.
  final String type;

  /// Whether this is (part of) the key.
  final bool isKey;
}

/// An entity (table) in a [CcEntityRelationDiagram].
class CcErEntity {
  /// Creates a [CcErEntity].
  const CcErEntity({required this.name, this.fields = const []});

  /// Entity/table name.
  final String name;

  /// Fields.
  final List<CcErField> fields;
}

/// A relationship in a [CcEntityRelationDiagram].
class CcErRelation {
  /// Creates a [CcErRelation].
  const CcErRelation({required this.from, required this.to, this.label = ''});

  /// Source entity.
  final String from;

  /// Destination entity.
  final String to;

  /// Relationship label.
  final String label;
}

/// An entity-relationship diagram (PRD 18 §3) for schema changes. Entities
/// render as field tables; relationships render as labelled connectors.
class CcEntityRelationDiagram extends StatelessWidget {
  /// Creates a [CcEntityRelationDiagram].
  const CcEntityRelationDiagram({
    super.key,
    required this.entities,
    this.relations = const [],
  });

  /// Entities (tables).
  final List<CcErEntity> entities;

  /// Relationships.
  final List<CcErRelation> relations;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final e in entities) _entityCard(t, e)],
            ),
            if (relations.isNotEmpty) const SizedBox(height: 12),
            for (final r in relations)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${r.from}  ⟶  ${r.to}'
                  '${r.label.isEmpty ? '' : '  (${r.label})'}',
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _entityCard(DesignSystemTokens t, CcErEntity e) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: t.accentSoft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Text(
              e.name,
              style: TextStyle(
                color: t.fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final f in e.fields)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Text(
                '${f.isKey ? '🔑 ' : ''}${f.name}: ${f.type}',
                style: TextStyle(color: t.muted, fontSize: 11),
              ),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

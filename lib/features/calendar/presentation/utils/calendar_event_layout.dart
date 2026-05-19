import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kalender/kalender.dart' as k;

/// A kalender [k.EventLayoutStrategy] that lays events out from their *real*
/// time ranges rather than their rendered heights.
///
/// kalender's stock [k.overlapLayoutStrategy] inflates every tile to
/// `minimumTileHeight` — both before grouping (so two short back-to-back events
/// like 09:15–09:30 and 09:30–09:45, which don't actually conflict, get treated
/// as overlapping and cascaded) and when sizing the tile (so a 15-minute event
/// is painted 30-minutes tall, visually running past its real end and into the
/// following event's slot — and because later events paint on top, that spill is
/// hidden *underneath* the next tile).
///
/// This strategy fixes both: it groups on the untouched event ranges so only
/// genuine time conflicts cascade, and it sizes each tile to its true duration,
/// growing a short tile toward `minimumTileHeight` (the legibility floor) *only*
/// into empty space — never past the start of the next event. So an event ends
/// exactly where its time ends, and a short event followed immediately by
/// another is not inflated into it.
k.EventLayoutDelegate calendarEventLayoutStrategy(
  Iterable<k.CalendarEvent> events,
  k.InternalDateTime date,
  k.TimeOfDayRange timeOfDayRange,
  double heightPerMinute,
  double? minimumTileHeight,
  k.EventLayoutDelegateCache? cache,
  k.Location? location,
) {
  return _CalendarEventLayoutDelegate(
    events: events,
    date: date,
    timeOfDayRange: timeOfDayRange,
    heightPerMinute: heightPerMinute,
    minimumTileHeight: minimumTileHeight,
    layoutCache: cache ?? k.EventLayoutDelegateCache(),
    location: location,
  );
}

class _CalendarEventLayoutDelegate extends k.EventLayoutDelegate {
  _CalendarEventLayoutDelegate({
    required super.events,
    required super.date,
    required super.timeOfDayRange,
    required super.heightPerMinute,
    required super.minimumTileHeight,
    required super.layoutCache,
    required super.location,
  });

  /// Earliest first, longer first on ties. The earliest event becomes the
  /// full-width base of a cascade, and because children paint in this order the
  /// later events end up on top.
  @override
  List<k.CalendarEvent> sortEvents(Iterable<k.CalendarEvent> events) {
    return events.toList()
      ..sort((a, b) {
        final byStart =
            a.dateTimeRange.start.compareTo(b.dateTimeRange.start);
        return byStart != 0 ? byStart : b.duration.compareTo(a.duration);
      });
  }

  @override
  List<k.VerticalLayoutData> sortVerticalLayoutData(
    List<k.VerticalLayoutData> layoutData,
  ) =>
      layoutData;

  /// Vertical extents from the events' real durations, ignoring
  /// `minimumTileHeight`. Used to detect genuine time conflicts and as the basis
  /// for the rendered extents (which only grow short tiles into empty space).
  List<k.VerticalLayoutData> _realVerticalData() {
    return [
      for (var i = 0; i < events.length; i++)
        () {
          final event = events.elementAt(i);
          final top = calculateDistanceFromStart(event);
          final height = event.duration.inSeconds * heightPerMinute / 60;
          return k.VerticalLayoutData(id: i, top: top, bottom: top + height);
        }(),
    ];
  }

  @override
  void performLayout(Size size) {
    final real = _realVerticalData();

    // The top of the nearest event that starts at or after each event ends —
    // the point past which growing a short tile would run it into its
    // neighbour (which then paints on top, hiding the spill underneath). The
    // legibility floor is capped here so a tile never overlaps the next event.
    final nextStart = <int, double>{};
    for (final a in real) {
      var cap = double.infinity;
      for (final b in real) {
        if (b.id != a.id && b.top >= a.bottom && b.top < cap) {
          cap = b.top;
        }
      }
      nextStart[a.id] = cap;
    }

    final floor = minimumTileHeight ?? 0;

    // Rendered extents: the real duration, grown toward [floor] for short tiles
    // but never past the next event's start. A 15-minute event (≥ floor) renders
    // at its exact height; a shorter, isolated one fills up to the floor.
    final render = <int, k.VerticalLayoutData>{
      for (final datum in real)
        datum.id: k.VerticalLayoutData(
          id: datum.id,
          top: datum.top,
          bottom: math.max(
            datum.bottom,
            math.min(datum.top + floor, nextStart[datum.id]!),
          ),
        ),
    };

    // Group by genuine time overlap (real ranges, no minimum-height inflation).
    final groups = groupVerticalLayoutData(real);

    for (final group in groups) {
      final members = group.verticalLayoutData;
      if (members.length == 1) {
        // No conflict → full width at its real position.
        final datum = render[members.first.id]!;
        layoutChild(
          datum.id,
          BoxConstraints.tightFor(width: size.width, height: datum.height),
        );
        positionChild(datum.id, Offset(0, datum.top));
        continue;
      }

      // Genuine conflict → cascade: each subsequent tile is narrower, pinned to
      // the right edge, and painted on top. Mirrors kalender's overlap strategy
      // but runs on the rendered extents.
      final placed = <k.EventLayoutData>[];
      for (final member in members) {
        final datum = render[member.id]!;
        final overlaps = placed.where((e) => e.overlaps(datum)).toList();
        final overlapCount = overlaps.length + 1;

        double? lastWidth;
        if (overlaps.isNotEmpty) {
          lastWidth =
              overlaps.reduce((e, f) => e.width <= f.width ? e : f).width;
        }

        final double width;
        final double xOffset;
        if (lastWidth == null) {
          width = size.width / overlapCount;
          xOffset = width * (overlapCount - 1);
        } else {
          width = lastWidth / 1.8;
          xOffset = size.width - width;
        }

        layoutChild(
          datum.id,
          BoxConstraints.tightFor(width: width, height: datum.height),
        );
        positionChild(datum.id, Offset(xOffset, datum.top));
        placed.add(
          k.EventLayoutData(
            left: xOffset,
            right: size.width,
            verticalLayoutData: datum,
          ),
        );
      }
    }
  }
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kalender/kalender.dart' as k;

/// A kalender [k.EventLayoutStrategy] that lays events out from their *real*
/// time ranges rather than their rendered heights, placing genuine time
/// conflicts *side by side* in equal-width columns.
///
/// kalender ships two strategies and both fall short here:
///
///  * [k.overlapLayoutStrategy] stacks conflicting tiles on top of one another,
///    each narrower and pinned to the right. The base tile keeps its full width,
///    so its title runs *underneath* the tiles on top — two overlapping events
///    paint their titles in the same horizontal band and collide into an
///    unreadable mess.
///  * [k.sideBySideLayoutStrategy] places tiles next to each other (the layout
///    we want) but inflates every tile to `minimumTileHeight` first: before
///    grouping, so two short back-to-back events like 09:15–09:30 and
///    09:30–09:45, which don't actually conflict, get treated as overlapping and
///    split into separate columns; and when sizing, so a 15-minute event is
///    painted 30-minutes tall, visually running past its real end into the
///    following event's slot.
///
/// This strategy takes the side-by-side placement but fixes both inflation
/// problems: it groups and assigns columns on the untouched event ranges so only
/// genuine time conflicts share the width, and it sizes each tile to its true
/// duration, growing a short tile toward `minimumTileHeight` (the legibility
/// floor) *only* into empty space — never past the start of the next event. So
/// overlapping events sit side by side and stay readable, an event ends exactly
/// where its time ends, and a short event followed immediately by another is not
/// inflated into it.
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

  /// Earliest first, longer first on ties — a stable order so the leftmost
  /// column holds the earliest (and, on a tie, the longest) event.
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
      // Order members top-to-bottom (taller first on ties) so columns fill from
      // the left in a stable, readable order. Mirrors kalender's side-by-side
      // delegate — we run it on the real ranges, not the inflated ones.
      final members = group.verticalLayoutData
        ..sort(
          (a, b) => a.top.compareTo(b.top) == 0
              ? b.bottom.compareTo(a.bottom)
              : a.top.compareTo(b.top),
        );

      // Column count = the most events that are ever live at the same instant
      // (the longest chain of mutual overlaps). A lone event is a chain of one
      // and so spans the full width.
      final columns = findLongestChain(members);
      final columnWidth = size.width / columns;

      // x-offset and width of each tile already placed in this group, so a later
      // tile can butt against its nearest left neighbour's right edge.
      final placed = <int, ({double x, double width})>{};

      for (var i = 0; i < members.length; i++) {
        final member = members[i];

        // Earlier-placed tiles that overlap this one sit to its left: start just
        // past the nearest one's right edge, or — if none — at the column its
        // count of left-overlaps implies.
        final leftOverlaps =
            members.take(i).where((e) => e.overlaps(member)).toList();
        final lastLeft = leftOverlaps.isEmpty ? null : leftOverlaps.last;
        final xOffset = lastLeft == null
            ? columnWidth * leftOverlaps.length
            : placed[lastLeft.id]!.x + placed[lastLeft.id]!.width;

        // A tile with no later-sorted overlap to its right stretches to fill the
        // remaining width; otherwise it keeps a single column's width.
        final hasRightOverlap =
            members.skip(i + 1).any((e) => e.overlaps(member));
        final width = hasRightOverlap ? columnWidth : size.width - xOffset;

        final datum = render[member.id]!;
        layoutChild(
          datum.id,
          BoxConstraints.tightFor(width: width, height: datum.height),
        );
        positionChild(datum.id, Offset(xOffset, datum.top));
        placed[member.id] = (x: xOffset, width: width);
      }
    }
  }
}

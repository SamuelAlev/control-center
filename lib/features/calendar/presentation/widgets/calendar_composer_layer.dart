import 'dart:math' as math;

import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_write_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_event_composer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The composer card's width.
const double _kComposerWidth = 360;

/// The placeholder tile for the span being composed: titled [title], on the
/// first calendar the person may write to, so it takes that calendar's color.
CalendarEvent? composerPreviewEvent({
  required CalendarSlot? slot,
  required List<CalendarSourceView> calendars,
  required String workspaceId,
  required String title,
}) {
  if (slot == null || calendars.isEmpty) {
    return null;
  }
  final calendar = calendars.first;
  return CalendarEvent(
    id: 'composer-preview',
    workspaceId: workspaceId,
    accountId: calendar.accountId,
    externalEventId: '',
    calendarId: calendar.id,
    title: title,
    startTime: slot.start,
    endTime: slot.end,
    isAllDay: slot.allDay,
    updatedAt: slot.start,
  );
}

/// [composerPreviewEvent] for any span, on the calendars the person may
/// write to right now: the grid's placeholder while a span is drawn and
/// while the composer is open.
CalendarEvent? Function(CalendarSlot slot) composerDraft(
  WidgetRef ref, {
  required String workspaceId,
  required String title,
}) {
  final calendars = ref.watch(writableCalendarsProvider);
  return (slot) => composerPreviewEvent(
    slot: slot,
    calendars: calendars,
    workspaceId: workspaceId,
    title: title,
  );
}

/// Floats the open event composer over [child], beside the point its span was
/// drawn from: to the right of it when it fits, else to the left, always held
/// inside the calendar.
class CalendarComposerLayer extends ConsumerStatefulWidget {
  /// Creates a [CalendarComposerLayer].
  const CalendarComposerLayer({super.key, required this.child});

  /// The calendar the card floats over.
  final Widget child;

  @override
  ConsumerState<CalendarComposerLayer> createState() => _LayerState();
}

class _LayerState extends ConsumerState<CalendarComposerLayer> {
  final _stackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final slot = ref.watch(calendarComposerProvider);
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final ready = box != null && box.hasSize;
    if (slot != null && !ready) {
      // Opened before this stack was ever laid out (a fresh mount): place
      // the card on the next frame, once there is a box to place it in.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
    final anchor = slot == null || !ready
        ? null
        : box.globalToLocal(slot.anchor);
    return Stack(
      key: _stackKey,
      children: [
        widget.child,
        if (slot != null && anchor != null)
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _ComposerPlacement(anchor),
              // Keyed on where it opened, so the entrance plays once per span
              // drawn rather than on every time edit.
              child: _Entrance(
                key: ValueKey(slot.anchor),
                child: _ComposerCard(slot: slot),
              ),
            ),
          ),
      ],
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({required this.slot});

  final CalendarSlot slot;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: card.bg,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: card.border),
        boxShadow: CcElevation.floating,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: SingleChildScrollView(child: CalendarEventComposer(slot: slot)),
      ),
    );
  }
}

/// A short rise-and-fade as the card appears; instant under reduced motion.
class _Entrance extends StatelessWidget {
  const _Entrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (CcMotion.reduced(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: CcMotion.slow,
      curve: Curves.easeOutExpo,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Places the card beside [anchor] within the calendar's bounds.
///
/// RTL carve-out: [anchor] is a viewport point and the card is placed on the
/// side with room, so physical left/right is the honest geometry here.
class _ComposerPlacement extends SingleChildLayoutDelegate {
  const _ComposerPlacement(this.anchor);

  final Offset anchor;

  static const double _gap = 16;
  static const double _margin = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.min(_kComposerWidth, constraints.maxWidth - 2 * _margin),
        maxHeight: math.max(0, constraints.maxHeight - 2 * _margin),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.dx + _gap;
    if (x + childSize.width > size.width - _margin) {
      x = anchor.dx - _gap - childSize.width;
    }
    final maxX = math.max(_margin, size.width - childSize.width - _margin);
    final maxY = math.max(_margin, size.height - childSize.height - _margin);
    return Offset(
      x.clamp(_margin, maxX),
      (anchor.dy - 24).clamp(_margin, maxY),
    );
  }

  @override
  bool shouldRelayout(_ComposerPlacement old) => old.anchor != anchor;
}

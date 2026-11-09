import 'package:cc_domain/cc_domain.dart' show RepoOpKind, ValidationException;
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_draft.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_reschedule.dart';
import 'package:cc_host/cc_host.dart' show RepoOp;
import 'package:cc_server_core/src/google_calendar_server.dart'
    show ServerCalendarWrites;

/// The person's Google Calendar writes (`calendar.rsvp`,
/// `calendar.createEvent`, `calendar.moveEvent`, `calendar.deleteEvent`), run on the host's OAuth
/// token for the caller's own connected account (the thin client holds none).
///
/// Workspace-scoped: the dispatcher checks the workspace and the caller's
/// membership, then [ServerCalendarWrites] refuses an account that is not the
/// caller's own sign-in. Event ids are LOCAL ids, looked up in the bound
/// workspace, so a foreign id is simply not found. A null [writes] (bare
/// catalogs) leaves the ops out.
List<RepoOp> buildCalendarWriteOps(ServerCalendarWrites? writes) => [
  if (writes != null) ...[
    RepoOp(
      name: 'calendar.rsvp',
      kind: RepoOpKind.mutate,
      requiredArgs: ['event_id', 'response'],
      handler: (ctx) async {
        await writes.respond(
          workspaceId: ctx.workspaceId!,
          userId: ctx.userId,
          eventId: ctx.args['event_id'] as String,
          responseStatus: ctx.args['response'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'calendar.createEvent',
      kind: RepoOpKind.mutate,
      requiredArgs: ['account_id', 'calendar_id', 'title', 'start', 'end'],
      handler: (ctx) async {
        final CalendarEventDraft draft;
        try {
          draft = CalendarEventDraft.fromArgs(ctx.args);
        } on ArgumentError catch (e) {
          throw ValidationException('${e.name ?? 'event'} ${e.message}');
        }
        final id = await writes.create(
          workspaceId: ctx.workspaceId!,
          userId: ctx.userId,
          draft: draft,
        );
        return {'event_id': id};
      },
    ),
    RepoOp(
      name: 'calendar.moveEvent',
      kind: RepoOpKind.mutate,
      requiredArgs: ['event_id', 'start', 'end'],
      handler: (ctx) async {
        final CalendarEventReschedule move;
        try {
          move = CalendarEventReschedule.fromArgs(ctx.args);
        } on ArgumentError catch (e) {
          throw ValidationException('${e.name ?? 'event'} ${e.message}');
        }
        await writes.move(
          workspaceId: ctx.workspaceId!,
          userId: ctx.userId,
          move: move,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'calendar.deleteEvent',
      kind: RepoOpKind.mutate,
      requiredArgs: ['event_id'],
      handler: (ctx) async {
        await writes.delete(
          workspaceId: ctx.workspaceId!,
          userId: ctx.userId,
          eventId: ctx.args['event_id'] as String,
        );
        return {'ok': true};
      },
    ),
  ],
];

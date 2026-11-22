/// What the Plan Studio says when an action fails, and what it still offers
/// this person after a refusal.
///
/// No field on the wire says whether a viewer may approve, revise or widen
/// an orchestration, and a client never compares user ids to decide. So the
/// studio starts by offering everything and lowers what it offers on the
/// first refusal by kind (the rig pattern): no write grant on the space's
/// repositories (`repo_grant_required` at level `write`) stops approving and
/// editing; `orchestration_not_yours` (the run acts for someone else) stops
/// approving more nodes and continuing a held node. Read by `data.kind`,
/// never by message text.
library;

import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/forge/presentation/repo_code_refusal.dart';
import 'package:control_center/features/messaging/presentation/space_access_refusal.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';

/// The kind of the refusal to widen an orchestration someone else's run
/// acts for.
const String orchestrationNotYoursKind = 'orchestration_not_yours';

/// What a failed Plan Studio action says: the write sentence for want of a
/// write grant, the space's own wording for any other refusal to reach its
/// repositories, else the sentence for its kind (the generic lead-in with
/// the raw kind for an unknown one), else the shared failure wording.
String planActionFailureMessage(AppLocalizations l10n, Object error) =>
    isRepoGrantRefusal(error, level: 'write')
    ? l10n.planNeedsWrite
    : spaceAccessFailureOf(l10n, error)?.message ??
          dispatchFailureMessage(l10n, error);

/// What the studio still offers this person; it only ever moves down.
class PlanStudioAccess {
  /// Creates the access; the default offers everything.
  const PlanStudioAccess({this.writeRefused = false, this.notYours = false});

  /// Whether the server refused a write for want of a write grant.
  final bool writeRefused;

  /// Whether the server refused widening because the run is someone else's.
  final bool notYours;

  /// Whether approving the plan, saving a revision and editing are offered.
  bool get mayWrite => !writeRefused;

  /// Whether approving more nodes and continuing a held node are offered.
  bool get mayWiden => !writeRefused && !notYours;

  /// This access after [error]: lowered when it is one of the two refusals,
  /// unchanged otherwise.
  PlanStudioAccess after(Object error) => PlanStudioAccess(
    writeRefused: writeRefused || isRepoGrantRefusal(error, level: 'write'),
    notYours: notYours || refusalKindOf(error) == orchestrationNotYoursKind,
  );

  /// Why controls are missing, shown in the approval bar once nothing else
  /// is: the write sentence, or, on an executing plan, the not-yours one.
  String? reason(AppLocalizations l10n, {required bool executing}) =>
      writeRefused
      ? l10n.planNeedsWrite
      : notYours && executing
      ? l10n.orchestrationRefusalNotYours
      : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanStudioAccess &&
          writeRefused == other.writeRefused &&
          notYours == other.notYours;

  @override
  int get hashCode => Object.hash(writeRefused, notYours);
}

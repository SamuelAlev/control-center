import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';

/// The one place a space is brought into existence.
///
/// Writes the row and publishes [SpaceCreated] together — omitting the event
/// leaves the room stuck in `provisioning` forever. Holds no other behaviour
/// (roster, repos, first conversation belong to callers).
class SpaceFactory {
  /// Creates a [SpaceFactory] over [_repository], announcing on [_eventBus].
  ///
  /// [_eventBus] is nullable for hosts with no event-driven background work
  /// (tests, a client-side composition with no provisioner). A null bus means
  /// nothing provisions, which is the correct behaviour there — not a silently
  /// skipped step on a host that does.
  const SpaceFactory({
    required this._repository,
    this._eventBus,
  });

  final MessagingRepository _repository;
  final DomainEventBus? _eventBus;

  /// Creates a space in [workspaceId] and announces it.
  ///
  /// Returns once the row is written; provisioning continues off [SpaceCreated].
  /// [repoIds] is checkout scope: null → every workspace repo; empty → none;
  /// automated callers must pass an explicit list. [beforeAnnounce] runs after
  /// the row and before [SpaceCreated] (e.g. PR association must exist before
  /// the provisioner reads it).
  Future<Space> create(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    Future<void> Function(Space space)? beforeAnnounce,
  }) async {
    final space = await _repository.createSpace(
      workspaceId,
      name,
      agentIds,
      mode: mode,
      pipelineRunId: pipelineRunId,
      createdByUserId: createdByUserId,
      kind: kind,
      repoIds: repoIds,
      repoBranches: repoBranches,
    );
    await beforeAnnounce?.call(space);
    _eventBus?.publish(
      SpaceCreated(
        spaceId: space.id,
        // The method's own argument, not `space.workspaceId`: the entity's
        // field is still nullable, and this is the workspace the row was just
        // created in.
        workspaceId: workspaceId,
        occurredAt: DateTime.now(),
      ),
    );
    return space;
  }
}

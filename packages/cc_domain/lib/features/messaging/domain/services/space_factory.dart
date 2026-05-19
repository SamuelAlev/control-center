import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';

/// The one place a space is brought into existence.
///
/// Writing the row is only half of creating a space. A new space is born
/// `provisioning`, and the checkout that clears that state — the copy-on-write
/// worktrees its conversations work in — is driven off [SpaceCreated] by the
/// background provisioner. A caller that writes the row and forgets the event
/// leaves a room parked behind its "preparing workspace" gate forever: the
/// composer refuses to send, no worktree ever lands on disk, and nothing later
/// notices, because the only signal that provisioning was ever due is the event
/// that was never published.
///
/// Pairing the two by hand at each call site is a convention, not an invariant:
/// a caller that forgets the event fails no test and simply produces a space
/// nothing will ever provision. The pair lives here instead, which makes
/// `MessagingRepository.createSpace` an implementation detail of this class
/// rather than an entry point.
///
/// It deliberately holds no other behaviour: agents joining, repo scope and the
/// space's first conversation all belong to the callers that know about them.
/// This exists to make one invariant unbreakable, not to become a god object.
class SpaceFactory {
  /// Creates a [SpaceFactory] over [repository], announcing on [eventBus].
  ///
  /// [eventBus] is nullable for hosts with no event-driven background work
  /// (tests, a client-side composition with no provisioner). A null bus means
  /// nothing provisions, which is the correct behaviour there — not a silently
  /// skipped step on a host that does.
  const SpaceFactory({
    required MessagingRepository repository,
    DomainEventBus? eventBus,
  }) : _repository = repository,
       _eventBus = eventBus;

  final MessagingRepository _repository;
  final DomainEventBus? _eventBus;

  /// Creates a space in [workspaceId] and announces it.
  ///
  /// Returns as soon as the row is written: provisioning runs in the background
  /// off the published [SpaceCreated], so a caller that does not need the
  /// checkout (an agent dispatch gates on readiness itself) is not held for the
  /// length of one.
  ///
  /// [repoIds] is the space's checkout scope and is the field that decides how
  /// much disk a run costs. Null means every workspace repo — keep it for a
  /// room a human opens with no stated scope, and pass an explicit list (or an
  /// empty one, meaning "no repos") from anything automated. A pipeline step
  /// that leaves this null checks out the whole workspace once per space it
  /// mints.
  ///
  /// [beforeAnnounce] runs after the row is written and BEFORE [SpaceCreated]
  /// is published — for the rows a listener goes straight back to the database
  /// looking for. The PR-review space is the case that needs it: its
  /// association (which pull request, at which head ref) is what the
  /// provisioner reads to decide what to check out, so announcing first races
  /// the provisioner into checking the default branch out instead of the PR.
  /// Anything that must be true before the rest of the system hears about the
  /// space belongs here rather than after the call.
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

import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;

/// Announces that the stored user [before] is now [after]: publishes
/// [UserProfileChanged] when the username, display name or avatar changed,
/// and logs a username change. Call it after the write succeeded.
///
/// Every writer of those fields calls this, and every server cache of who
/// someone is listens for the event, so a rename reaches all of them through
/// one path.
void announceUserProfileChange(
  DomainEventBus? bus,
  User before,
  User after, {
  required DateTime at,
}) {
  if (before.handle == after.handle &&
      before.displayName == after.displayName &&
      before.avatarRef == after.avatarRef) {
    return;
  }
  if (before.handle != after.handle) {
    CcHostLog.info(
      'identity: username changed user=${after.id} '
      'from=${before.handle} to=${after.handle}',
    );
  }
  bus?.publish(
    UserProfileChanged(
      userId: after.id,
      previousHandle: before.handle,
      handle: after.handle,
      displayName: after.displayName,
      avatarRef: after.avatarRef,
      occurredAt: at,
    ),
  );
}

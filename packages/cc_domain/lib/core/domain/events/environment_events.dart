import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// An environment's status changed.
class EnvironmentStatusChanged implements DomainEvent {
  /// Creates an [EnvironmentStatusChanged] event.
  const EnvironmentStatusChanged({
    required this.workspaceId,
    required this.spaceId,
    required this.environmentId,
    required this.status,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// Owning space.
  final String spaceId;

  /// The environment.
  final String environmentId;

  /// The new status.
  final String status;

  @override
  final DateTime occurredAt;
}

/// An environment became ready.
class EnvironmentReady implements DomainEvent {
  /// Creates an [EnvironmentReady] event.
  const EnvironmentReady({
    required this.workspaceId,
    required this.spaceId,
    required this.environmentId,
    required this.occurredAt,
    this.url,
  });

  /// Owning workspace.
  final String workspaceId;

  /// Owning space.
  final String spaceId;

  /// The environment.
  final String environmentId;

  /// Its primary URL.
  final String? url;

  @override
  final DateTime occurredAt;
}

/// An environment was destroyed.
class EnvironmentDestroyed implements DomainEvent {
  /// Creates an [EnvironmentDestroyed] event.
  const EnvironmentDestroyed({
    required this.workspaceId,
    required this.spaceId,
    required this.environmentId,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// Owning space.
  final String spaceId;

  /// The environment.
  final String environmentId;

  @override
  final DateTime occurredAt;
}

/// A supervised process exited.
class EnvironmentProcessExited implements DomainEvent {
  /// Creates an [EnvironmentProcessExited] event.
  const EnvironmentProcessExited({
    required this.workspaceId,
    required this.spaceId,
    required this.environmentId,
    required this.componentId,
    required this.exitCode,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// Owning space.
  final String spaceId;

  /// The environment.
  final String environmentId;

  /// The component.
  final String componentId;

  /// Its exit code.
  final int exitCode;

  @override
  final DateTime occurredAt;
}

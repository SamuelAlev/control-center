import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the application-wide [DomainEventBus].
///
/// Declared in its own web-safe library (depends only on `cc_domain` +
/// Riverpod, no Drift) so presentation/providers can consume the event bus
/// without importing the Drift-typed `core/providers/provider.dart` god-file —
/// part of the "lib = presentation only" decoupling that lets the web build
/// avoid the native data layer.
final domainEventBusProvider = Provider<DomainEventBus>((ref) {
  final bus = DomainEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

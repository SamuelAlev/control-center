import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/observability_events.dart';
import 'package:control_center/core/domain/services/activity_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityLogger', () {
    test('log() publishes ActivityLogged event when eventBus is provided', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      logger.log(
        actorType: 'user',
        action: 'click',
        entityType: 'button',
      );

      // Allow stream to deliver
      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorType, 'user');
        expect(captured!.action, 'click');
        expect(captured!.entityType, 'button');
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('log() does nothing when eventBus is null', () {
      final logger = ActivityLogger();
      // Should not throw
      logger.log(
        actorType: 'user',
        action: 'click',
        entityType: 'button',
      );
    });

    test('logAgentRun() publishes with correct actorType', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      logger.logAgentRun(
        agentId: 'agent-42',
        action: 'start',
        conversationId: 'conv-1',
      );

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorType, 'agent');
        expect(captured!.actorId, 'agent-42');
        expect(captured!.action, 'start');
        expect(captured!.entityType, 'run');
        expect(captured!.entityId, 'conv-1');
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('logUserAction() publishes with correct actorType', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      logger.logUserAction(
        action: 'deploy',
        entityType: 'workspace',
        entityId: 'ws-1',
      );

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorType, 'user');
        expect(captured!.action, 'deploy');
        expect(captured!.entityType, 'workspace');
        expect(captured!.entityId, 'ws-1');
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('logSystemAction() publishes with correct actorType', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      logger.logSystemAction(
        action: 'cleanup',
        entityType: 'temp_file',
      );

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorType, 'system');
        expect(captured!.action, 'cleanup');
        expect(captured!.entityType, 'temp_file');
        sub.cancel();
        eventBus.dispose();
      });
    });
    test('log() includes optional fields when provided', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      logger.log(
        actorType: 'user',
        actorId: 'user-7',
        action: 'save',
        entityType: 'file',
        entityId: 'file-99',
        details: 'Saved config.json',
        runId: 'run-1',
      );

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorId, 'user-7');
        expect(captured!.entityId, 'file-99');
        expect(captured!.details, 'Saved config.json');
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('logAgentRun() includes workspaceId and details when provided', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      logger.logAgentRun(
        agentId: 'agent-7',
        action: 'complete',
        workspaceId: 'ws-3',
        conversationId: 'conv-3',
        details: 'Finished with 0 errors',
      );

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorType, 'agent');
        expect(captured!.actorId, 'agent-7');
        expect(captured!.action, 'complete');
        expect(captured!.entityType, 'run');
        expect(captured!.entityId, 'conv-3');
        expect(captured!.details, 'Finished with 0 errors');
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('logUserAction() includes details when provided', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      logger.logUserAction(
        action: 'rename',
        entityType: 'workspace',
        entityId: 'ws-5',
        details: 'Renamed to "production"',
      );

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorType, 'user');
        expect(captured!.action, 'rename');
        expect(captured!.entityType, 'workspace');
        expect(captured!.details, 'Renamed to "production"');
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('logSystemAction() includes entityId and details when provided', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      logger.logSystemAction(
        action: 'prune',
        entityType: 'cache',
        entityId: 'cache-mem-1',
        details: 'Removed 142 expired entries',
      );

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorType, 'system');
        expect(captured!.action, 'prune');
        expect(captured!.entityType, 'cache');
        expect(captured!.entityId, 'cache-mem-1');
        expect(captured!.details, 'Removed 142 expired entries');
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('multiple events on same bus all arrive', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      final captured = <ActivityLogged>[];
      final sub = eventBus.on<ActivityLogged>().listen(captured.add);

      logger.logUserAction(action: 'one', entityType: 'et');
      logger.logSystemAction(action: 'two', entityType: 'et');
      logger.logAgentRun(agentId: 'a', action: 'three');

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured.length, 3);
        expect(
          captured.map((e) => e.action),
          containsAll(['one', 'two', 'three']),
        );
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('each log generates a unique id', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      final captured = <ActivityLogged>[];
      final sub = eventBus.on<ActivityLogged>().listen(captured.add);

      logger.logUserAction(action: 'a', entityType: 'et');
      logger.logUserAction(action: 'b', entityType: 'et');

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured.length, 2);
        expect(captured[0].id, isNot(equals(captured[1].id)));
        expect(captured[0].id, isNotEmpty);
        expect(captured[1].id, isNotEmpty);
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('occurredAt is set on published events', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      final before = DateTime.now();
      logger.log(actorType: 'agent', action: 'test', entityType: 'test');

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.occurredAt, isNotNull);
        // occurredAt should be within a reasonable window
        final after = DateTime.now();
        expect(
          captured!.occurredAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(captured!.occurredAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('optional fields default to null when not provided', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      logger.log(actorType: 'user', action: 'click', entityType: 'button');

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorId, isNull);
        expect(captured!.entityId, isNull);
        expect(captured!.details, isNull);
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('log() is idempotent with runId (does not throw)', () {
      final eventBus = DomainEventBus();
      final logger = ActivityLogger(eventBus: eventBus);

      ActivityLogged? captured;
      final sub = eventBus.on<ActivityLogged>().listen((e) => captured = e);

      // runId is accepted but not surfaced on ActivityLogged — verify it does not crash
      logger.log(
        actorType: 'user',
        action: 'save',
        entityType: 'file',
        runId: 'run-xyz',
      );

      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        expect(captured, isNotNull);
        expect(captured!.actorType, 'user');
        expect(captured!.action, 'save');
        sub.cancel();
        eventBus.dispose();
      });
    });

    test('log() does nothing when eventBus is null (logAgentRun)', () {
      final logger = ActivityLogger();
      // Should not throw
      logger.logAgentRun(agentId: 'a', action: 'test');
    });

    test('log() does nothing when eventBus is null (logUserAction)', () {
      final logger = ActivityLogger();
      // Should not throw
      logger.logUserAction(action: 'test', entityType: 'et');
    });

    test('log() does nothing when eventBus is null (logSystemAction)', () {
      final logger = ActivityLogger();
      // Should not throw
      logger.logSystemAction(action: 'test', entityType: 'et');
    });
  });
}

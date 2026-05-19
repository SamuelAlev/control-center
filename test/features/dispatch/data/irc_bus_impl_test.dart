import 'package:cc_domain/core/utils/cancellation_token.dart';
import 'package:cc_domain/features/dispatch/domain/irc/irc_message.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_lifecycle.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_infra/src/dispatch/agent_registry_impl.dart';
import 'package:cc_infra/src/dispatch/irc_bus_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AgentRegistryImpl registry;
  late IrcBusImpl bus;

  setUp(() {
    registry = AgentRegistryImpl();
    bus = IrcBusImpl(registry);
  });

  void register(String id, {String workspaceId = 'ws-1', AgentKind kind = AgentKind.main, AgentStatus status = AgentStatus.running}) {
    registry.register(RegisterAgentInput(
      id: id,
      displayName: id,
      workspaceId: workspaceId,
      kind: kind,
      status: status,
    ));
  }

  test('a send with no live sink buffers into the recipient mailbox', () async {
    register('a');
    register('b');
    final receipt = await bus.send(from: 'a', to: 'b', body: 'hello');
    expect(receipt.outcome, IrcDeliveryOutcome.failed); // buffered, not live-seen
    expect(bus.unreadCount('b'), 1);
    final drained = bus.inbox('b');
    expect(drained.single.body, 'hello');
    expect(bus.unreadCount('b'), 0);
  });

  test('a pending wait is satisfied directly (injected) and never buffered',
      () async {
    register('a');
    register('b');
    final waiting = bus.wait('b', timeoutMs: 1000);
    await pumpEventQueue();
    final receipt = await bus.send(from: 'a', to: 'b', body: 'ping');
    expect(receipt.outcome, IrcDeliveryOutcome.injected);
    final msg = await waiting;
    expect(msg!.body, 'ping');
    expect(bus.unreadCount('b'), 0);
  });

  test('wait drains already-buffered mail before parking a waiter', () async {
    register('a');
    register('b');
    await bus.send(from: 'a', to: 'b', body: 'earlier');
    final msg = await bus.wait('b', timeoutMs: 1000);
    expect(msg!.body, 'earlier');
  });

  test('wait honors a from-filter', () async {
    register('a');
    register('b');
    register('c');
    await bus.send(from: 'a', to: 'b', body: 'from-a');
    await bus.send(from: 'c', to: 'b', body: 'from-c');
    final fromC = await bus.wait('b', from: 'c', timeoutMs: 1000);
    expect(fromC!.body, 'from-c');
  });

  test('wait times out to null', () async {
    register('b');
    final msg = await bus.wait('b', timeoutMs: 20);
    expect(msg, isNull);
  });

  test('wait throws when its cancellation token fires', () async {
    register('b');
    final source = CancellationTokenSource();
    final future = bus.wait('b', timeoutMs: 1000, signal: source.token);
    await pumpEventQueue();
    source.cancel('stop');
    await expectLater(future, throwsA(isA<CancelledException>()));
  });

  test('a cross-workspace send fails (workspace isolation)', () async {
    register('a', workspaceId: 'ws-1');
    register('b', workspaceId: 'ws-2');
    final receipt = await bus.send(from: 'a', to: 'b', body: 'leak?');
    expect(receipt.outcome, IrcDeliveryOutcome.failed);
    expect(receipt.error, contains('different workspace'));
    expect(bus.unreadCount('b'), 0);
  });

  test('messaging an advisor fails (read-only transcript)', () async {
    register('a');
    register('adv', kind: AgentKind.advisor);
    final receipt = await bus.send(from: 'a', to: 'adv', body: 'hi');
    expect(receipt.outcome, IrcDeliveryOutcome.failed);
    expect(receipt.error, contains('advisor'));
  });

  test('messaging an unknown or aborted agent fails', () async {
    register('a');
    register('b', status: AgentStatus.aborted);
    expect((await bus.send(from: 'a', to: 'ghost', body: 'x')).outcome,
        IrcDeliveryOutcome.failed);
    expect((await bus.send(from: 'a', to: 'b', body: 'x')).outcome,
        IrcDeliveryOutcome.failed);
  });

  test('a parked recipient is revived first (outcome revived)', () async {
    register('a');
    register('b');
    registry.setStatus('b', AgentStatus.idle);
    final lifecycle = AgentLifecycleManager(registry);
    addTearDown(lifecycle.dispose);
    lifecycle.adopt('b', idleTtlMs: 0, reviver: () async => _StubSession());
    await lifecycle.park('b');
    expect(registry.get('b')!.status, AgentStatus.parked);

    final revivingBus = IrcBusImpl(registry, lifecycle: lifecycle);
    final receipt = await revivingBus.send(from: 'a', to: 'b', body: 'wake');
    expect(receipt.outcome, IrcDeliveryOutcome.revived);
    expect(registry.get('b')!.status, AgentStatus.idle);
  });
}

class _StubSession implements AgentSessionController {
  @override
  String? get dispatchId => 'd-stub';
  @override
  Future<void> dispose() async {}
}

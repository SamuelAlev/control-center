import 'package:cc_mcp/src/tools/pending_delegation_hops.dart';
import 'package:test/test.dart';

void main() {
  late PendingDelegationHops hops;

  setUp(() {
    hops = PendingDelegationHops();
  });

  test('an agent with no asks in flight is its own chain', () {
    expect(hops.chain('ws-1', 'a'), ['a']);
    expect(hops.wouldCycle('ws-1', 'a', 'b'), isFalse);
  });

  test('asking an agent that is already waiting on you cycles', () {
    final leave = hops.enter('ws-1', 'a', 'b');
    expect(hops.chain('ws-1', 'b'), ['a', 'b']);
    expect(hops.wouldCycle('ws-1', 'b', 'a'), isTrue);
    expect(hops.wouldCycle('ws-1', 'a', 'a'), isTrue);
    leave();
    expect(hops.chain('ws-1', 'b'), ['b']);
    expect(hops.wouldCycle('ws-1', 'b', 'a'), isFalse);
  });

  test('the longest ancestor chain is what chain reports', () {
    hops
      ..enter('ws-1', 'a', 'd')
      ..enter('ws-1', 'd', 'b')
      ..enter('ws-1', 'c', 'b');
    expect(hops.chain('ws-1', 'b'), ['a', 'd', 'b']);
  });

  test('a shorter concurrent ask is still a cycle', () {
    hops
      ..enter('ws-1', 'a', 'd')
      ..enter('ws-1', 'd', 'b')
      ..enter('ws-1', 'c', 'b');
    expect(hops.chain('ws-1', 'b'), isNot(contains('c')));
    expect(hops.wouldCycle('ws-1', 'b', 'c'), isTrue);
  });

  test('hops in one workspace do not leak into another', () {
    hops.enter('ws-1', 'a', 'b');
    expect(hops.wouldCycle('ws-2', 'b', 'a'), isFalse);
    expect(hops.chain('ws-2', 'b'), ['b']);
  });

  test(
    'identical asks release one at a time and a second release is a no-op',
    () {
      final first = hops.enter('ws-1', 'a', 'b');
      final second = hops.enter('ws-1', 'a', 'b');
      first();
      expect(hops.wouldCycle('ws-1', 'b', 'a'), isTrue);
      first();
      expect(hops.wouldCycle('ws-1', 'b', 'a'), isTrue);
      second();
      expect(hops.wouldCycle('ws-1', 'b', 'a'), isFalse);
      second();
      expect(hops.chain('ws-1', 'b'), ['b']);
    },
  );
}

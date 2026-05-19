import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';
import 'package:test/test.dart';

void main() {
  group('SpaceLocus wire', () {
    test('carries the conversation alongside the space', () {
      const locus = SpaceLocus(spaceId: 'sp-1', conversationId: 'conv-1');
      expect(locus.toWire(), {'t': 'sp', 'c': 'sp-1', 'cv': 'conv-1'});
      expect(PresenceLocus.fromWire(locus.toWire()), locus);
    });

    test('omits the conversation key when there is none', () {
      const locus = SpaceLocus(spaceId: 'sp-1');
      expect(locus.toWire(), {'t': 'sp', 'c': 'sp-1'});
      expect(PresenceLocus.fromWire(locus.toWire()), locus);
    });

    test(
      'a payload from a client that predates the conversation key parses',
      () {
        expect(
          PresenceLocus.fromWire({'t': 'sp', 'c': 'sp-1'}),
          const SpaceLocus(spaceId: 'sp-1'),
        );
      },
    );

    test('the conversation is part of identity — same space, different '
        'conversation is a different locus', () {
      // Equality drives follow-mode's "has the target moved" check. Ignoring
      // the conversation would freeze a follower on the first tab the agent
      // happened to be in.
      expect(
        const SpaceLocus(spaceId: 'sp-1', conversationId: 'conv-1'),
        isNot(const SpaceLocus(spaceId: 'sp-1', conversationId: 'conv-2')),
      );
      expect(
        const SpaceLocus(spaceId: 'sp-1', conversationId: 'conv-1'),
        isNot(const SpaceLocus(spaceId: 'sp-1')),
      );
    });
  });
}

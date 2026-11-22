import 'package:cc_domain/features/messaging/domain/services/peer_message_limits.dart';
import 'package:cc_domain/features/ticketing/domain/value_objects/delegation_brief.dart';
import 'package:test/test.dart';

void main() {
  group('DelegationBrief', () {
    test('folds items to one line and treats blank constraints as none', () {
      final brief = DelegationBrief(
        doneMeans: ['  Tests pass\r\n  on CI  '],
        constraints: '   ',
        references: ['a.dart'],
      );

      expect(brief.doneMeans, ['Tests pass on CI']);
      expect(brief.constraints, isNull);
      expect(brief.isEmpty, isFalse);
      expect(DelegationBrief().isEmpty, isTrue);
      expect(DelegationBrief().render(null), isNull);
      expect(DelegationBrief().render('Just text'), 'Just text');
    });

    test('round-trips through ticket metadata and compares by value', () {
      final brief = DelegationBrief(
        doneMeans: ['One', 'Two'],
        constraints: 'Stay in lib/',
        references: ['TICKET-1'],
      );
      final metadata = {DelegationBrief.metadataKey: brief.toMetadata()};

      expect(DelegationBrief.fromMetadata(metadata), brief);
      expect(DelegationBrief.fromMetadata(metadata).hashCode, brief.hashCode);
      expect(DelegationBrief.fromMetadata(const {}), isNull);
      expect(
        DelegationBrief.fromMetadata({
          DelegationBrief.metadataKey: {'done_means': 'not a list'},
        }),
        isNull,
      );
    });

    test('refuses every broken limit', () {
      expect(
        () => DelegationBrief(doneMeans: List.filled(13, 'x')),
        throwsArgumentError,
      );
      expect(
        () => DelegationBrief(doneMeans: ['x' * 301]),
        throwsArgumentError,
      );
      expect(() => DelegationBrief(doneMeans: ['']), throwsArgumentError);
      expect(
        () => DelegationBrief(constraints: 'c' * 2001),
        throwsArgumentError,
      );
      expect(
        () => DelegationBrief(references: List.filled(21, 'r')),
        throwsArgumentError,
      );
      expect(
        () => DelegationBrief(references: ['r' * 501]),
        throwsArgumentError,
      );
    });
  });

  group('peerMessageSizeRefusal', () {
    test('fits up to the limit and names it past it', () {
      expect(
        peerMessageSizeRefusal('x' * maxPeerMessageChars, label: 'message'),
        isNull,
      );
      final refusal = peerMessageSizeRefusal(
        'x' * (maxPeerMessageChars + 1),
        label: 'message',
      );
      expect(refusal, contains('The message is 16385 characters'));
      expect(refusal, contains('at most 16384'));
      expect(refusal, contains('file or a ticket'));
    });
  });
}

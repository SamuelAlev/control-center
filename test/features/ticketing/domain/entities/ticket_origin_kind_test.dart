import 'package:control_center/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketOriginKind', () {
    test('has all expected values', timeout: const Timeout.factor(2), () {
      expect(TicketOriginKind.values, hasLength(5));
      expect(TicketOriginKind.values, containsAll([
        TicketOriginKind.manual,
        TicketOriginKind.pipelineStep,
        TicketOriginKind.agentDelegation,
        TicketOriginKind.externalSync,
        TicketOriginKind.recovery,
      ]));
    });

    test('values are distinct', timeout: const Timeout.factor(2), () {
      final set = TicketOriginKind.values.toSet();
      expect(set, hasLength(5));
    });
  });
}

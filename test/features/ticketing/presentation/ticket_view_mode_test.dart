import 'package:control_center/features/ticketing/presentation/ticket_view_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketViewMode', () {
    test('defaults to list for unknown/null persisted values', () {
      expect(TicketViewMode.fromStorage(null), TicketViewMode.list);
      expect(TicketViewMode.fromStorage(''), TicketViewMode.list);
      expect(TicketViewMode.fromStorage('garbage'), TicketViewMode.list);
    });

    test('round-trips each mode through storage', () {
      for (final mode in TicketViewMode.values) {
        expect(
          TicketViewMode.fromStorage(mode.toStorageString()),
          mode,
          reason: 'round-trip for $mode',
        );
      }
    });

    test('parses the canonical board value', () {
      expect(TicketViewMode.fromStorage('board'), TicketViewMode.board);
      expect(TicketViewMode.fromStorage('list'), TicketViewMode.list);
    });
  });
}

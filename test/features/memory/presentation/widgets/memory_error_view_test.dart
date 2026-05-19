import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('MemoryErrorView', () {
    testWidgets('renders error with retry button', (tester) async {
      await tester.pumpWidget(testWrap(
        MemoryErrorView(
          error: Exception('Connection refused'),
          onRetry: () {},
        ),
      ));

      // Exception.toString() includes "Exception: " prefix
      expect(find.text('Exception: Connection refused'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders different error messages', (tester) async {
      await tester.pumpWidget(testWrap(
        MemoryErrorView(
          error: 'Database is locked',
          onRetry: () {},
        ),
      ));

      expect(find.text('Database is locked'), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button tapped', (tester) async {
      var retried = false;
      await tester.pumpWidget(testWrap(
        MemoryErrorView(
          error: Exception('timeout'),
          onRetry: () => retried = true,
        ),
      ));

      await tester.tap(find.text('Retry'));
      // Pump to settle CcButton animation timers
      await tester.pump(const Duration(milliseconds: 200));
      expect(retried, isTrue);
    });

    testWidgets('renders with StateError', (tester) async {
      await tester.pumpWidget(testWrap(
        MemoryErrorView(
          error: StateError('Bad state: not initialized'),
          onRetry: () {},
        ),
      ));

      // StateError.toString() yields "Bad state: Bad state: not initialized"
      expect(find.text('Bad state: Bad state: not initialized'), findsOneWidget);
    });
  });
}

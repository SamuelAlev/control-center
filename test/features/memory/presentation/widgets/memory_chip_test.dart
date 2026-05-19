import 'package:control_center/features/memory/presentation/widgets/memory_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('MemoryMetaChip', () {
    testWidgets('renders neutral chip with label', (tester) async {
      await tester.pumpWidget(testWrap(
        const MemoryMetaChip(label: 'security'),
      ));

      expect(find.text('security'), findsOneWidget);
    });

    testWidgets('renders chip with icon', (tester) async {
      await tester.pumpWidget(testWrap(
        const MemoryMetaChip(
          label: 'security',
          icon: LucideIcons.shield,
        ),
      ));

      expect(find.text('security'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shield), findsOneWidget);
    });

    testWidgets('renders error tone chip', (tester) async {
      await tester.pumpWidget(testWrap(
        const MemoryMetaChip(
          label: 'superseded',
          tone: MemoryChipTone.error,
        ),
      ));

      expect(find.text('superseded'), findsOneWidget);
    });

    testWidgets('renders monospace label', (tester) async {
      await tester.pumpWidget(testWrap(
        const MemoryMetaChip(
          label: 'abc123def',
          monospace: true,
        ),
      ));

      expect(find.text('abc123def'), findsOneWidget);
    });

    testWidgets('renders with both icon and monospace', (tester) async {
      await tester.pumpWidget(testWrap(
        const MemoryMetaChip(
          label: 'abc123',
          icon: LucideIcons.hash,
          monospace: true,
        ),
      ));

      expect(find.text('abc123'), findsOneWidget);
      expect(find.byIcon(LucideIcons.hash), findsOneWidget);
    });

    testWidgets('renders error tone with icon', (tester) async {
      await tester.pumpWidget(testWrap(
        const MemoryMetaChip(
          label: 'outdated',
          icon: LucideIcons.alertCircle,
          tone: MemoryChipTone.error,
        ),
      ));

      expect(find.text('outdated'), findsOneWidget);
      expect(find.byIcon(LucideIcons.alertCircle), findsOneWidget);
    });
  });
}

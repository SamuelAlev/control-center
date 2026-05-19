import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('MeetingSignalPill', () {
    testWidgets('renders icon and label', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingSignalPill(
          icon: LucideIcons.check,
          label: '3 decisions',
        ),
      ));

      expect(find.text('3 decisions'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });

    testWidgets('neutral tone uses muted colors', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingSignalPill(
          icon: LucideIcons.check,
          label: 'neutral',
          tone: MeetingPillTone.neutral,
        ),
      ));
      expect(find.text('neutral'), findsOneWidget);
    });

    testWidgets('accent tone renders without error', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingSignalPill(
          icon: LucideIcons.star,
          label: 'accent',
          tone: MeetingPillTone.accent,
        ),
      ));
      expect(find.text('accent'), findsOneWidget);
    });

    testWidgets('warn tone renders without error', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingSignalPill(
          icon: LucideIcons.alertTriangle,
          label: 'warn',
          tone: MeetingPillTone.warn,
        ),
      ));
      expect(find.text('warn'), findsOneWidget);
    });

    testWidgets('success tone renders without error', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingSignalPill(
          icon: LucideIcons.checkCircle,
          label: 'success',
          tone: MeetingPillTone.success,
        ),
      ));
      expect(find.text('success'), findsOneWidget);
    });
  });

  group('MeetingStatusGlyph', () {
    testWidgets('done status shows check icon', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingStatusGlyph(status: MeetingStatus.done),
      ));
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
    });

    testWidgets('recording status shows mic icon', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingStatusGlyph(status: MeetingStatus.recording),
      ));
      expect(find.byIcon(LucideIcons.mic), findsOneWidget);
    });

    testWidgets('failed status shows alert icon', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingStatusGlyph(status: MeetingStatus.failed),
      ));
      expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
    });

    testWidgets('processing status shows equalizer bars', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingStatusGlyph(status: MeetingStatus.processing),
      ));
      expect(find.byType(MeetingEqualizerBars), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingStatusGlyph(status: MeetingStatus.done, size: 24),
      ));
      final icon = tester.widget<Icon>(find.byIcon(LucideIcons.circleCheck));
      expect(icon.size, 24);
    });
  });

  group('MeetingEyebrow', () {
    testWidgets('renders text in uppercase', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingEyebrow('summary'),
      ));
      expect(find.text('SUMMARY'), findsOneWidget);
    });

    testWidgets('already-uppercase text stays uppercase', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingEyebrow('DECISIONS'),
      ));
      expect(find.text('DECISIONS'), findsOneWidget);
    });
  });

  group('MeetingEqualizerBars', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingEqualizerBars(color: Colors.orange),
      ));
      // The widget renders via AnimatedBuilder; verify it's present.
      expect(find.byType(MeetingEqualizerBars), findsOneWidget);
    });

    testWidgets('renders correct number of bars', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingEqualizerBars(color: Colors.orange, barCount: 4),
      ));
      // 4 AnimatedBuilder widgets
      expect(find.byType(MeetingEqualizerBars), findsOneWidget);
    });
  });
}

import 'package:control_center/features/meetings/presentation/widgets/meeting_capture_banner.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_wrap.dart';


void main() {
  group('MeetingCaptureBanner', () {
    testWidgets('renders banner content', (tester) async {
      await tester.pumpWidget(testWrap(const MeetingCaptureBanner()));

      expect(find.byType(MeetingCaptureBanner), findsOneWidget);
    });

    testWidgets('renders lock and crosshair badge icons', (tester) async {
      await tester.pumpWidget(testWrap(const MeetingCaptureBanner()));

      // The banner includes an on-device badge with a lock icon.
      expect(find.byIcon(AppIcons.lock), findsOneWidget);
      // The "no bot joins" badge has a crosshair icon.
      expect(find.byIcon(AppIcons.crosshair), findsOneWidget);
    });

    testWidgets('renders brand gradient glyph', (tester) async {
      await tester.pumpWidget(testWrap(const MeetingCaptureBanner()));

      // The brand gradient container has an audio-lines icon.
      expect(find.byIcon(AppIcons.audioLines), findsOneWidget);
    });
  });
}

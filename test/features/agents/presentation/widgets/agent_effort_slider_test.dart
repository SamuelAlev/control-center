import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_effort_slider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
          child: child,
        ),
      ),
    ),
  );
}

Widget _wrapSlider({
  required List<ThinkingLevel> levels,
  String? value,
  String? defaultValue,
  required ValueChanged<String> onChanged,
}) {
  return _wrap(
    Center(
      child: SizedBox(
        width: 320,
        child: AgentEffortSlider(
          levels: levels,
          value: value,
          defaultValue: defaultValue,
          semanticLabel: 'Reasoning effort',
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

const _levels = [
  ThinkingLevel(id: 'low', label: 'Low'),
  ThinkingLevel(id: 'medium', label: 'Medium'),
  ThinkingLevel(id: 'high', label: 'High'),
];

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('AgentEffortSlider', () {
    testWidgets('names each stop after the model\'s effort levels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapSlider(levels: _levels, value: 'medium', onChanged: (_) {}),
      );

      expect(find.byType(CcSlider), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('tapping the last stop commits that level id', (tester) async {
      String? received;
      await tester.pumpWidget(
        _wrapSlider(
          levels: _levels,
          value: 'medium',
          onChanged: (v) => received = v,
        ),
      );

      final track = tester.getRect(find.byKey(CcSlider.trackKey));
      await tester.tapAt(Offset(track.right - 1, track.center.dy));
      await tester.pump();

      expect(received, 'high');
    });

    testWidgets('a single level is a reading, not a slider', (tester) async {
      await tester.pumpWidget(
        _wrapSlider(
          levels: const [ThinkingLevel(id: 'high', label: 'High')],
          value: 'high',
          onChanged: (_) {},
        ),
      );

      expect(find.byType(CcSlider), findsNothing);
      expect(find.text('High'), findsOneWidget);
    });
  });
}

import 'package:control_center/shared/widgets/reference_chip_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  group('ReferenceChipShell', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(testWrap(
        ReferenceChipShell(
          child: const Text('#42'),
          onTap: () {},
        ),
      ));

      expect(find.text('#42'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testWrap(
        ReferenceChipShell(
          child: const Text('click me'),
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('click me'));
      expect(tapped, isTrue);
    });

    testWidgets('renders complex child widget', (tester) async {
      await tester.pumpWidget(testWrap(
        ReferenceChipShell(
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.code, size: 14),
              SizedBox(width: 4),
              Text('abc123'),
            ],
          ),
          onTap: () {},
        ),
      ));

      expect(find.text('abc123'), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
    });
  });

  group('ReferenceFallbackLink', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(testWrap(
        ReferenceFallbackLink(
          label: 'github.com/org/repo#42',
          onTap: () {},
        ),
      ));

      expect(find.text('github.com/org/repo#42'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testWrap(
        ReferenceFallbackLink(
          label: 'tap link',
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('tap link'));
      expect(tapped, isTrue);
    });
  });
}

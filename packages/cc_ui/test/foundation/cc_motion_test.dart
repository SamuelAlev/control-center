import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  test('three enter speeds and their faster exits', () {
    expect(CcMotion.fast, const Duration(milliseconds: 80));
    expect(CcMotion.moderate, const Duration(milliseconds: 160));
    expect(CcMotion.normal, CcMotion.moderate);
    expect(CcMotion.slow, const Duration(milliseconds: 240));
    expect(CcMotion.fastExit, const Duration(milliseconds: 60));
    expect(CcMotion.moderateExit, const Duration(milliseconds: 120));
    expect(CcMotion.slowExit, const Duration(milliseconds: 160));
    expect(CcMotion.fade, const Duration(milliseconds: 80));
  });

  test('exitFor pairs each enter with one-tier-faster leave', () {
    expect(CcMotion.exitFor(CcMotion.fast), CcMotion.fastExit);
    expect(CcMotion.exitFor(CcMotion.moderate), CcMotion.moderateExit);
    expect(CcMotion.exitFor(CcMotion.normal), CcMotion.moderateExit);
    expect(CcMotion.exitFor(CcMotion.slow), CcMotion.slowExit);
    expect(
      CcMotion.exitFor(const Duration(milliseconds: 400)),
      const Duration(milliseconds: 266),
    );
  });

  testWidgets('resolve keeps travel when motion is allowed', (tester) async {
    late Duration travel;
    late Duration fade;
    await tester.pumpWidget(
      ccTestApp(
        Builder(
          builder: (context) {
            travel = CcMotion.resolve(context, CcMotion.slow);
            fade = CcMotion.resolveFade(context, CcMotion.slow);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(travel, CcMotion.slow);
    expect(fade, CcMotion.slow);
  });

  testWidgets('resolve drops travel and resolveFade keeps a fade', (
    tester,
  ) async {
    late Duration travel;
    late Duration fade;
    await tester.pumpWidget(
      ccTestApp(
        Builder(
          builder: (context) {
            travel = CcMotion.resolveTravel(context, CcMotion.slow);
            fade = CcMotion.resolveFade(context, CcMotion.slow);
            return const SizedBox();
          },
        ),
        theme: CcThemeData.light(reducedMotion: true),
      ),
    );
    expect(travel, Duration.zero);
    expect(fade, CcMotion.fade);
  });

  testWidgets('MediaQuery.disableAnimations is treated as reduced', (
    tester,
  ) async {
    late bool reduced;
    await tester.pumpWidget(
      CcTheme(
        data: CcThemeData.light(),
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(color: Color(0x00000000)),
          ),
        ),
      ),
    );
    // Rebuild with a Builder now that MediaQuery is in the tree.
    await tester.pumpWidget(
      CcTheme(
        data: CcThemeData.light(),
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                reduced = CcMotion.reduced(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    expect(reduced, isTrue);
  });
}

import 'package:control_center/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isAtRoute matches the route and its sub-routes, never a sibling', () {
    expect(isAtRoute('/onboarding', onboardingRoute), isTrue);
    expect(isAtRoute('/onboarding/step', onboardingRoute), isTrue);
    expect(isAtRoute('/onboardingx', onboardingRoute), isFalse);
    expect(isAtRoute('/splash', onboardingRoute), isFalse);
  });

  test('authentication routes are splash and onboarding only', () {
    expect(isAuthenticationRoute(splashRoute), isTrue);
    expect(isAuthenticationRoute(onboardingRoute), isTrue);
    expect(isAuthenticationRoute(workspaceListRoute), isFalse);
    expect(isAuthenticationRoute('/splashy'), isFalse);
  });
}

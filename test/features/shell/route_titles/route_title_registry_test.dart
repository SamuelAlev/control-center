import 'package:control_center/features/shell/breadcrumbs/breadcrumb_registry.dart';
import 'package:control_center/features/shell/route_titles/route_title_registry.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routeTitleRegistry', () {
    test(
      'covers every workspace-shell route the breadcrumb registry covers',
      () {
        final expected = breadcrumbRegistry.keys.toSet();
        final missing = expected.difference(routeTitleRegistry.keys.toSet());
        expect(
          missing,
          isEmpty,
          reason: 'Missing route-title builders for: $missing',
        );
      },
    );

    test('also covers the pre-context routes', () {
      expect(routeTitleRegistry, contains(splashRoute));
      expect(routeTitleRegistry, contains(onboardingRoute));
      expect(routeTitleRegistry, contains(workspaceListRoute));
    });

    test(
      'every entry key uses a go_router fullPath pattern (leading slash)',
      () {
        for (final key in routeTitleRegistry.keys) {
          expect(
            key.startsWith('/'),
            isTrue,
            reason: 'Pattern "$key" must start with "/" to match fullPath',
          );
        }
      },
    );
  });
}

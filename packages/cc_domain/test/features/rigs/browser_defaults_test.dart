import 'package:cc_domain/features/rigs/domain/value_objects/browser_defaults.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:test/test.dart';

void main() {
  group('browserRigHomeHtml', () {
    test('each engine gets its own page: mark, name, status and example', () {
      for (final engine in RigBrowserEngine.values) {
        final page = browserRigHomeHtml(engine);
        expect(page, contains('<title>Enclosed ${engine.label}</title>'));
        expect(page, contains('<h1>${engine.label}</h1>'));
        expect(
          page,
          contains('Connected'),
          reason: 'The page is the live machine, so its status line says so.',
        );
        expect(
          page,
          contains('screenshot'),
          reason:
              'The one line of copy is a concrete example of what the '
              'enclosure is for, not a lecture about protocols.',
        );
        expect(
          page,
          contains(browserRigEngineMark(engine)),
          reason:
              'The page carries the engine mark inline — the same SVG the '
              'client breathes on the boot screen, so the two must agree.',
        );
        // The engine-tinted glow rides both schemes.
        expect(page, contains('radial-gradient'));
      }
    });

    test('the three pages are distinct', () {
      final pages = {
        for (final engine in RigBrowserEngine.values)
          browserRigHomeHtml(engine),
      };
      expect(
        pages,
        hasLength(RigBrowserEngine.values.length),
        reason:
            'One rig per engine exists to COMPARE engines — a shared page '
            'would leave three identical tabs nobody can tell apart.',
      );
    });

    test('the page follows the opener\'s theme and keeps the glow', () {
      final light = browserRigHomeHtml(
        RigBrowserEngine.chromium,
        theme: RigBrowserHomeTheme.light,
      );
      final dark = browserRigHomeHtml(
        RigBrowserEngine.chromium,
        theme: RigBrowserHomeTheme.dark,
      );
      expect(light, contains('color-scheme: light'));
      expect(dark, contains('color-scheme: dark'));
      expect(light, isNot(equals(dark)));
      for (final page in [light, dark]) {
        expect(
          page,
          contains('#4e8bf5'),
          reason:
              'The engine-accented radial glow is the one flourish the page '
              'keeps in both themes.',
        );
      }
    });

    test('an unthemed page keeps the historical dark look', () {
      expect(
        browserRigHomeHtml(RigBrowserEngine.chromium),
        contains('color-scheme: dark'),
        reason:
            'A server that never heard a theme keeps the look every rig had '
            'before themes existed.',
      );
    });

    test('pages and marks are fully self-contained', () {
      for (final engine in RigBrowserEngine.values) {
        for (final theme in RigBrowserHomeTheme.values) {
          final page = browserRigHomeHtml(engine, theme: theme);
          expect(
            page,
            isNot(contains('http')),
            reason:
                'The page renders behind a fully closed egress gate, so no '
                'URL — and no xmlns, which is also an http substring — may '
                'appear. This is also what keeps the workload script clean: '
                'the page travels base64\'d, and the smolvm test pins that '
                'the script never contains "http".',
          );
          expect(page, isNot(contains('<script')));
        }
        final mark = browserRigEngineMark(engine);
        expect(mark, startsWith('<svg '));
        expect(mark, endsWith('</svg>'));
      }
    });
  });
}

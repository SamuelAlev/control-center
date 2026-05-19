import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:test/test.dart';

void main() {
  group('RigBrowserEngine', () {
    test('an unknown engine is null, never quietly Chromium', () {
      // A caller that asked for Safari asked a compatibility question, and
      // answering it with a different browser is worse than not answering.
      expect(RigBrowserEngine.fromWire('safari'), isNull);
      expect(RigBrowserEngine.fromWire(null), isNull);
      for (final engine in RigBrowserEngine.values) {
        expect(RigBrowserEngine.fromWire(engine.wire), engine);
      }
    });

    test('only Chromium pushes frames, and only WebKit answers PNG', () {
      // Both facts decide real machinery: the first picks the watch lane, the
      // second decides whether the host needs ffmpeg to serve it.
      expect(RigBrowserEngine.chromium.hasScreencast, isTrue);
      expect(RigBrowserEngine.firefox.hasScreencast, isFalse);
      expect(RigBrowserEngine.webkit.hasScreencast, isFalse);

      expect(RigBrowserEngine.webkit.capturesJpeg, isFalse);
      expect(RigBrowserEngine.webkit.stillMediaType, 'image/png');
      expect(RigBrowserEngine.chromium.stillMediaType, 'image/jpeg');
      expect(RigBrowserEngine.firefox.stillMediaType, 'image/jpeg');
    });
  });

  group('RigSpec', () {
    test('a spec round-trips its engine', () {
      final spec = RigSpec(
        surface: RigSurface.browser,
        browserEngine: RigBrowserEngine.webkit,
        conversationId: 'c1',
        egressAllowlist: const ['example.test'],
      );
      final restored = RigSpec.fromJson(spec.toJson());
      expect(restored.browserEngine, RigBrowserEngine.webkit);
      expect(restored, spec);
    });

    test('a row written before engines existed reads as Chromium', () {
      // Every browser rig that predates this enum ran Chromium, and reading
      // those back as "unknown" would strand them.
      final json = RigSpec(
        surface: RigSurface.browser,
        conversationId: 'c1',
      ).toJson()..remove('browserEngine');
      expect(RigSpec.fromJson(json).browserEngine, RigBrowserEngine.chromium);
    });

    test('two engines are two different specs', () {
      // Load-bearing: the reuse check and the in-flight open key are both
      // equality on this value, and identity equality made every comparison
      // answer "different" while a field comparison that ignored the engine
      // would answer "same" — which hands a Firefox tab the Chromium machine.
      final chromium = RigSpec(
        surface: RigSurface.browser,
        conversationId: 'c1',
      );
      final firefox = chromium.copyWith(
        browserEngine: RigBrowserEngine.firefox,
      );
      expect(firefox, isNot(chromium));
      expect(firefox.hashCode, isNot(chromium.hashCode));
      expect(
        firefox.copyWith(browserEngine: RigBrowserEngine.chromium),
        chromium,
      );
    });

    test('Firefox and WebKit are given more memory than headless-shell', () {
      // Firefox runs a full browser and WebKit runs MiniBrowser on top of an
      // X server; the 2 GB that suits headless-shell does not cover either.
      final chromium = RigSpec(surface: RigSurface.browser).memoryMb;
      for (final engine in [
        RigBrowserEngine.firefox,
        RigBrowserEngine.webkit,
      ]) {
        expect(
          RigSpec(surface: RigSurface.browser, browserEngine: engine).memoryMb,
          greaterThan(chromium),
        );
      }
      expect(
        RigSpec(
          surface: RigSurface.browser,
          browserEngine: RigBrowserEngine.firefox,
          memoryMb: 1024,
        ).memoryMb,
        1024,
        reason: 'An explicit budget still wins.',
      );
    });
  });

  group('RigBackendCapabilities', () {
    test('an older server that names no engines still offers Chromium', () {
      // Such a server hosts the browser surface perfectly well; reading its
      // silence as "no browsers" would grey out a tab that works.
      final capabilities = RigBackendCapabilities.fromJson({
        'backend': EnclosureBackend.smolvm.wire,
        'available': true,
        'surfaces': [RigSurface.browser.wire],
      });
      expect(capabilities.browserEngines, {RigBrowserEngine.chromium});
      expect(capabilities.supportsEngine(RigBrowserEngine.chromium), isTrue);
      expect(capabilities.supportsEngine(RigBrowserEngine.firefox), isFalse);
    });

    test('an empty engine list is taken at its word', () {
      final capabilities = RigBackendCapabilities.fromJson({
        'backend': EnclosureBackend.smolvm.wire,
        'available': true,
        'surfaces': [RigSurface.browser.wire],
        'browserEngines': <String>[],
      });
      expect(capabilities.browserEngines, isEmpty);
    });

    test('engines round-trip through the detect payload', () {
      const capabilities = RigBackendCapabilities(
        backend: EnclosureBackend.smolvm,
        available: true,
        surfaces: {RigSurface.browser},
        browserEngines: {
          RigBrowserEngine.chromium,
          RigBrowserEngine.firefox,
          RigBrowserEngine.webkit,
        },
      );
      final restored = RigBackendCapabilities.fromJson(capabilities.toJson());
      expect(restored.browserEngines, capabilities.browserEngines);
      for (final engine in RigBrowserEngine.values) {
        expect(restored.supportsEngine(engine), isTrue);
      }
    });
  });
}

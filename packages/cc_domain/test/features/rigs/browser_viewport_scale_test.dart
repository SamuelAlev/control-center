import 'package:cc_domain/features/rigs/domain/value_objects/browser_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:test/test.dart';

// `set_viewport` carries the viewer's device pixel ratio so the guest paints
// real device pixels instead of the panel upscaling a 1x render. The size
// stays in CSS pixels — that split is the whole point, and getting it backwards
// gives a guest that renders text at half size.
BrowserSetViewport parse(Map<String, dynamic> args) {
  final parsed = BrowserAction.parse({'action': 'set_viewport', ...args});
  expect(parsed, isA<RigActionParsed>(), reason: 'parse failed: $parsed');
  return (parsed as RigActionParsed).action as BrowserSetViewport;
}

void main() {
  group('set_viewport device scale', () {
    test('defaults to 1, so an old client is unchanged', () {
      final action = parse({'width': 1280, 'height': 800});
      expect(action.deviceScaleFactor, 1);
      // Absent from the wire too: a 1x request must look exactly like the
      // requests that predate this field.
      expect(action.toJson(), isNot(contains('device_scale_factor')));
    });

    test('carries a fractional ratio, because displays have them', () {
      // A small viewport, so the raster budget leaves the ratio intact and
      // this tests the plumbing rather than the budget (pinned below).
      // 1.5 and 2.75 are both real device pixel ratios. Rounding one to an int
      // is the difference between a sharp guest and a blurry one, which is why
      // this reads a double rather than reusing the int reader next to it.
      expect(
        parse({
          'width': 640,
          'height': 480,
          'device_scale_factor': 1.5,
        }).deviceScaleFactor,
        1.5,
      );
    });

    test('clamps above 2 rather than refusing', () {
      // This arrives from a viewer reporting its own display. A 3x phone is a
      // reason to render sharper, not a bad request — and past 2 the extra
      // pixels stop being visible while still costing four times the bytes.
      expect(
        parse({
          'width': 640,
          'height': 480,
          'device_scale_factor': 3,
        }).deviceScaleFactor,
        2,
      );
      expect(
        parse({
          'width': 640,
          'height': 480,
          'device_scale_factor': 0.5,
        }).deviceScaleFactor,
        1,
      );
    });

    test('a non-numeric or non-finite ratio falls back to 1', () {
      for (final junk in <Object>['huge', double.nan, double.infinity]) {
        expect(
          parse({
            'width': 640,
            'height': 480,
            'device_scale_factor': junk,
          }).deviceScaleFactor,
          1,
          reason: '$junk must not reach an engine as a scale',
        );
      }
    });

    test('the size stays in CSS pixels, whatever the scale', () {
      // The guest lays out at 640x480 and RENDERS 1280x960. Multiplying the
      // size here instead would give half-size text nobody can read — the bug
      // the logical-size resize was avoiding before it had this knob.
      final action = parse({
        'width': 640,
        'height': 480,
        'device_scale_factor': 2,
      });
      expect(action.size.width, 640);
      expect(action.size.height, 480);
      expect(action.toJson()['width'], 640);
      expect(action.toJson()['device_scale_factor'], 2);
    });

    test('mobile still round-trips alongside it', () {
      final action = parse({
        'width': 390,
        'height': 844,
        'mobile': true,
        'device_scale_factor': 2,
      });
      expect(action.mobile, isTrue);
      expect(action.deviceScaleFactor, 2);
      expect(action.summary, contains('2'));
    });
  });

  group('rigOptDouble', () {
    test('accepts ints, doubles and numeric strings; rejects the rest', () {
      expect(rigOptDouble({'v': 2}, 'v'), 2.0);
      expect(rigOptDouble({'v': 1.5}, 'v'), 1.5);
      expect(rigOptDouble({'v': '1.75'}, 'v'), 1.75);
      expect(rigOptDouble({'v': 'no'}, 'v'), isNull);
      expect(rigOptDouble({'v': double.nan}, 'v'), isNull);
      expect(rigOptDouble(<String, dynamic>{}, 'v'), isNull);
    });
  });

  // The constraint the first cut of this feature was missing. A browser rig is
  // a 2-vCPU microVM with no GPU: at 1296x970 it kept up, and at 2x — 5.03 MP
  // of software rasterisation — its control channel stopped answering, so
  // Page.navigate and input.performActions started timing out. The viewport
  // ceiling always meant "this is what the guest can render"; rendering at a
  // device scale is what let the render exceed it.
  group('raster budget', () {
    test('the panel size that broke it does not ask for 2x again', () {
      const observed = 1296 * 970;
      expect(observed * 4, greaterThan(RigDisplaySize.devicePixelBudget));
      expect(RigDisplaySize(1296, 970).deviceScaleWithin(2), 1);
      final action = parse({
        'width': 1296,
        'height': 970,
        'device_scale_factor': 2,
      });
      expect(
        action.deviceScaleFactor,
        1,
        reason: 'the server must re-derive the budget, not trust the client',
      );
    });

    test('a small panel has headroom and does get a sharp guest', () {
      final scale = RigDisplaySize(640, 480).deviceScaleWithin(2);
      expect(scale, 2);
      expect(
        640 * 480 * scale * scale,
        lessThanOrEqualTo(RigDisplaySize.devicePixelBudget),
      );
    });

    test('a mid-size panel lands between, still inside the budget', () {
      final size = RigDisplaySize(800, 600);
      final scale = size.deviceScaleWithin(2);
      expect(scale, greaterThan(1));
      expect(scale, lessThan(2));
      expect(
        (size.pixels * scale * scale).round(),
        lessThanOrEqualTo(RigDisplaySize.devicePixelBudget),
      );
    });

    test('a gain too small to see is not worth a re-raster', () {
      // Just inside the budget: the guest would repaint everything for a
      // sharpening nobody can point at.
      final size = RigDisplaySize(1200, 1000);
      final affordable = RigDisplaySize.devicePixelBudget / size.pixels;
      expect(affordable, greaterThan(1));
      expect(size.deviceScaleWithin(2), 1);
    });

    test('never upscales past what was asked for', () {
      expect(RigDisplaySize(320, 240).deviceScaleWithin(1.5), 1.5);
      expect(RigDisplaySize(320, 240).deviceScaleWithin(1), 1);
    });
  });
}

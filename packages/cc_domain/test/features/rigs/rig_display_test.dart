import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:test/test.dart';

/// The two-lane display contract.
///
/// A human watching should get a fluid, full-resolution picture; a model
/// should get a small cheap one. The whole point of having two lanes is that
/// neither compromises for the other, so the thing worth pinning is that the
/// agent ceiling never leaks into the watch lane and the watch lane's
/// negotiation never escapes its own ceiling.
void main() {
  group('agent lane', () {
    test('a large desktop is downscaled to the model ceiling', () {
      final huge = RigDisplaySize(2560, 1600);
      final forAgent = huge.fitInside(RigDisplaySize.agentCeiling);
      expect(forAgent.width, lessThanOrEqualTo(1280));
      expect(forAgent.height, lessThanOrEqualTo(800));
    });

    test('aspect ratio survives the downscale', () {
      final wide = RigDisplaySize(3840, 1080);
      final forAgent = wide.fitInside(RigDisplaySize.agentCeiling);
      const before = 3840 / 1080;
      final after = forAgent.width / forAgent.height;
      expect((before - after).abs(), lessThan(0.05));
    });

    test('a small display is never upscaled', () {
      // Enlarging a screenshot adds bytes and zero information.
      final small = RigDisplaySize(800, 600);
      expect(small.fitInside(RigDisplaySize.agentCeiling), small);
    });
  });

  group('watch lane', () {
    test('the human lane is not bound by the agent ceiling', () {
      final request = RigWatchRequest(size: RigDisplaySize(1920, 1200)).clamped();
      expect(
        request.size.width,
        greaterThan(RigDisplaySize.agentCeiling.width),
        reason:
            'If the watch lane were clamped to the model ceiling there would '
            'be no reason to have two lanes.',
      );
    });

    test('a viewer on a huge monitor is still clamped', () {
      final request = RigWatchRequest(size: RigDisplaySize(6016, 3384)).clamped();
      expect(request.size.width, lessThanOrEqualTo(2560));
      expect(request.size.height, lessThanOrEqualTo(1600));
    });

    test('fps and quality are clamped server-side', () {
      final request = RigWatchRequest(
        size: RigDisplaySize(1280, 800),
        fps: 500,
        quality: 900,
      ).clamped();
      expect(request.fps, 60);
      expect(request.quality, 100);
    });

    test('the bitrate ceiling scales with pixels and rate', () {
      final small = RigWatchRequest(size: RigDisplaySize(640, 480), fps: 10);
      final large = RigWatchRequest(size: RigDisplaySize(2560, 1600), fps: 30);
      expect(large.bitrateCeiling, greaterThan(small.bitrateCeiling));
      // Bounded at both ends, so neither a tiny canvas nor a 6K one can ask
      // for an absurd rate.
      expect(small.bitrateCeiling, greaterThanOrEqualTo(250000));
      expect(large.bitrateCeiling, lessThanOrEqualTo(16000000));
    });

    test('malformed query parameters fall back rather than throwing', () {
      // These arrive as URL query strings from a viewer. A bad fps should
      // yield a stream, not a 400.
      final request = RigWatchRequest.fromJson({
        'width': 'wide',
        'height': null,
        'fps': 'fast',
        'codec': 'betamax',
      });
      expect(request.size, RigDisplaySize.defaultDesktop);
      expect(request.fps, 15);
      expect(request.codec, RigStreamCodec.mjpeg);
    });

    test('query parameters as strings are read as numbers', () {
      final request = RigWatchRequest.fromJson({
        'width': '1600',
        'height': '900',
        'fps': '24',
      });
      expect(request.size, RigDisplaySize(1600, 900));
      expect(request.fps, 24);
    });
  });

  group('display size', () {
    test('odd dimensions are rounded down to even', () {
      // Odd dimensions break H.264 chroma subsampling and several guest
      // mode-set paths; failing three layers away in an encoder is a much
      // worse error than rounding here.
      final size = RigDisplaySize(1281, 801);
      expect(size.width.isEven, isTrue);
      expect(size.height.isEven, isTrue);
    });

    test('a non-positive dimension is an error, not a default', () {
      expect(() => RigDisplaySize(0, 100), throwsArgumentError);
      expect(() => RigDisplaySize(100, -1), throwsArgumentError);
    });

    test('codecs carry the content type the relay sets', () {
      // Not `multipart/x-mixed-replace`: no surface has ever emitted a
      // boundary, so declaring one was a header that lied about the body. All
      // three send concatenated JPEGs and the viewer resynchronises on the
      // JPEG markers.
      expect(RigStreamCodec.mjpeg.contentType, 'video/x-motion-jpeg');
      expect(RigStreamCodec.h264.contentType, 'video/h264');
    });

    test('withCodec replaces only the codec', () {
      // The negotiation the viewer cannot influence: it asks for what it can
      // decode, the driver declares what it emits.
      final asked = RigWatchRequest(
        size: RigDisplaySize(800, 600),
        fps: 12,
        quality: 55,
      );
      final settled = asked.withCodec(RigStreamCodec.h264);
      expect(settled.codec, RigStreamCodec.h264);
      expect(settled.size, asked.size);
      expect(settled.fps, 12);
      expect(settled.quality, 55);
    });
  });
}

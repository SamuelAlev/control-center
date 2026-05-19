import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_server_core/src/local_rpc_server.dart';
import 'package:test/test.dart';

void main() {
  group('relay content type', () {
    test('a parameterised type keeps its subtype and its parameter', () {
      // The regression this pins: the relay split on '/' and used the tail as
      // the subtype, so this shipped as
      // `multipart/x-mixed-replace; boundary=ccrigframe` SUBTYPED on
      // "x-mixed-replace; boundary=ccrigframe" — a media type no client knows.
      final parsed = relayContentType(
        'multipart/x-mixed-replace; boundary=ccrigframe',
      );
      expect(parsed.primaryType, 'multipart');
      expect(parsed.subType, 'x-mixed-replace');
      expect(parsed.parameters['boundary'], 'ccrigframe');
    });

    test('every codec the rigs declare survives the round trip', () {
      for (final codec in RigStreamCodec.values) {
        final parsed = relayContentType(codec.contentType);
        expect(
          '${parsed.primaryType}/${parsed.subType}',
          codec.contentType,
          reason: 'The header must say exactly what the lane emits.',
        );
      }
    });

    test('the audio lane type is unchanged', () {
      final parsed = relayContentType('audio/mpeg');
      expect(parsed.mimeType, 'audio/mpeg');
    });

    test('a malformed type degrades to a blob rather than throwing', () {
      // A lane that cannot label itself is still a lane; killing the response
      // over the header would be a worse trade than an honest "unknown".
      expect(relayContentType('nonsense').mimeType, 'application/octet-stream');
    });
  });

  group('RigStreamUnavailable', () {
    test('carries a stable code the viewer can switch on', () {
      // The relay puts this on the wire as `x-rig-stream-error` so the viewer
      // can say "this host needs ffmpeg" instead of "the live view could not
      // be opened", which sends nobody anywhere.
      const error = RigStreamUnavailable(
        code: 'ffmpeg-missing',
        message: 'The mobile live view needs ffmpeg on the host.',
      );
      expect(error.code, 'ffmpeg-missing');
      expect('$error', contains('ffmpeg-missing'));
      expect('$error', contains('needs ffmpeg'));
    });
  });
}

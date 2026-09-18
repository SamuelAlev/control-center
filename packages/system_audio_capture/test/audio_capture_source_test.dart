import 'package:flutter_test/flutter_test.dart';
import 'package:system_audio_capture/system_audio_capture.dart';

void main() {
  test('fromMap maps known kinds and unknown fallback', () {
    expect(
      AudioCaptureSource.fromMap({
        'id': 'system',
        'name': 'Speakers',
        'kind': 'system',
      }).kind,
      AudioCaptureSourceKind.system,
    );
    expect(
      AudioCaptureSource.fromMap({
        'id': 'pid:12',
        'name': 'Slack',
        'kind': 'process',
      }).kind,
      AudioCaptureSourceKind.process,
    );
    expect(
      AudioCaptureSource.fromMap({
        'id': 'mon',
        'name': 'HDMI',
        'kind': 'monitor',
      }).kind,
      AudioCaptureSourceKind.monitor,
    );
    expect(
      AudioCaptureSource.fromMap({
        'id': 'x',
        'name': 'Future',
        'kind': 'loopback-v2',
      }).kind,
      AudioCaptureSourceKind.unknown,
    );
  });
}

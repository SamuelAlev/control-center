// Desktop side of the browser-audio-capture seam (`audio_capture_bindings.dart`).
library;

import 'package:cc_domain/features/meetings/domain/services/meeting_audio_capture_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Throws: the desktop recorder captures the microphone + system loopback
/// audio NATIVELY (`meeting_capture_bindings_io.dart`) and streams it to the
/// host over the recording control port — it never asks for a
/// [MeetingAudioCapturePort] factory (that is the web recorder's
/// browser-audio seam). Kept so the provider resolves on both targets.
MeetingAudioCapturePort Function() buildMeetingAudioCaptureFactory(Ref ref) =>
    () => throw UnsupportedError(
      'Browser audio capture is only available on web — the desktop '
      'captures natively.',
    );

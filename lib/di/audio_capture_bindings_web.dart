// Web side of the browser-audio-capture seam (`audio_capture_bindings.dart`).
library;

import 'package:cc_domain/features/meetings/domain/services/meeting_audio_capture_port.dart';
import 'package:control_center/features/meetings/data/web/web_audio_capture.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Factory for a fresh browser audio capture (one per recording). The web
/// recorder pumps its mic + system frames to the host over the control port.
MeetingAudioCapturePort Function() buildMeetingAudioCaptureFactory(Ref ref) =>
    WebAudioCapture.new;

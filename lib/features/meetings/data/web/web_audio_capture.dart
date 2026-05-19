import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_audio_capture_port.dart';
import 'package:web/web.dart' as web;

/// Captures the browser microphone (`getUserMedia`) and the system / screenshare
/// audio (`getDisplayMedia`) as two 16 kHz mono PCM16 byte streams — the web
/// equivalent of the desktop recorder's mic + system-loopback capture. The
/// recorder controller pumps these frames to the host over `meeting.ingestAudio`.
///
/// A [web.ScriptProcessorNode] does the Float32→PCM16 conversion (and resampling
/// when the browser won't honour a 16 kHz [web.AudioContext]). ScriptProcessor is
/// deprecated in favour of an `AudioWorklet`, but the worklet needs a separate JS
/// module served as an asset; ScriptProcessor keeps v1 self-contained and is
/// universally supported. (AudioWorklet is the documented follow-up.)
class WebAudioCapture implements MeetingAudioCapturePort {
  /// Whisper/transducer input rate the rest of the pipeline expects.
  static const int _targetSampleRate = 16000;

  /// ScriptProcessor buffer size (power of two). 4096 @ 16 kHz ≈ 256 ms/frame.
  static const int _bufferSize = 4096;

  web.AudioContext? _ctx;
  web.MediaStream? _micStream;
  web.MediaStream? _displayStream;
  web.MediaStreamAudioSourceNode? _micSource;
  web.MediaStreamAudioSourceNode? _displaySource;
  web.ScriptProcessorNode? _micProcessor;
  web.ScriptProcessorNode? _displayProcessor;
  web.GainNode? _sink;
  bool _started = false;

  final StreamController<Uint8List> _mic = StreamController<Uint8List>();
  final StreamController<Uint8List> _system = StreamController<Uint8List>();

  /// Microphone ("me") PCM16 frames.
  @override
  Stream<Uint8List> get micStream => _mic.stream;

  /// System / screenshare ("them") PCM16 frames.
  @override
  Stream<Uint8List> get systemStream => _system.stream;

  /// Requests mic + display audio and wires the capture graph. Throws a
  /// [MeetingCaptureException] when the mic is denied, the share is cancelled,
  /// or the share yields no audio track (recording requires system audio).
  @override
  Future<void> start() async {
    if (_started) {
      return;
    }
    final media = web.window.navigator.mediaDevices;

    // Mic ("me"): browser echo-cancellation ON (web has no signal-level AEC3),
    // AGC OFF to match the desktop capture profile.
    final web.MediaStream micStream;
    try {
      micStream = await media
          .getUserMedia(
            web.MediaStreamConstraints(
              audio: web.MediaTrackConstraints(
                echoCancellation: true.toJS,
                noiseSuppression: true.toJS,
                autoGainControl: false.toJS,
              ),
            ),
          )
          .toDart;
    } catch (e) {
      throw MeetingCaptureException('Microphone access was denied ($e).');
    }

    // System ("them"): getDisplayMedia must request video (audio-only display
    // capture is not allowed); audio only arrives when the user picks a tab/
    // screen and enables "share audio". The video track is kept alive (stopping
    // it ends the share) but never consumed.
    final web.MediaStream displayStream;
    try {
      displayStream = await media
          .getDisplayMedia(
            web.DisplayMediaStreamOptions(audio: true.toJS, video: true.toJS),
          )
          .toDart;
    } catch (e) {
      _stopStream(micStream);
      throw MeetingCaptureException('Screen sharing was cancelled ($e).');
    }

    if (displayStream.getAudioTracks().toDart.isEmpty) {
      _stopStream(micStream);
      _stopStream(displayStream);
      throw MeetingCaptureException(
        'No system audio was shared. Recording needs the meeting audio — share '
        'a browser tab (or your whole screen) and enable "Share tab audio" / '
        '"Share system audio" in the picker. Note: Safari and Firefox, and '
        'full-screen sharing on macOS, often cannot share system audio.',
      );
    }

    _micStream = micStream;
    _displayStream = displayStream;

    final ctx = _ctx = web.AudioContext(
      web.AudioContextOptions(sampleRate: _targetSampleRate.toDouble()),
    );
    // A ScriptProcessor only fires while connected through to the destination;
    // route both through a muted gain node so capture never plays back (which
    // would echo the meeting audio out the speakers and feed back into the mic).
    final sink = _sink = ctx.createGain();
    sink.gain.value = 0;
    sink.connect(ctx.destination);

    _micSource = ctx.createMediaStreamSource(micStream);
    _micProcessor = _wireProcessor(ctx, _micSource!, sink, _mic);
    _displaySource = ctx.createMediaStreamSource(displayStream);
    _displayProcessor = _wireProcessor(ctx, _displaySource!, sink, _system);

    _started = true;
  }

  web.ScriptProcessorNode _wireProcessor(
    web.AudioContext ctx,
    web.MediaStreamAudioSourceNode source,
    web.GainNode sink,
    StreamController<Uint8List> out,
  ) {
    // ignore: deprecated_member_use
    final processor = ctx.createScriptProcessor(_bufferSize, 1, 1);
    final ctxRate = ctx.sampleRate.toInt();
    processor.onaudioprocess = ((web.AudioProcessingEvent event) {
      if (out.isClosed) {
        return;
      }
      final input = event.inputBuffer.getChannelData(0).toDart;
      final samples = ctxRate == _targetSampleRate
          ? input
          : _resample(input, ctxRate, _targetSampleRate);
      out.add(_floatToPcm16(samples));
    }).toJS;
    source.connect(processor);
    processor.connect(sink);
    return processor;
  }

  /// Tears down the graph and stops every track. Closes the byte streams.
  @override
  Future<void> stop() async {
    _started = false;
    _micProcessor?.disconnect();
    _displayProcessor?.disconnect();
    _micSource?.disconnect();
    _displaySource?.disconnect();
    _sink?.disconnect();
    _micProcessor = null;
    _displayProcessor = null;
    _micSource = null;
    _displaySource = null;
    _sink = null;

    final ctx = _ctx;
    _ctx = null;
    if (ctx != null) {
      try {
        await ctx.close().toDart;
      } catch (_) {
        // Best-effort: the context may already be closing.
      }
    }

    final mic = _micStream;
    _micStream = null;
    if (mic != null) {
      _stopStream(mic);
    }
    final display = _displayStream;
    _displayStream = null;
    if (display != null) {
      _stopStream(display);
    }

    if (!_mic.isClosed) {
      await _mic.close();
    }
    if (!_system.isClosed) {
      await _system.close();
    }
  }

  static void _stopStream(web.MediaStream stream) {
    final tracks = stream.getTracks().toDart;
    for (final track in tracks) {
      track.stop();
    }
  }

  /// Float32 `[-1, 1]` → little-endian Int16 PCM bytes.
  static Uint8List _floatToPcm16(Float32List samples) {
    final bytes = Uint8List(samples.length * 2);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < samples.length; i++) {
      var s = samples[i];
      if (s > 1.0) {
        s = 1.0;
      } else if (s < -1.0) {
        s = -1.0;
      }
      view.setInt16(i * 2, (s * 32767).round(), Endian.little);
    }
    return bytes;
  }

  /// Linear-interpolation downsample from [fromRate] to [toRate]. Only used when
  /// the browser declines a 16 kHz [web.AudioContext] (most honour it).
  static Float32List _resample(Float32List input, int fromRate, int toRate) {
    if (input.isEmpty || fromRate == toRate) {
      return input;
    }
    final ratio = fromRate / toRate;
    final outLen = (input.length / ratio).floor();
    final out = Float32List(outLen);
    for (var i = 0; i < outLen; i++) {
      final src = i * ratio;
      final i0 = src.floor();
      final i1 = (i0 + 1) < input.length ? i0 + 1 : i0;
      final frac = src - i0;
      out[i] = input[i0] * (1 - frac) + input[i1] * frac;
    }
    return out;
  }
}

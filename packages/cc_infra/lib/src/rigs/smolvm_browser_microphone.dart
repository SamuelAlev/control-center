part of 'rig_service.dart';

/// One persistent host-to-guest PCM lane for a browser rig.
///
/// Starting `smolvm machine exec` per audio chunk drops most of a real-time
/// stream to process startup latency. This object owns one `pacat` child for
/// the active capture session and closes it on replacement, end, or rig
/// teardown.
class _SmolvmBrowserMicrophone {
  _SmolvmBrowserMicrophone({
    required this.binary,
    required this.machineName,
    required this.rigId,
  });

  final String binary;
  final String machineName;
  final String rigId;

  Process? _process;
  String? _sessionId;
  int? _sampleRate;
  int? _channels;

  Future<bool> send(
    Uint8List bytes, {
    required String sessionId,
    required int sampleRate,
    required int channels,
    bool start = false,
    bool end = false,
  }) async {
    if (start) {
      await _closeProcess();
      _sessionId = sessionId;
    }
    if (_sessionId != sessionId) {
      return true;
    }
    if (end) {
      _sessionId = null;
      await _closeProcess();
      return true;
    }
    if (bytes.isEmpty) {
      return true;
    }

    final resolvedRate = sampleRate.clamp(8000, 96000);
    final resolvedChannels = channels.clamp(1, 2);
    if (_process == null ||
        _sampleRate != resolvedRate ||
        _channels != resolvedChannels) {
      await _closeProcess();
      _sampleRate = resolvedRate;
      _channels = resolvedChannels;
      _process = await Process.start(binary, [
        'machine',
        'exec',
        '--name',
        machineName,
        '-i',
        '--',
        'env',
        'PULSE_SERVER=unix:/tmp/cc-pulse/native',
        'PULSE_SINK=ccmic',
        'pacat',
        '--playback',
        '--device=ccmic',
        '--format=s16le',
        '--rate=$resolvedRate',
        '--channels=$resolvedChannels',
        '--latency-msec=50',
      ]);
      unawaited(_process!.stdout.drain<void>());
      unawaited(
        _process!.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach(
              (line) =>
                  CcInfraLog.debug('rig/$rigId browser microphone: $line'),
            ),
      );
    }

    try {
      _process!.stdin.add(bytes);
      await _process!.stdin.flush();
      return true;
    } on Object catch (error) {
      CcInfraLog.warning('rig/$rigId browser microphone failed: $error');
      await _closeProcess();
      return false;
    }
  }

  Future<void> close() async {
    _sessionId = null;
    await _closeProcess();
  }

  Future<void> _closeProcess() async {
    final process = _process;
    _process = null;
    _sampleRate = null;
    _channels = null;
    if (process == null) {
      return;
    }
    try {
      await process.stdin.close();
    } on Object {
      // A guest-side failure may already have closed the pipe.
    }
    try {
      await process.exitCode.timeout(const Duration(seconds: 1));
    } on Object {
      process.kill();
    }
  }
}

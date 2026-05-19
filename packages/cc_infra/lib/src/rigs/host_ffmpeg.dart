import 'dart:async';
import 'dart:io';

/// A running child process, narrowed to what a rig lane needs of it.
///
/// The narrowing is what makes the transcoder testable: a fake can be twenty
/// lines, where faking `dart:io`'s `Process` means faking everything a
/// hypervisor's process would ever expose.
abstract interface class HostProcess {
  /// The child's stdin.
  ///
  /// Typed as the narrow [StreamSink] half of `IOSink` deliberately: feeding
  /// and closing is all a lane does with it, and a fake that has to implement
  /// `IOSink` in full is a fake nobody writes.
  StreamSink<List<int>> get stdin;

  /// The child's stdout.
  Stream<List<int>> get stdout;

  /// The child's stderr.
  Stream<List<int>> get stderr;

  /// Completes with the child's exit code.
  Future<int> get exitCode;

  /// Signals the child. Idempotent: killing an already-dead child is a no-op.
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);
}

/// Starts a child process. The seam every rig-side spawn goes through.
typedef HostProcessSpawn =
    Future<HostProcess> Function(String executable, List<String> args);

/// The real spawn: `Process.start`, wrapped in [HostProcess].
Future<HostProcess> spawnHostProcess(
  String executable,
  List<String> args,
) async => _RealHostProcess(await Process.start(executable, args));

class _RealHostProcess implements HostProcess {
  _RealHostProcess(this._process);

  final Process _process;

  @override
  StreamSink<List<int>> get stdin => _process.stdin;

  @override
  Stream<List<int>> get stdout => _process.stdout;

  @override
  Stream<List<int>> get stderr => _process.stderr;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      _process.kill(signal);
}

/// The host's `ffmpeg`, located once and reused.
///
/// Two rig lanes need it and neither can fake it: Android emits H.264 from
/// `screenrecord` while the viewer decodes JPEG, and a phone screenshot is a
/// full-resolution PNG where the agent lane wants a downscaled JPEG. Both are
/// transcodes, and a transcode belongs in a CHILD PROCESS — decoding video on
/// the server's isolate is exactly the work that leaves `cc_server` unable to
/// answer an RPC while somebody watches a machine.
///
/// Absence is reported, never worked around. A silent fallback here would be a
/// viewer that connects and shows nothing, which is indistinguishable from a
/// broken rig.
class HostFfmpeg {
  /// Creates a [HostFfmpeg] over an already-resolved binary.
  const HostFfmpeg({
    required this.path,
    HostProcessSpawn spawn = spawnHostProcess,
  }) : _spawn = spawn;

  /// Absolute path to the `ffmpeg` binary.
  final String path;

  final HostProcessSpawn _spawn;

  /// Starts `ffmpeg` with [args].
  Future<HostProcess> start(List<String> args) => _spawn(path, args);

  /// The process-wide cached probe. `null` means "not looked yet"; a resolved
  /// entry holding `null` means "looked, and it is not installed".
  static Future<HostFfmpeg?>? _located;

  /// Locates `ffmpeg` on `PATH`, or null when it is not installed.
  ///
  /// Probed ONCE per process and cached, including the negative: this sits on
  /// the path of every screenshot, and a `which` per frame is a process spawn
  /// per frame. ffmpeg does not get installed halfway through a session.
  static Future<HostFfmpeg?> locate() => _located ??= _locate();

  static Future<HostFfmpeg?> _locate() async {
    try {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
        'ffmpeg',
      ]);
      if (result.exitCode == 0) {
        final found = '${result.stdout}'.split('\n').first.trim();
        if (found.isNotEmpty) {
          return HostFfmpeg(path: found);
        }
      }
    } on Object {
      // No `which`/`where` on this host, or it could not be run: the same
      // answer as "not installed", and the caller says so out loud.
    }
    return null;
  }

  /// Forgets the cached probe. Tests only — a real host does not gain an
  /// ffmpeg mid-session.
  static void debugResetProbe() => _located = null;
}

/// Resolves the host's ffmpeg. Injectable so a driver can be exercised — and
/// its missing-ffmpeg branch pinned — without one installed.
typedef FfmpegResolver = Future<HostFfmpeg?> Function();

/// Maps a 1–100 JPEG quality onto ffmpeg's mjpeg `-q:v` scale (2 best, 31
/// worst).
///
/// The same expression the in-guest agent uses (`build_image.sh`), so
/// `quality=70` means the same thing on a phone as it does on a desktop rather
/// than being two unrelated dials that happen to share a name.
int mjpegQualityFlag(int quality) {
  final q = quality.clamp(1, 100);
  final scaled = 31 - (q * 30 ~/ 100);
  return scaled < 2 ? 2 : scaled;
}

/// The scale filter that fits a frame inside [width]x[height] without ever
/// enlarging it, on even dimensions.
///
/// `min(iw, w)` rather than a bare `w` because upscaling adds bytes and zero
/// information; `force_divisible_by=2` because MJPEG is 4:2:0 and an odd
/// dimension makes the encoder refuse the frame three layers away from
/// anything that could explain it.
String ffmpegFitFilter(int width, int height) {
  // `\,` escapes the comma for ffmpeg's OWN filtergraph parser, where a bare
  // comma separates filters. The argv reaches ffmpeg without a shell, so the
  // backslash has to survive into the argument itself.
  const esc = r'\,';
  return 'scale=min(iw$esc$width):min(ih$esc$height)'
      ':force_original_aspect_ratio=decrease:force_divisible_by=2';
}

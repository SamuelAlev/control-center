// Live frame viewer for a rig's watch lane.
//
// The server relays an open-ended `video/x-motion-jpeg` body; this widget owns
// the HTTP lifecycle and paints whatever [MjpegFrameReader] resynchronises out
// of it. The decode happens HERE and not on the server: a video decoder on the
// request path is exactly the CPU work that would leave `cc_server` unable to
// answer an RPC while somebody watches a VM.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/mjpeg_frame_reader.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

/// Renders the live JPEG stream at [url], reconnecting when it drops.
///
/// [url] carries the negotiated size in its query, so changing it is how a
/// resize is applied: the widget notices the new URL, tears the old stream
/// down and opens the new one.
class MjpegView extends StatefulWidget {
  /// Creates an [MjpegView].
  const MjpegView({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.paused = false,
  });

  /// The signed `/rig/stream/<id>` URL.
  final String url;

  /// When true the stream is closed and the last frame is held on screen.
  ///
  /// A rig tab sitting behind another tab must not keep the guest encoding
  /// and the link carrying frames nobody is looking at — that is real CPU in
  /// the VM and real bandwidth for a picture on no screen.
  final bool paused;

  /// How to fit frames into the widget's box.
  final BoxFit fit;

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  /// The ceiling on repaints. The server already adapts fps and quality under
  /// a bitrate budget; this is the client's own guard against decoding more
  /// pictures than a display can show. Frames that arrive inside the window
  /// are not queued — the newest one simply wins, which is what "live" means.
  static const Duration _minFrameGap = Duration(milliseconds: 33); // ~30fps

  /// After this many consecutive failures the viewer SAYS the lane ended —
  /// but it keeps trying, slowly. Giving up permanently meant a `cc_server`
  /// restart left "The live view ended" on screen until the tab was recreated.
  static const int _quietAfterAttempts = 6;
  static const Duration _maxBackoff = Duration(seconds: 15);

  final MjpegFrameReader _reader = MjpegFrameReader();

  http.Client? _client;
  StreamSubscription<List<int>>? _sub;
  Timer? _retry;
  Uint8List? _frame;
  Uint8List? _pendingFrame;
  Timer? _paint;
  DateTime? _lastPaint;
  String? _error;
  bool _connecting = true;
  int _reconnects = 0;

  /// Bumped on every connect/disconnect so a stream this widget has moved on
  /// from cannot tear down the one that replaced it.
  ///
  /// `_disconnect()` awaits a cancel, and `didUpdateWidget` starts the next
  /// connect immediately after — so without a generation the old teardown
  /// resumed AFTER the new client was assigned and closed it. Every
  /// renegotiated resize could kill its own fresh stream.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.paused) {
      unawaited(_connect());
    }
  }

  @override
  void didUpdateWidget(MjpegView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused != oldWidget.paused) {
      if (widget.paused) {
        // Keep `_frame` so the tab still shows its last picture rather than a
        // spinner when it comes back.
        unawaited(_restart(connect: false));
        return;
      }
      unawaited(_restart());
      return;
    }
    if (widget.paused) {
      return;
    }
    if (oldWidget.url != widget.url) {
      // A renegotiated size (or a different rig) means a different stream.
      // Keep the last frame on screen through the swap so a resize does not
      // flash an empty canvas.
      unawaited(_restart());
    }
  }

  @override
  void dispose() {
    _generation++;
    _retry?.cancel();
    _paint?.cancel();
    unawaited(_sub?.cancel());
    _client?.close();
    _sub = null;
    _client = null;
    super.dispose();
  }

  /// Tears the current stream down and (optionally) opens the next one.
  ///
  /// One entry point so the generation is bumped exactly once per swap.
  Future<void> _restart({bool connect = true}) async {
    _retry?.cancel();
    _retry = null;
    final generation = ++_generation;
    final sub = _sub;
    final client = _client;
    _sub = null;
    _client = null;
    _reader.reset();
    await sub?.cancel();
    client?.close();
    if (!connect || !mounted || generation != _generation) {
      return;
    }
    _reconnects = 0;
    await _connect();
  }

  Future<void> _connect() async {
    if (!mounted) {
      return;
    }
    final generation = _generation;
    setState(() {
      _connecting = true;
      _error = null;
    });
    final client = http.Client();
    _client = client;
    try {
      final request = http.Request('GET', Uri.parse(widget.url))
        ..headers['Accept'] = 'video/x-motion-jpeg';
      final response = await client.send(request);
      if (generation != _generation) {
        client.close();
        return;
      }
      if (response.statusCode != 200) {
        // Close it HERE. Leaving it assigned to `_client` kept one live HTTP
        // client per failed attempt open until the widget was disposed.
        client.close();
        if (identical(_client, client)) {
          _client = null;
        }
        if (mounted) {
          setState(() {
            _connecting = false;
            _error = _errorFor(response);
          });
        }
        // A 403/404 is a verdict about THIS rig, not a transient failure:
        // retrying it forever would be a request per backoff for a machine
        // that is gone or was never ours.
        if (response.statusCode != 403 && response.statusCode != 404) {
          _scheduleReconnect();
        }
        return;
      }
      if (mounted) {
        setState(() {
          _connecting = false;
          _error = null;
          _reconnects = 0;
        });
      }
      _sub = response.stream.listen(
        (chunk) {
          if (generation != _generation) {
            return;
          }
          final frame = _reader.add(chunk);
          if (frame != null) {
            _offerFrame(frame);
          }
        },
        onDone: () {
          if (generation == _generation) {
            _scheduleReconnect();
          }
        },
        onError: (Object e) {
          if (generation != _generation) {
            return;
          }
          if (mounted) {
            setState(() => _error = '$e');
          }
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } on Object catch (e) {
      client.close();
      if (identical(_client, client)) {
        _client = null;
      }
      if (generation != _generation) {
        return;
      }
      if (mounted) {
        setState(() {
          _connecting = false;
          _error = '$e';
        });
      }
      _scheduleReconnect();
    }
  }

  static String _errorFor(http.StreamedResponse response) =>
      switch (response.statusCode) {
        403 => 'notAllowed',
        404 => 'notRunning',
        // The rig is alive and this HOST cannot serve its lane. The reason
        // code says which missing piece, because "the live view could not be
        // opened" sends nobody anywhere.
        503 =>
          response.headers['x-rig-stream-error'] == 'ffmpeg-missing'
              ? 'needsFfmpeg'
              : 'unavailable',
        _ => 'http:${response.statusCode}',
      };

  /// Paints [frame] now, or holds it as the next one when a repaint would
  /// arrive inside [_minFrameGap].
  void _offerFrame(Uint8List frame) {
    if (!mounted) {
      return;
    }
    final now = DateTime.now();
    final last = _lastPaint;
    if (last != null && now.difference(last) < _minFrameGap) {
      _pendingFrame = frame;
      _paint ??= Timer(_minFrameGap - now.difference(last), _paintPending);
      return;
    }
    _lastPaint = now;
    setState(() => _frame = frame);
  }

  void _paintPending() {
    _paint = null;
    final pending = _pendingFrame;
    _pendingFrame = null;
    if (pending == null || !mounted) {
      return;
    }
    _lastPaint = DateTime.now();
    setState(() => _frame = pending);
  }

  void _scheduleReconnect() {
    if (!mounted || widget.paused) {
      return;
    }
    _reconnects++;
    if (_reconnects == _quietAfterAttempts) {
      // Say so, then keep trying at the capped interval. A server restart or a
      // network blip is exactly the case where the viewer must heal itself.
      setState(() => _error = 'ended');
    }
    final shift = _reconnects - 1;
    final ms = shift >= 12 ? _maxBackoff.inMilliseconds : 250 * (1 << shift);
    final delay = Duration(
      milliseconds: ms.clamp(250, _maxBackoff.inMilliseconds),
    );
    final generation = _generation;
    _retry?.cancel();
    _retry = Timer(delay, () async {
      _retry = null;
      if (!mounted || widget.paused || generation != _generation) {
        return;
      }
      // Release the dead client before opening another, or each retry leaks
      // the previous HTTP client and its subscription.
      final sub = _sub;
      final client = _client;
      _sub = null;
      _client = null;
      _reader.reset();
      await sub?.cancel();
      client?.close();
      if (mounted && generation == _generation) {
        await _connect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final frame = _frame;

    if (frame != null) {
      // Decode capped at the LAID-OUT size, not the capture resolution. The
      // guest streams at up to 1920x1080 at 30 fps into a panel that is often
      // 300–800 logical pixels wide; without a cap, every frame decoded (and
      // allocated a texture) at full source size. Each frame is a fresh
      // `MemoryImage` key, so this is per-frame cost, not a one-off.
      return LayoutBuilder(
        builder: (context, constraints) {
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final targetWidth = constraints.maxWidth.isFinite
              ? (constraints.maxWidth * dpr).round()
              : null;
          return Image.memory(
            frame,
            fit: widget.fit,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            cacheWidth: targetWidth != null && targetWidth > 0
                ? targetWidth
                : null,
            errorBuilder: (context, _, _) => const SizedBox.shrink(),
          );
        },
      );
    }
    if (_connecting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CcSpinner(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.rigConnectingStream,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          switch (_error) {
            'notAllowed' => l10n.rigStreamNotAllowed,
            'notRunning' => l10n.rigStreamNotRunning,
            'needsFfmpeg' => l10n.rigStreamNeedsFfmpeg,
            'ended' => l10n.rigStreamEnded,
            _ => l10n.rigStreamFailed,
          },
          textAlign: TextAlign.center,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      ),
    );
  }
}

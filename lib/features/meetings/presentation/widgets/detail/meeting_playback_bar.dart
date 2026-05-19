import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Audio playback for a recorded meeting: a play/pause control, a clickable
/// waveform scrubber, and elapsed / total time. Shown only when the meeting
/// retained audio (`audioPath`). The host assembles + serves the mixed track;
/// this widget fetches the waveform/duration over RPC ([meetingAudioClipProvider])
/// and streams the bytes from the server's `/meeting/audio` URL — so playback is
/// identical on web and desktop, local or remote. Renders nothing while loading
/// or when there is no usable audio.
class MeetingPlaybackBar extends ConsumerWidget {
  /// Creates a [MeetingPlaybackBar] for meeting [meetingId] in [workspaceId].
  const MeetingPlaybackBar({
    super.key,
    required this.workspaceId,
    required this.meetingId,
    required this.audioPath,
    required this.status,
  });

  /// The owning workspace — used to sign the server audio URL.
  final String workspaceId;

  /// The meeting whose audio is played back.
  final String meetingId;

  /// The meeting's `audioPath` (set once audio was retained), or null. Only used
  /// as the gate for whether any audio exists to play.
  final String? audioPath;

  /// The meeting's lifecycle status. Part of the clip provider key so the audio
  /// is (re)fetched once the meeting finalizes — the WAVs are only complete after
  /// the summary pipeline runs. See [MeetingAudioRef].
  final MeetingStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (audioPath == null || audioPath!.isEmpty) {
      return const SizedBox.shrink();
    }
    // The byte source: the host's `/meeting/audio` URL, built from the live
    // connection. Null when there is no proxy scope (no live connection) — then
    // there is nothing to play.
    final url = MediaProxyScope.meetingAudioUrlOf(
      context,
      workspaceId: workspaceId,
      meetingId: meetingId,
    );
    if (url == null) {
      return const SizedBox.shrink();
    }
    final clip = ref.watch(
      meetingAudioClipProvider((
        workspaceId: workspaceId,
        meetingId: meetingId,
        status: status,
      )),
    );
    return clip.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) => data == null
          ? const SizedBox.shrink()
          // Key on the source URL so the player rebuilds cleanly when switching
          // meetings, while a status-only reload of the same meeting preserves
          // playback state.
          : _Player(key: ValueKey(url), info: data, url: url),
    );
  }
}

class _Player extends ConsumerStatefulWidget {
  const _Player({super.key, required this.info, required this.url});

  /// Waveform + duration for the scrubber.
  final MeetingAudioInfo info;

  /// The host `/meeting/audio` URL the player streams from.
  final String url;

  @override
  ConsumerState<_Player> createState() => _PlayerState();
}

class _PlayerState extends ConsumerState<_Player> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<void>> _subs = [];

  /// The player's `seek` tear-off, captured ONCE so the exact same closure
  /// instance is handed to both [MeetingPlaybackController.attach] and `detach`.
  /// Two tear-offs of the same instance method are `==` but never `identical`,
  /// and the controller's handoff guard compares with `identical` — so passing a
  /// fresh `_player.seek` to `detach` would never match, and the shared store
  /// would never reset on teardown.
  late final Future<void> Function(Duration position) _seekHandler =
      _player.seek;

  /// Set in [dispose] so a late-resolving [_init] (navigated away while the clip
  /// was still loading) and a tap that lands mid-teardown cannot re-arm playback
  /// on a player that is already being torn down.
  bool _disposed = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _ready = false;

  /// Shared playback store the transcript watches (#8). Captured once in
  /// [initState] rather than read on demand: `dispose()` calls
  /// [MeetingPlaybackController.detach], and touching `ref` from `dispose()`
  /// throws ("Using ref when a widget ... has been unmounted is unsafe"). The
  /// notifier instance is stable (a plain, non-autoDispose provider), so the
  /// captured reference stays valid through teardown.
  late final MeetingPlaybackController _playback;

  @override
  void initState() {
    super.initState();
    _playback = ref.read(meetingPlaybackProvider.notifier);
    _init();
  }

  Future<void> _init() async {
    _duration = Duration(milliseconds: widget.info.durationMs);
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      // Stream from the host over HTTP (works on web + desktop, local + remote).
      await _player.setSourceUrl(widget.url);
      // Bail if the widget was torn down while the clip was loading: the player
      // is already (being) disposed, so wiring listeners, attaching the seek
      // handler, or reporting readiness would re-arm dead state.
      if (_disposed || !mounted) {
        return;
      }
      _subs.add(_player.onPositionChanged.listen((pos) {
        if (mounted) {
          setState(() => _position = pos);
          _playback.report(positionMs: pos.inMilliseconds);
        }
      }));
      _subs.add(_player.onDurationChanged.listen((dur) {
        if (mounted && dur > Duration.zero) {
          setState(() => _duration = dur);
          _playback.report(durationMs: dur.inMilliseconds);
        }
      }));
      _subs.add(_player.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() => _playing = state == PlayerState.playing);
          _playback.report(playing: state == PlayerState.playing);
        }
      }));
      _subs.add(_player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
          _playback.report(playing: false, positionMs: 0);
        }
      }));
      // Expose the seek handler + initial readiness so the transcript can drive
      // the playhead (tap a line → seek) and highlight the playing line.
      _playback
        ..attach(_seekHandler)
        ..report(ready: true, durationMs: _duration.inMilliseconds);
      if (mounted) {
        setState(() => _ready = true);
      }
    } on Object {
      // Audio backend unavailable (e.g. headless / missing codec): leave the
      // bar disabled rather than crashing the detail screen.
      if (mounted) {
        setState(() => _ready = false);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    // Reset the shared store + drop the seek handler. Passing the SAME captured
    // tear-off makes the controller's `identical` handoff guard match.
    _playback.detach(_seekHandler);
    for (final s in _subs) {
      s.cancel();
    }
    // Stop native audio reliably. `State.dispose()` cannot be async, so we can't
    // await here; instead we capture the player and drive stop → dispose to
    // completion in a detached closure. `stop()` is issued FIRST — its native
    // AVPlayer pause halts sound immediately and is idempotent — rather than
    // relying on `AudioPlayer.dispose()` alone, whose internal stop is gated
    // behind a re-checked `desiredState` that a racing resume could skip. The
    // closure keeps `player` reachable until the chain settles, so it is not
    // garbage-collected before the native pause lands; errors are swallowed
    // because the player may already be tearing down.
    final player = _player;
    unawaited(() async {
      try {
        await player.stop();
      } catch (_) {
        // Already stopped or disposed — nothing to do.
      }
      try {
        await player.dispose();
      } catch (_) {
        // Already disposed — nothing to do.
      }
    }());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_ready || _disposed) {
      return;
    }
    if (_playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> _seekToFraction(double fraction) async {
    if (!_ready || _duration == Duration.zero) {
      return;
    }
    final clamped = fraction.clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * clamped).round(),
    );
    setState(() => _position = target);
    _playback.report(positionMs: target.inMilliseconds);
    await _player.seek(target);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final total = _duration.inMilliseconds == 0
        ? Duration(milliseconds: widget.info.durationMs)
        : _duration;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ds.surface,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: ds.borderSecondary),
      ),
      child: Row(
        children: [
          _PlayButton(playing: _playing, enabled: _ready, onPressed: _toggle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: 40,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _seekToFraction(
                      d.localPosition.dx / constraints.maxWidth,
                    ),
                    onHorizontalDragUpdate: (d) => _seekToFraction(
                      d.localPosition.dx / constraints.maxWidth,
                    ),
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 40),
                      painter: _WaveformPainter(
                        buckets: widget.info.waveform,
                        progress: progress,
                        playedColor: ds.accent,
                        remainingColor: ds.muted.withValues(alpha: 0.35),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${MeetingFormat.clock(_position)} / ${MeetingFormat.clock(total)}',
            style: meetingMono(context, fontSize: 12),
          ),
          if (!_ready) ...[
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: l10n.meetingPlaybackUnavailable,
              child: Icon(AppIcons.triangleAlert, size: 14, color: ds.warn),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.enabled,
    required this.onPressed,
  });

  final bool playing;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: playing ? l10n.meetingPlaybackPause : l10n.meetingPlaybackPlay,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: enabled ? ds.accent : ds.hoverStrong,
            shape: BoxShape.circle,
          ),
          child: Icon(
            playing ? AppIcons.pause : AppIcons.play,
            size: 16,
            color: enabled ? ds.surface : ds.muted,
          ),
        ),
      ),
    );
  }
}

/// Paints the waveform as centered vertical bars, coloring the played portion
/// with [playedColor] and the rest with [remainingColor].
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.buckets,
    required this.progress,
    required this.playedColor,
    required this.remainingColor,
  });

  final List<double> buckets;
  final double progress;
  final Color playedColor;
  final Color remainingColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) {
      return;
    }
    final mid = size.height / 2;
    // Fit as many bars as the width allows, never more than we have buckets.
    const barWidth = 2.0;
    const gap = 1.0;
    const slot = barWidth + gap;
    final barCount = (size.width / slot).floor().clamp(1, buckets.length);
    final playedBars = (barCount * progress).round();
    final played = Paint()..color = playedColor;
    final remaining = Paint()..color = remainingColor;

    for (var i = 0; i < barCount; i++) {
      // Sample the buckets evenly when there are more buckets than bars.
      final bucketIdx = ((i / barCount) * buckets.length).floor();
      final amp = buckets[bucketIdx.clamp(0, buckets.length - 1)];
      final half = (amp * (size.height / 2)).clamp(1.0, size.height / 2);
      final x = i * slot;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x, mid - half, x + barWidth, mid + half),
        const Radius.circular(1),
      );
      canvas.drawRRect(rect, i < playedBars ? played : remaining);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.buckets != buckets ||
      old.playedColor != playedColor ||
      old.remainingColor != remainingColor;
}

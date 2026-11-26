import 'dart:async';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

/// Audio playback for a recorded meeting: a play/pause control, a clickable
/// waveform scrubber and elapsed / total time. Shown only when the meeting
/// retained audio (`audioPath`). The host assembles + serves the mixed track;
/// this widget fetches the waveform/duration over RPC ([meetingAudioClipProvider])
/// and streams the bytes from the server's `/meeting/audio` URL — so playback is
/// identical on web and desktop, local or remote. While the clip loads it holds
/// an empty frame of the bar's own height, so the page below does not jump when
/// the waveform arrives; it renders nothing when there is no usable audio.
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
    // there is nothing to play; nor is there without libmpv (stock Linux).
    final url = MediaProxyScope.meetingAudioUrlOf(
      context,
      workspaceId: workspaceId,
      meetingId: meetingId,
    );
    if (url == null || !ref.watch(mediaPlaybackAvailableProvider)) {
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
      loading: () => const _PlaybackFrame(child: SizedBox.expand()),
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
  final Player _player = Player();
  final List<StreamSubscription<void>> _subs = [];

  /// The player's `seek` tear-off, captured ONCE so the exact same closure
  /// instance is handed to both [MeetingPlaybackController.attach] and `detach`.
  /// Two tear-offs of the same instance method are `==` but never `identical`,
  /// and the controller's handoff guard compares with `identical` — so passing a
  /// fresh `_player.seek` to `detach` would never match and the shared store
  /// would never reset on teardown.
  late final Future<void> Function(Duration position) _seekHandler =
      _player.seek;

  /// Set in [dispose] so a late-resolving [_init] (navigated away while the clip
  /// was still loading) and a tap that lands mid-teardown cannot re-arm playback
  /// on a player that is already being torn down.
  bool _disposed = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final FocusNode _seekFocus = FocusNode(debugLabel: 'meeting-seek-bar');
  bool _playing = false;
  bool _ready = false;

  /// The player could not open the clip. Distinct from "not ready yet": only a
  /// failure earns the warning glyph.
  bool _failed = false;

  /// Shared playback store the transcript watches (#8). Captured once in
  /// [initState] rather than read on demand: `dispose()` calls
  /// [MeetingPlaybackController.detach] and touching `ref` from `dispose()`
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
      // Route through the app-wide output device before the clip loads, so
      // playback starts on the chosen hardware rather than switching to it a
      // beat later. Read (not watched): a device change mid-clip is rare and
      // re-routing under a playing stream restarts it.
      await applyAppAudioOutput(_player, ref.read(audioOutputDeviceProvider));
      if (_disposed || !mounted) {
        return;
      }
      // Load without playing; stream from the host over HTTP (works on web +
      // desktop, local + remote). Default playlist mode is none — no looping.
      await _player.open(Media(widget.url), play: false);
      // Bail if the widget was torn down while the clip was loading: the player
      // is already (being) disposed, so wiring listeners, attaching the seek
      // handler, or reporting readiness would re-arm dead state.
      if (_disposed || !mounted) {
        return;
      }
      _subs.add(
        _player.stream.position.listen((pos) {
          if (mounted) {
            setState(() => _position = pos);
            _playback.report(positionMs: pos.inMilliseconds);
          }
        }),
      );
      _subs.add(
        _player.stream.duration.listen((dur) {
          if (mounted && dur > Duration.zero) {
            setState(() => _duration = dur);
            _playback.report(durationMs: dur.inMilliseconds);
          }
        }),
      );
      _subs.add(
        _player.stream.playing.listen((playing) {
          if (mounted) {
            setState(() => _playing = playing);
            _playback.report(playing: playing);
          }
        }),
      );
      _subs.add(
        _player.stream.completed.listen((completed) {
          if (mounted && completed) {
            setState(() {
              _playing = false;
              _position = Duration.zero;
            });
            _playback.report(playing: false, positionMs: 0);
          }
        }),
      );
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
        setState(() {
          _ready = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _seekFocus.dispose();
    // Reset the shared store + drop the seek handler. Passing the SAME captured
    // tear-off makes the controller's `identical` handoff guard match.
    _playback.detach(_seekHandler);
    for (final s in _subs) {
      s.cancel();
    }
    // Stop native audio reliably. `State.dispose()` cannot be async, so we can't
    // await here; instead we capture the player and drive stop → dispose to
    // completion in a detached closure. The explicit stop is issued FIRST —
    // libmpv halts output immediately — rather than relying on dispose alone.
    // The closure keeps `player` reachable until the chain settles; errors are
    // swallowed because the player may already be tearing down.
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
      await _player.play();
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
    // A seek, not a tick: the transcript must not scroll the page to the line
    // this lands on.
    _playback.reportSeek(target.inMilliseconds);
    await _player.seek(target);
  }

  Duration _shifted(Duration delta) {
    final ms = (_position + delta).inMilliseconds;
    return Duration(milliseconds: ms.clamp(0, _duration.inMilliseconds));
  }

  void _seekBy(Duration delta) {
    if (_duration != Duration.zero) {
      unawaited(
        _seekToFraction(
          _shifted(delta).inMilliseconds / _duration.inMilliseconds,
        ),
      );
    }
  }

  /// ←/→ seek 5 s (Shift: 15 s), Home/End jump to either end. The waveform is
  /// drawn left to right in every locale, so the arrows stay physical.
  KeyEventResult _onSeekKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final step = Duration(
      seconds: HardwareKeyboard.instance.isShiftPressed ? 15 : 5,
    );
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _seekBy(-step);
      case LogicalKeyboardKey.arrowRight:
        _seekBy(step);
      case LogicalKeyboardKey.home:
        unawaited(_seekToFraction(0));
      case LogicalKeyboardKey.end:
        unawaited(_seekToFraction(1));
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
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

    return _PlaybackFrame(
      child: Row(
        children: [
          _PlayButton(playing: _playing, enabled: _ready, onPressed: _toggle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: 40,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const nudge = Duration(seconds: 5);
                  final seekable = _ready && _duration != Duration.zero;
                  final bar = GestureDetector(
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
                  // Flutter asserts an increase/decrease action carries both
                  // the value and the matching increased/decreased reading.
                  return Semantics(
                    slider: true,
                    label: l10n.playbackPosition,
                    value: MeetingFormat.clock(_position),
                    increasedValue: seekable
                        ? MeetingFormat.clock(_shifted(nudge))
                        : null,
                    decreasedValue: seekable
                        ? MeetingFormat.clock(_shifted(-nudge))
                        : null,
                    onIncrease: seekable ? () => _seekBy(nudge) : null,
                    onDecrease: seekable ? () => _seekBy(-nudge) : null,
                    child: Focus(
                      focusNode: _seekFocus,
                      onKeyEvent: _onSeekKey,
                      child: FocusRing(
                        focusNode: _seekFocus,
                        borderRadius: AppRadii.brSm,
                        child: bar,
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
            style: meetingMeta(context, fontSize: 12),
          ),
          if (_failed) ...[
            const SizedBox(width: AppSpacing.sm),
            CcTooltip(
              message: l10n.meetingPlaybackUnavailable,
              child: Icon(AppIcons.triangleAlert, size: 14, color: ds.warn),
            ),
          ],
        ],
      ),
    );
  }
}

/// The bar's surface at its fixed height, shared by the player and by the
/// placeholder shown while the clip loads.
class _PlaybackFrame extends StatelessWidget {
  const _PlaybackFrame({required this.child});

  final Widget child;

  /// Height of the content row: the waveform's.
  static const double contentHeight = 40;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
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
      child: SizedBox(height: contentHeight, child: child),
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
    return CcTooltip(
      message: playing ? l10n.meetingPlaybackPause : l10n.meetingPlaybackPlay,
      child: CcTappable(
        onPressed: enabled ? onPressed : null,
        semanticLabel: playing
            ? l10n.meetingPlaybackPause
            : l10n.meetingPlaybackPlay,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        builder: (context, states) => Container(
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

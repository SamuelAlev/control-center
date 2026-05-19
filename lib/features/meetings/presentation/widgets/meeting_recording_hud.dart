import 'dart:async';

import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/live_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A floating, draggable recording HUD that persists across the app while a
/// meeting is being recorded and you've navigated away from the record screen
/// — echoing the focus-mode floating toolbar. Mounted once at the shell level.
///
/// Returns an empty box (and so is invisible / non-interactive) unless a
/// recording is in progress and the current route is not the record screen.
class MeetingRecordingHud extends ConsumerStatefulWidget {
  /// Creates a [MeetingRecordingHud].
  const MeetingRecordingHud({super.key});

  @override
  ConsumerState<MeetingRecordingHud> createState() =>
      _MeetingRecordingHudState();
}

class _MeetingRecordingHudState extends ConsumerState<MeetingRecordingHud> {
  Offset? _offset;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _stop(String meetingId) {
    unawaited(ref.read(meetingRecorderControllerProvider.notifier).stop());
    context.go(meetingDetailRoute(meetingId));
  }

  @override
  Widget build(BuildContext context) {
    final recorder = ref.watch(meetingRecorderControllerProvider);
    final location = GoRouterState.of(context).matchedLocation;

    final hidden = !recorder.isRecording ||
        recorder.meetingId == null ||
        location == meetingsRecordRoute;
    if (hidden) {
      return const SizedBox.shrink();
    }

    final meetingId = recorder.meetingId!;
    const hudWidth = 290.0;
    const hudHeight = 52.0;
    final media = MediaQuery.of(context).size;
    final offset = _offset ??
        Offset(media.width - hudWidth - 24, media.height - hudHeight - 24);

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final next = offset + details.delta;
          setState(() {
            _offset = Offset(
              next.dx.clamp(8.0, media.width - hudWidth - 8),
              next.dy.clamp(8.0, media.height - hudHeight - 8),
            );
          });
        },
        child: _HudBody(
          recorder: recorder,
          onOpen: () => context.go(meetingsRecordRoute),
          onStop: () => _stop(meetingId),
        ),
      ),
    );
  }
}

class _HudBody extends StatelessWidget {
  const _HudBody({
    required this.recorder,
    required this.onOpen,
    required this.onStop,
  });

  final MeetingRecorderState recorder;
  final VoidCallback onOpen;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    // The HUD is a high-contrast floating chip: an ink surface with near-white
    // content, independent of the page theme.
    final ink = ds.fg;
    final onInk = ds.canvas;
    final paused = recorder.paused;
    final elapsed = recorder.elapsedAt(DateTime.now());

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 52,
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
          decoration: BoxDecoration(
            color: ink,
            borderRadius: AppRadii.brMd,
            boxShadow: AppShadows.golden,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              paused
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: onInk.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    )
                  : LiveDot(color: ds.danger, size: 9),
              const SizedBox(width: 10),
              Text(
                MeetingFormat.clock(elapsed),
                style: meetingMono(context, fontSize: 14, color: onInk),
              ),
              const SizedBox(width: 8),
              Text(
                paused ? l10n.meetingHudPaused : l10n.meetingHudRecording,
                style: TextStyle(fontSize: 12, color: onInk.withValues(alpha: 0.7)),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 18, color: onInk.withValues(alpha: 0.2)),
              const SizedBox(width: 8),
              _HudButton(
                icon: LucideIcons.play,
                label: l10n.meetingHudOpen,
                color: onInk,
                onTap: onOpen,
              ),
              const SizedBox(width: 4),
              _HudButton(
                icon: LucideIcons.square,
                label: l10n.meetingHudStop,
                color: onInk,
                background: ds.danger,
                onTap: onStop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = background != null ? Colors.white : color;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.brSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.12),
          borderRadius: AppRadii.brSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, color: fg)),
          ],
        ),
      ),
    );
  }
}

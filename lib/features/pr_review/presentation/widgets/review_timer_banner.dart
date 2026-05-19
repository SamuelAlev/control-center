import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/review_session_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A non-modal banner that shows elapsed review time and surfaces a fatigue
/// warning at 60 minutes (Cisco/SmartBear research: review quality collapses
/// after that threshold).
///
/// The banner only renders once the session is tracked; it disappears when
/// dismissed or when the session ends.
class ReviewTimerBanner extends ConsumerStatefulWidget {
  /// Creates a [ReviewTimerBanner] for [prNumber].
  const ReviewTimerBanner({super.key, required this.prNumber});

  /// The PR number this banner tracks.
  final int prNumber;

  @override
  ConsumerState<ReviewTimerBanner> createState() => _ReviewTimerBannerState();
}

class _ReviewTimerBannerState extends ConsumerState<ReviewTimerBanner> {
  Timer? _ticker;
  bool _dismissed = false;
  int _elapsedMinutes = 0;

  static const _warnMinutes = 60;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(reviewSessionProvider.notifier).start(widget.prNumber);
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      final startedAt = ref
          .read(reviewSessionProvider.notifier)
          .startedAt(widget.prNumber);
      if (startedAt == null) {
        return;
      }
      setState(() {
        _elapsedMinutes = DateTime.now().difference(startedAt).inMinutes;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) {
      return const SizedBox.shrink();
    }
    if (_elapsedMinutes < _warnMinutes) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    // Warning semantic tokens from the design system.
    final warningBg =
        tokens?.bgWarningSecondary ?? Colors.orange.withValues(alpha: 0.12);
    final warningFg = tokens?.fgWarningPrimary ?? Colors.orange;
    final warningBorder =
        tokens?.fgWarningSecondary ?? Colors.orange.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: warningBg,
          border: Border(
            top: BorderSide(color: warningBorder),
            bottom: BorderSide(color: warningBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(AppIcons.clock, size: 15, color: warningFg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.reviewFatigueWarning(_elapsedMinutes),
                style: CcTypography.body.copyWith(color: warningFg),
              ),
            ),
            CcButton(
              onPressed: () => setState(() => _dismissed = true),
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              child: Text(l10n.dismiss),
            ),
          ],
        ),
      ),
    );
  }
}

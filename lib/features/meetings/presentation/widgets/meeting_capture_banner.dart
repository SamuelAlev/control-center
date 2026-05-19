import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The warm "capture is armed" banner: a brand-gradient glyph, an explanatory
/// line, and a row of capability badges. A bounded brand moment on an otherwise
/// quiet surface.
class MeetingCaptureBanner extends StatelessWidget {
  /// Creates a [MeetingCaptureBanner].
  const MeetingCaptureBanner({super.key});

  /// The signature warm brand gradient (135°, sunshine → ember).
  static const LinearGradient _brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB83E), Color(0xFFFF8105), Color(0xFFFA520F), Color(0xFFC0400F)],
    stops: [0.0, 0.34, 0.70, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ds.panel,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: ds.borderSecondary),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: _brandGradient,
              borderRadius: AppRadii.brSm,
            ),
            child: const Icon(LucideIcons.audioLines, size: 22, color: Color(0xFF1F1F1F)),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.meetingsCaptureTitle} ',
                    style: TextStyle(fontSize: 13, height: 1.5, color: ds.fg),
                  ),
                  TextSpan(
                    text: l10n.meetingsCaptureBody,
                    style: TextStyle(fontSize: 13, height: 1.5, color: ds.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _Badge(
                leading: _GreenDot(color: context.mSuccess),
                label: l10n.meetingsCapturePermission,
              ),
              _Badge(icon: LucideIcons.lock, label: l10n.meetingsCaptureOnDevice),
              _Badge(icon: LucideIcons.crosshair, label: l10n.meetingsCaptureNoBot),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreenDot extends StatelessWidget {
  const _GreenDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.icon, this.leading});

  final String label;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: ds.borderSecondary),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 5)],
          if (icon != null) ...[
            Icon(icon, size: 12, color: ds.muted),
            const SizedBox(width: 5),
          ],
          Text(label, style: meetingMono(context, fontSize: 11)),
        ],
      ),
    );
  }
}

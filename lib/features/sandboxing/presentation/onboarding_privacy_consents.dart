import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/privacy_providers.dart';
import 'package:control_center/features/telemetry/providers/usage_analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The privacy choices asked on the sandbox/security onboarding step.
///
/// - Crash reports: this device's preference (on unless declined), shared
///   with Settings → Privacy through [errorReportingEnabledProvider].
/// - Usage analytics: the server-wide switch, asked only of the server
///   operator. It is opt-in, so it shows off and nothing is collected by any
///   client of this server until the operator turns it on here or in
///   Settings → Privacy ([usageAnalyticsProvider]).
class OnboardingPrivacyConsents extends ConsumerWidget {
  /// Creates the consent rows.
  const OnboardingPrivacyConsents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final crashReports = ref.watch(errorReportingEnabledProvider);
    final usageAnalytics = ref.watch(usageAnalyticsProvider);
    final askUsageAnalytics = ref.watch(canManageUsageAnalyticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConsentRow(
          icon: AppIcons.activity,
          title: l10n.onboardingDiagnosticsTitle,
          subtitle: l10n.onboardingDiagnosticsSubtitle,
          value: crashReports,
          onChanged: (v) => ref
              .read(errorReportingEnabledProvider.notifier)
              .setEnabled(value: v),
        ),
        if (askUsageAnalytics) ...[
          const SizedBox(height: 16),
          _ConsentRow(
            icon: AppIcons.barChart2,
            title: l10n.usageAnalyticsTitle,
            subtitle: l10n.onboardingUsageAnalyticsSubtitle,
            value: usageAnalytics ?? false,
            // Disabled until the server's current answer has loaded, so the
            // switch never flips a value it has not seen.
            onChanged: usageAnalytics == null
                ? null
                : (v) => ref
                      .read(usageAnalyticsProvider.notifier)
                      .setEnabled(value: v),
          ),
        ],
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: value ? tokens?.fgBrandPrimary : tokens?.fgTertiary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: tokens?.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: tokens?.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CcSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

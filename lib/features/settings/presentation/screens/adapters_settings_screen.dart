import 'package:control_center/features/settings/presentation/widgets/adapters_settings.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Settings screen for configuring adapters.
class AdaptersSettingsScreen extends StatelessWidget {
  /// Creates an [AdaptersSettingsScreen].
  const AdaptersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adapterId = GoRouterState.of(
      context,
    ).uri.queryParameters[settingsAdapterQueryParam];
    return AdaptersSettings(initialAdapterId: adapterId);
  }
}

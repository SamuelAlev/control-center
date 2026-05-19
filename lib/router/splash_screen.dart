import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';

/// Neutral loading screen shown while the router waits for the onboarding
/// gate to resolve. Avoids flashing the onboarding flow when the user has
/// already completed it.
class SplashScreen extends StatelessWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Scaffold(
      backgroundColor: ds.bgPrimary,
      body: const Center(child: CcSpinner()),
    );
  }
}

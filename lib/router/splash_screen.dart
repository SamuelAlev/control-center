import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Neutral loading screen shown while the router waits for the onboarding
/// gate to resolve. Avoids flashing the onboarding flow when the user has
/// already completed it.
class SplashScreen extends StatelessWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: const Center(child: FCircularProgress()),
    );
  }
}

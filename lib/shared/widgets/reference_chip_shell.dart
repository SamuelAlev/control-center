import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Rounded, bordered container used by inline GitHub reference chips
/// (PR previews, commit previews). Owns the consistent look across types.
class ReferenceChipShell extends StatelessWidget {
  /// Creates a [ReferenceChipShell].
  const ReferenceChipShell({
    super.key,
    required this.child,
    required this.onTap,
  });

  /// Chip content.
  final Widget child;

  /// Invoked when the chip is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final border = context.theme.colors.border;
    final background =
        tokens?.bgSecondary ?? context.theme.colors.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
            borderRadius: AppRadii.brSm,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Plain link fallback used when a reference preview can't be resolved.
/// Visually matches the in-text link style so it blends with surrounding
/// markdown content rather than standing out as a failed chip.
class ReferenceFallbackLink extends StatelessWidget {
  /// Creates a [ReferenceFallbackLink].
  const ReferenceFallbackLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  /// Text shown in place of the chip.
  final String label;

  /// Invoked when the link is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final linkColor = tokens?.fgBrandPrimary ?? const Color(0xFFfa520f);
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
      ),
    );
  }
}

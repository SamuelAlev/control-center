import 'dart:io';

import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Square workspace mark used everywhere a workspace is shown (the title-bar
/// switcher, the manage-workspaces editor, …).
///
/// Renders the workspace logo image when one is set, otherwise the workspace
/// initial on the brand block gradient. Falls back to a neutral grid icon only
/// when there is neither a logo nor a name.
class WorkspaceAvatar extends StatelessWidget {
  /// Creates a [WorkspaceAvatar].
  const WorkspaceAvatar({
    super.key,
    required this.logoPath,
    required this.size,
    this.name,
    this.radius,
    this.fontSize,
  });

  /// Absolute path to the workspace logo image, if any.
  final String? logoPath;

  /// Edge length of the (square) avatar.
  final double size;

  /// Workspace name — its first character is used for the gradient fallback.
  final String? name;

  /// Corner radius. Defaults to 4px for large marks (≥64px), 2px otherwise.
  final double? radius;

  /// Initial font size. Defaults to 45% of [size].
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? (size >= 64 ? AppRadii.lg : AppRadii.sm);
    final path = logoPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final ds = context.designSystem ?? DesignSystemTokens.light();
    final trimmed = (name ?? '').trim();

    // No logo and no name — keep a neutral mark rather than a stray "?".
    if (trimmed.isEmpty) {
      final bg = ds.bgTertiary;
      final fg = ds.fgTertiary;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(r),
        ),
        child: Icon(LucideIcons.layoutGrid, size: size * 0.55, color: fg),
      );
    }

    final ink = ds.fg;
    final initial = trimmed.substring(0, 1).toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.34, 0.70, 1.0],
          colors: [
            ds.sunshine500,
            ds.sunshine900,
            ds.accent,
            ds.blockEdge,
          ],
        ),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(r),
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize ?? size * 0.45,
          height: 1,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
    );
  }
}

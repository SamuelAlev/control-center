import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';

/// Sort modes for the agent roster list.
enum AgentSort {
  /// Sort by experience points.
  xp,

  /// Sort by total runs.
  runs,

  /// Sort by success rate.
  success,

  /// Sort by merged PRs.
  prsMerged,
}

/// A circular avatar showing the agent's initials with a tinted background.
class AgentAvatar extends StatelessWidget {
/// Constructs the avatar with a display name, size, and accent color.
  const AgentAvatar({super.key, required this.name, required this.size, required this.color});
/// The agent's display name, used to derive initials.
  final String name;
/// Diameter of the circular avatar.
  final double size;
/// Accent color for the background tint and text.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// A centered placeholder shown when a section has no data, displaying
/// an icon and message.
class SectionEmpty extends StatelessWidget {
/// Constructs the empty-state widget with an icon and message string.
  const SectionEmpty({super.key, required this.icon, required this.message});
/// Icon to display above the message.
  final IconData icon;
/// Descriptive message shown to the user.
  final String message;

  @override
  Widget build(BuildContext context) {
    final muted = context.designSystem!.textTertiary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: muted, size: 22),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats an integer in a compact human-readable form (e.g. 1.5k, 2.3M).
String compactInt(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}k';
  }
  return n.toString();
}

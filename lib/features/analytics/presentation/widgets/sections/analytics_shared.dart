import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

enum AgentSort { xp, runs, success, prsMerged }

class AgentAvatar extends StatelessWidget {
  const AgentAvatar({super.key, required this.name, required this.size, required this.color});
  final String name;
  final double size;
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

class SectionEmpty extends StatelessWidget {
  const SectionEmpty({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final muted = tokens?.textTertiary ?? FTheme.of(context).colors.mutedForeground;
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

String compactInt(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}k';
  }
  return n.toString();
}

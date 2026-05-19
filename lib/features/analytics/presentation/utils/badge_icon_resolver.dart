import 'package:control_center/features/analytics/domain/entities/user_badge.dart' show UserBadgeCategory;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Resolves a [String] icon name from [UserBadgeCategory.iconName] to the
/// corresponding Lucide [IconData]. Returns a fallback icon for unknown names.
IconData badgeIconData(String iconName) {
  return _iconMap[iconName] ?? LucideIcons.award;
}

const _iconMap = <String, IconData>{
  'messageSquareCode': LucideIcons.messageSquareCode,
  'scanEye': LucideIcons.scanEye,
  'rocket': LucideIcons.rocket,
  'lightbulb': LucideIcons.lightbulb,
  'compass': LucideIcons.compass,
};

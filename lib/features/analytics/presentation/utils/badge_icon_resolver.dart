import 'package:control_center/features/analytics/domain/entities/user_badge.dart' show UserBadgeCategory;
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';

/// Resolves a [String] icon name from [UserBadgeCategory.iconName] to the
/// corresponding Lucide [IconData]. Returns a fallback icon for unknown names.
IconData badgeIconData(String iconName) {
  return _iconMap[iconName] ?? AppIcons.award;
}

const _iconMap = <String, IconData>{
  'messageSquareCode': AppIcons.messageSquareCode,
  'scanEye': AppIcons.scanEye,
  'rocket': AppIcons.rocket,
  'lightbulb': AppIcons.lightbulb,
  'compass': AppIcons.compass,
};

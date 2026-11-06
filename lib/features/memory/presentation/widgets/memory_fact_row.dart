import 'dart:async';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_actions.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_excerpt.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The glyph of a memory type: a list reads by kind before it reads by word.
IconData memoryTypeIcon(MemoryType type) => switch (type) {
  MemoryType.fact => AppIcons.lightbulb,
  MemoryType.preference => AppIcons.star,
  MemoryType.decision => AppIcons.gitBranch,
  MemoryType.commitment => AppIcons.listChecks,
  MemoryType.goal => AppIcons.target,
  MemoryType.event => AppIcons.calendar,
  MemoryType.instruction => AppIcons.compass,
  MemoryType.relationship => AppIcons.network,
  MemoryType.context => AppIcons.mapPin,
  MemoryType.learning => AppIcons.sparkles,
  MemoryType.observation => AppIcons.eye,
  MemoryType.error => AppIcons.triangleAlert,
  MemoryType.artifact => AppIcons.fileText,
  MemoryType.request => AppIcons.messageSquare,
  MemoryType.unknown => AppIcons.circleHelp,
};

/// One fact. Opens on a click; deleting sits behind hover, and a confirmation.
class MemoryFactRow extends ConsumerWidget {
  /// Creates a [MemoryFactRow].
  const MemoryFactRow({super.key, required this.fact, this.deletable = true});

  /// The fact.
  final MemoryFact fact;

  /// False where the row is a link from another record, not the list itself.
  final bool deletable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    final repo = MemoryDomainScope.repoSlugOf(fact.domain);
    return SettingsEntityRow(
      leading: MemoryConfidenceMarker(
        icon: memoryTypeIcon(fact.memoryType),
        confidence: fact.confidence,
      ),
      title: fact.topic,
      subtitleWidget: MemoryExcerpt(markdown: fact.content),
      tone: fact.isSuperseded ? CcStatusTone.caution : null,
      statusLabel: fact.isSuperseded ? l10n.superseded : null,
      meta: [
        CcTooltip(
          message: l10n.confidenceTooltip,
          child: SettingsMetaFact(
            value: '${(fact.confidence.clamp(0.0, 1.0) * 100).round()}%',
          ),
        ),
        if (repo != null)
          SettingsMetaFact(value: repo, icon: AppIcons.folderGit),
        if (fact.memoryType != MemoryType.fact)
          Text(fact.memoryType.label, style: caption),
        AppTimestamp.relative(fact.updatedAt, style: caption),
      ],
      trailing: deletable
          ? CcIconButton(
              variant: CcButtonVariant.destructive,
              icon: AppIcons.trash2,
              size: CcButtonSize.sm,
              tooltip: l10n.delete,
              onPressed: () => unawaited(deleteMemoryFact(context, ref, fact)),
            )
          : null,
      revealTrailing: true,
      onPressed: () => openMemoryFact(context, fact),
    );
  }
}

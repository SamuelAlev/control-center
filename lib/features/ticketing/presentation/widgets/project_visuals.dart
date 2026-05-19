import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';

/// Resolves a [ProjectColor] to a display [Color].
///
/// The semantic hues reuse the design system design tokens; purple / teal / pink
/// are a small **sanctioned categorical palette** (design system 500-step hues)
/// for project identity, analogous to the diff viewer's domain palette. They
/// are always paired with the project name and box glyph — never color alone.
Color projectColorValue(DesignSystemTokens t, ProjectColor color) =>
    switch (color) {
      ProjectColor.gray => t.fgQuaternary,
      ProjectColor.blue => t.fgBrandPrimary,
      ProjectColor.green => t.fgSuccessPrimary,
      ProjectColor.amber => t.fgWarningPrimary,
      ProjectColor.red => t.fgErrorPrimary,
      ProjectColor.purple => const Color(0xFF7A5AF8),
      ProjectColor.teal => const Color(0xFF15B79E),
      ProjectColor.pink => const Color(0xFFEE46BC),
    };

/// Localized label for a project's lifecycle status.
String projectStatusLabel(AppLocalizations l10n, ProjectStatus status) =>
    switch (status) {
      ProjectStatus.active => l10n.projectStatusActive,
      ProjectStatus.completed => l10n.projectStatusCompleted,
      ProjectStatus.archived => l10n.projectStatusArchived,
    };

/// A small filled rounded-square "swatch" with the project's box glyph,
/// distinct from the circular status dot. Pairs the color with an icon so it
/// reads in grayscale and for color-blind users.
class ProjectGlyph extends StatelessWidget {
  /// Creates a [ProjectGlyph].
  const ProjectGlyph({super.key, required this.color, this.size = 16});

  /// The project color.
  final ProjectColor color;

  /// The glyph's side length.
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final c = projectColorValue(t, color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(AppIcons.box, size: size * 0.66, color: c),
    );
  }
}

/// Localized group heading for a relation kind as it reads from the subject
/// ticket's perspective (used by the relations card section headers).
String ticketRelationGroupLabel(
  AppLocalizations l10n,
  TicketRelationKind kind,
) =>
    switch (kind) {
      TicketRelationKind.subIssueOf => l10n.relationGroupParent,
      TicketRelationKind.parentOf => l10n.relationGroupSubIssues,
      TicketRelationKind.blockedBy => l10n.relationGroupBlockedBy,
      TicketRelationKind.blocking => l10n.relationGroupBlocking,
      TicketRelationKind.relatedTo => l10n.relationGroupRelated,
      TicketRelationKind.duplicateOf => l10n.relationGroupDuplicateOf,
      TicketRelationKind.duplicatedBy => l10n.relationGroupDuplicatedBy,
    };

/// Lucide icon for a relation kind (paired with the group label).
IconData ticketRelationIcon(TicketRelationKind kind) => switch (kind) {
      TicketRelationKind.subIssueOf => AppIcons.cornerLeftUp,
      TicketRelationKind.parentOf => AppIcons.cornerLeftDown,
      TicketRelationKind.blockedBy => AppIcons.circleSlash,
      TicketRelationKind.blocking => AppIcons.ban,
      TicketRelationKind.relatedTo => AppIcons.gitCompareArrows,
      TicketRelationKind.duplicateOf => AppIcons.copy,
      TicketRelationKind.duplicatedBy => AppIcons.copy,
    };

/// Localized "Relate to" menu item label (the action wording, with an ellipsis
/// because picking the relation opens a ticket picker).
String ticketRelationMenuLabel(
  AppLocalizations l10n,
  TicketRelationKind kind,
) =>
    switch (kind) {
      TicketRelationKind.subIssueOf => l10n.relationSubIssueOf,
      TicketRelationKind.parentOf => l10n.relationParentOf,
      TicketRelationKind.blockedBy => l10n.relationBlockedBy,
      TicketRelationKind.blocking => l10n.relationBlocking,
      TicketRelationKind.relatedTo => l10n.relationRelatedTo,
      TicketRelationKind.duplicateOf => l10n.relationDuplicateOf,
      TicketRelationKind.duplicatedBy => l10n.relationDuplicateOf,
    };

import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

/// Horizontal row of removable chips for the composer's attached files
/// and scratchpads. Hidden when the list is empty.
class AttachmentStrip extends StatelessWidget {
  /// Creates a new [AttachmentStrip].
  const AttachmentStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  /// Attachments to display as removable chips.
  final List<ComposerAttachment> attachments;

  /// Called when the user removes an attachment.
  final void Function(ComposerAttachment) onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) => _AttachmentChip(
          attachment: attachments[i],
          onRemove: () => onRemove(attachments[i]),
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.attachment, required this.onRemove});

  final ComposerAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final label = attachment.path != null
        ? p.basename(attachment.path!)
        : attachment.label;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFor(attachment),
            size: 14,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              style: theme.typography.xs.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.x,
                  size: 12,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ComposerAttachment a) {
    if (a.kind == 'scratchpad') {
      return LucideIcons.notebookText;
    }
    if (a.isImage) {
      return LucideIcons.image;
    }
    return LucideIcons.fileText;
  }
}


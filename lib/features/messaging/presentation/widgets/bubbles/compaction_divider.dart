import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/widgets.dart';

/// Renders a compaction as a slim, expandable divider rather than a wall of
/// summary text.
///
/// **Why not just show the summary.** A compaction summary is long by
/// construction — it stands in for dozens of turns — so rendering it inline
/// drops a page of prose into the middle of the conversation at exactly the
/// moment the reader is scrolling past it. What they actually need at that
/// point is one fact: *the agent's memory of everything above this line is now
/// this summary*. The summary itself is worth reading occasionally, so it
/// expands; it is not worth reading every scroll, so it collapses.
///
/// The scrollback above the divider is deliberately untouched. Only the
/// MODEL's context resets here — the conversation the human is reading is
/// still whole, and hiding it would be lying about what happened.
class CompactionDivider extends StatefulWidget {
  /// Creates a [CompactionDivider] for a compaction [message].
  const CompactionDivider({super.key, required this.message});

  /// The compaction message, whose content is the summary.
  final Message message;

  @override
  State<CompactionDivider> createState() => _CompactionDividerState();
}

class _CompactionDividerState extends State<CompactionDivider> {
  bool _expanded = false;

  /// How many messages this compaction folded, when the server recorded it.
  int? get _foldedCount {
    final raw = widget.message.metadata?['compactedCount'];
    return raw is num ? raw.toInt() : null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final count = _foldedCount;
    final label = count == null
        ? l10n.compactionDivider
        : l10n.compactionDividerCount(count);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: label,
            button: true,
            expanded: _expanded,
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    Expanded(child: CcDivider(color: tokens.borderSecondary)),
                    const SizedBox(width: 12),
                    Icon(
                      _expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
                      size: 12,
                      color: tokens.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: CcDivider(color: tokens.borderSecondary)),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.borderSecondary),
                color: tokens.bgSecondary,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: StyledMarkdownBody(data: widget.message.content),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

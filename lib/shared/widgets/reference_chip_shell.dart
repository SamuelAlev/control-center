import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Rounded, bordered container used by inline GitHub reference chips
/// (PR previews, commit previews). Owns the consistent look across types.
///
/// The chip is a control, so it opts out of the surrounding markdown
/// [SelectionArea]: the title is not selectable and the pointer is a click
/// cursor. Hover washes the fill the same way the PR header's branch chips do.
class ReferenceChipShell extends StatefulWidget {
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
  State<ReferenceChipShell> createState() => _ReferenceChipShellState();
}

class _ReferenceChipShellState extends State<ReferenceChipShell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            // Outside the border, so the fill doesn't run up to the words.
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: _hovered ? tokens.bgTertiary : tokens.bgSecondary,
                border: Border.all(color: tokens.borderSecondary),
                borderRadius: AppRadii.brSm,
              ),
              child: widget.child,
            ),
          ),
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
    final linkColor = tokens?.fgBrandPrimary ?? const Color(0xFFfa500f);
    return GestureDetector(
      onTap: onTap,
      child: CcLinkText(
        label,
        style: TextStyle(color: linkColor).withLinkUnderline(),
      ),
    );
  }
}

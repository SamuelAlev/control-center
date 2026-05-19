import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/context_usage_flyout.dart';
import 'package:control_center/features/messaging/providers/context_inspection_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compact live context-window gauge — "145k / 200k" with a thin fill bar
/// that warms from neutral → amber (≥75%) → red (≥90%) as the conversation
/// approaches the model's window. Mirrors the estimate that drives
/// auto-compaction, so a full bar means a compaction pass is imminent.
///
/// One agent's window at a time. A space holding several is metered on
/// whichever agent last worked there (the header resolves it via
/// `spaceMeteredAgentIdProvider`) and the chip then names it — see [showAgent].
///
/// Tapping it opens a [ContextUsageFlyout] with the per-category breakdown.
class ContextMeterChip extends ConsumerStatefulWidget {
  /// Creates a [ContextMeterChip] for the [spaceId] / [agentId] pair.
  const ContextMeterChip({
    super.key,
    required this.spaceId,
    required this.agentId,
    this.showAgent = false,
  });

  /// The space whose usage to show.
  final String spaceId;

  /// The agent whose context window bounds the meter.
  final String agentId;

  /// Whether to name the agent the reading belongs to (an avatar beside the
  /// numbers, and the agent's name in the accessible label).
  ///
  /// On for a space holding more than one agent, where the meter follows
  /// whoever is working: without attribution the numbers would silently change
  /// subject mid-conversation and read as a context window that shrank.
  final bool showAgent;

  @override
  ConsumerState<ContextMeterChip> createState() => _ContextMeterChipState();
}

class _ContextMeterChipState extends ConsumerState<ContextMeterChip> {
  final CcOverlayController _controller = CcOverlayController();
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    // Keep the hover wash and text colour while the flyout is open — the
    // pointer usually rests over the popover, not the chip, so hover
    // alone would drop it.
    _controller.addListener(_onOverlayToggled);
  }

  void _onOverlayToggled() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onOverlayToggled);
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    // Opening the flyout is an explicit "show me now" — refresh the summary in
    // the background so the breakdown is fresh without blocking the open.
    if (!_controller.isOpen) {
      ref.invalidate(
        contextInspectionProvider((
          spaceId: widget.spaceId,
          agentId: widget.agentId,
          includeContent: false,
        )),
      );
    }
    _controller.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // The SAME merged breakdown the flyout renders (server-measured persistent
    // segments + client conversation) — a conversation-only estimate here
    // would undercut the flyout's total by the whole persistent surface.
    final breakdown = ref.watch(
      contextBreakdownProvider((
        spaceId: widget.spaceId,
        agentId: widget.agentId,
      )),
    );
    if (breakdown.windowTokens <= 0 || breakdown.totalTokens <= 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    // The breakdown's own window estimate already watches this agent, so
    // naming it costs no extra read.
    final name = widget.showAgent
        ? ref.watch(agentDetailProvider(widget.agentId)).value?.name
        : null;
    final agentName = (name != null && name.isNotEmpty) ? name : null;
    // Attribution belongs in the accessible name too: the meter changes
    // subject on its own, and a reader that only ever says "context usage"
    // would report the swap as the same window jumping.
    final label = agentName == null
        ? l10n.contextUsage
        : '${l10n.contextUsage} · $agentName';

    // The compaction trigger's thresholds (ContextWindowUsage.isWarning /
    // isCritical), applied to the merged fraction.
    final isWarning = breakdown.fraction >= 0.75;
    final isCritical = breakdown.fraction >= 0.90;
    final fillColor = isCritical
        ? tokens.bgErrorSolid
        : isWarning
        ? tokens.bgWarningSolid
        : tokens.bgSuccessSolid;

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      followerAnchor: Alignment.topRight,
      targetAnchor: Alignment.bottomRight,
      offset: const Offset(0, 6),
      semanticLabel: label,
      overlayBuilder: (context, _) => ContextUsageFlyout(
        spaceId: widget.spaceId,
        agentId: widget.agentId,
        controller: _controller,
        agentName: agentName,
      ),
      target: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: Semantics(
            button: true,
            label: label,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              // The header row STRETCHES its children vertically; Center
              // hands the wash loose constraints so it hugs the meter
              // instead of filling the header's full height. The tap
              // target keeps the full height — only the decoration shrinks.
              child: Center(
                child: AnimatedContainer(
                  duration: CcMotion.resolve(context, CcMotion.fast),
                  curve: CcMotion.standard,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    // Idle is the SAME color at alpha 0, never transparent
                    // black: lerping to 0x00000000 sweeps through dark
                    // translucent shades — a visible flash on unhover.
                    // No radius: a rounded wash read as a bordered chip
                    // around the numbers.
                    color: _hover || _controller.isOpen
                        ? tokens.bgSecondaryHover
                        : tokens.bgSecondaryHover.withValues(alpha: 0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Whose window this is, past one agent. The meter
                      // follows whoever is working, so an unattributed number
                      // would change subject silently and read as a context
                      // window that shrank. Passive by construction (no
                      // hover card): the tap belongs to the chip.
                      if (agentName != null) ...[
                        AgentAvatar(
                          agentId: widget.agentId,
                          name: agentName,
                          size: 16,
                          showHoverCard: false,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_fmt(breakdown.totalTokens)} / '
                            '${_fmt(breakdown.windowTokens)}',
                            style: TextStyle(
                              fontFamily: CcFonts.codeFamily,
                              fontSize: 11,
                              height: 1.1,
                              color: isWarning
                                  ? fillColor
                                  : _hover || _controller.isOpen
                                  ? tokens.textSecondary
                                  : tokens.textTertiary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 3),
                          SizedBox(
                            width: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Stack(
                                children: [
                                  // A fill-TINTED track: bgTertiary
                                  // disappears into the hover wash
                                  // (bgSecondaryHover).
                                  Container(
                                    height: 3,
                                    color: fillColor.withValues(alpha: 0.18),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: breakdown.fraction.clamp(
                                      0.02,
                                      1.0,
                                    ),
                                    child: Container(
                                      height: 3,
                                      color: fillColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Formats a token count compactly: 145000 → "145k", 263000 → "263k",
  /// 900 → "900".
  String _fmt(int tokens) {
    if (tokens >= 1000) {
      return '${(tokens / 1000).round()}k';
    }
    return '$tokens';
  }
}

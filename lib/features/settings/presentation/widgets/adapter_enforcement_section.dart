import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The honesty matrix for one adapter, rendered under its row in
/// Settings → Adapters — collapsed to a single summary line by default.
///
/// A conversation mode advertises a guarantee ("plan mode is read-only"), but
/// the guarantee is only as strong as the transport underneath it and the four
/// transports differ enormously. This section is where the operator finds out
/// which one they picked: five yes/no facts, the honest sentence about how a
/// mode reaches this runner and the caveats that follow from the no's.
///
/// ## Why it collapses
///
/// Settings → Adapters lists every runner in the catalogue (eight today) and
/// twelve lines of matrix per row turned a scannable list into a wall — the
/// verdict was buried in prose the operator had to read to reach. Collapsing
/// does not hide the disclosure, it *promotes* it: the header keeps the shield
/// glyph, the verdict word and the caveat count on screen at all times, so
/// "this runner does not enforce modes and there are four caveats" is now
/// legible at a glance instead of after a paragraph. The detail is one tap away
/// for the operator who wants the reasoning.
///
/// Never status-by-color-alone (the AAA-where-feasible bar): the header summary
/// and each row carry a glyph *and* a word, so the answer survives greyscale, a
/// colour deficiency and a screen reader.
class AdapterEnforcementSection extends StatefulWidget {
  /// Creates an [AdapterEnforcementSection] for [transport].
  const AdapterEnforcementSection({
    required this.transport,
    this.initiallyExpanded = false,
    super.key,
  });

  /// The transport whose enforcement is described. Enforcement is a property of
  /// the transport, never of the individual CLI, so this is all the section
  /// needs.
  final AdapterTransport transport;

  /// Whether the matrix starts open. Off by default; the gallery and tests pass
  /// true to see the whole thing without a tap.
  final bool initiallyExpanded;

  @override
  State<AdapterEnforcementSection> createState() =>
      _AdapterEnforcementSectionState();
}

class _AdapterEnforcementSectionState extends State<AdapterEnforcementSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final enforcement = enforcementForTransport(widget.transport);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnforcementHeader(
          enforcement: enforcement,
          expanded: _expanded,
          tokens: t,
          onToggle: () => setState(() => _expanded = !_expanded),
        ),
        // AnimatedSize over an empty box rather than a Visibility: the collapsed
        // state costs no layout for five rows plus prose and the open/close
        // reads as one motion instead of a jump.
        AnimatedSize(
          duration: CcMotion.resolve(context, CcMotion.normal),
          curve: CcMotion.standard,
          alignment: Alignment.topCenter,
          child: _expanded
              ? _EnforcementDetail(enforcement: enforcement, tokens: t)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The always-visible line: shield, title, verdict + caveat count, chevron.
class _EnforcementHeader extends StatelessWidget {
  const _EnforcementHeader({
    required this.enforcement,
    required this.expanded,
    required this.tokens,
    required this.onToggle,
  });

  final AdapterEnforcement enforcement;
  final bool expanded;
  final DesignSystemTokens tokens;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enforces = enforcement.enforcesModeGuarantees;
    final caveats = enforcement.caveats;
    final verdictColor = enforces ? tokens.success : tokens.fgWarningPrimary;
    final verdict = enforces
        ? l10n.enforcementSummaryModesEnforced
        : l10n.enforcementSummaryModesNotEnforced;

    return CcTappable(
      onPressed: onToggle,
      semanticLabel:
          '${l10n.adapterEnforcementTitle} · $verdict'
          '${caveats.isEmpty ? '' : ' · ${l10n.enforcementCaveatCount(caveats.length)}'}'
          ' · ${expanded ? l10n.collapse : l10n.expand}',
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? tokens.hover : const Color(0x00000000),
            borderRadius: AppRadii.brSm,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  enforces ? AppIcons.shieldCheck : AppIcons.shieldAlert,
                  size: 14,
                  color: verdictColor,
                ),
                const SizedBox(width: 6),
                // Every text gets the same 16px line box (caption's height,
                // kept when shrinking to 11px) so the Row's center alignment
                // lands all baselines on the same pixel; raw TextStyles with
                // unset height gave each run its own box and they drifted.
                Text(
                  l10n.adapterEnforcementTitle,
                  style: CcTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                // The verdict travels with the header so the honest answer is
                // never behind the fold.
                Expanded(
                  child: Text(
                    verdict,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(
                      fontSize: 11,
                      height: 16 / 11,
                      fontWeight: FontWeight.w600,
                      color: verdictColor,
                    ),
                  ),
                ),
                if (caveats.isNotEmpty) ...[
                  Text(
                    l10n.enforcementCaveatCount(caveats.length),
                    style: CcTypography.caption.copyWith(
                      fontSize: 11,
                      height: 16 / 11,
                      color: tokens.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                AnimatedRotation(
                  turns: expanded ? 0 : -0.25,
                  duration: CcMotion.resolve(context, CcMotion.fast),
                  child: Icon(
                    AppIcons.chevronDown,
                    size: 14,
                    color: tokens.muted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The expanded body: the five yes/no facts, the mode-mapping sentence and one
/// line per caveat.
class _EnforcementDetail extends StatelessWidget {
  const _EnforcementDetail({required this.enforcement, required this.tokens});

  final AdapterEnforcement enforcement;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = tokens;
    final caveats = enforcement.caveats;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EnforcementRow(
            label: l10n.enforcementFiltersToolSurface,
            value: enforcement.filtersToolSurface,
            tokens: t,
          ),
          _EnforcementRow(
            label: l10n.enforcementInterceptsToolCalls,
            value: enforcement.interceptsToolCalls,
            tokens: t,
          ),
          _EnforcementRow(
            label: l10n.enforcementNativeToolsInterceptable,
            value: enforcement.nativeToolsInterceptable,
            tokens: t,
          ),
          _EnforcementRow(
            label: l10n.enforcementObservesCompletionContract,
            value: enforcement.observesCompletionContract,
            tokens: t,
          ),
          _EnforcementRow(
            label: l10n.enforcementInProcessToolsSandboxed,
            value: enforcement.inProcessToolsSandboxed,
            tokens: t,
          ),
          const SizedBox(height: 8),
          // English source text, like `Adapter.description`: engineering prose
          // about our own integration, authored with no BuildContext in reach.
          Text(
            enforcement.modeMappingNote,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: t.textSecondary,
            ),
          ),
          if (caveats.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.adapterEnforcementCaveats,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: t.fgWarningPrimary,
              ),
            ),
            const SizedBox(height: 4),
            for (final caveat in caveats)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        AppIcons.triangleAlert,
                        size: 12,
                        color: t.fgWarningPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        caveatMessage(l10n, caveat),
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.45,
                          color: t.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The localized sentence for [caveat].
///
/// Exhaustive switch on purpose: a new caveat in the domain must be given a
/// string here or the build fails, which is the only way this list stays in step
/// with the matrix.
String caveatMessage(AppLocalizations l10n, AdapterEnforcementCaveat caveat) {
  switch (caveat) {
    case AdapterEnforcementCaveat.toolSurfaceNotFiltered:
      return l10n.caveatToolSurfaceNotFiltered;
    case AdapterEnforcementCaveat.toolCallsNotIntercepted:
      return l10n.caveatToolCallsNotIntercepted;
    case AdapterEnforcementCaveat.nativeToolsBypassControlCenter:
      return l10n.caveatNativeToolsBypassControlCenter;
    case AdapterEnforcementCaveat.inProcessToolsUnsandboxed:
      return l10n.caveatInProcessToolsUnsandboxed;
    case AdapterEnforcementCaveat.completionContractUnobservable:
      return l10n.caveatCompletionContractUnobservable;
  }
}

/// One yes/no fact. Glyph plus word — the colour is a reinforcement, never the
/// signal.
class _EnforcementRow extends StatelessWidget {
  const _EnforcementRow({
    required this.label,
    required this.value,
    required this.tokens,
  });

  final String label;
  final bool value;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final answer = value ? l10n.enforcementYes : l10n.enforcementNo;
    final color = value ? tokens.success : tokens.fgWarningPrimary;

    return Semantics(
      label: '$label: $answer',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                value ? AppIcons.check : AppIcons.x,
                size: 13,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: tokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              answer,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

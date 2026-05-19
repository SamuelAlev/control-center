import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_dropdown.dart';
import 'package:control_center/features/messaging/providers/channel_adapter_enforcement_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The degradation marker beside the mode selector (PRD 24 §3).
///
/// [ModeDropdown] presents a mode as a promise — plan mode tints itself with the
/// brand accent precisely to say "the restriction is on". For three of the four
/// transports that promise is kept by the sandbox and the prompt, not by Control
/// Center: the runner's own read/write/edit/shell tools never pass a gate we
/// own. This badge is where the operator learns which of those two situations
/// they are in, at the moment they choose the mode.
///
/// It renders nothing at all when there is nothing to disclose — in chat mode
/// (which promises no restriction), on a fully-enforcing adapter and while the
/// adapter is still unresolved. An absent badge therefore means "no claim being
/// made", never "verified safe".
class ModeEnforcementBadge extends ConsumerWidget {
  /// Creates a [ModeEnforcementBadge] for [channelId].
  const ModeEnforcementBadge({
    required this.channelId,
    required this.currentMode,
    super.key,
  });

  /// The channel whose agents' adapter decides what can be enforced.
  final String channelId;

  /// The channel's current conversation mode.
  final Mode currentMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chat mode guarantees nothing about writes, so there is no guarantee to
    // walk back — a badge here would be noise on the common path.
    if (currentMode == Mode.chat) {
      return const SizedBox.shrink();
    }

    final resolved = ref.watch(channelAdapterEnforcementProvider(channelId));
    if (resolved == null || resolved.enforcement.enforcesModeGuarantees) {
      return const SizedBox.shrink();
    }

    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final message = l10n.modeDegradedTooltip(
      currentMode.displayName,
      resolved.adapter.name,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: CcTooltip(
        message: message,
        placement: CcTooltipPlacement.top,
        child: Semantics(
          label: '${l10n.modeDegraded}. $message',
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: t.fgWarningPrimary.withValues(alpha: 0.12),
              borderRadius: AppRadii.brLg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.triangleAlert,
                  size: 14,
                  color: t.fgWarningPrimary,
                ),
                // The word carries the state as much as the glyph does: colour
                // is never the only channel (the a11y bar in CLAUDE.md).
                const SizedBox(width: 5),
                Text(
                  l10n.modeDegraded,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t.fgWarningPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

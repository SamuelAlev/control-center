import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/focus_mode/presentation/widgets/focus_config_dialog.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global-sidebar footer entry for focus mode. Idle it starts a session. During
/// one the glyph gives way to the minutes left, in the brand accent (never
/// amber, which means blocked), and a menu above it holds the session's
/// actions.
class FocusSidebarEntry extends ConsumerStatefulWidget
    implements CcFluidHoverTarget {
  /// Creates a [FocusSidebarEntry].
  const FocusSidebarEntry({super.key});

  @override
  bool get fluidHoverEnabled => true;

  @override
  ConsumerState<FocusSidebarEntry> createState() => _FocusSidebarEntryState();
}

class _FocusSidebarEntryState extends ConsumerState<FocusSidebarEntry> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final focus = ref.watch(focusModeProvider);
    if (!focus.active) {
      return CcSidebarItem(
        icon: AppIcons.focus,
        label: l10n.focusModeStart,
        onPressed: () => showCcDialog<void>(
          context: context,
          builder: (_) => const FocusConfigDialog(),
        ),
      );
    }
    final accent = context.designSystem?.accent;
    final minutes = focus.minutesRemaining;
    final notifier = ref.read(focusModeProvider.notifier);
    return CcMenu(
      controller: _controller,
      toggleOnTargetTap: false,
      targetAnchor: AlignmentDirectional.topStart,
      followerAnchor: AlignmentDirectional.bottomStart,
      offset: const Offset(0, -AppSpacing.sm),
      semanticLabel: l10n.focusModeRemaining(minutes),
      items: [
        CcMenuItem.section(l10n.focusModeRemaining(minutes)),
        CcMenuItem(
          icon: AppIcons.pictureInPicture2,
          label: l10n.focusModeFloat,
          onSelected: notifier.enterCompactMode,
        ),
        CcMenuItem(
          icon: AppIcons.x,
          label: l10n.focusModeEnd,
          onSelected: notifier.deactivate,
        ),
      ],
      target: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final open = _controller.isOpen;
          return CcSidebarItem(
            icon: AppIcons.focus,
            label: l10n.focusModeRemaining(minutes),
            selected: open,
            iconBuilder: (color, _) => SizedBox(
              width: kCcSidebarItemExtent - AppSpacing.sm,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${minutes}m',
                  maxLines: 1,
                  style: CcTypography.caption.copyWith(
                    color: open ? color : accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            onPressed: _controller.toggle,
          );
        },
      ),
    );
  }
}

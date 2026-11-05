part of 'notification_bell.dart';

class _BellButton extends StatelessWidget {
  const _BellButton({
    required this.unread,
    required this.open,
    required this.onTap,
  });

  final int unread;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SidebarHeaderIconButton(
          icon: AppIcons.bell,
          tooltip: l10n.notificationsTooltip,
          active: open,
          onPressed: onTap,
        ),
        if (unread > 0)
          PositionedDirectional(
            top: 2,
            end: 2,
            // Never absorb the tap; the button underneath owns it.
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 15),
                height: 15,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: tokens?.fgBrandPrimary,
                  borderRadius: AppRadii.brSm,
                  border: Border.all(
                    color: tokens?.sidebar ?? const Color(0xFFFFFFFF),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: TextStyle(
                    color: tokens?.textWhite ?? const Color(0xFFFFFFFF),
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

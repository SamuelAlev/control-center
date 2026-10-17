import 'package:cc_remote/app_icons.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

class SpaceHeading extends StatelessWidget {
  const SpaceHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: tokens.textPrimary,
        ),
      ),
    );
  }
}

class SpacePick extends StatelessWidget {
  const SpacePick(this.title, this.selected, this.onTap, {super.key});

  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CcButton(
        size: CcButtonSize.lg,
        fullWidth: true,
        variant: CcButtonVariant.secondary,
        onPressed: onTap,
        trailing: selected
            ? Icon(AppIcons.check, size: 18, color: tokens.accent)
            : null,
        child: Text(title, textAlign: TextAlign.start),
      ),
    );
  }
}

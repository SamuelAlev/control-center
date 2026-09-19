import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Midpoint affordance on an editor edge: route-key pill when the edge is
/// conditional, otherwise a small dot. Hover turns it into an × so disconnect
/// is a shape change, not a colour change.
class PipelineEditorEdgeHandle extends StatefulWidget {
  /// Creates a [PipelineEditorEdgeHandle].
  const PipelineEditorEdgeHandle({
    super.key,
    required this.routeKey,
    required this.onDisconnect,
  });

  /// Router branch label, or null / empty for an unconditional edge.
  final String? routeKey;

  /// Click / activate — the screen owns duplicate-edge semantics.
  final VoidCallback onDisconnect;

  @override
  State<PipelineEditorEdgeHandle> createState() =>
      _PipelineEditorEdgeHandleState();
}

class _PipelineEditorEdgeHandleState extends State<PipelineEditorEdgeHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final label = widget.routeKey;
    final hasLabel = label != null && label.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: CcTooltip(
        message: l10n.pipelineRemoveConnection,
        child: CcTappable(
          semanticLabel: l10n.pipelineRemoveConnection,
          onPressed: widget.onDisconnect,
          builder: (context, states) {
            final active =
                _hovered || states.contains(WidgetState.hovered);
            if (active) {
              return Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: tokens.bgPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.borderSecondary),
                ),
                child: Icon(AppIcons.x, size: 12, color: tokens.textPrimary),
              );
            }
            if (hasLabel) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.bgPrimary,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: tokens.borderSecondary),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: CcFonts.code(
                    textStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              );
            }
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: tokens.bgPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.borderSecondary),
              ),
            );
          },
        ),
      ),
    );
  }
}

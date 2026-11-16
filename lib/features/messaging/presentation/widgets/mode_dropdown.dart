import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Localized display support for [Mode].
extension ModeL10n on Mode {
  /// Human-readable label for display.
  String get displayName => switch (this) {
    Mode.chat => 'Agent',
    Mode.plan => 'Plan',
    Mode.review => 'Review',
    Mode.orchestrate => 'Orchestrate',
  };

  /// Modes available for selection in the dropdown.
  static List<Mode> get selectable => const [
    Mode.chat,
    Mode.plan,
    Mode.orchestrate,
  ];
}

/// Compact mode selector rendered on the far-left of the composer toolbar.
///
/// Displays the current [Mode] as a label (e.g. "Agent", "Plan") and opens a
/// [CcMenu] with the selectable subset of modes. When [Mode.plan] is active the
/// label is tinted with the brand accent so the restriction is visually obvious.
class ModeDropdown extends StatelessWidget {
  /// Creates a [ModeDropdown].
  const ModeDropdown({
    required this.currentMode,
    required this.onChanged,
    super.key,
  });

  /// The currently selected conversation mode.
  final Mode currentMode;

  /// Called when the user selects a different mode from the menu.
  final ValueChanged<Mode> onChanged;

  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final isPlan = currentMode == Mode.plan;
    final foregroundColor = isPlan ? t.fgBrandPrimary : t.fgSecondary;
    final backgroundColor = isPlan ? t.accentSoft : t.bgTertiary;

    return CcMenu(
      semanticLabel: l10n.conversationMode,
      targetAnchor: AlignmentDirectional.topStart,
      followerAnchor: AlignmentDirectional.bottomStart,
      offset: const Offset(0, -4),
      minWidth: 160,
      items: [
        for (final mode in ModeL10n.selectable)
          CcMenuItem(
            label: mode.displayName,
            icon: _iconFor(mode),
            onSelected: () => onChanged(mode),
          ),
      ],
      // A narrow composer squeezes the picker: the label ellipsizes first, and
      // below the width the icon, chevron and padding need it collapses to a
      // square chip with just the mode icon.
      target: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < _minLabelledWidth;
          return Container(
            height: _height,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? (_height - 16) / 2 : 10,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadii.brLg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconFor(currentMode), size: 16, color: foregroundColor),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      currentMode.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(AppIcons.chevronDown, size: 16, color: foregroundColor),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Padding, mode icon, gaps, chevron and a few characters of label: below
  /// this the labelled chip would show an empty or overflowing label.
  static const double _minLabelledWidth = 10 + 16 + 6 + 24 + 4 + 16 + 10;

  IconData _iconFor(Mode mode) => switch (mode) {
    Mode.chat => AppIcons.sparkles,
    Mode.plan => AppIcons.squarePen,
    Mode.review => AppIcons.messageSquare,
    Mode.orchestrate => AppIcons.workflow,
  };
}

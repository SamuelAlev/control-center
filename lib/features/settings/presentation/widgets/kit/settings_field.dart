import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// How a [SettingsField] arranges its label against its control.
enum SettingsFieldLayout {
  /// Pick per available width: side-by-side when there is room, stacked when
  /// there is not. The default, and what makes the same field work on the
  /// desktop deck and the phone remote without a second widget.
  auto,

  /// Label and description in a fixed left column, control on the right. The
  /// column is what turns a form into something scannable: every control lands
  /// on the same vertical line, so the eye reads a list of values rather than a
  /// stack of unrelated boxes.
  inline,

  /// Label above, control below at full width. For values that need the room —
  /// pasted XML, a URL, a JSON blob — where an inline control would be a
  /// letterbox.
  stacked,
}

/// The shared label column width for [SettingsFieldLayout.inline].
///
/// One exported constant, because the alignment only works if every field on
/// the page agrees on it — including the ones a feature renders itself.
const double kSettingsFieldLabelWidth = 232;

/// Below this width an [SettingsFieldLayout.auto] field stacks. Chosen so the
/// control still has ~300px after the label column, which is the point at which
/// a text field stops being able to show a URL.
const double kSettingsFieldInlineBreakpoint = 560;

/// One labelled control: label, optional description, the control itself and an
/// optional hint or error beneath it.
///
/// Every settings input goes through this. Before it, a label was whatever the
/// author reached for that day — 12px tertiary above a field here, a 14px
/// semibold row title there, nothing at all in a third place — so two adjacent
/// controls could not be compared at a glance. The anatomy is now fixed:
///
/// - **Label**: 13px semibold ink. It is the thing you are looking for.
/// - **Description**: 12px muted. What the value does, or where to find it.
/// - **Control**: whatever the caller passes; the field never wraps it in
///   chrome of its own.
/// - **Hint / error**: 12px muted, or 12px danger with an icon. Never both.
///
/// The control is passed in rather than described by props on purpose: a
/// select, a text field, a button row and a segmented toggle all deserve the
/// same label anatomy, and a `SettingsField` that knew about each of them would
/// grow a switch statement every time a new control arrives.
class SettingsField extends StatelessWidget {
  /// Creates a [SettingsField].
  const SettingsField({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.hint,
    this.error,
    this.optional = false,
    this.badge,
    this.layout = SettingsFieldLayout.auto,
    this.controlWidth,
    this.labelWidth = kSettingsFieldLabelWidth,
    this.centerControl = false,
  });

  /// The field label. Sentence case, and it names the value, not the action.
  final String label;

  /// The control.
  final Widget child;

  /// One sentence on what this value does or where it comes from.
  final String? description;

  /// A format example or follow-up note, rendered under the control.
  final String? hint;

  /// Validation message. Takes precedence over [hint] and colours the note.
  final String? error;

  /// Marks the field as not required. Rendered as a quiet caption beside the
  /// label — the honest half of a required/optional pair, since marking every
  /// required field is noise when most of them are.
  final bool optional;

  /// Optional badge beside the label (e.g. a scope or provenance tag).
  final Widget? badge;

  /// How to arrange label against control.
  final SettingsFieldLayout layout;

  /// Caps the control's width in [SettingsFieldLayout.inline]. A select or a
  /// number input that stretches to 600px reads as a mistake; a URL field
  /// should take everything it can get, so leave this null there.
  final double? controlWidth;

  /// Width of the label column in [SettingsFieldLayout.inline].
  final double labelWidth;

  /// Centres the control against the label block instead of aligning their
  /// tops, in [SettingsFieldLayout.inline].
  ///
  /// The default top alignment is right for a control that is TALLER than its
  /// label — a text field, a select, a stack of radios — where the label reads
  /// as the heading of the thing beside it. It is wrong for a short control
  /// beside a described label: a 32px button next to a label-plus-description
  /// block ends up floating at the top of a taller row, which reads as a
  /// misalignment rather than a hierarchy. Opt in there.
  final bool centerControl;

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case SettingsFieldLayout.inline:
        return _inline(context);
      case SettingsFieldLayout.stacked:
        return _stacked(context);
      case SettingsFieldLayout.auto:
        return LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= kSettingsFieldInlineBreakpoint
              ? _inline(context)
              : _stacked(context),
        );
    }
  }

  Widget _stacked(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LabelBlock(
          label: label,
          description: description,
          optional: optional,
          badge: badge,
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
        ..._note(context),
      ],
    );
  }

  Widget _inline(BuildContext context) {
    final row = Row(
      crossAxisAlignment: centerControl
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            // Nudges the label onto the optical centre line of a 40px control
            // sitting beside it. Centring already puts it there, so the nudge
            // would push it back off by the same amount it corrects for.
            padding: EdgeInsets.only(top: centerControl ? 0 : AppSpacing.sm),
            child: _LabelBlock(
              label: label,
              description: description,
              optional: optional,
              badge: badge,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        if (controlWidth == null)
          Expanded(child: child)
        else ...[
          SizedBox(width: controlWidth, child: child),
          const Spacer(),
        ],
      ],
    );

    final note = _note(context);
    if (note.isEmpty) {
      return row;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        // Indented to the control column: the note belongs to the control, not
        // to the label.
        Padding(
          padding: EdgeInsets.only(left: labelWidth + AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: note,
          ),
        ),
      ],
    );
  }

  List<Widget> _note(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    if (error != null) {
      return [
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.circleAlert,
              size: 13,
              color: tokens.textErrorPrimary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                error!,
                style: CcTypography.caption.copyWith(
                  color: tokens.textErrorPrimary,
                ),
              ),
            ),
          ],
        ),
      ];
    }
    if (hint != null) {
      return [
        const SizedBox(height: AppSpacing.xs),
        Text(
          hint!,
          style: CcTypography.caption.copyWith(
            color: tokens.textTertiary,
            height: 1.45,
          ),
        ),
      ];
    }
    return const [];
  }
}

class _LabelBlock extends StatelessWidget {
  const _LabelBlock({
    required this.label,
    required this.description,
    required this.optional,
    required this.badge,
  });

  final String label;
  final String? description;
  final bool optional;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              label,
              style: CcTypography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            if (optional)
              Text(
                l10n.settingsFieldOptional,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ?badge,
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(
            description!,
            style: CcTypography.caption.copyWith(
              color: tokens.textTertiary,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

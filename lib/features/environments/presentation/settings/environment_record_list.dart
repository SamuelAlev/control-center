import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One record's collapsed face, and the form behind it.
class EnvironmentRecordEntry {
  /// Creates an [EnvironmentRecordEntry].
  const EnvironmentRecordEntry({
    required this.icon,
    required this.title,
    required this.summary,
    required this.detail,
    this.hasIssue = false,
    this.canRemove = true,
  });

  /// What kind of record it is.
  final IconData icon;

  /// Its name.
  final String title;

  /// What it says, so the row can be read without opening it.
  final Widget summary;

  /// Its form. Built only while the row is open.
  final Widget detail;

  /// Whether a field inside has a problem.
  final bool hasIssue;

  /// False for the one record a definition can't go without.
  final bool canRemove;
}

/// One way to add a record.
typedef EnvironmentRecordAdder = ({String label, VoidCallback onAdd});

/// The records of one section, a line each: a form per record makes it
/// impossible to see where one stops and the next begins.
class EnvironmentRecordList extends StatefulWidget {
  /// Creates an [EnvironmentRecordList].
  const EnvironmentRecordList({
    super.key,
    required this.count,
    required this.enabled,
    required this.entry,
    required this.adders,
    required this.onRemove,
    this.onMove,
  });

  /// How many records there are.
  final int count;

  /// False for someone who can read but not change definitions.
  final bool enabled;

  /// The record at an index.
  final EnvironmentRecordEntry Function(int index) entry;

  /// The ways to add one.
  final List<EnvironmentRecordAdder> adders;

  /// Removes the record at an index.
  final ValueChanged<int> onRemove;

  /// Moves a record, where order means something.
  final void Function(int from, int to)? onMove;

  @override
  State<EnvironmentRecordList> createState() => _EnvironmentRecordListState();
}

class _EnvironmentRecordListState extends State<EnvironmentRecordList> {
  /// Which positions are open. Held here, not in the rows, so an open record
  /// stays open as it moves and a removal doesn't open its neighbor.
  Set<int> _open = {};

  void _add(VoidCallback onAdd) {
    // A new record is only defaults: it exists to be filled in.
    setState(() => _open = {..._open, widget.count});
    onAdd();
  }

  void _remove(int index) {
    setState(
      () => _open = {
        for (final open in _open)
          if (open != index) open > index ? open - 1 : open,
      },
    );
    widget.onRemove(index);
  }

  void _move(int from, int to) {
    setState(
      () => _open = {
        for (final open in _open)
          open == from ? to : (open == to ? from : open),
      },
    );
    widget.onMove!(from, to);
  }

  Widget _row(AppLocalizations l10n, int index) {
    final entry = widget.entry(index);
    final onMove = widget.onMove;
    return SettingsEntityRow(
      // By position alone: a revision bump rebuilds the fields inside, and must
      // not disturb the row someone is editing.
      key: ValueKey('record:$index'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      // Flush with the card, so these fields share the control line of every
      // other field on the page.
      detailPadding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      icon: entry.icon,
      title: entry.title,
      subtitleWidget: entry.summary,
      tone: entry.hasIssue ? CcStatusTone.negative : null,
      statusLabel: entry.hasIssue ? l10n.environmentsRecordNeedsFix : null,
      expanded: _open.contains(index),
      onExpandedChanged: (open) => setState(
        () => _open = open ? {..._open, index} : ({..._open}..remove(index)),
      ),
      revealTrailing: true,
      trailing: widget.enabled
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onMove != null) ...[
                  CcIconButton(
                    icon: AppIcons.arrowUp,
                    size: CcButtonSize.sm,
                    tooltip: l10n.accountPoolMoveUp,
                    onPressed: index == 0
                        ? null
                        : () => _move(index, index - 1),
                  ),
                  CcIconButton(
                    icon: AppIcons.arrowDown,
                    size: CcButtonSize.sm,
                    tooltip: l10n.accountPoolMoveDown,
                    onPressed: index == widget.count - 1
                        ? null
                        : () => _move(index, index + 1),
                  ),
                ],
                CcIconButton(
                  variant: CcButtonVariant.destructive,
                  icon: AppIcons.trash2,
                  size: CcButtonSize.sm,
                  tooltip: l10n.remove,
                  onPressed: entry.canRemove ? () => _remove(index) : null,
                ),
              ],
            )
          : null,
      detail: entry.detail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsGroup(
          separator: SettingsGroupSeparator.rule,
          children: [
            for (var index = 0; index < widget.count; index++)
              _row(l10n, index),
          ],
        ),
        if (widget.enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final adder in widget.adders)
                  CcButton(
                    variant: CcButtonVariant.secondary,
                    size: CcButtonSize.sm,
                    icon: AppIcons.plus,
                    onPressed: () => _add(adder.onAdd),
                    child: Text(adder.label),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A record's one-line summary: plain words beside machine values.
class EnvironmentRecordSummary extends StatelessWidget {
  /// Creates an [EnvironmentRecordSummary].
  const EnvironmentRecordSummary({super.key, required this.parts});

  /// The facts in order. `code` marks a machine value. Blanks are dropped.
  final List<({String text, bool code})> parts;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final plain = CcTypography.caption.copyWith(color: t.textTertiary);
    final code = CcFonts.code(textStyle: plain);
    final shown = parts.where((part) => part.text.isNotEmpty).toList();
    return Text.rich(
      TextSpan(
        style: plain,
        children: [
          for (final (index, part) in shown.indexed) ...[
            if (index > 0) const TextSpan(text: ' · '),
            TextSpan(text: part.text, style: part.code ? code : null),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

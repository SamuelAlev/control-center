import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extends a schedule its viewer owns (`wakeRules.update`): a later end, and
/// optionally more runs and more money. The end may not pass the rule's
/// longest life (a year for a person's rule, 30 days for an agent's, from
/// its creation); the server refuses past it (`wake_expiry_too_long`).
Future<void> showScheduleExtendDialog(
  BuildContext context,
  WakeRuleView rule,
) => showCcDialog<void>(
  context: context,
  builder: (_) => _ExtendDialog(rule: rule),
);

class _ExtendDialog extends ConsumerStatefulWidget {
  const _ExtendDialog({required this.rule});

  final WakeRuleView rule;

  @override
  ConsumerState<_ExtendDialog> createState() => _ExtendDialogState();
}

class _ExtendDialogState extends ConsumerState<_ExtendDialog> {
  final _days = TextEditingController(text: '7');
  late final _maxRuns = TextEditingController(
    text: widget.rule.maxRuns == null ? '' : '${widget.rule.maxRuns}',
  );
  late final _dollars = TextEditingController(
    text: '${(widget.rule.costCapMicros / 1000000).ceil()}',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_days, _maxRuns, _dollars]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get _latest => widget.rule.createdAt.add(ruleMaxLife(widget.rule));

  DateTime? get _newExpiry {
    final days = int.tryParse(_days.text.trim());
    if (days == null || days < 1) {
      return null;
    }
    final base = widget.rule.expiresAt.isAfter(DateTime.now())
        ? widget.rule.expiresAt
        : DateTime.now().toUtc();
    final at = base.add(Duration(days: days));
    return at.isAfter(_latest) ? null : at;
  }

  int? get _runs {
    final text = _maxRuns.text.trim();
    if (text.isEmpty) {
      return null;
    }
    final v = int.tryParse(text);
    return v != null && v >= 1 && v <= WakeRuleBounds.maxRunsCeiling ? v : -1;
  }

  int? get _capMicros {
    final v = int.tryParse(_dollars.text.trim());
    if (v == null || v < 1) {
      return -1;
    }
    final micros = v * 1000000;
    return micros > WakeRuleLimits.maxCostCapMicros ? -1 : micros;
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final rule = widget.rule;
    final runs = _runs;
    final cap = _capMicros!;
    try {
      await ref
          .read(wakeRuleScheduleRepositoryProvider)
          .update(
            rule.workspaceId,
            rule.id,
            expiresAt: _newExpiry,
            maxRuns: runs != null && runs != rule.maxRuns ? runs : null,
            costCapMicros: cap != rule.costCapMicros ? cap : null,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = dispatchFailureMessage(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final expiry = _newExpiry;
    final runs = _runs;
    final cap = _capMicros;
    final valid = expiry != null && runs != -1 && cap != -1;
    Widget field(TextEditingController c, String label, String? error) =>
        CcTextField(
          controller: c,
          label: label,
          errorText: error,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
        );
    return CcDialog(
      title: l10n.scheduleExtendTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.scheduleExtendNow(
              workTimeLabel(context, widget.rule.expiresAt),
              workTimeLabel(context, _latest),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          field(
            _days,
            l10n.scheduleExtendDays,
            expiry == null && _days.text.trim().isNotEmpty
                ? l10n.scheduleExtendTooLong(workTimeLabel(context, _latest))
                : null,
          ),
          if (expiry != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.scheduleExpires(workTimeLabel(context, expiry))),
          ],
          const SizedBox(height: AppSpacing.md),
          field(
            _maxRuns,
            l10n.scheduleMaxRuns,
            runs == -1
                ? l10n.scheduleMaxRunsRange(WakeRuleBounds.maxRunsCeiling)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          field(
            _dollars,
            l10n.scheduleCostCap,
            cap == -1
                ? l10n.scheduleCostCapRange(
                    fmtMicros(WakeRuleLimits.maxCostCapMicros, locale: locale),
                  )
                : null,
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            CcAlert(variant: CcAlertVariant.danger, title: error),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          loading: _busy,
          onPressed: valid && !_busy ? _save : null,
          child: Text(l10n.scheduleExtend),
        ),
      ],
    );
  }
}

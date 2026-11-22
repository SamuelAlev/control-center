import 'package:cc_domain/cc_domain.dart' show OrchestrationCapRefusedException;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter/widgets.dart';

/// Asks for a new spending cap above both [capMicros] and what was spent so
/// far ([spentMicros]), in whole dollars, at most [maxMicros] when given.
/// Returns the new cap in micro-dollars, or null when cancelled. Used to
/// resume a goal that ran out of budget and a pipeline run held at its
/// orchestration budget.
///
/// With [submit], the dialog sends the raise itself and stays open on a
/// refusal: it shows the refusal's sentence, and when another raise landed
/// first (`orchestration_cap_changed`) it shows the fresh cap and checks the
/// next value against it.
Future<int?> showRaiseCapDialog(
  BuildContext context, {
  required String title,
  required int capMicros,
  required int spentMicros,
  int? maxMicros,
  Future<void> Function(int micros)? submit,
}) => showCcDialog<int>(
  context: context,
  builder: (_) => _RaiseCapDialog(
    title: title,
    capMicros: capMicros,
    spentMicros: spentMicros,
    maxMicros: maxMicros,
    submit: submit,
  ),
);

class _RaiseCapDialog extends StatefulWidget {
  const _RaiseCapDialog({
    required this.title,
    required this.capMicros,
    required this.spentMicros,
    required this.maxMicros,
    required this.submit,
  });

  final String title;
  final int capMicros;
  final int spentMicros;
  final int? maxMicros;
  final Future<void> Function(int micros)? submit;

  @override
  State<_RaiseCapDialog> createState() => _RaiseCapDialogState();
}

class _RaiseCapDialogState extends State<_RaiseCapDialog> {
  late int _cap = widget.capMicros;
  late final _dollars = TextEditingController(text: '${_suggested()}');
  bool _busy = false;
  String? _error;
  int? _freshCap;

  int _suggested() {
    final doubled = (widget.capMicros / 1000000).ceil() * 2;
    final max = widget.maxMicros;
    return max != null && doubled * 1000000 > max ? max ~/ 1000000 : doubled;
  }

  int get _floor => _cap > widget.spentMicros ? _cap : widget.spentMicros;

  @override
  void dispose() {
    _dollars.dispose();
    super.dispose();
  }

  int? get _entered {
    final dollars = int.tryParse(_dollars.text.trim());
    return dollars == null ? null : dollars * 1000000;
  }

  bool get _tooHigh {
    final micros = _entered;
    final max = widget.maxMicros;
    return micros != null && max != null && micros > max;
  }

  int? get _micros {
    final micros = _entered;
    return micros != null && micros > _floor && !_tooHigh ? micros : null;
  }

  Future<void> _confirm(int micros) async {
    final submit = widget.submit;
    if (submit == null) {
      Navigator.of(context).pop(micros);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _freshCap = null;
    });
    try {
      await submit(micros);
      if (mounted) {
        Navigator.of(context).pop(micros);
      }
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      final fresh =
          refusalKindOf(e) == OrchestrationCapRefusedException.changedKind
          ? _storedCap(e)
          : null;
      setState(() {
        _error = dispatchFailureMessage(l10n, e);
        if (fresh != null) {
          _cap = fresh;
          _freshCap = fresh;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  static int? _storedCap(Object error) {
    final data = error is RemoteRpcException ? error.data : null;
    final value = data is Map ? data['max_cost_micros'] : null;
    return value is num ? value.toInt() : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    String money(int micros) => fmtMicros(micros, locale: locale);
    final micros = _micros;
    final max = widget.maxMicros;
    return CcDialog(
      title: widget.title,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.raiseCapSpentOf(money(widget.spentMicros), money(_cap))),
          const SizedBox(height: AppSpacing.md),
          CcTextField(
            key: const ValueKey('raise-cap-dollars'),
            controller: _dollars,
            label: l10n.raiseCapNewCap,
            prefix: const Text(r'$'),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            errorText: micros != null
                ? null
                : _tooHigh && max != null
                ? l10n.raiseCapAtMost(money(max))
                : l10n.raiseCapMustExceed(money(_floor)),
            onChanged: (_) => setState(() {}),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            CcAlert(
              variant: CcAlertVariant.danger,
              title: error,
              description: _freshCap == null
                  ? null
                  : Text(l10n.raiseCapNowAt(money(_freshCap!))),
            ),
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
          onPressed: micros == null || _busy ? null : () => _confirm(micros),
          child: Text(l10n.raiseCapConfirm),
        ),
      ],
    );
  }
}

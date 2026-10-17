import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

class DisconnectCard extends StatefulWidget {
  const DisconnectCard({required this.onConfirm, super.key});
  final Future<void> Function() onConfirm;
  @override
  State<DisconnectCard> createState() => _DisconnectCardState();
}

class _DisconnectCardState extends State<DisconnectCard> {
  bool _armed = false;
  bool _busy = false;
  Object? _error;
  Future<void> _tap() async {
    if (!_armed) {
      setState(() => _armed = true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _armed = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcAlert(
      variant: CcAlertVariant.danger,
      title: _armed ? l10n.disconnectTapAgain : l10n.disconnectDevice,
      description: _error == null ? null : Text('$_error'),
      action: CcButton(
        size: CcButtonSize.lg,
        variant: CcButtonVariant.destructive,
        loading: _busy,
        onPressed: _busy ? null : _tap,
        child: Text(_armed ? l10n.confirm : l10n.disconnect),
      ),
    );
  }
}

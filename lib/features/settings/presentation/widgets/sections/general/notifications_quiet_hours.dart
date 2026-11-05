part of 'notifications_section.dart';

class _QuietHoursRow extends ConsumerWidget {
  const _QuietHoursRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config =
        ref.watch(_quietHoursProvider).asData?.value ??
        const QuietHoursConfig(
          enabled: false,
          start: TimeOfDay(hour: 22, minute: 0),
          end: TimeOfDay(hour: 8, minute: 0),
        );

    Future<void> update(QuietHoursConfig next) async {
      await ref.read(notificationPreferencesProvider).setQuietHours(next);
      ref.invalidate(_quietHoursProvider);
    }

    return SettingsRow(
      icon: AppIcons.moonStar,
      title: 'Quiet hours',
      subtitle: config.enabled
          ? 'Non-urgent notifications suppressed '
                '${_fmt(config.start)}–${_fmt(config.end)}.'
          : 'Non-urgent notifications deliver at any time.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.enabled) ...[
            _TimeInput(
              value: config.start,
              onChanged: (t) => update(
                QuietHoursConfig(
                  enabled: config.enabled,
                  start: t,
                  end: config.end,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('–'),
            ),
            _TimeInput(
              value: config.end,
              onChanged: (t) => update(
                QuietHoursConfig(
                  enabled: config.enabled,
                  start: config.start,
                  end: t,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          CcSwitch(
            value: config.enabled,
            onChanged: (v) => update(
              QuietHoursConfig(
                enabled: v,
                start: config.start,
                end: config.end,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

class _TimeInput extends StatefulWidget {
  const _TimeInput({required this.value, required this.onChanged});
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<_TimeInput> createState() => _TimeInputState();
}

class _TimeInputState extends State<_TimeInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(covariant _TimeInput old) {
    super.didUpdateWidget(old);
    final next = _fmt(widget.value);
    if (_ctrl.text != next) {
      _ctrl.text = next;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  void _commit(String v) {
    final parts = v.split(':');
    if (parts.length != 2) {
      return;
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return;
    }
    widget.onChanged(TimeOfDay(hour: h, minute: m));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: CcTextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        textStyle: CcTypography.caption.copyWith(
          color: context.ds.textTertiary,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
          LengthLimitingTextInputFormatter(5),
        ],
        onSubmitted: _commit,
        onEditingComplete: () => _commit(_ctrl.text),
      ),
    );
  }
}

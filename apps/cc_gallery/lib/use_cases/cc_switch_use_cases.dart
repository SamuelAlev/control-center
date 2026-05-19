import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcSwitch] — the design system's flat on/off toggle.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Inputs → CcSwitch` (from [CcSwitch] as the
/// `type` and the bracketed `path` segments). The builders return the component
/// directly — the gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Inputs';

/// The four resting states side by side: off, on, and the disabled treatment
/// of each. A null `onChanged` disables the control.
@widgetbook.UseCase(name: 'States', type: CcSwitch, path: _path)
Widget ccSwitchStatesUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: Wrap(
      spacing: 32,
      runSpacing: 24,
      children: [
        for (final entry in const [
          ('Off', false, true),
          ('On', true, true),
          ('Off · disabled', false, false),
          ('On · disabled', true, false),
        ])
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CcSwitch(
                value: entry.$2,
                onChanged: entry.$3 ? (_) {} : null,
                semanticLabel: entry.$1,
              ),
              const SizedBox(height: 8),
              Text(
                entry.$1,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            ],
          ),
      ],
    ),
  );
}

/// A realistic settings row — a labelled toggle the user can flip, mirroring how
/// the switch reads inside a workspace preferences panel.
@widgetbook.UseCase(name: 'Setting row', type: CcSwitch, path: _path)
Widget ccSwitchSettingRowUseCase(BuildContext context) {
  return const Center(child: _SettingRowDemo());
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcSwitch, path: _path)
Widget ccSwitchPlaygroundUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final label = context.knobs.string(
    label: 'Semantic label',
    initialValue: 'Auto-merge approved pull requests',
  );
  return Center(child: _PlaygroundDemo(enabled: enabled, semanticLabel: label));
}

class _SettingRowDemo extends StatefulWidget {
  const _SettingRowDemo();
  @override
  State<_SettingRowDemo> createState() => _SettingRowDemoState();
}

class _SettingRowDemoState extends State<_SettingRowDemo> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      width: 360,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-dispatch agents',
                  style: CcTypography.body.copyWith(color: t.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Run the assigned Claude agent the moment a ticket lands.',
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CcSwitch(
            value: _on,
            onChanged: (v) => setState(() => _on = v),
            semanticLabel: 'Auto-dispatch agents',
          ),
        ],
      ),
    );
  }
}

class _PlaygroundDemo extends StatefulWidget {
  const _PlaygroundDemo({required this.enabled, required this.semanticLabel});

  final bool enabled;
  final String semanticLabel;

  @override
  State<_PlaygroundDemo> createState() => _PlaygroundDemoState();
}

class _PlaygroundDemoState extends State<_PlaygroundDemo> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return CcSwitch(
      value: _on,
      onChanged: widget.enabled ? (v) => setState(() => _on = v) : null,
      semanticLabel: widget.semanticLabel,
    );
  }
}

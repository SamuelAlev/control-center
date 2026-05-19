import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcBanner] — a floating, ambient banner for a time-critical,
/// actionable event. Louder than an inline [CcAlert]: it lifts with the golden
/// float shadow and stacks into the shell's ambient rail. Intent reads from the
/// glyph, tint and copy together (never color alone) and the entrance
/// slide/fade collapses under reduced motion.

const _path = '[Components]/Feedback';

/// Every semantic variant stacked, each with a matching glyph and actions.
@widgetbook.UseCase(name: 'Variants', type: CcBanner, path: _path)
Widget ccBannerVariantsUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcBanner(
            title: 'Standup starting soon',
            body: 'Daily sync starts in 2 minutes.',
            icon: CcIcons.calendarClock,
            actions: [
              CcBannerAction(label: 'Join', onPressed: () {}, primary: true),
              CcBannerAction(label: 'Record & link', onPressed: () {}),
            ],
            onDismiss: () {},
          ),
          const SizedBox(height: 12),
          CcBanner(
            title: 'Calendar disconnected',
            body: 'Reconnect sam@usectrl.dev to resume syncing.',
            variant: CcBannerVariant.warning,
            icon: CcIcons.calendarX,
            actions: [
              CcBannerAction(
                label: 'Reconnect',
                onPressed: () {},
                primary: true,
              ),
            ],
            onDismiss: () {},
          ),
          const SizedBox(height: 12),
          CcBanner(
            title: 'Workspace seeded',
            body: 'The CEO agent created three starter tickets.',
            variant: CcBannerVariant.success,
            onDismiss: () {},
          ),
          const SizedBox(height: 12),
          CcBanner(
            title: 'Sync failed',
            body: 'GitHub returned 503 — retrying shortly.',
            variant: CcBannerVariant.danger,
            onDismiss: () {},
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcBanner, path: _path)
Widget ccBannerPlaygroundUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: 'Variant',
    options: CcBannerVariant.values,
    labelBuilder: (v) => v.name,
  );
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Standup starting soon',
  );
  final body = context.knobs.string(
    label: 'Body',
    initialValue: 'Daily sync starts in 2 minutes.',
  );
  final withPrimary = context.knobs.boolean(
    label: 'Primary action',
    initialValue: true,
  );
  final withSecondary = context.knobs.boolean(
    label: 'Secondary action',
    initialValue: true,
  );
  final dismissible = context.knobs.boolean(
    label: 'Dismissible',
    initialValue: true,
  );

  return Center(
    child: SizedBox(
      width: 560,
      child: CcBanner(
        variant: variant,
        title: title,
        body: body.isEmpty ? null : body,
        actions: [
          if (withPrimary)
            CcBannerAction(label: 'Join', onPressed: () {}, primary: true),
          if (withSecondary)
            CcBannerAction(label: 'Record & link', onPressed: () {}),
        ],
        onDismiss: dismissible ? () {} : null,
      ),
    ),
  );
}

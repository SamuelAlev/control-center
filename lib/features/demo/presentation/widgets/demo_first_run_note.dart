import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/demo/providers/demo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one-time note a demo visitor sees on their first frame.
///
/// It says the three things a visitor cannot find out for themselves and would
/// otherwise mis-read: the data is invented, the agents are scripted rather
/// than thinking, and the workspace is temporary. Saying so plainly is what
/// keeps the demo honest — a scripted run is indistinguishable from a real one
/// by design, which is exactly why it has to be disclosed.
///
/// Renders nothing against a real server, and nothing once dismissed.
class DemoFirstRunNote extends ConsumerWidget {
  /// Creates the note.
  const DemoFirstRunNote({super.key, this.sessionMinutes = 45});

  /// How long the visitor's workspace lives, in minutes.
  final int sessionMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isDemoServerProvider)) {
      return const SizedBox.shrink();
    }
    final dismissed = ref.watch(demoShellDismissalsProvider);
    if (dismissed.contains(kDemoFirstRunNoteId)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: CcBanner(
        title: l10n.demoFirstRunTitle,
        body: l10n.demoFirstRunBody(sessionMinutes),
        variant: CcBannerVariant.info,
        icon: CcIcons.sparkles,
        dismissLabel: l10n.demoFirstRunDismiss,
        onDismiss: () => ref
            .read(demoShellDismissalsProvider.notifier)
            .dismiss(kDemoFirstRunNoteId),
      ),
    );
  }
}

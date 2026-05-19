import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/update/web_update_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The web client's "a new version is available" banner: a quiet, dismissible
/// strip above the title bar that never reloads on its own — the user clicks
/// Refresh (web only; a no-op everywhere else).
///
/// This is real state, not decoration: the origin (Cloudflare, every push to
/// main) is a different build than the one this tab is running. While a
/// meeting is recording the Refresh button is disabled with the reason and a
/// queued refresh runs the moment recording stops — the only interruptible
/// moment is a safe one.
class WebUpdateBanner extends ConsumerStatefulWidget {
  /// Creates a [WebUpdateBanner].
  const WebUpdateBanner({super.key});

  @override
  ConsumerState<WebUpdateBanner> createState() => _WebUpdateBannerState();
}

class _WebUpdateBannerState extends ConsumerState<WebUpdateBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    // Arm the periodic + focus-driven checks from the shell's first frame
    // (the shell only exists once the app is connected — past the boot path).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(webUpdateProvider.notifier).start();
      }
    });
  }

  @override
  void dispose() {
    if (kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Tab re-focus: the cheapest high-signal poll trigger (a user returning
    // to a long-lived tab is the moment a deploy actually matters).
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(webUpdateProvider.notifier).checkForUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }
    final update = ref.watch(webUpdateProvider);
    final recording = ref.watch(
      meetingRecorderControllerProvider.select((s) => s.isRecording),
    );
    // Registered BEFORE any early return: the user has already consented to a
    // refresh that is merely waiting for the recording to stop, and if a poll
    // clears `updateAvailable` in the meantime an early return would unmount
    // the banner, drop this listener, and silently strand that consent.
    ref.listen<bool>(
      meetingRecorderControllerProvider.select((s) => s.isRecording),
      (previous, next) {
        if (previous == true && next == false) {
          ref.read(webUpdateProvider.notifier).onBusyConditionCleared();
        }
      },
    );
    // Stay mounted (invisibly) while a consented refresh is still queued.
    if (!update.updateAvailable) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(webUpdateProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: CcBanner(
        title: l10n.updateBannerTitle,
        body: recording ? l10n.updateBlockedRecording : null,
        variant: CcBannerVariant.info,
        actions: [
          CcBannerAction(
            label: l10n.updateBannerRefresh,
            primary: true,
            onPressed: () => controller.requestRefresh(busy: recording),
          ),
        ],
        onDismiss: controller.dismiss,
      ),
    );
  }
}

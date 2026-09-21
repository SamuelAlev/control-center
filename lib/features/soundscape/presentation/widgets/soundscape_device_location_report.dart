part of 'soundscape_controls.dart';

/// Asks for the device location when the soundscape settings open, not at
/// app boot. The shell mounts the audio host immediately; this widget only
/// exists inside the settings panel.
class _DeviceLocationReport extends ConsumerStatefulWidget {
  const _DeviceLocationReport();

  @override
  ConsumerState<_DeviceLocationReport> createState() =>
      _DeviceLocationReportState();
}

class _DeviceLocationReportState extends ConsumerState<_DeviceLocationReport> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final workspaceId = ref.read(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return;
      }
      unawaited(reportDeviceWeatherLocation(ref, workspaceId));
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

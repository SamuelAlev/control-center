import 'dart:async';

import 'package:cc_data/cc_data.dart' show RigImageView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/settings/rig_image_row.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The base images: what is on disk, what is missing, and how to get one.
///
/// Riverpod throughout — a `Future` + `FutureBuilder` + `setState` triple was
/// the odd one out on this page and could not express the one thing this
/// section actually needs: a download that keeps running after the RPC call
/// returns. `rig.downloadImage` starts the transfer and answers immediately
/// (a base image is hundreds of megabytes; holding an RPC call open for
/// minutes times the client out on a transfer that is working), so progress
/// is the growing `downloadedBytes` in `rig.images` and this section polls it
/// while anything is in flight.
class RigImagesSection extends ConsumerStatefulWidget {
  /// Creates a [RigImagesSection].
  const RigImagesSection({super.key});

  @override
  ConsumerState<RigImagesSection> createState() => _RigImagesSectionState();
}

class _RigImagesSectionState extends ConsumerState<RigImagesSection> {
  /// How often the image list is re-read while a download is in flight. Slow
  /// enough to be free, fast enough that a progress number looks alive.
  static const Duration _pollInterval = Duration(seconds: 2);

  /// Images whose download this session started, so the row can show progress
  /// before the server has written the first partial byte.
  final Set<String> _starting = {};
  String? _busyImageId;
  String? _error;
  Timer? _poll;

  /// Which row has its import field open, and what is typed in it.
  String? _importingId;
  final TextEditingController _pathController = TextEditingController();

  @override
  void dispose() {
    _poll?.cancel();
    _pathController.dispose();
    super.dispose();
  }

  /// Keeps a refresh timer running exactly while something is downloading.
  void _syncPolling(List<RigImageView> images) {
    final inFlight = images.any(_isDownloading);
    if (inFlight && _poll == null) {
      _poll = Timer.periodic(_pollInterval, (_) {
        if (mounted) {
          ref.invalidate(rigImagesProvider);
        }
      });
    } else if (!inFlight && _poll != null) {
      _poll!.cancel();
      _poll = null;
    }
  }

  bool _isDownloading(RigImageView image) =>
      !image.present &&
      (_starting.contains(image.id) || (image.downloadedBytes ?? 0) > 0);

  void _refresh() {
    ref.invalidate(rigImagesProvider);
    // The capability probe caches its result; a newly installed image changes
    // which surfaces can boot, so it has to be re-run.
    ref.invalidate(rigCapabilitiesProvider);
  }

  Future<void> _download(String imageId) async {
    setState(() {
      _error = null;
      _starting.add(imageId);
    });
    try {
      // Returns when the server ACCEPTS the download, not when it finishes.
      await ref.read(rigRepositoryProvider).downloadImage(imageId);
      _refresh();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _starting.remove(imageId);
        });
      }
    }
  }

  Future<void> _import(String imageId, String path) async {
    setState(() {
      _busyImageId = imageId;
      _error = null;
    });
    try {
      await ref.read(rigRepositoryProvider).importImage(imageId, path);
      if (mounted) {
        setState(() {
          _importingId = null;
          _pathController.clear();
        });
        _refresh();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busyImageId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final imagesAsync = ref.watch(rigImagesProvider);

    return SectionCard(
      label: l10n.rigsImagesTitle,
      child: imagesAsync.when(
        loading: () => const Center(child: CcSpinner()),
        error: (e, _) => Text(
          l10n.failedWithError('$e'),
          style: CcTypography.caption.copyWith(color: t.danger),
        ),
        data: (images) {
          // Scheduled out of the build pass: Riverpod 3 forbids modifying a
          // provider while the tree is building, and the poll invalidates one.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _syncPolling(images);
            }
          });
          if (images.isEmpty) {
            return Text(
              l10n.rigsUnsupportedServer,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.rigsImagesHint,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final image in images) ...[
                if (image != images.first)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: CcDivider(),
                  ),
                RigImageRow(
                  image: image,
                  busy: _busyImageId == image.id,
                  downloading: _isDownloading(image),
                  importing: _importingId == image.id,
                  pathController: _pathController,
                  onDownload: image.published
                      ? () => unawaited(_download(image.id))
                      : null,
                  onStartImport: () => setState(() {
                    _importingId = image.id;
                    _pathController.clear();
                  }),
                  onCancelImport: () => setState(() => _importingId = null),
                  onConfirmImport: () {
                    final path = _pathController.text.trim();
                    if (path.isNotEmpty) {
                      unawaited(_import(image.id, path));
                    }
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: CcTypography.caption.copyWith(color: t.danger),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

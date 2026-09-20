import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/gif_result.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kDebounceMs = 400;

/// Searches GIFs SERVER-SIDE over the `gif.search` RPC op (the thin client
/// holds no Klipy app key; the browser can't reach Klipy cross-origin). The
/// host runs Klipy with its configured key and returns flat `GifResult` maps.
Future<List<GifResult>> _searchGifs(RemoteRpcClient rpc, String query) async {
  final data = await rpc.call('gif.search', {'query': query});
  return _parseGifs(data);
}

/// Fetches trending GIFs SERVER-SIDE over the `gif.trending` RPC op.
Future<List<GifResult>> _trendingGifs(RemoteRpcClient rpc) async {
  final data = await rpc.call('gif.trending', const {});
  return _parseGifs(data);
}

List<GifResult> _parseGifs(Map<String, dynamic> data) => [
  for (final g in (data['gifs'] as List? ?? const []))
    GifResult.fromWire((g as Map).cast<String, dynamic>()),
];

/// Toolbar GIF picker: a [CcIconButton] that opens a search popover anchored
/// to the trigger.
///
/// The popover is driven by an explicit controller with `toggleOnTargetTap`
/// off so the icon button keeps its hover/press treatment and is the only
/// recognizer on the tap. Positioning rides [CcPopover] rather than a
/// root-[Overlay] insert whose coordinates were computed against a nested
/// overlay — that mismatch parked the panel at the top-left of the window.
class GifPickerPopover extends ConsumerStatefulWidget {
  /// Creates a [GifPickerPopover].
  const GifPickerPopover({super.key, required this.onGifSelected});

  /// Called with the chosen GIF; the popover then closes.
  final void Function(GifResult gif) onGifSelected;

  @override
  ConsumerState<GifPickerPopover> createState() => _GifPickerPopoverState();
}

class _GifPickerPopoverState extends ConsumerState<GifPickerPopover> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      targetAnchor: AlignmentDirectional.bottomEnd,
      followerAnchor: AlignmentDirectional.topEnd,
      overlayBuilder: (context, _) => _GifPickerBody(
        rpcClient: ref.read(rpcClientProvider),
        onSelected: (gif) {
          widget.onGifSelected(gif);
          _controller.hide();
        },
        onClose: _controller.hide,
      ),
      target: CcIconButton(
        variant: CcButtonVariant.ghost,
        size: CcButtonSize.sm,
        onPressed: _controller.toggle,
        icon: AppIcons.clapperboard,
        tooltip: l10n.addGif,
      ),
    );
  }
}

class _GifPickerBody extends StatefulWidget {
  const _GifPickerBody({
    required this.rpcClient,
    required this.onSelected,
    required this.onClose,
  });

  final RemoteRpcClient rpcClient;
  final void Function(GifResult gif) onSelected;
  final VoidCallback onClose;

  @override
  State<_GifPickerBody> createState() => _GifPickerBodyState();
}

class _GifPickerBodyState extends State<_GifPickerBody> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  List<GifResult> _gifs = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTrending());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gifs = await _trendingGifs(widget.rpcClient);
      if (!mounted) {
        return;
      }
      setState(() {
        _gifs = gifs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      unawaited(_loadTrending());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: _kDebounceMs), () async {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final gifs = await _searchGifs(widget.rpcClient, query.trim());
        if (!mounted) {
          return;
        }
        setState(() {
          _gifs = gifs;
          _loading = false;
        });
      } catch (e) {
        if (!mounted) {
          return;
        }
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.designSystem ?? DesignSystemTokens.light();
    // Preferred size; CcOverlayAnchor caps height to the gap beside the
    // trigger so a comment field near the bottom of the window still gets a
    // scrolling panel instead of a clipped one.
    return SizedBox(
      key: const Key('gif-picker-panel'),
      width: 440,
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                const Icon(AppIcons.clapperboard, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).searchGifs,
                  style: CcTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                CcIconButton(
                  icon: AppIcons.x,
                  tooltip: AppLocalizations.of(context).close,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CcTextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: _search,
              size: CcTextFieldSize.sm,
              hintText: AppLocalizations.of(context).searchGifsHint,
              prefix: const Icon(AppIcons.search, size: 16),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(DesignSystemTokens theme) {
    if (_loading && _gifs.isEmpty) {
      return const Center(child: CcSpinner());
    }
    if (_error != null && _gifs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.alertCircle, size: 32, color: theme.textTertiary),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).failedToLoadGifs,
                style: CcTypography.body.copyWith(color: theme.textTertiary),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: CcTypography.caption.copyWith(color: theme.textTertiary),
              ),
            ],
          ),
        ),
      );
    }
    if (_gifs.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noGifsFound,
          style: CcTypography.body.copyWith(color: theme.textTertiary),
        ),
      );
    }
    return GridView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _gifs.length,
      itemBuilder: (context, index) {
        final gif = _gifs[index];
        return CcTappable(
          onPressed: () => widget.onSelected(gif),
          borderRadius: BorderRadius.circular(8),
          builder: (context, states) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CcImageFade(
                  // ~131px square tile; cap the decode. The proxy streams
                  // animated GIFs through untouched so the animation survives —
                  // only the in-memory per-frame decode shrinks.
                  image: ResizeImage(
                    DiskCachedNetworkImage(
                      MediaProxyScope.urlOf(context, gif.previewUrl),
                    ),
                    width: (131 * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                  ),
                  fit: BoxFit.cover,
                  // Quiet surface while the first frame resolves — no spinner,
                  // which reads as "stuck" on a grid of tiny tiles.
                  placeholder: ColoredBox(
                    color: theme.textTertiary.withValues(alpha: 0.1),
                  ),
                  errorBuilder: (_, _) => Container(
                    color: theme.textTertiary.withValues(alpha: 0.1),
                    child: Icon(
                      AppIcons.imageOff,
                      color: theme.textTertiary,
                      size: 24,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderSecondary,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

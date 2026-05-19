import 'package:cc_rpc/cc_rpc.dart' show ServerConnectionPhase;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:control_center/core/providers/shutdown_progress_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen overlay rendered while the local `cc_server` is shutting down.
///
/// Fed entirely by [shutdownProgressProvider]: the server streams a
/// `server/shutdown_progress` frame per service as it tears it down, and this
/// overlay renders the ordered list ticking from "in progress" → "done". When
/// no frame has arrived yet (e.g. an unbuilt binary or a remote server) it
/// falls back to a single indeterminate "shutting down" row so the overlay is
/// never empty. Mounted as the topmost child of the root [Stack] in
/// `ControlCenterApp`, above every route and the toast overlay.
///
/// Renders nothing while no shutdown is active.
class ServerShutdownOverlay extends ConsumerWidget {
  /// Creates a [ServerShutdownOverlay].
  const ServerShutdownOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shutdownProgressProvider);
    if (!state.active) {
      return const SizedBox.shrink();
    }
    // `shutdownProgressProvider.active` is never cleared once a shutdown starts,
    // so gate on the live connection too: the instant the server is actually
    // gone (the local server exited or the transport dropped — the phase leaves
    // `connected`/`connecting`), stop covering the app so the reconnect/connect
    // screen underneath is reachable, instead of a shutdown dialog that never
    // goes away. A null status (no supervisor wired — tests/pre-boot) keeps the
    // overlay up, matching the prior behaviour.
    final phase = ref.watch(
      serverConnectionStatusProvider.select((s) => s.value?.phase),
    );
    if (phase == ServerConnectionPhase.reconnecting ||
        phase == ServerConnectionPhase.closed ||
        phase == ServerConnectionPhase.identityMismatch) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final family = context.ccTheme?.fontFamily;
    return ExcludeSemantics(
      // Don't announce the whole app behind the scrim.
      child: ColoredBox(
        // A dimming scrim — darker than the card so the white/dark card stands
        // out.  Using fgPrimary (near-black in light, near-white in dark) at
        // low alpha creates a veil that clearly separates the floating card
        // from the app surface behind it.
        color: t.fgPrimary.withValues(alpha: 0.32),
        child: DefaultTextStyle(
          // Off-Material overlays must supply their own text style (AGENTS.md):
          // the only ambient DefaultTextStyle here is WidgetsApp's error
          // fallback (48px, double yellow underline). Individual Text widgets
          // have explicit styles, but this prevents any leakage.
          style: CcFonts.ui(
            family: family,
            textStyle: CcTypography.body.copyWith(
              color: t.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: _ShutdownCard(state: state, l10n: l10n),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShutdownCard extends StatelessWidget {
  const _ShutdownCard({required this.state, required this.l10n});

  final ShutdownProgressState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final family = context.ccTheme?.fontFamily;
    final services = state.services;
    final done = services
        .where((s) => s.status == ShutdownServiceStatus.done)
        .length;
    final total = services.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.borderPrimary),
        boxShadow: AppShadows.golden,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Spinner(color: t.fgSecondary, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.shutdownTitle,
                style: CcFonts.ui(
                  family: family,
                  textStyle: CcTypography.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.shutdownSubtitle,
            style: CcFonts.ui(
              family: family,
              textStyle: CcTypography.body.copyWith(
                fontSize: 13,
                color: t.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressBar(done: done, total: total),
          const SizedBox(height: AppSpacing.md),
          if (services.isEmpty)
            _ServiceRow(label: l10n.shutdownTitle, kind: _RowKind.active)
          else
            // The rows are inlined directly into this min-size Column (rather
            // than a Flexible/ListBody) so the card is intrinsically sized and
            // never requires a bounded height. A vertical Flexible throws under
            // unbounded-height constraints, which the tree can transiently hit
            // while the app tears down on server quit — leaving this subtree
            // un-sized and spamming "Cannot hit test a render box with no size"
            // every frame. The shutdown service list is short, so it will not
            // overflow.
            for (final entry in services.indexed)
              _ServiceRow(
                label: _label(entry.$2.id),
                kind: _kindFor(services, entry.$1),
              ),
        ],
      ),
    );
  }

  /// The first not-yet-`done` service is the one currently shutting down.
  _RowKind _kindFor(List<ShutdownService> services, int index) {
    if (services[index].status == ShutdownServiceStatus.done) {
      return _RowKind.done;
    }
    final current =
        index == 0 || services[index - 1].status == ShutdownServiceStatus.done;
    return current ? _RowKind.active : _RowKind.pending;
  }

  String _label(String id) => switch (id) {
    'approvals' => l10n.shutdownServiceApprovals,
    'backgroundJobs' => l10n.shutdownServiceBackgroundJobs,
    'scheduler' => l10n.shutdownServiceScheduler,
    'calendar' => l10n.shutdownServiceCalendar,
    'weather' => l10n.shutdownServiceWeather,
    'soundscape' => l10n.shutdownServiceSoundscape,
    'meetings' => l10n.shutdownServiceMeetings,
    'voiceModels' => l10n.shutdownServiceVoiceModels,
    'networking' => l10n.shutdownServiceNetworking,
    'presence' => l10n.shutdownServicePresence,
    'dataSync' => l10n.shutdownServiceDataSync,
    'deviceRelay' => l10n.shutdownServiceDeviceRelay,
    'mcpConnections' => l10n.shutdownServiceMcpConnections,
    'codeEditors' => l10n.shutdownServiceCodeEditors,
    _ => id,
  };
}

enum _RowKind { done, active, pending }

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.label, required this.kind});

  final String label;
  final _RowKind kind;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final family = context.ccTheme?.fontFamily;
    final Color iconColor;
    final Color textColor;
    switch (kind) {
      case _RowKind.done:
        iconColor = t.fgSuccessPrimary;
        textColor = t.textTertiary;
      case _RowKind.active:
        iconColor = t.fgSecondary;
        textColor = t.textPrimary;
      case _RowKind.pending:
        iconColor = t.fgTertiary;
        textColor = t.textTertiary;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Center(
              child: switch (kind) {
                _RowKind.done => Icon(
                  AppIcons.check,
                  size: 14,
                  color: iconColor,
                ),
                _RowKind.active => _Spinner(color: iconColor, size: 13),
                _RowKind.pending => _Dot(color: iconColor),
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcFonts.ui(
                family: family,
                textStyle: CcTypography.body.copyWith(
                  fontSize: 12.5,
                  color: textColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Linear `done / total` bar. When the server hasn't reported the list yet
/// (`total == 0`) it shows a single animated indeterminate sweep.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fraction = total > 0 ? (done / total).clamp(0.0, 1.0) : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 3,
        child: Stack(
          children: [
            ColoredBox(color: t.borderPrimary, child: const SizedBox.expand()),
            if (fraction != null)
              FractionallySizedBox(
                widthFactor: fraction,
                child: ColoredBox(
                  color: t.fgSuccessPrimary,
                  child: const SizedBox.expand(),
                ),
              )
            else
              const _IndeterminateSweep(),
          ],
        ),
      ),
    );
  }
}

/// A short translating highlight for the pre-`begin` indeterminate state.
class _IndeterminateSweep extends StatefulWidget {
  const _IndeterminateSweep();

  @override
  State<_IndeterminateSweep> createState() => _IndeterminateSweepState();
}

class _IndeterminateSweepState extends State<_IndeterminateSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inherited-widget lookups (CcMotion → CcTheme) can't happen in initState.
    if (CcMotion.reduced(context)) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final w = (maxW * 0.35).clamp(8.0, double.infinity);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final start = (_controller.value * (maxW + w)) - w;
            return Stack(
              children: [
                Positioned(
                  left: start,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: ColoredBox(
                    color: t.fgSecondary,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A rotating `loaderCircle`. Holds still under reduced motion.
class _Spinner extends StatefulWidget {
  const _Spinner({required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inherited-widget lookups (CcMotion → CcTheme) can't happen in initState.
    if (CcMotion.reduced(context)) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        AppIcons.loaderCircle,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart'
    show ServerConnectionPhase, ServerConnectionStatus;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:control_center/core/providers/server_switch_provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide modal shown while the server connection is lost.
///
/// While the supervisor is reconnecting it offers "Try to reconnect" (skips
/// the backoff) and "Go to sign-in" (leaves for the platform's server sign-in
/// screen), with a countdown to the next automatic attempt. It goes away on its
/// own once a reconnect succeeds. When retrying cannot help (the server
/// rejected this device or presented another identity) only sign-in is left.
///
/// A drop that heals within [graceDelay] (a path failover, a local respawn)
/// never shows it. Mounted beside `ServerShutdownOverlay` in
/// `ControlCenterApp`'s root [Stack]; that overlay steps aside as soon as the
/// connection drops, so a stopping server hands off from one to the other.
class ServerDisconnectedOverlay extends ConsumerStatefulWidget {
  /// Creates a [ServerDisconnectedOverlay].
  const ServerDisconnectedOverlay({super.key});

  /// How long a drop must last before the dialog shows.
  static const graceDelay = Duration(milliseconds: 1500);

  @override
  ConsumerState<ServerDisconnectedOverlay> createState() =>
      _ServerDisconnectedOverlayState();
}

enum _Kind { lost, ended }

class _ServerDisconnectedOverlayState
    extends ConsumerState<ServerDisconnectedOverlay> {
  /// Runs from the drop until [ServerDisconnectedOverlay.graceDelay] passes.
  Timer? _grace;
  bool _graceElapsed = false;

  /// Re-renders the countdown to the next attempt while reconnecting.
  Timer? _ticker;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      serverConnectionStatusProvider,
      (_, next) => _onStatus(next.value),
      fireImmediately: true,
    );
  }

  void _onStatus(ServerConnectionStatus? status) {
    if (status?.phase == ServerConnectionPhase.reconnecting) {
      _grace ??= Timer(ServerDisconnectedOverlay.graceDelay, () {
        if (mounted) {
          setState(() => _graceElapsed = true);
        }
      });
      _ticker ??= Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _grace?.cancel();
      _grace = null;
      _graceElapsed = false;
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _grace?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  _Kind? _kindOf(ServerConnectionStatus? status) {
    if (status == null) {
      return null;
    }
    if (status.phase == ServerConnectionPhase.identityMismatch ||
        status.authenticationRejected) {
      return _Kind.ended;
    }
    if (status.phase == ServerConnectionPhase.reconnecting && _graceElapsed) {
      return _Kind.lost;
    }
    return null;
  }

  Future<void> _signIn(Future<void> Function() returnToSignIn) async {
    setState(() => _leaving = true);
    try {
      await returnToSignIn();
    } on Object catch (e) {
      AppLog.w('connection', 'returning to the sign-in screen failed: $e');
      if (mounted) {
        setState(() => _leaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(serverConnectionStatusProvider).value;
    final kind = _kindOf(status);
    if (status == null || kind == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final family = context.ccTheme?.fontFamily;
    final supervisor = ref.watch(serverConnectionSupervisorProvider);
    final returnToSignIn = ref.watch(returnToServerSignInProvider);

    final nextAttemptAt = status.nextAttemptAt;
    final secondsLeft = nextAttemptAt == null
        ? 0
        : (nextAttemptAt.difference(DateTime.now()).inMilliseconds / 1000)
              .ceil();
    final attempting = kind == _Kind.lost && secondsLeft <= 0;

    TextStyle style(TextStyle base, Color color) => CcFonts.ui(
      family: family,
      textStyle: base.copyWith(color: color, decoration: TextDecoration.none),
    );

    final String body;
    if (kind == _Kind.lost) {
      body = l10n.serverLostBody;
    } else if (status.phase == ServerConnectionPhase.identityMismatch) {
      body = l10n.serverSetupErrorIdentityMismatch;
    } else {
      body = l10n.serverSetupErrorAuthRejected;
    }

    final actions = <Widget>[
      if (returnToSignIn != null)
        CcButton(
          variant: kind == _Kind.lost
              ? CcButtonVariant.secondary
              : CcButtonVariant.primary,
          loading: _leaving,
          autofocus: kind == _Kind.ended,
          onPressed: _leaving ? null : () => unawaited(_signIn(returnToSignIn)),
          child: Text(l10n.serverLostSignIn),
        ),
      if (kind == _Kind.lost && supervisor != null)
        CcButton(
          icon: AppIcons.refreshCw,
          loading: attempting,
          autofocus: true,
          onPressed: attempting || _leaving ? null : supervisor.reconnectNow,
          child: Text(l10n.serverLostReconnect),
        ),
    ];

    final title = kind == _Kind.lost
        ? l10n.serverLostTitle
        : l10n.serverEndedTitle;
    return ColoredBox(
      // Same veil as the shutdown overlay; it also swallows every pointer
      // event, so the app underneath cannot be used while it is offline.
      color: t.fgPrimary.withValues(alpha: 0.32),
      child: DefaultTextStyle(
        // Root-overlay content: never inherit WidgetsApp's error fallback.
        style: style(CcTypography.body, t.textPrimary),
        child: BlockSemantics(
          child: Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FocusScope(
                  autofocus: true,
                  child: Semantics(
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: title,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
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
                              Icon(
                                kind == _Kind.lost
                                    ? AppIcons.unplug
                                    : AppIcons.shieldAlert,
                                size: 16,
                                color: kind == _Kind.lost
                                    ? t.fgSecondary
                                    : t.fgErrorPrimary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Semantics(
                                  liveRegion: true,
                                  header: true,
                                  child: Text(
                                    title,
                                    style: style(
                                      CcTypography.label.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      t.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            body,
                            style: style(
                              CcTypography.body.copyWith(fontSize: 13),
                              t.textSecondary,
                            ),
                          ),
                          if (kind == _Kind.lost) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              attempting
                                  ? l10n.serverLostRetrying
                                  : l10n.serverLostNextAttempt(secondsLeft),
                              style: style(
                                CcTypography.body.copyWith(fontSize: 12.5),
                                t.textTertiary,
                              ),
                            ),
                          ],
                          if (actions.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: actions,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/connect/domain/value_objects/connect_health_error.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/connect/presentation/settings/connect_server_actions.dart';
import 'package:control_center/features/connect/presentation/widgets/connect_health.dart';
import 'package:control_center/features/connect/presentation/widgets/connect_mode_options.dart';
import 'package:control_center/features/connect/providers/connect_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Single sign-on: how this server runs provider
/// sign-ins through Control Center Connect.
///
/// Server-owner only. It is absent for anyone else, exactly like the server
/// refuses them every `connect.*` op ([watchConnectSectionApplies]). A
/// `CC_CONNECT_URL` in the server's environment pins the mode, and the card
/// says so instead of offering choices the server will refuse.
class ConnectSection extends ConsumerWidget {
  /// Creates a [ConnectSection].
  const ConnectSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(connectStatusProvider);
    if (async.hasError && !async.hasValue) {
      return SectionCard(
        label: l10n.connectTitle,
        child: CcAlert(
          title: l10n.failedWithError('${async.error}'),
          variant: CcAlertVariant.danger,
        ),
      );
    }
    final status = async.value;
    if (status == null) {
      return const SizedBox.shrink();
    }
    return ConnectStatusCard(status: status);
  }
}

/// Whether [ConnectSection] has anything to show: the server's Connect status
/// (null for anyone but the server owner), or why it could not be read.
/// Nothing while the first answer is on its way.
bool watchConnectSectionApplies(WidgetRef ref) {
  final async = ref.watch(connectStatusProvider);
  return async.value != null || (async.hasError && !async.hasValue);
}

/// The Connect card for one [status]; split from [ConnectSection] so tests
/// can pump a status without a server.
class ConnectStatusCard extends ConsumerStatefulWidget {
  /// Creates a [ConnectStatusCard].
  const ConnectStatusCard({super.key, required this.status});

  /// What the server reported.
  final ConnectStatus status;

  @override
  ConsumerState<ConnectStatusCard> createState() => _ConnectStatusCardState();
}

class _ConnectStatusCardState extends ConsumerState<ConnectStatusCard> {
  late final _url = TextEditingController(
    text: widget.status.mode == ConnectModeSetting.custom
        ? widget.status.url
        : '',
  );
  ConnectModeSetting? _draft;
  String? _urlError;
  bool _applying = false;
  bool _confirming = false;

  ConnectModeSetting? get _selected =>
      _draft ??
      (widget.status.mode == ConnectModeSetting.unset
          ? null
          : widget.status.mode);

  bool get _dirty {
    final selected = _selected;
    if (selected == null) {
      return false;
    }
    if (selected != widget.status.mode) {
      return true;
    }
    return selected == ConnectModeSetting.custom &&
        _url.text.trim() != widget.status.url;
  }

  @override
  void initState() {
    super.initState();
    // The Apply button follows what is typed, not just what is selected.
    _url.addListener(_onUrlChanged);
  }

  void _onUrlChanged() => setState(() {});

  @override
  void dispose() {
    _url
      ..removeListener(_onUrlChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() op, {
    required void Function(bool) busy,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() => busy(true));
    try {
      await op();
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => busy(false));
      }
    }
  }

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context);
    final mode = _selected;
    if (mode == null) {
      return;
    }
    final url = _url.text.trim();
    if (mode == ConnectModeSetting.custom && !isConnectServerUrl(url)) {
      setState(() => _urlError = l10n.connectCustomUrlInvalid);
      return;
    }
    setState(() => _urlError = null);
    await _run(() async {
      await ConnectSettingsActions(
        ref,
      ).configure(mode, url: mode == ConnectModeSetting.custom ? url : null);
      if (mounted) {
        setState(() => _draft = null);
      }
    }, busy: (v) => _applying = v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = widget.status;
    final off = status.mode == ConnectModeSetting.off;
    final healthy = status.usable && status.error == ConnectHealthError.none;
    return SectionCard(
      label: l10n.connectTitle,
      subtitle: Text(l10n.connectDescription),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSummary(
            facts: [
              SettingsFact(
                label: l10n.connectFactMode,
                value: connectModeLabel(l10n, status.mode),
                mono: false,
              ),
              SettingsFact(
                label: l10n.connectFactHealth,
                value: off || status.mode == ConnectModeSetting.unset
                    ? l10n.connectHealthOff
                    : healthy
                    ? l10n.connectHealthOk
                    : l10n.connectHealthDown,
                tone: off || status.mode == ConnectModeSetting.unset
                    ? null
                    : healthy
                    ? CcStatusTone.positive
                    : CcStatusTone.negative,
                mono: false,
              ),
              if (status.epoch != null)
                SettingsFact(
                  label: l10n.connectFactEpoch,
                  value: '${status.epoch}',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (status.locked) ...[
            CcAlert(title: l10n.connectLocked, variant: CcAlertVariant.info),
            const SizedBox(height: AppSpacing.md),
          ],
          ConnectHealthAlerts(
            error: status.error,
            stale: status.stale,
            pendingPins: status.pendingPins,
            confirming: _confirming,
            onConfirmPins: () => unawaited(
              _run(
                () => ConnectSettingsActions(ref).confirmPins(),
                busy: (v) => _confirming = v,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsGroup(
            title: l10n.connectFactMode,
            gap: AppSpacing.xs,
            children: [
              ConnectModeOptions(
                selected: _selected,
                enabled: !status.locked && !_applying,
                urlController: _url,
                urlError: _urlError,
                onSelected: (mode) => setState(() {
                  _draft = mode;
                  _urlError = null;
                }),
                onUrlSubmitted: (_) => unawaited(_apply()),
              ),
              if (_dirty && !status.locked)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CcButton(
                    size: CcButtonSize.sm,
                    loading: _applying,
                    onPressed: _applying ? null : () => unawaited(_apply()),
                    child: Text(l10n.apply),
                  ),
                ),
            ],
          ),
          if (status.lanes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SettingsGroup(
              title: l10n.connectLanesTitle,
              description: l10n.connectLanesDescription,
              gap: AppSpacing.xs,
              children: [
                ConnectLaneList(
                  rows: [
                    for (final lane in status.lanes)
                      ConnectLaneRow.fromServer(l10n, lane),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ConnectServerActions(status: status),
        ],
      ),
    );
  }
}

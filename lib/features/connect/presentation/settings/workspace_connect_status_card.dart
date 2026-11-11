import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/features/connect/domain/value_objects/connect_health_error.dart';
import 'package:cc_domain/features/connect/domain/value_objects/workspace_connect_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/connect/presentation/settings/workspace_connect_parts.dart';
import 'package:control_center/features/connect/presentation/widgets/connect_health.dart';
import 'package:control_center/features/connect/presentation/widgets/connect_mode_options.dart';
import 'package:control_center/features/connect/providers/workspace_connect_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace Connect card for one [status]; split from
/// `WorkspaceConnectSection` so tests can pump a status without a server.
class WorkspaceConnectStatusCard extends ConsumerStatefulWidget {
  /// Creates a [WorkspaceConnectStatusCard].
  const WorkspaceConnectStatusCard({
    super.key,
    required this.workspaceId,
    required this.status,
    required this.canEdit,
  });

  /// The workspace whose choice this is.
  final String workspaceId;

  /// What the server reported.
  final WorkspaceConnectStatus status;

  /// Whether the reader is a workspace admin.
  final bool canEdit;

  @override
  ConsumerState<WorkspaceConnectStatusCard> createState() =>
      _WorkspaceConnectStatusCardState();
}

class _WorkspaceConnectStatusCardState
    extends ConsumerState<WorkspaceConnectStatusCard> {
  late final _url = TextEditingController(
    text: widget.status.mode == WorkspaceConnectMode.custom
        ? widget.status.url
        : '',
  );
  WorkspaceConnectMode? _draft;
  String? _urlError;
  bool _applying = false;
  bool _confirming = false;
  bool _testing = false;

  WorkspaceConnectMode get _selected => _draft ?? widget.status.mode;

  bool get _dirty {
    if (_selected != widget.status.mode) {
      return true;
    }
    return _selected == WorkspaceConnectMode.custom &&
        _url.text.trim() != widget.status.url;
  }

  WorkspaceConnectStatusNotifier get _notifier =>
      ref.read(workspaceConnectStatusProvider(widget.workspaceId).notifier);

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

  Future<T?> _run<T>(
    Future<T> Function() op, {
    required void Function(bool) busy,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() => busy(true));
    try {
      return await op();
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => busy(false));
      }
    }
  }

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context);
    final mode = _selected;
    final url = _url.text.trim();
    if (mode == WorkspaceConnectMode.custom && !isHttpsConnectUrl(url)) {
      setState(() => _urlError = l10n.connectCustomUrlInvalid);
      return;
    }
    setState(() => _urlError = null);
    // Another app means everyone signs in again: say so before doing it.
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.workspaceConnectSwitchTitle,
      message: l10n.workspaceConnectSwitchBody,
      confirmLabel: l10n.workspaceConnectSwitchAction,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final status = await _run(
      () => _notifier.set(
        mode,
        url: mode == WorkspaceConnectMode.custom ? url : null,
      ),
      busy: (v) => _applying = v,
    );
    if (status != null && mounted) {
      setState(() => _draft = null);
    }
  }

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    final status = await _run(_notifier.test, busy: (v) => _testing = v);
    if (status == null || !mounted) {
      return;
    }
    final ok = status.health == WorkspaceConnectHealth.ok;
    CcToastScope.maybeOf(context)?.show(
      ok
          ? l10n.connectTestOk
          : status.error == ConnectHealthError.none
          ? l10n.connectHealthDown
          : connectHealthMessage(l10n, status.error),
      variant: ok ? CcToastVariant.success : CcToastVariant.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final status = widget.status;
    final canEdit = widget.canEdit;
    final installId = status.installId;
    return SectionCard(
      label: l10n.connectTitle,
      subtitle: Text(l10n.workspaceConnectDescription),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkspaceConnectFacts(status: status),
          const SizedBox(height: AppSpacing.lg),
          if (status.locked) ...[
            CcAlert(
              title: l10n.workspaceConnectLocked,
              variant: CcAlertVariant.info,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ConnectHealthAlerts(
            error: status.error,
            stale: status.stale,
            pendingPins: status.pendingPins,
            confirming: _confirming,
            onConfirmPins: canEdit
                ? () => unawaited(
                    _run(_notifier.confirmPins, busy: (v) => _confirming = v),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsGroup(
            title: l10n.connectFactMode,
            gap: AppSpacing.xs,
            children: [
              ConnectChoiceList<WorkspaceConnectMode>(
                choices: workspaceConnectChoices(
                  l10n,
                  status,
                  canEdit: canEdit && !_applying,
                ),
                selected: _selected,
                onSelected: (mode) => setState(() {
                  _draft = mode;
                  _urlError = null;
                }),
                urlChoice: WorkspaceConnectMode.custom,
                urlController: _url,
                urlError: _urlError,
                urlHelper: (_) => l10n.workspaceConnectCustomUrlHint,
                onUrlSubmitted: (_) => unawaited(_apply()),
              ),
              if (!canEdit)
                Text(
                  l10n.settingsWorkspaceAdminOnly,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                )
              else if (_dirty)
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
              description: l10n.workspaceConnectLanesDescription,
              gap: AppSpacing.xs,
              children: [
                ConnectLaneList(rows: workspaceConnectLaneRows(l10n, status)),
              ],
            ),
          ],
          if (canEdit &&
              installId != null &&
              status.effectiveMode.usesConnect) ...[
            const SizedBox(height: AppSpacing.lg),
            WorkspaceConnectAdminActions(
              installId: installId,
              testing: _testing,
              onTest: () => unawaited(_test()),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/push/push_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Include in SettingsScreen's ListView; does not request permission on mount.
class PushSettingsSection extends ConsumerStatefulWidget {
  const PushSettingsSection({super.key});

  @override
  ConsumerState<PushSettingsSection> createState() =>
      _PushSettingsSectionState();
}

class _PushSettingsSectionState extends ConsumerState<PushSettingsSection>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Browser/site permissions may have changed while Settings was hidden.
      // Re-read status only; never request a permission outside a tap.
      ref.invalidate(remotePushStatusProvider);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _failed =
              error is! StateError || error.message != 'push.permissionDenied',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(remotePushStatusProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.pushTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.pushIntro,
          style: TextStyle(fontSize: 13, color: tokens.fgSecondary),
        ),
        const SizedBox(height: 12),
        switch (state) {
          AsyncData(:final value) => _controls(value, l10n, tokens),
          AsyncError() => Column(
            children: [
              Text(
                l10n.pushError,
                style: TextStyle(color: tokens.textErrorPrimary),
              ),
              _button(
                l10n.retry,
                () => ref.invalidate(remotePushStatusProvider),
              ),
            ],
          ),
          _ => Text(
            l10n.pushLoading,
            style: TextStyle(color: tokens.fgSecondary),
          ),
        },
        if (_failed)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: Text(
              l10n.pushError,
              style: TextStyle(color: tokens.textErrorPrimary),
            ),
          ),
      ],
    );
  }

  Widget _controls(
    RemotePushStatus status,
    AppLocalizations l10n,
    DesignSystemTokens t,
  ) {
    final reason = status.unsupportedReason;
    final permissionAvailable =
        status.permission == 'default' || status.permission == 'granted';
    final note = switch (reason) {
      'secure' => l10n.pushSecureOrigin,
      'install' => l10n.pushInstallIos,
      'unsupported' => l10n.pushUnsupported,
      _ when status.permission == 'denied' => l10n.pushDenied,
      _ when !permissionAvailable => l10n.pushUnsupported,
      _
          when status.enabled &&
              (!status.browserSubscribed || status.permission != 'granted') =>
        l10n.pushResubscribe,
      _ => status.enabled ? l10n.pushStatusEnabled : l10n.pushStatusDisabled,
    };
    final groups = <(String, Set<String>)>[
      (l10n.pushCategoryAgents, {'agentRunCompleted', 'agentAwaitingInput'}),
      (l10n.pushCategoryMessages, {'newMessage'}),
      (
        l10n.pushCategoryPullRequests,
        {
          'pullRequestPublished',
          'prMerged',
          'prMentioned',
          'reviewRequested',
          'reviewStale',
          'prMergeReadiness',
          'prReviewDecision',
          'prChecksStatus',
          'prThreadActivity',
        },
      ),
      (l10n.pushCategoryTickets, {'ticketAssigned', 'ticketStatusChanged'}),
      (l10n.pushCategoryCalendar, {'meetingStartsSoon', 'calendarAuthExpired'}),
      (l10n.pushCategoryMachines, {'rigStatusChanged'}),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(note, style: TextStyle(fontSize: 13, color: t.fgSecondary)),
        const SizedBox(height: 8),
        _button(
          status.enabled ? l10n.pushResubscribe : l10n.pushEnable,
          reason != null || !permissionAvailable || _busy
              ? null
              : () => _run(() => enableRemotePush(ref, status)),
        ),
        if (reason == null && status.permission == 'denied')
          _button(
            l10n.refresh,
            _busy ? null : () => ref.invalidate(remotePushStatusProvider),
          ),
        if (status.enabled) ...[
          _button(
            l10n.pushDisable,
            _busy ? null : () => _run(() => disableRemotePush(ref)),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: CcChip(
              label: l10n.pushQuiet,
              selected: status.quiet,
              onPressed:
                  _busy ||
                      reason != null ||
                      status.permission != 'granted' ||
                      !status.browserSubscribed
                  ? null
                  : () => _run(
                      () => enableRemotePush(ref, status, quiet: !status.quiet),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.pushCategories,
            style: TextStyle(fontSize: 13, color: t.textPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, keys) in groups)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: CcChip(
                    label: label,
                    selected: status.categories.containsAll(keys),
                    onPressed:
                        _busy ||
                            reason != null ||
                            status.permission != 'granted' ||
                            !status.browserSubscribed
                        ? null
                        : () {
                            final next = {...status.categories};
                            status.categories.containsAll(keys)
                                ? next.removeAll(keys)
                                : next.addAll(keys);
                            _run(
                              () => enableRemotePush(
                                ref,
                                status,
                                categories: next,
                              ),
                            );
                          },
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _button(String label, VoidCallback? onPressed) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
    child: CcButton(onPressed: onPressed, child: Text(label)),
  );
}

// The rig browser's toolbar: the same chrome the in-app browser tab has —
// back / forward / reload, an address bar, the guest's display size — driven
// over rig.act against the enclosed Chromium. It is the ONLY chrome the
// browser surface has (no header row): closing the tab shuts the machine
// down.
//
// The address field is fed two ways. PUSHED: `rig.current_url` rides the rig
// row watch, so a link the person clicked in the canvas, a script redirect or
// an agent's navigate all land here unasked. PULLED: `rig.browserState`
// reads the session history, which is the only place back/forward
// reachability exists. While the field has focus it is the user's draft and
// nothing overwrites it.
library;

import 'dart:async';

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/browser_permission.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_url.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_browser_toolbar_trailing.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Back / forward / reload / address bar for a live browser rig.
class RigBrowserToolbar extends ConsumerStatefulWidget {
  /// Creates a [RigBrowserToolbar].
  const RigBrowserToolbar({
    super.key,
    required this.workspaceId,
    required this.rig,
    required this.onNetworkSecurity,
    this.networkRestarting = false,
    this.audioOn = false,
    this.onToggleAudio,
    this.microphoneOn = false,
    this.onToggleMicrophone,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The browser rig being driven.
  final RigView rig;

  /// Opens the per-session network security setting.
  final VoidCallback onNetworkSecurity;

  /// Whether the unrestricted replacement is being started.
  final bool networkRestarting;

  /// Whether guest audio currently plays here.
  final bool audioOn;

  /// Toggles guest audio; null when this panel has no output lane.
  final VoidCallback? onToggleAudio;

  /// Whether the viewer's microphone currently feeds the guest.
  final bool microphoneOn;

  /// Toggles microphone input; null when this panel has no input lane.
  final VoidCallback? onToggleMicrophone;

  @override
  ConsumerState<RigBrowserToolbar> createState() => _RigBrowserToolbarState();
}

class _RigBrowserToolbarState extends ConsumerState<RigBrowserToolbar> {
  late final TextEditingController _address;
  final FocusNode _addressFocus = FocusNode();

  bool _canGoBack = false;
  bool _canGoForward = false;

  /// Whether the page is mid-load. While true the reload button is a stop
  /// button (the browser convention), and the state is re-polled on a short
  /// timer because "loading finished" has no pushed signal of its own.
  bool _loading = false;
  Timer? _loadingPoll;
  List<BrowserPermissionEntry> _permissions = const [];

  /// A toolbar-initiated action in flight. Drives the thin progress bar the
  /// in-app browser shows under its toolbar — the screencast itself is the
  /// real loading indicator, this is just the acknowledge.
  bool _busy = false;

  /// The URL the field last showed from the rig, so a user edit is not
  /// mistaken for a navigation that needs rendering.
  String _shownUrl = '';

  @override
  void initState() {
    super.initState();
    _shownUrl = browserAddressBarText(widget.rig.currentUrl);
    _address = TextEditingController(text: _shownUrl);
    // The pushed URL alone cannot say whether back/forward lead anywhere;
    // that has to be asked of the session history.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshState());
    _loadingPoll = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => unawaited(_refreshState()),
    );
  }

  @override
  void dispose() {
    _loadingPoll?.cancel();
    _address.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RigBrowserToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final url = widget.rig.currentUrl ?? '';
    if (visibleBrowserUrl(url) == _shownUrl ||
        (isBrowserInternalUrl(url) && _shownUrl.isNotEmpty)) {
      return;
    }
    _applyAddress(url);
    unawaited(_refreshState());
  }

  /// Writes [raw] into the field unless it is browser furniture that would
  /// blank a real address the person is already looking at.
  void _applyAddress(String raw) {
    if (isBrowserInternalUrl(raw) && _shownUrl.isNotEmpty) {
      return;
    }
    final url = browserAddressBarText(raw);
    if (url == _shownUrl) {
      return;
    }
    _shownUrl = url;
    if (!_addressFocus.hasFocus) {
      _address.text = url;
    }
  }

  Future<void> _act(Map<String, dynamic> action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(rigRepositoryProvider)
          .act(
            workspaceId: widget.workspaceId,
            rigId: widget.rig.id,
            action: action,
          );
      if (result.isError && mounted) {
        CcToastScope.of(
          context,
        ).show(result.text, variant: CcToastVariant.danger);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    unawaited(_refreshState());
  }

  /// Pulls the history position. Failures keep the last known state: a
  /// momentarily unreachable browser must not flash working buttons dead.
  Future<void> _refreshState() async {
    try {
      final state = await ref
          .read(rigRepositoryProvider)
          .browserState(widget.workspaceId, widget.rig.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _canGoBack = state.canGoBack;
        _canGoForward = state.canGoForward;
        _loading = state.loading;
        _permissions = state.permissions;
      });
      _applyAddress(state.url);
    } on Object {
      // Keep what we have.
    }
  }

  void _submitAddress(String value) {
    final url = normalizeBrowserAddressInput(value);
    if (url == null) {
      return;
    }
    _address.text = url;
    _addressFocus.unfocus();
    unawaited(_act({'action': 'navigate', 'url': url}));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: t.bgSecondary,
            border: Border(bottom: BorderSide(color: t.lineStrong)),
          ),
          child: Row(
            children: [
              CcIconButton(
                icon: AppIcons.arrowLeft,
                size: CcButtonSize.sm,
                onPressed: _canGoBack && !_busy
                    ? () => unawaited(
                        _act(const {'action': 'history', 'delta': -1}),
                      )
                    : null,
                tooltip: l10n.backLabel,
              ),
              CcIconButton(
                icon: AppIcons.arrowRight,
                size: CcButtonSize.sm,
                onPressed: _canGoForward && !_busy
                    ? () => unawaited(
                        _act(const {'action': 'history', 'delta': 1}),
                      )
                    : null,
                tooltip: l10n.forward,
              ),
              CcIconButton(
                icon: _loading ? AppIcons.x : AppIcons.refreshCw,
                size: CcButtonSize.sm,
                onPressed: _busy
                    ? null
                    : () => unawaited(
                        _act(
                          _loading
                              ? const {'action': 'stop_loading'}
                              : const {'action': 'reload'},
                        ),
                      ),
                tooltip: _loading ? l10n.stop : l10n.reload,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CcTextField(
                  controller: _address,
                  focusNode: _addressFocus,
                  size: CcTextFieldSize.sm,
                  hintText: l10n.ideBrowserAddressHint,
                  prefix: Icon(AppIcons.globe, size: 14, color: t.textTertiary),
                  onSubmitted: _submitAddress,
                ),
              ),
              RigBrowserToolbarTrailing(
                rig: widget.rig,
                permissions: _permissions,
                networkRestarting: widget.networkRestarting,
                onNetworkSecurity: widget.onNetworkSecurity,
                audioOn: widget.audioOn,
                onToggleAudio: widget.onToggleAudio,
                microphoneOn: widget.microphoneOn,
                onToggleMicrophone: widget.onToggleMicrophone,
                onRespond: (id, {required allow}) => unawaited(
                  _act({
                    'action': 'permission_respond',
                    'request_id': id,
                    'allow': allow,
                  }),
                ),
              ),
            ],
          ),
        ),
        if (_busy)
          CcProgressBar(
            height: 2,
            color: t.accent,
            trackColor: const Color(0x00000000),
          ),
      ],
    );
  }
}

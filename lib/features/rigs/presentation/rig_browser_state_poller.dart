part of 'rig_browser_toolbar.dart';

/// One browser-state request at a time, only while its toolbar is visible.
/// A refresh requested during a slow read is replayed once after that read;
/// timer ticks begin only after reads finish, never piling up behind them.
class _BrowserStatePoller {
  _BrowserStatePoller({
    required this.readState,
    required this.onState,
    required this._workspaceId,
    required this._rigId,
  });

  final Future<RigBrowserStateView> Function(String workspaceId, String rigId)
  readState;
  final void Function(RigBrowserStateView state) onState;
  static const _interval = Duration(milliseconds: 400);

  String _workspaceId;
  String _rigId;
  Timer? _timer;
  bool _active = false;
  bool _reading = false;
  bool _pending = false;
  bool _disposed = false;
  int _generation = 0;

  void setActive(bool active) {
    if (_disposed || _active == active) {
      return;
    }
    _active = active;
    _timer?.cancel();
    _timer = null;
    if (active) {
      refresh();
    } else {
      _pending = false;
      // An outstanding response must not paint a hidden tab. Reveal will
      // request a fresh snapshot even if that response is still outstanding.
      _generation++;
    }
  }

  void setIdentity(String workspaceId, String rigId) {
    if (_workspaceId == workspaceId && _rigId == rigId) {
      return;
    }
    _workspaceId = workspaceId;
    _rigId = rigId;
    _generation++;
    _timer?.cancel();
    _timer = null;
    if (_active) {
      refresh();
    }
  }

  void refresh() {
    if (_disposed || !_active) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    if (_reading) {
      _pending = true;
    } else {
      _pending = false;
      unawaited(_read());
    }
  }

  Future<void> _read() async {
    _reading = true;
    final generation = _generation;
    final workspaceId = _workspaceId;
    final rigId = _rigId;
    try {
      final state = await readState(workspaceId, rigId);
      if (!_disposed && _active && generation == _generation) {
        onState(state);
      }
    } on Object {
      // Preserve the last known controls when the browser is unreachable.
    } finally {
      _reading = false;
      if (!_disposed && _active) {
        if (_pending) {
          _pending = false;
          unawaited(_read());
        } else {
          _timer = Timer(_interval, refresh);
        }
      }
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _timer = null;
  }
}

bool _samePermissions(
  List<BrowserPermissionEntry> old,
  List<BrowserPermissionEntry> next,
) {
  if (identical(old, next)) {
    return true;
  }
  if (old.length != next.length) {
    return false;
  }
  for (var i = 0; i < old.length; i++) {
    final a = old[i];
    final b = next[i];
    if (a.id != b.id ||
        a.origin != b.origin ||
        a.kind != b.kind ||
        a.decision != b.decision ||
        a.contextId != b.contextId) {
      return false;
    }
  }
  return true;
}

extension _BrowserToolbarAddress on _RigBrowserToolbarState {
  /// Preserve address drafts and the last real address on internal errors.
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

  void _submitAddress(String value) {
    final url = normalizeBrowserAddressInput(value);
    if (url == null) {
      return;
    }
    _address.text = url;
    _addressFocus.unfocus();
    unawaited(_act({'action': 'navigate', 'url': url}));
  }
}

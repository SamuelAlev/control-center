part of 'rig_input_surface.dart';

/// Clipboard chords and file pastes between the host and the machine.
extension _RigInputClipboard on _RigInputSurfaceState {
  /// Shows [outcome] to the user, quietly when there was nothing to carry.
  void _report(RigClipboardOutcome outcome) {
    if (!mounted || outcome.wasEmpty) {
      // A copy with nothing selected is a no-op, and a toast for it is noise
      // in a surface where people press ctrl+C constantly.
      return;
    }
    CcToastScope.of(context).show(
      outcome.summary,
      variant: outcome.ok ? CcToastVariant.neutral : CcToastVariant.danger,
    );
  }

  /// Runs a clipboard chord only after the relevant boundary crossing has
  /// been approved.
  Future<void> _runClipboardChord(RigClipboardChord chord) async {
    final bridge = _bridge;
    if (bridge == null || _clipboardBusy) {
      return;
    }
    _clipboardBusy = true;
    try {
      final direction = chord == RigClipboardChord.paste
          ? RigClipboardDirection.hostToRig
          : RigClipboardDirection.rigToHost;
      if (!await ensureRigClipboardPermission(
        context: context,
        ref: ref,
        rigId: widget.rig.id,
        direction: direction,
      )) {
        // On Windows/Linux the host and guest use the same Ctrl shortcut.
        // Refusing the boundary crossing must not also eat Ctrl+C inside a
        // guest terminal or prevent a guest-local paste. On Apple platforms
        // Cmd is the host-only crossing shortcut and must not become Ctrl.
        if (!_usesMetaClipboardShortcut) {
          _enqueueGuestClipboardChord(chord);
        }
        return;
      }
      if (chord == RigClipboardChord.paste) {
        await _pasteIntoGuest(bridge);
      } else {
        await _copyFromGuest(bridge, cut: chord == RigClipboardChord.cut);
      }
    } on Object catch (e) {
      AppLog.d('rig-input', 'clipboard chord ${chord.name} failed: $e');
    } finally {
      _clipboardBusy = false;
    }
  }

  /// Whether the host clipboard chord uses Cmd rather than the guest's Ctrl.
  bool get _usesMetaClipboardShortcut =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Sends the guest-side Ctrl chord without moving clipboard content.
  void _enqueueGuestClipboardChord(RigClipboardChord chord) {
    final letter = switch (chord) {
      RigClipboardChord.copy => 'c',
      RigClipboardChord.cut => 'x',
      RigClipboardChord.paste => 'v',
    };
    _enqueue(
      _isIos
          ? rigIosClipboardKeyAction(letter)
          : _speaksComputerInput
          ? {'action': 'key', 'text': 'ctrl+$letter'}
          : {
              'action': 'key',
              'key': letter,
              'modifiers': ['ctrl'],
            },
    );
  }

  /// Tells the guest to copy, then carries what it copied to this host.
  Future<void> _copyFromGuest(
    RigClipboardBridge bridge, {
    required bool cut,
  }) async {
    _enqueueGuestClipboardChord(
      cut ? RigClipboardChord.cut : RigClipboardChord.copy,
    );
    // Awaited, not assumed: reading before the chord has reached the guest
    // reads the PREVIOUS clipboard, and writing that to the host is silent
    // data loss for whatever the user actually had.
    await _actions.drain();
    // The guest's own applications need a moment to service the chord and
    // take ownership of the selection. Short enough to feel instant, long
    // enough that a normal application has answered.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) {
      return;
    }
    // `pullToHost` refuses to carry content the guest was already holding —
    // which is what a ctrl+C that meant "interrupt" looks like on Windows and
    // Linux, where the crossing chord is the guest's own.
    _report(await bridge.pullToHost());
  }

  /// Puts this host's clipboard into the guest and tells it to paste.
  Future<void> _pasteIntoGuest(RigClipboardBridge bridge) async {
    final snapshot = await bridge.readHost();
    if (!mounted) {
      return;
    }
    if (snapshot.isEmpty) {
      return;
    }
    // Files are a COPY, not a clipboard write: they have to exist inside the
    // guest before anything there can open them.
    if (snapshot.files.isNotEmpty) {
      await _deliverFiles(bridge, snapshot.files, point: _lastGuestPoint);
      return;
    }
    final pushed = await bridge.pushToGuest(snapshot);
    if (!mounted) {
      return;
    }
    if (pushed.ok) {
      _enqueueGuestClipboardChord(RigClipboardChord.paste);
      return;
    }
    // The guest's clipboard could not be written — on the browser surface
    // that is a page served over plain http, which browsers give no
    // clipboard at all. Text can still be INSERTED at the caret, which is
    // what a paste does anyway; an image cannot, so say so.
    final text = snapshot.text;
    if (!_isComputer && text != null && text.isNotEmpty) {
      _enqueue({'action': 'type', 'text': text});
      return;
    }
    _report(pushed);
  }

  /// Copies [files] into the guest, offered at [point] when there is one.
  Future<void> _deliverFiles(
    RigClipboardBridge bridge,
    List<HostFile> files, {
    (int, int)? point,
  }) async {
    if (files.isEmpty) {
      return;
    }
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      CcToastScope.of(context).show(
        files.length == 1
            ? l10n.rigDropSendingOne(files.single.name)
            : l10n.rigDropSendingMany(files.length),
      );
    }
    final result = await bridge.dropFiles(files, x: point?.$1, y: point?.$2);
    if (!mounted) {
      return;
    }
    CcToastScope.of(context).show(
      result.summary,
      variant: result.isError ? CcToastVariant.danger : CcToastVariant.neutral,
    );
  }
}

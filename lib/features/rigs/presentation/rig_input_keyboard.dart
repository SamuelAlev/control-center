part of 'rig_input_surface.dart';

/// Key events translated into the names the action layer speaks.
extension _RigInputKeyboard on _RigInputSurfaceState {
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      // Presses are sent as full chords on the way down; a release on its
      // own has nothing to add. Swallowed so it cannot leak into the app.
      return KeyEventResult.handled;
    }
    if (kRigBareModifiers.contains(event.logicalKey)) {
      return KeyEventResult.handled; // Rides along in the chord.
    }
    // Clipboard chords are intercepted BEFORE the generic key path, because
    // the generic path would forward Cmd+C to a Linux guest as `super+c`,
    // which means nothing anywhere. See [rigClipboardChordFor] for how the
    // ambiguous (Windows/Linux) case stays honest.
    final clipboard = rigClipboardChordFor(event);
    if (clipboard != null) {
      _keystrokes.flush();
      unawaited(_runClipboardChord(clipboard));
      return KeyEventResult.handled;
    }
    final pressed = HardwareKeyboard.instance;
    final ctrl = pressed.isControlPressed;
    final alt = pressed.isAltPressed;
    final meta = pressed.isMetaPressed;
    final shift = pressed.isShiftPressed;
    if (_isIos) {
      final character = event.character;
      if (character != null &&
          character.isNotEmpty &&
          !ctrl &&
          !alt &&
          !meta &&
          !kRigControlCharacters.contains(character)) {
        _keystrokes.add(character);
        return KeyEventResult.handled;
      }
      final action = rigIosKeyAction(
        key: event.logicalKey,
        character: character,
        control: ctrl,
        alt: alt,
        meta: meta,
        shift: shift,
      );
      if (action != null) {
        _enqueue(action);
      }
      return KeyEventResult.handled;
    }

    final character = event.character;
    if (_speaksComputerInput) {
      if (character != null &&
          character.isNotEmpty &&
          !ctrl &&
          !alt &&
          !meta &&
          !kRigControlCharacters.contains(character)) {
        // Buffered, not sent: a word becomes one `type` action. Anything
        // that is not a printable character flushes it first (see
        // [_enqueue]), so ordering survives.
        _keystrokes.add(character);
        return KeyEventResult.handled;
      }
      final name = rigX11NameFor(event.logicalKey);
      if (name == null) {
        return KeyEventResult.handled;
      }
      final combo = [
        if (ctrl) 'ctrl',
        if (alt) 'alt',
        if (meta) 'super',
        // Shift only matters for named keys — a shifted character already
        // arrived uppercase through the character branch above.
        if (shift) 'shift',
        name,
      ].join('+');
      _enqueue({'action': 'key', 'text': combo});
      return KeyEventResult.handled;
    }

    // Browser: printable characters are batched into ONE `type` action, the
    // same as the computer surface — a word per round trip instead of a JSON
    // RPC per letter, and an audit entry whose redaction covers a run of
    // text rather than hashing one character at a time (a one-character hash
    // over a ~100-symbol alphabet is brute-forced instantly, so per-character
    // "redaction" protected nothing).
    if (character != null &&
        character.isNotEmpty &&
        !ctrl &&
        !alt &&
        !meta &&
        !kRigControlCharacters.contains(character)) {
      _keystrokes.add(character);
      return KeyEventResult.handled;
    }
    final modifiers = [
      if (ctrl) 'ctrl',
      if (alt) 'alt',
      if (meta) 'meta',
      if (shift) 'shift',
    ];
    final cdpName = rigCdpNameFor(event.logicalKey);
    if (cdpName != null) {
      // Named keys carry their modifiers: shift+ArrowLeft extends the
      // selection, ctrl+Enter submits the form.
      _enqueue({
        'action': 'key',
        'key': cdpName,
        if (modifiers.isNotEmpty) 'modifiers': modifiers,
      });
      return KeyEventResult.handled;
    }
    // A printable key with a real modifier held is a chord (ctrl+c copies).
    // Bare characters never reach here — the branch above took them.
    if (ctrl || alt || meta) {
      // The KEY CHARACTER first, the label only as a fallback. `keyLabel` is
      // the physical key's name, which on a non-Latin layout is a word ("КА")
      // rather than a character — so a `length == 1` test dropped every
      // modifier chord on those layouts with no feedback at all, and the
      // machine simply did not respond to ctrl+C.
      final candidate = (character != null && character.isNotEmpty)
          ? character
          : event.logicalKey.keyLabel;
      if (candidate.length == 1) {
        _enqueue({
          'action': 'key',
          'key': candidate.toLowerCase(),
          'modifiers': modifiers,
        });
      } else {
        // Still nothing usable: say so once rather than swallowing the press.
        // A chord that silently does nothing is indistinguishable from a
        // frozen guest.
        AppLog.d(
          'rig-input',
          'Dropped a modifier chord with no CDP name: '
              '${event.logicalKey.debugName ?? candidate} '
              '(modifiers: ${modifiers.join("+")})',
        );
      }
    }
    return KeyEventResult.handled;
  }
}

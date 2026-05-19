import 'package:control_center/features/rigs/presentation/rig_input_surface.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_file_transfer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which keystroke over a rig canvas means "cross the boundary".
///
/// The distinction this pins is the one that breaks quietly: on macOS the host
/// chord (Cmd) is unambiguous, and off Apple platforms it is the SAME
/// keystroke the guest uses — where ctrl+C in a terminal is an interrupt, not
/// a copy. A regression here does not throw; it silently overwrites somebody's
/// clipboard, or stops SIGINT reaching a shell.
void main() {
  /// Reads the chord for [key] with the given modifiers actually HELD.
  ///
  /// The modifier state has to be real: `rigClipboardChordFor` reads
  /// `HardwareKeyboard.instance` rather than the event, because a chord is
  /// about which keys are down, not about which one arrived last.
  ///
  /// [platform] is set and cleared INSIDE the call rather than in
  /// `setUp`/`tearDown`, because the widget binding checks that no debug
  /// override is left set at the end of each test BODY — before tearDown gets
  /// a chance to clear it.
  Future<RigClipboardChord?> chordFor(
    LogicalKeyboardKey key, {
    required TargetPlatform platform,
    bool meta = false,
    bool control = false,
    bool alt = false,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    final held = <LogicalKeyboardKey>[
      if (meta) LogicalKeyboardKey.metaLeft,
      if (control) LogicalKeyboardKey.controlLeft,
      if (alt) LogicalKeyboardKey.altLeft,
    ];
    try {
      for (final modifier in held) {
        await simulateKeyDownEvent(modifier);
      }
      // Only `logicalKey` is read; the physical key is a placeholder.
      return rigClipboardChordFor(
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyC,
          logicalKey: key,
          timeStamp: Duration.zero,
        ),
      );
    } finally {
      for (final modifier in held.reversed) {
        await simulateKeyUpEvent(modifier);
      }
      debugDefaultTargetPlatformOverride = null;
    }
  }

  group('on macOS, where Cmd is the host chord', () {
    testWidgets('Cmd+C, Cmd+X and Cmd+V cross the boundary', (tester) async {
      expect(
        await chordFor(
          LogicalKeyboardKey.keyC,
          platform: TargetPlatform.macOS,
          meta: true,
        ),
        RigClipboardChord.copy,
      );
      expect(
        await chordFor(
          LogicalKeyboardKey.keyX,
          platform: TargetPlatform.macOS,
          meta: true,
        ),
        RigClipboardChord.cut,
      );
      expect(
        await chordFor(
          LogicalKeyboardKey.keyV,
          platform: TargetPlatform.macOS,
          meta: true,
        ),
        RigClipboardChord.paste,
      );
    });

    testWidgets('Ctrl+C is left alone, so SIGINT still reaches a guest shell', (
      tester,
    ) async {
      expect(
        await chordFor(
          LogicalKeyboardKey.keyC,
          platform: TargetPlatform.macOS,
          control: true,
        ),
        isNull,
      );
    });

    testWidgets('a chord with extra modifiers is not a plain copy', (
      tester,
    ) async {
      expect(
        await chordFor(
          LogicalKeyboardKey.keyC,
          platform: TargetPlatform.macOS,
          meta: true,
          control: true,
        ),
        isNull,
      );
      expect(
        await chordFor(
          LogicalKeyboardKey.keyC,
          platform: TargetPlatform.macOS,
          meta: true,
          alt: true,
        ),
        isNull,
      );
    });

    testWidgets('an unrelated key with Cmd held is not a clipboard chord', (
      tester,
    ) async {
      expect(
        await chordFor(
          LogicalKeyboardKey.keyS,
          platform: TargetPlatform.macOS,
          meta: true,
        ),
        isNull,
      );
    });
  });

  group('off Apple platforms, where Ctrl is the host chord', () {
    testWidgets('Ctrl+C, Ctrl+X and Ctrl+V cross the boundary', (tester) async {
      expect(
        await chordFor(
          LogicalKeyboardKey.keyC,
          platform: TargetPlatform.linux,
          control: true,
        ),
        RigClipboardChord.copy,
      );
      expect(
        await chordFor(
          LogicalKeyboardKey.keyX,
          platform: TargetPlatform.linux,
          control: true,
        ),
        RigClipboardChord.cut,
      );
      expect(
        await chordFor(
          LogicalKeyboardKey.keyV,
          platform: TargetPlatform.windows,
          control: true,
        ),
        RigClipboardChord.paste,
      );
    });

    testWidgets('Cmd is not the chord here', (tester) async {
      expect(
        await chordFor(
          LogicalKeyboardKey.keyC,
          platform: TargetPlatform.linux,
          meta: true,
        ),
        isNull,
      );
    });

    testWidgets('a bare key is never a chord', (tester) async {
      expect(
        await chordFor(LogicalKeyboardKey.keyC, platform: TargetPlatform.linux),
        isNull,
      );
    });
  });

  /// Every path typed at a prompt goes through this, and the names come from
  /// wherever the user dragged them.
  group('shellQuoteForPrompt', () {
    test('quotes an ordinary path', () {
      expect(shellQuoteForPrompt('/home/cc/a.txt'), "'/home/cc/a.txt'");
    });

    test('a space stays one argument', () {
      expect(shellQuoteForPrompt('/a/my file.txt'), "'/a/my file.txt'");
    });

    test('a quote cannot end the quoting', () {
      expect(shellQuoteForPrompt("/a/it's here"), r"'/a/it'\''s here'");
    });

    test('metacharacters cannot become a second command', () {
      final quoted = shellQuoteForPrompt(r"/a/x'; rm -rf ~; echo '");
      // The dangerous part survives only as literal text inside the quotes.
      expect(quoted.startsWith("'"), isTrue);
      expect(quoted.endsWith("'"), isTrue);
      expect(quoted, contains(r"'\''"));
    });

    test('a dollar sign is not expanded', () {
      expect(shellQuoteForPrompt(r'/a/$HOME'), r"'/a/$HOME'");
    });
  });

  group('pastedImageName', () {
    test('is sortable and second-resolution', () {
      expect(
        pastedImageName(DateTime(2026, 3, 7, 9, 4, 5)),
        'pasted-20260307-090405.png',
      );
    });

    test('two seconds produce two names', () {
      expect(
        pastedImageName(DateTime(2026, 3, 7, 9, 4, 5)),
        isNot(pastedImageName(DateTime(2026, 3, 7, 9, 4, 6))),
      );
    });
  });
}

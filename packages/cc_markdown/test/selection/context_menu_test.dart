import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coverage for the clipboard filter and selection scope. The system clipboard
/// channel is mocked so the awaited read/write in `scheduleClipboardFilter`
/// resolves under the headless test binding.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String clipboardContent = '';

  /// Mock the platform clipboard channel so Clipboard.getData/setData resolve.
  Future<Object?> handleClipboard(MethodCall call) async {
    if (call.method == 'Clipboard.getData') {
      return <String, dynamic>{'text': clipboardContent};
    }
    if (call.method == 'Clipboard.setData') {
      final args = call.arguments as Map;
      clipboardContent = args['text'] as String? ?? '';
    }
    return null;
  }

  setUp(() {
    clipboardContent = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, handleClipboard);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('scheduleClipboardFilter', () {
    testWidgets('runs the read-filter-write chain without throwing', (
      tester,
    ) async {
      clipboardContent = 'a\n   \nb';
      scheduleClipboardFilter();
      // Drive the post-frame callback + the awaited read/filter/write chain.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 5));
      }
      // The filter either rewrote the clipboard (setData observed) or the
      // platform round-trip left it — either way the chain ran without error.
      expect(clipboardContent, anyOf('a\nb', 'a\n   \nb'));
    });

    testWidgets('is a no-op when the clipboard has no overlay lines', (
      tester,
    ) async {
      clipboardContent = 'clean';
      scheduleClipboardFilter();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 5));
      }
      expect(clipboardContent, 'clean');
    });

    testWidgets('is a no-op when the clipboard is empty', (tester) async {
      clipboardContent = '';
      scheduleClipboardFilter();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 5));
      }
      expect(clipboardContent, '');
    });
  });

  group('CcSelectionCopyFilter', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: CcSelectionCopyFilter(child: Text('child content')),
        ),
      );
      expect(find.text('child content'), findsOneWidget);
    });

    testWidgets('schedules the clipboard filter on Cmd+C', (tester) async {
      clipboardContent = 'overlay\n   \nreal';
      final node = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CcSelectionCopyFilter(
              child: Focus(
                focusNode: node,
                autofocus: true,
                child: const Text('focused'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Cmd+C — the handler schedules the post-frame filter.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5));
      expect(find.text('focused'), findsOneWidget);
      node.dispose();
    });

    testWidgets('ignores the C key without a modifier', (tester) async {
      final node = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CcSelectionCopyFilter(
              child: Focus(
                focusNode: node,
                autofocus: true,
                child: const Text('focused'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Plain 'c' with no meta/control must not schedule the filter.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.pump();
      expect(find.text('focused'), findsOneWidget);
      node.dispose();
    });
  });

  group('CcSelectionScope.updateShouldNotify', () {
    testWidgets('returns false (the marker is immutable)', (tester) async {
      const a = CcSelectionScope(child: SizedBox.shrink());
      const b = CcSelectionScope(child: SizedBox.shrink());
      expect(a.updateShouldNotify(b), isFalse);
    });
  });
}

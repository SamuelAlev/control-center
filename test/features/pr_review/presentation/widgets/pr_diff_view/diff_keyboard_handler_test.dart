import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/diff_keyboard_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

PrFile _testFile({String filename = 'lib/a.dart'}) {
  return PrFile(
    filename: filename,
    status: PrFileStatus.modified,
    additions: 1,
    deletions: 1,
    patch: '@@ -1,1 +1,1 @@\n code\n',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrDiffKeyboardHandler', () {
    late List<PrFile> files;
    late bool searchOpen;
    bool closeSearchCalled = false;
    bool nextMatchCalled = false;
    bool prevMatchCalled = false;

    PrDiffKeyboardHandler createHandler() {
      closeSearchCalled = false;
      nextMatchCalled = false;
      prevMatchCalled = false;
      return PrDiffKeyboardHandler(
        files: files,
        searchOpenGetter: () => searchOpen,
        activeScrollPositionGetter: () => null,
        estimatedFileTopGetter: (i) => i * 200.0,
        fileStateKeys: {},
        onOpenSearch: () {},
        onCloseSearch: () => closeSearchCalled = true,
        onGoToNextMatch: () => nextMatchCalled = true,
        onGoToPrevMatch: () => prevMatchCalled = true,
        onFullRefresh: () {},
      );
    }

    setUp(() {
      files = [_testFile(), _testFile(filename: 'lib/b.dart')];
      searchOpen = false;
    });

    test('Escape closes search when search is open', () {
      searchOpen = true;
      final handler = createHandler();
      const event = KeyDownEvent(
        logicalKey: LogicalKeyboardKey.escape,
        physicalKey: PhysicalKeyboardKey.escape,
        character: null,
        timeStamp: Duration.zero,
      );
      final result = handler.handleGlobalKey(event);
      expect(result, isTrue);
      expect(closeSearchCalled, isTrue);
    });

    test('Escape does nothing when search is closed', () {
      final handler = createHandler();
      const event = KeyDownEvent(
        logicalKey: LogicalKeyboardKey.escape,
        physicalKey: PhysicalKeyboardKey.escape,
        character: null,
        timeStamp: Duration.zero,
      );
      final result = handler.handleGlobalKey(event);
      expect(result, isFalse);
    });

    test('Enter navigates to next match when search is open', () {
      searchOpen = true;
      final handler = createHandler();
      const event = KeyDownEvent(
        logicalKey: LogicalKeyboardKey.enter,
        physicalKey: PhysicalKeyboardKey.enter,
        character: null,
        timeStamp: Duration.zero,
      );
      final result = handler.handleGlobalKey(event);
      expect(result, isTrue);
      expect(nextMatchCalled, isTrue);
    });

    test('Shift+Enter navigates to previous match when search is open', () async {
      searchOpen = true;
      final handler = createHandler();
      await simulateKeyDownEvent(LogicalKeyboardKey.shift);
      const event = KeyDownEvent(
        logicalKey: LogicalKeyboardKey.enter,
        physicalKey: PhysicalKeyboardKey.enter,
        character: null,
        timeStamp: Duration.zero,
      );
      final result = handler.handleGlobalKey(event);
      await simulateKeyUpEvent(LogicalKeyboardKey.shift);
      expect(result, isTrue);
      expect(prevMatchCalled, isTrue);
    });

    test('Enter does nothing when search is closed', () {
      final handler = createHandler();
      const event = KeyDownEvent(
        logicalKey: LogicalKeyboardKey.enter,
        physicalKey: PhysicalKeyboardKey.enter,
        character: null,
        timeStamp: Duration.zero,
      );
      final result = handler.handleGlobalKey(event);
      expect(result, isFalse);
    });

    test('J handles when search closed without modifiers', () async {
      final handler = createHandler();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyJ);
      const event = KeyUpEvent(
        logicalKey: LogicalKeyboardKey.keyJ,
        physicalKey: PhysicalKeyboardKey.keyJ,
        timeStamp: Duration.zero,
      );
      handler.handleGlobalKey(event);
    });

    test('ignores KeyUpEvent', () {
      final handler = createHandler();
      const event = KeyUpEvent(
        logicalKey: LogicalKeyboardKey.keyJ,
        physicalKey: PhysicalKeyboardKey.keyJ,
        timeStamp: Duration.zero,
      );
      final result = handler.handleGlobalKey(event);
      expect(result, isFalse);
    });

    test('focusedFileIndex starts at 0', () {
      final handler = createHandler();
      expect(handler.focusedFileIndex, 0);
    });

    test('stepToFile does nothing with empty files', () {
      files = [];
      final handler = createHandler();
      handler.focusedFileIndex = 0;
      handler.stepToFile(1);
      expect(handler.focusedFileIndex, 0);
    });

    test('stepToFile clamps to valid range', () {
      final handler = createHandler();
      handler.focusedFileIndex = 0;
      handler.stepToFile(-1);
      expect(handler.focusedFileIndex, 0);
      handler.focusedFileIndex = files.length - 1;
      handler.stepToFile(1);
      expect(handler.focusedFileIndex, files.length - 1);
    });

    test('jumpToFile does nothing without scroll position', () {
      final handler = createHandler();
      handler.focusedFileIndex = 0;
      handler.jumpToFile(1);
      expect(handler.focusedFileIndex, 0);
    });

    test('handleGlobalKey ignores key repeat when search open', () {
      searchOpen = true;
      final handler = createHandler();
      const event = KeyRepeatEvent(
        logicalKey: LogicalKeyboardKey.enter,
        physicalKey: PhysicalKeyboardKey.enter,
        character: null,
        timeStamp: Duration.zero,
      );
      final result = handler.handleGlobalKey(event);
      expect(result, isTrue);
      expect(nextMatchCalled, isTrue);
    });

    test('handleGlobalKey returns false for non-key events', () {
      final handler = createHandler();
      const event = KeyUpEvent(
        logicalKey: LogicalKeyboardKey.enter,
        physicalKey: PhysicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      final result = handler.handleGlobalKey(event);
      expect(result, isFalse);
    });
  });
}

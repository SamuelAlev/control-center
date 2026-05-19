import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/diff_search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PrFile _testFile({String filename = 'lib/a.dart', String patch = ''}) {
  return PrFile(
    filename: filename,
    status: PrFileStatus.modified,
    additions: 1,
    deletions: 1,
    patch: patch.isEmpty ? '@@ -1,1 +1,1 @@\n main\n new\n' : patch,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrDiffSearchController', () {
    late List<PrFile> files;
    bool changed = false;
    OverlayEntry? insertedEntry;
    OverlayEntry? removedEntry;

    PrDiffSearchController create({List<PrFile>? f}) {
      changed = false;
      insertedEntry = null;
      removedEntry = null;
      final fileList = f ?? files;
      return PrDiffSearchController(
        files: fileList,
        onChanged: () => changed = true,
        fileStateKeys: {},
        activeScrollPositionGetter: () => null,
        estimatedFileTopGetter: (i) => i * 200.0,
        onInsertOverlay: (e) => insertedEntry = e,
        onRemoveOverlay: (e) => removedEntry = e,
      );
    }

    setUp(() {
      files = [_testFile()];
    });

    test('initial state has search closed', () {
      final ctrl = create();
      expect(ctrl.searchOpen, isFalse);
      expect(ctrl.searchQuery, '');
      expect(ctrl.totalMatches, 0);
      expect(ctrl.currentMatchIdx, 0);
    });

    test('openSearch sets searchOpen to true', () {
      final ctrl = create();
      ctrl.openSearch();
      expect(ctrl.searchOpen, isTrue);
      expect(changed, isTrue);
    });

    test('openSearch when already open selects text', () {
      final ctrl = create();
      ctrl.openSearch();
      changed = false;
      ctrl.searchCtrl.text = 'hello';
      ctrl.openSearch();
      expect(changed, isFalse);
    });

    test('closeSearch resets state', () {
      final ctrl = create();
      ctrl.openSearch();
      insertedEntry = OverlayEntry(builder: (_) => const SizedBox());
      ctrl.searchOverlay = insertedEntry;

      ctrl.closeSearch();
      expect(ctrl.searchOpen, isFalse);
      expect(ctrl.searchQuery, '');
      expect(ctrl.totalMatches, 0);
      expect(ctrl.currentMatchIdx, 0);
      expect(removedEntry, isNotNull);
    });

    test('closeSearch when not open does nothing', () {
      final ctrl = create();
      changed = false;
      ctrl.closeSearch();
      expect(changed, isFalse);
    });

    test('onSearchChanged updates query and finds matches', () async {
      final ctrl = create();
      ctrl.onSearchChanged('main');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(ctrl.searchQuery, 'main');
      expect(ctrl.totalMatches, 1);
      expect(ctrl.currentMatchIdx, 1);
    });

    test('onSearchChanged empty clears matches', () async {
      final ctrl = create();
      ctrl.onSearchChanged('main');
      await Future.delayed(const Duration(milliseconds: 100));
      ctrl.onSearchChanged('');
      expect(ctrl.searchQuery, '');
      expect(ctrl.totalMatches, 0);
      expect(ctrl.currentMatchIdx, 0);
    });

    test('updateMatchData with no query clears matches', () {
      final ctrl = create();
      ctrl.searchQuery = '';
      ctrl.updateMatchData();
      expect(ctrl.totalMatches, 0);
    });

    test('updateMatchData finds multiple matches', () {
      final ctrl = create();
      ctrl.searchQuery = 'n';
      ctrl.updateMatchData();
      expect(ctrl.totalMatches, 2);
      expect(ctrl.matchLocations.length, 2);
    });

    test('goToNextMatch wraps around', () {
      final ctrl = create();
      ctrl.searchQuery = 'n';
      ctrl.updateMatchData();
      expect(ctrl.currentMatchIdx, 1);
      ctrl.goToNextMatch();
      expect(ctrl.currentMatchIdx, 2);
      ctrl.goToNextMatch();
      expect(ctrl.currentMatchIdx, 1);
      ctrl.goToNextMatch();
      expect(ctrl.currentMatchIdx, 2);
    });

    test('goToPrevMatch wraps around', () {
      final ctrl = create();
      ctrl.searchQuery = 'n';
      ctrl.updateMatchData();
      expect(ctrl.currentMatchIdx, 1);
      ctrl.goToPrevMatch();
      expect(ctrl.currentMatchIdx, 2);
      ctrl.goToPrevMatch();
      expect(ctrl.currentMatchIdx, 1);
    });

    test('goToNextMatch does nothing with zero matches', () {
      final ctrl = create();
      ctrl.goToNextMatch();
      expect(ctrl.currentMatchIdx, 0);
    });

    test('goToPrevMatch does nothing with zero matches', () {
      final ctrl = create();
      ctrl.goToPrevMatch();
      expect(ctrl.currentMatchIdx, 0);
    });

    test('dispose cleans up resources', () {
      final ctrl = create();
      ctrl.onSearchChanged('test');
      ctrl.dispose();
      expect(ctrl.searchOpen, isFalse);
    });

    test('search is case-insensitive', () async {
      final ctrl = create();
      ctrl.onSearchChanged('MAIN');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(ctrl.totalMatches, 1);
    });

    test('multiple files parsed on search', () {
      files = [
        _testFile(filename: 'lib/a.dart', patch: '@@ -1,1 +1,1 @@\n alpha\n'),
        _testFile(filename: 'lib/b.dart', patch: '@@ -1,1 +1,1 @@\n gamma\n'),
      ];
      final ctrl = create();
      ctrl.searchQuery = 'alpha';
      ctrl.updateMatchData();
      expect(ctrl.totalMatches, 1);
    });

    test('files without patches produce no matches', () {
      files = [_testFile(filename: 'lib/c.dart')];
      final ctrl = create();
      ctrl.searchQuery = 'test';
      ctrl.updateMatchData();
      expect(ctrl.totalMatches, 0);
    });
  });

  group('SearchMatch', () {
    test('constructs with required params', () {
      const match = SearchMatch(fileIndex: 0, lineIndex: 5);
      expect(match.fileIndex, 0);
      expect(match.lineIndex, 5);
    });

    test('equality works', () {
      const a = SearchMatch(fileIndex: 0, lineIndex: 1);
      const b = SearchMatch(fileIndex: 0, lineIndex: 1);
      expect(a, equals(b));
    });
  });
}

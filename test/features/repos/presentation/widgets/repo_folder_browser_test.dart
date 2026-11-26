import 'package:cc_domain/core/domain/entities/directory_listing.dart';
import 'package:control_center/features/repos/presentation/widgets/repo_folder_browser.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('a checkout is one checkbox stop that Space toggles', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final toggled = <String>[];
    final opened = <String>[];
    await tester.pumpWidget(
      testWrap(
        RepoFolderList(
          loading: false,
          error: null,
          listing: const DirectoryListing(
            path: '/src',
            parent: null,
            isGitRepo: false,
            roots: ['/src'],
            entries: [
              DirectoryEntry(name: 'app', path: '/src/app', isGitRepo: true),
            ],
          ),
          selected: const {'/src/app'},
          enabled: true,
          emptyLabel: 'Empty',
          onOpen: opened.add,
          onToggle: toggled.add,
        ),
      ),
    );
    await tester.pump();

    final box = find.bySemanticsLabel('Select this folder');
    expect(box, findsOneWidget);
    expect(
      tester.getSemantics(box),
      isSemantics(isButton: true, hasCheckedState: true, isChecked: true),
    );

    // Tab from the row lands on the checkbox target, not on a second copy.
    Focus.of(tester.element(find.text('app'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(toggled, ['/src/app']);
    expect(opened, isEmpty);
    handle.dispose();
  });
}

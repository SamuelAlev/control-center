import 'package:cc_domain/features/pr_review/domain/services/scm_path_order.dart';
import 'package:test/test.dart';

/// Exercises [compareScmPaths], the VS Code Source Control "sort by path"
/// order the IDE panel and review pane list changed files in.
void main() {
  List<String> sorted(List<String> paths) =>
      [...paths]..sort(compareScmPaths);

  test('mixes untracked files into path order', () {
    const base = 'src/modules/AccountManagement';
    // Tracked first, untracked appended: the order `git diff` + `ls-files
    // --others` produce.
    final gitOrder = [
      'public/locales/en.json',
      '$base/presentations/components/ExpiryDateFlyout.tsx',
      '$base/presentations/views/FeatureGroupItem.tsx',
      '$base/presentations/views/FeaturesPanel.spec.tsx',
      '$base/presentations/views/LimitsPanel.spec.tsx',
      '$base/presentations/views/LimitsPanel.tsx',
      '$base/useCases/updateEntitlements.spec.ts',
      '$base/useCases/updateEntitlements.ts',
      '$base/presentations/components/AutoSaveStorageLimitField.tsx',
      '$base/presentations/helpers/storageUnits.spec.ts',
      '$base/presentations/helpers/storageUnits.ts',
    ];
    expect(sorted(gitOrder), [
      'public/locales/en.json',
      '$base/presentations/components/AutoSaveStorageLimitField.tsx',
      '$base/presentations/components/ExpiryDateFlyout.tsx',
      '$base/presentations/helpers/storageUnits.spec.ts',
      '$base/presentations/helpers/storageUnits.ts',
      '$base/presentations/views/FeatureGroupItem.tsx',
      '$base/presentations/views/FeaturesPanel.spec.tsx',
      '$base/presentations/views/LimitsPanel.spec.tsx',
      '$base/presentations/views/LimitsPanel.tsx',
      '$base/useCases/updateEntitlements.spec.ts',
      '$base/useCases/updateEntitlements.ts',
    ]);
  });

  test('lists a directory\'s files before its subdirectories', () {
    expect(sorted(['lib/z/a.dart', 'lib/b.dart', 'README.md', 'a/x.md']), [
      'README.md',
      'a/x.md',
      'lib/b.dart',
      'lib/z/a.dart',
    ]);
  });

  test('ignores case in directories and file names', () {
    expect(sorted(['src/b.ts', 'Src/A.ts', 'src/a.ts']), [
      'Src/A.ts',
      'src/a.ts',
      'src/b.ts',
    ]);
    expect(sorted(['b.ts', 'C.ts', 'a.ts']), ['a.ts', 'b.ts', 'C.ts']);
  });

  test('orders numbers in file names by value', () {
    expect(sorted(['file10.txt', 'file2.txt', 'file1.txt']), [
      'file1.txt',
      'file2.txt',
      'file10.txt',
    ]);
  });

  test('sorts punctuation before digits before letters', () {
    expect(sorted(['a.ts', '_a.ts', '1.ts', '-a.ts']), [
      '_a.ts',
      '-a.ts',
      '1.ts',
      'a.ts',
    ]);
    expect(sorted(['a_b.ts', 'a.ts', 'a-b.ts', 'ab.ts']), [
      'a_b.ts',
      'a-b.ts',
      'a.ts',
      'ab.ts',
    ]);
  });

  test('is a total order on names the collation treats as equal', () {
    expect(sorted(['A.ts', 'a.ts']), ['A.ts', 'a.ts']);
    expect(sorted(['file01.txt', 'file1.txt']), ['file1.txt', 'file01.txt']);
  });
}

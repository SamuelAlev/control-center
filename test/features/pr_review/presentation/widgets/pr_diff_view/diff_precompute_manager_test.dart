import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/diff_precompute_manager.dart';
import 'package:flutter_test/flutter_test.dart';

PrFile _file({
  String filename = 'lib/main.dart',
  String patch = '@@ -1,3 +1,4 @@\n context\n-old\n+new\n end\n',
}) {
  return PrFile(
    filename: filename,
    status: PrFileStatus.modified,
    additions: 1,
    deletions: 1,
    patch: patch,
  );
}

void main() {
  group('PrDiffPrecomputeManager', () {
    late PrDiffPrecomputeManager manager;

    setUp(() {
      manager = PrDiffPrecomputeManager(files: []);
    });

    test('estimatedFileTop returns toolbar height for index 0', () {
      manager.files = [_file()];
      expect(manager.estimatedFileTop(0), greaterThan(0));
    });

    test('estimatedFileTop increases with index', () {
      manager.files = [_file(), _file(filename: 'lib/b.dart')];
      final top0 = manager.estimatedFileTop(0);
      final top1 = manager.estimatedFileTop(1);
      expect(top1, greaterThan(top0));
    });

    test('kPrDiffAutoCollapseThreshold is 500', () {
      expect(kPrDiffAutoCollapseThreshold, 500);
    });
  });
}

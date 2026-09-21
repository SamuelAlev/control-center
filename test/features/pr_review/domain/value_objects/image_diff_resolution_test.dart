import 'package:cc_domain/features/pr_review/domain/value_objects/image_diff_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ImageDiffResolution round-trips refs without inventing bytes', () {
    const original = ImageDiffResolution(
      baseRef: 'blob:sha256:aa',
      headRef: 'blob:sha256:bb',
      overlayRef: 'blob:sha256:cc',
      mediaType: 'image/png',
      changedPercent: 4.2,
      isIdentical: false,
    );
    final copy = ImageDiffResolution.fromJson(original.toJson());
    expect(copy, original);
    expect(copy.toJson().containsKey('bytes'), isFalse);
  });
}

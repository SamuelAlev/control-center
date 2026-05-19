import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';

export 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/file_header.dart'
    show kPrDiffAutoCollapseThreshold;

/// Manages precomputed layout estimates for the PR diff scroll view.
class PrDiffPrecomputeManager {
  /// Creates a precompute manager with the given files.
  PrDiffPrecomputeManager({required this.files});

  /// Files being displayed.
  List<PrFile> files;

  /// Estimated height of a collapsed file header.
  static const double _collapsedFileHeightEstimate = 52;

  /// Vertical padding between files.
  static const double _filePaddingBetween = 16;

  /// Height of the diff toolbar.
  static const double _toolbarHeight = 48;

  /// Returns the estimated Y offset of file [index] in the scroll view.
  double estimatedFileTop(int index) {
    if (index <= 0) {
      return _toolbarHeight;
    }
    return _toolbarHeight +
        index * (_collapsedFileHeightEstimate + _filePaddingBetween);
  }
}

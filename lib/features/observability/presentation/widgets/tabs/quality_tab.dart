import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/benchmark_section.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/evals_section.dart';
import 'package:flutter/widgets.dart';

/// The Quality tab: the scored benchmark (pass/fail, reward, spend-per-task)
/// and the eval suites.
class QualityTab extends StatelessWidget {
  /// Creates a [QualityTab].
  const QualityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BenchmarkSection(),
          SizedBox(height: AppSpacing.lg),
          EvalsSection(),
        ],
      ),
    );
  }
}

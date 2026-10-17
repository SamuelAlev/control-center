part of 'pr_detail_screen.dart';

extension _PrDetailChecks on _PrDetailScreenState {
  List<Widget> _checks(DesignSystemTokens t) {
    final async = ref.watch(prCheckRunsProvider(_coords));
    final runs = async.value ?? const <CheckRun>[];
    if (async.isLoading && runs.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CcSpinner(size: 20)),
        ),
      ];
    }
    if (runs.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            AppLocalizations.of(context).noChecksReported,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: t.textTertiary),
          ),
        ),
      ];
    }
    return [
      for (final run in runs)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CheckRow(run: run),
        ),
    ];
  }
}

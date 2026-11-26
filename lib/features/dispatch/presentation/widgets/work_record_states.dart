import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The four states of a record page: loading (a spinner), refused (the
/// refusal's sentence by its `data.kind`), not found ([notFound]), or the
/// record ([builder]). The refused and not-found states offer the way back.
class WorkRecordStates<T> extends StatelessWidget {
  /// Creates the states.
  const WorkRecordStates({
    super.key,
    required this.value,
    required this.notFound,
    required this.builder,
    this.backLabel,
    this.onBack,
  });

  /// The record as it loads.
  final AsyncValue<T?> value;

  /// What a missing record says.
  final String notFound;

  /// The back button's label, when a back action is offered.
  final String? backLabel;

  /// Leaves the page, when a back action is offered.
  final VoidCallback? onBack;

  /// Builds the record.
  final Widget Function(T record) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value.value case final T record?) {
      return builder(record);
    }
    if (value.isLoading) {
      return const Center(child: CcSpinner());
    }
    final error = value.error;
    final back = onBack;
    final label = backLabel;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: CcEmptyState(
          icon: error != null ? AppIcons.lock : AppIcons.searchX,
          message: error != null
              ? dispatchFailureMessage(l10n, error)
              : notFound,
          action: back != null && label != null
              ? CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.arrowLeft,
                  onPressed: back,
                  child: Text(label),
                )
              : null,
        ),
      ),
    );
  }
}

/// The three states of a list: loading, refused, empty ([empty]) or the
/// rows ([builder]).
class WorkListStates<T> extends StatelessWidget {
  /// Creates the states.
  const WorkListStates({
    super.key,
    required this.value,
    required this.emptyIcon,
    required this.empty,
    required this.builder,
    this.emptyDescription,
    this.emptyAction,
  });

  /// The rows as they load.
  final AsyncValue<List<T>> value;

  /// The empty state's icon.
  final IconData emptyIcon;

  /// What an empty list says.
  final String empty;

  /// One more sentence under [empty].
  final String? emptyDescription;

  /// An action in the empty state.
  final Widget? emptyAction;

  /// Builds the rows.
  final Widget Function(List<T> rows) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value.value case final rows? when rows.isNotEmpty) {
      return builder(rows);
    }
    if (value.isLoading && !value.hasValue) {
      // Padded so the spinner keeps its room in a card that sizes to it.
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CcSpinner()),
      );
    }
    final error = value.error;
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: CcEmptyState(
          icon: error != null ? AppIcons.lock : emptyIcon,
          message: error != null ? dispatchFailureMessage(l10n, error) : empty,
          description: error != null ? null : emptyDescription,
          action: error != null ? null : emptyAction,
        ),
      ),
    );
  }
}

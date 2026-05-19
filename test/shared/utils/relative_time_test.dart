import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ONE relative-time formatter (the PR surface used to carry a second,
/// English-only copy). It resolves through `gen_l10n`, so this drives it with a
/// real localization delegate rather than asserting on hardcoded strings.
void main() {
  late BuildContext ctx;

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en')}) {
    return tester.pumpWidget(
      Localizations(
        locale: locale,
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  testWidgets('null renders as an empty string', (tester) async {
    await pump(tester);
    expect(formatRelativeTime(ctx, null), '');
  });

  testWidgets('buckets seconds / minutes / hours / days', (tester) async {
    await pump(tester);
    final l10n = AppLocalizations.of(ctx);
    final now = DateTime.now();
    expect(formatRelativeTime(ctx, now), l10n.justNow);
    expect(
      formatRelativeTime(ctx, now.subtract(const Duration(seconds: 30))),
      l10n.secondsAgo(30),
    );
    expect(
      formatRelativeTime(ctx, now.subtract(const Duration(minutes: 5))),
      l10n.minutesAgo(5),
    );
    expect(
      formatRelativeTime(ctx, now.subtract(const Duration(hours: 3))),
      l10n.hoursAgo(3),
    );
    expect(
      formatRelativeTime(ctx, now.subtract(const Duration(days: 1))),
      l10n.yesterday,
    );
    expect(
      formatRelativeTime(ctx, now.subtract(const Duration(days: 4))),
      l10n.daysAgo(4),
    );
    expect(
      formatRelativeTime(ctx, now.subtract(const Duration(days: 90))),
      l10n.monthsAgo(3),
    );
    expect(
      formatRelativeTime(ctx, now.subtract(const Duration(days: 400))),
      l10n.yearsAgo(1),
    );
  });

  testWidgets('follows the ambient locale (not English-only)', (tester) async {
    await pump(tester, locale: const Locale('fr'));
    final french = formatRelativeTime(
      ctx,
      DateTime.now().subtract(const Duration(minutes: 5)),
    );
    await pump(tester);
    final english = formatRelativeTime(
      ctx,
      DateTime.now().subtract(const Duration(minutes: 5)),
    );
    expect(french, isNot(english));
  });
}

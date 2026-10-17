import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/skill_behavior_summary.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// Previews observed and inferred behavior evidence in the light theme.
@Preview(
  name: 'Behavior evidence — light',
  group: 'Skill evaluation',
  size: Size(720, 760),
)
Widget skillBehaviorLightPreview() => const _SkillBehaviorPreview();

/// Exercises the behavior report in narrow Arabic, right-to-left chrome.
@Preview(
  name: 'Behavior evidence — narrow RTL',
  group: 'Skill evaluation',
  size: Size(390, 760),
)
Widget skillBehaviorRtlPreview() => const _SkillBehaviorPreview(rtl: true);

/// Exercises behavior evidence and status contrast in the dark theme.
@Preview(
  name: 'Behavior evidence — dark',
  group: 'Skill evaluation',
  size: Size(720, 760),
)
Widget skillBehaviorDarkPreview() => const _SkillBehaviorPreview(dark: true);

class _SkillBehaviorPreview extends StatelessWidget {
  const _SkillBehaviorPreview({this.rtl = false, this.dark = false});

  final bool rtl, dark;

  @override
  Widget build(BuildContext context) {
    final theme = dark ? CcThemeData.dark() : CcThemeData.light();
    return CcTheme(
      data: theme,
      child: WidgetsApp(
        color: theme.tokens.bgPrimary,
        debugShowCheckedModeBanner: false,
        locale: Locale(rtl ? 'ar' : 'en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        textStyle: CcFonts.ui(textStyle: CcTypography.body).copyWith(
          color: theme.tokens.textPrimary,
          decoration: TextDecoration.none,
        ),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: ColoredBox(
          color: theme.tokens.bgPrimary,
          child: const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: SkillBehaviorSummary(behavior: _previewEvidence),
            ),
          ),
        ),
      ),
    );
  }
}

// Preview-only fixture; production receives server report data.
const _previewEvidence = <String, dynamic>{
  'routing': [
    {
      'armId': 'candidate-revision',
      'truePositive': 4,
      'falsePositive': 1,
      'falseNegative': 2,
      'trueNegative': 3,
      'unknownPositive': 1,
      'unknownNegative': 2,
      'notOffered': 1,
      'precision': 0.8,
      'recall': 0.6667,
      'falsePositiveRate': 0.25,
      'forced': false,
    },
    {
      'armId': 'forced-diagnostic',
      'truePositive': 2,
      'falsePositive': 0,
      'falseNegative': 0,
      'trueNegative': 0,
      'unknownPositive': 0,
      'unknownNegative': 1,
      'notOffered': 0,
      'precision': null,
      'recall': null,
      'falsePositiveRate': null,
      'forced': true,
    },
  ],
  'safety': [
    {
      'armId': 'candidate-revision',
      'attempts': 5,
      'artifactPasses': 4,
      'policyDenials': 1,
      'protectedFileViolations': 0,
    },
  ],
  'utilityByFamily': [
    {
      'armId': 'candidate-revision',
      'family': 'workspace-policy-and-revision-review-long-family-label',
      'attempts': 8,
      'verifiedSuccesses': 6,
    },
    {
      'armId': 'baseline',
      'family': 'workspace-policy-and-revision-review-long-family-label',
      'attempts': 8,
      'verifiedSuccesses': 4,
    },
  ],
};

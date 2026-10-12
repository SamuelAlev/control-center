import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_evaluation_model_fields.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive native/built-in selection in the light theme.
@Preview(
  name: 'Evaluator adapters — light',
  group: 'Skill evaluation',
  size: Size(560, 500),
)
Widget skillEvaluationAdaptersLightPreview() => const _ModelPreview();

/// Interactive native/built-in selection in the dark theme.
@Preview(
  name: 'Evaluator adapters — dark',
  group: 'Skill evaluation',
  size: Size(560, 500),
)
Widget skillEvaluationAdaptersDarkPreview() => const _ModelPreview(dark: true);

/// Narrow Arabic layout with the locale's bundled script companion.
@Preview(
  name: 'Evaluator adapters — narrow RTL',
  group: 'Skill evaluation',
  size: Size(390, 600),
)
Widget skillEvaluationAdaptersRtlPreview() => const _ModelPreview(rtl: true);

class _ModelPreview extends StatefulWidget {
  const _ModelPreview({this.dark = false, this.rtl = false});
  final bool dark, rtl;

  @override
  State<_ModelPreview> createState() => _ModelPreviewState();
}

class _ModelPreviewState extends State<_ModelPreview> {
  String adapter = 'claude-cli';
  String? provider = 'anthropic';
  String? model = 'claude-sonnet-4-6';

  @override
  Widget build(BuildContext context) {
    final theme = widget.dark ? CcThemeData.dark() : CcThemeData.light();
    return ProviderScope(
      // Preview-only inventory. Production models and availability come from RPC.
      overrides: [
        harnessModelsProvider.overrideWith(
          (ref) async => const [
            HarnessModelInfo(
              id: 'codex/gpt-5.6-terra',
              providerId: 'codex',
              displayName: 'GPT-5.6-Terra',
            ),
          ],
        ),
        adapterModelsProvider('claude-code').overrideWith(
          (ref) async => const [
            AcpModel(id: 'claude-sonnet-4-6', name: 'Claude Sonnet 4.6'),
            AcpModel(id: 'claude-opus-4-6', name: 'Claude Opus 4.6'),
          ],
        ),
      ],
      child: WidgetsApp(
        color: theme.tokens.bgPrimary,
        debugShowCheckedModeBanner: false,
        locale: Locale(widget.rtl ? 'ar' : 'en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => CcTheme(
          data: theme,
          child: Builder(
            builder: (context) => DefaultTextStyle(
              style: CcFonts.ui(textStyle: CcTypography.body).copyWith(
                color: theme.tokens.textPrimary,
                decoration: TextDecoration.none,
              ),
              child: child!,
            ),
          ),
        ),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SkillEvaluationModelFields(
                adapter: adapter,
                providerId: provider,
                modelId: model,
                capabilities: const SkillCampaignCapabilities(
                  available: true,
                  reason: null,
                  backends: ['builtin', 'claude-cli'],
                  usageBudgetProviders: ['codex'],
                ),
                onChanged: (selection) => setState(() {
                  adapter = selection.adapter;
                  provider = selection.providerId;
                  model = selection.modelId;
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

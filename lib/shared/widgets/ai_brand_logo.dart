import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A brand whose monochrome mark ships under `assets/ai_logos/`.
///
/// Two lookups, because a provider and the models it serves are different
/// questions: Cursor or OpenRouter serve Claude, GPT and Grok models alike, so
/// a model row shows who MADE the model ([forModel]) while a provider row shows
/// who SERVES it ([forProvider]).
enum AiBrand {
  /// Control Center's own mark, for the built-in harness.
  controlCenter('control-center'),

  /// Anthropic, the API provider.
  anthropic('anthropic'),

  /// The Claude spark: Claude models, Claude Code and the Claude plan.
  claude('claude'),

  /// OpenAI, and the GPT/o-series models.
  openai('openai'),

  /// Codex, the plan and the provider.
  codex('codex'),

  /// Cursor, and its Composer models.
  cursor('cursor'),

  /// DeepSeek.
  deepseek('deepseek'),

  /// Google Gemini, and Gemma.
  gemini('gemini'),

  /// GitHub. Not an AI brand: the service status surfaces draw it beside the
  /// AI providers whose status pages they poll.
  github('github'),

  /// Grok models.
  grok('grok'),

  /// Kimi Code, and Kimi models.
  kimi('kimi'),

  /// Meta Llama models.
  meta('meta'),

  /// Mistral.
  mistral('mistral'),

  /// Moonshot, the Kimi API provider.
  moonshot('moonshot'),

  /// OpenRouter.
  openrouter('openrouter'),

  /// Qwen models.
  qwen('qwen'),

  /// xAI, the provider.
  xai('xai'),

  /// z.ai, and GLM models.
  zai('zai');

  const AiBrand(this._file);

  final String _file;

  /// The bundled single-colour SVG.
  String get asset => 'assets/ai_logos/$_file.svg';

  /// The brand of a provider, harness or adapter id; null for a custom
  /// provider or anything this table does not know.
  static AiBrand? forProvider(String id) => switch (id) {
    'cc-harness' => controlCenter,
    'claude' || 'claude-code' => claude,
    'anthropic' => anthropic,
    'openai' => openai,
    'codex' => codex,
    'cursor' => cursor,
    'deepseek' => deepseek,
    'google' => gemini,
    'kimi-code' => kimi,
    'mistral' => mistral,
    'moonshotai' => moonshot,
    'openrouter' => openrouter,
    'xai' => xai,
    'zai' || 'zai-coding' => zai,
    _ => null,
  };

  /// The vendor that made a model, read from its id and display name; null
  /// when neither names a known family (Cursor's "Auto", an alias like
  /// "best"), so the caller can fall back to the serving provider.
  ///
  /// The id's leading segment is dropped first: in `cursor/claude-opus-5` the
  /// `cursor/` says who serves the model, not who made it.
  static AiBrand? forModel(String id, {String? name}) {
    final slash = id.indexOf('/');
    final bare = slash < 0 ? id : id.substring(slash + 1);
    final haystack = '$bare ${name ?? ''}'.toLowerCase();
    for (final (pattern, brand) in _families) {
      if (pattern.hasMatch(haystack)) {
        return brand;
      }
    }
    return null;
  }

  // Order matters only where families could overlap; none of these do today.
  static final _families = <(RegExp, AiBrand)>[
    (RegExp(r'\b(claude|opus|sonnet|haiku|fable)'), claude),
    (RegExp(r'\bgrok'), grok),
    (RegExp(r'\b(gpt|chatgpt|codex|o[1-9]\b|davinci)'), openai),
    (RegExp(r'\b(gemini|gemma)'), gemini),
    (RegExp(r'\b(composer|cursor)'), cursor),
    (RegExp(r'\bglm'), zai),
    (RegExp(r'\bkimi'), kimi),
    (RegExp(r'\bdeepseek'), deepseek),
    (
      RegExp(r'\b(mistral|mixtral|codestral|devstral|magistral|ministral)'),
      mistral,
    ),
    (RegExp(r'\bllama'), meta),
    (RegExp(r'\b(qwen|qwq)'), qwen),
  ];
}

/// An [AiBrand]'s mark tinted to [color], or a neutral glyph when [brand] is
/// null (a custom provider) or its asset fails to load — never a hole, so a
/// column of rows keeps its alignment.
class AiBrandLogo extends StatelessWidget {
  /// Creates an [AiBrandLogo].
  const AiBrandLogo({
    required this.brand,
    required this.color,
    this.size = 14,
    super.key,
  });

  /// The brand to draw; null draws the neutral fallback.
  final AiBrand? brand;

  /// The tint; every mark is single-colour by contract.
  final Color color;

  /// Rendered edge length in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(AppIcons.cpu, size: size, color: color);
    final brand = this.brand;
    if (brand == null) {
      return fallback;
    }
    // Decorative: every placement sits beside the brand's name in text.
    return ExcludeSemantics(
      child: SvgPicture.asset(
        brand.asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (_) => SizedBox(width: size, height: size),
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

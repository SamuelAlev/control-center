/// Friction signals extracted from a single user message's raw text.
///
/// The counts measure how much frustration the operator is expressing at the agent: yelling,
/// profanity, anguished interjections, negations ("no, that's not it"),
/// repetition ("like I said") and blame ("you forgot ...").
class FrictionMetrics {
  /// Creates a [FrictionMetrics] with explicit signal counts.
  const FrictionMetrics({
    this.chars = 0,
    this.words = 0,
    this.yelling = 0,
    this.profanity = 0,
    this.anguish = 0,
    this.negation = 0,
    this.repetition = 0,
    this.blame = 0,
  });

  /// Total character count of the original message.
  final int chars;

  /// Whitespace-delimited word count of the original message.
  final int words;

  /// Number of all-caps "shouting" sentences.
  final int yelling;

  /// Number of profanity occurrences.
  final int profanity;

  /// Number of anguished interjections ("nooo", "ughhh", "!!!", "...").
  final int anguish;

  /// Number of corrective negations ("no", "that's not what I meant").
  final int negation;

  /// Number of repetition cues ("like I said", "still doesn't work").
  final int repetition;

  /// Number of blaming phrases ("you forgot", "stop doing X").
  final int blame;

  /// Sum of the six friction signals (excludes [chars] and [words]).
  int get totalSignals =>
      yelling + profanity + anguish + negation + repetition + blame;

  /// A [FrictionMetrics] with every field at zero.
  static const empty = FrictionMetrics();

  @override
  /// Structural equality.
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrictionMetrics &&
          chars == other.chars &&
          words == other.words &&
          yelling == other.yelling &&
          profanity == other.profanity &&
          anguish == other.anguish &&
          negation == other.negation &&
          repetition == other.repetition &&
          blame == other.blame;

  @override
  /// Hash based on all fields.
  int get hashCode => Object.hash(
    chars,
    words,
    yelling,
    profanity,
    anguish,
    negation,
    repetition,
    blame,
  );

  @override
  String toString() =>
      'FrictionMetrics(chars: $chars, words: $words, '
      'yelling: $yelling, profanity: $profanity, anguish: $anguish, '
      'negation: $negation, repetition: $repetition, blame: $blame)';
}

/// Analyzes the raw text of a single user message and returns friction
/// signal counts as [FrictionMetrics].
///
/// The analyzer strips structured noise (code blocks, HTML, URLs, file
/// mentions, quotes) before counting and gates the signal counts so that a
/// long, deliberately formatted prompt is not mistaken for a tantrum.
class FrictionAnalyzer {
  /// Creates a [FrictionAnalyzer].
  const FrictionAnalyzer();

  /// Minimum non-empty prose lines above which signal counting is suppressed.
  ///
  /// Formatted prompts (3+ lines) are intentional, not frustrated, so all six
  /// signals are forced to zero.
  static const lineGateThreshold = 3;

  /// Fraction of uppercase letters above which a sentence counts as yelling.
  static const yellingThreshold = 0.5;

  /// Minimum letters a sentence must contain to be eligible for yelling.
  static const minLetters = 4;

  // --- Preprocessing patterns (applied in order, see [_toProse]). ---
  static final _fencedCode = RegExp(r'```[\s\S]*?```');
  static final _pairedTag = RegExp(r'<([a-zA-Z][\w-]*)[^>]*>[\s\S]*?</\1>');
  static final _bareTag = RegExp(r'<[^>]+>');
  static final _inlineCode = RegExp(r'`[^`]*`');
  static final _url = RegExp(r'https?://\S+');
  static final _fileMention = RegExp(r'(?:^|\s)@[\w./-]+');
  static final _quoteLine = RegExp(r'(?:^|\n)\s*>[^\n]*', multiLine: true);
  static final _imageMarker = RegExp(r'\[Image #\d+\]');
  static final _ansiEscape = RegExp(r'\x1b\[[0-9;]*m');

  // --- Counting patterns / data. ---
  static final _wordSplit = RegExp(r'\s+');
  static final _sentenceSplit = RegExp(r'[.!?]+|\n');
  static final _letter = RegExp('[a-zA-Z]');
  static final _upperLetter = RegExp('[A-Z]');

  /// Common English profanity terms (case-insensitive, word-boundary matched).
  /// Includes the deliberate "grr" frustration grunt from the source port.
  static const _profanityWords = <String>[
    'fuck',
    'fucking',
    'fucked',
    'fucker',
    'motherfucker',
    'shit',
    'shitty',
    'bullshit',
    'damn',
    'damned',
    'goddamn',
    'goddammit',
    'dammit',
    'crap',
    'crappy',
    'hell',
    'ass',
    'asshole',
    'jackass',
    'dumbass',
    'arse',
    'bitch',
    'bitching',
    'bastard',
    'dick',
    'dickhead',
    'piss',
    'pissed',
    'cunt',
    'prick',
    'bollocks',
    'bloody',
    'wanker',
    'twat',
    'douche',
    'douchebag',
    'wtf',
    'stfu',
    'fml',
    'omfg',
    'ffs',
    'gtfo',
    'lmfao',
    'grr',
  ];

  static final _profanity = RegExp(
    r'\b(?:' + _profanityWords.join('|') + r')\b',
    caseSensitive: false,
  );

  static final _dramaRuns = RegExp(r'[!?][!?1]{2,}');
  static final _interjections = RegExp(
    r'no{3,}|a+h{2,}|u+g+h{2,}|a+r+g+h+|st+o{3,}p+|w+h+y{3,}|'
    r'o+m+g{2,}|ye+s{3,}|br+u+h{2,}',
    caseSensitive: false,
  );
  static final _dude = RegExp(r'\bdude\b', caseSensitive: false);
  static final _ellipsis = RegExp(r'\.{2,}');

  static final _negationLead = RegExp(
    r'(?:^|\n)\s*(?:no|nope|nah|nvm|wrong|incorrect)\b',
    caseSensitive: false,
    multiLine: true,
  );
  static final _negationPhrase = RegExp(
    r"\b(?:that'?s\s+not\s+(?:what|right|it)|"
    r'not\s+what\s+i\s+(?:meant|asked|said|wanted))\b',
    caseSensitive: false,
  );

  static final _repetitionSaid = RegExp(
    r'\b(?:(?:like|as)\s+i\s+(?:said|told\s+you|asked)|'
    r'i\s+(?:meant|said|told\s+you|asked\s+you|'
    r'already\s+(?:said|told|did|asked|wrote)))\b',
    caseSensitive: false,
  );
  static final _repetitionStill = RegExp(
    r"\bstill\s+(?:doesn'?t|doesnt|isn'?t|isnt|not|broken|wrong|"
    r'fails|failing|the\s+same|same)\b',
    caseSensitive: false,
  );

  static final _blameYou = RegExp(
    r"\byou\s+(?:didn'?t|did\s+not|broke|missed|forgot|keep|"
    r'always|never|still|ignored)\b',
    caseSensitive: false,
  );
  static final _blameStop = RegExp(
    r'(?:^|[.!?\n])\s*stop\s+\w+ing\b',
    caseSensitive: false,
    multiLine: true,
  );

  /// Computes [FrictionMetrics] for [text].
  ///
  /// `chars` and `words` are always counted from the original [text]. The six
  /// signals are computed from the stripped "prose" and are forced to zero
  /// when the prose has [lineGateThreshold] or more non-empty lines.
  FrictionMetrics analyze(String text) {
    final chars = text.length;
    final words = text
        .trim()
        .split(_wordSplit)
        .where((w) => w.isNotEmpty)
        .length;

    final prose = _toProse(text);

    final nonEmptyLines = prose
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;
    if (nonEmptyLines >= lineGateThreshold) {
      return FrictionMetrics(chars: chars, words: words);
    }

    return FrictionMetrics(
      chars: chars,
      words: words,
      yelling: _countYelling(prose),
      profanity: _profanity.allMatches(prose).length,
      anguish: _countAnguish(prose),
      negation:
          _negationLead.allMatches(prose).length +
          _negationPhrase.allMatches(prose).length,
      repetition:
          _repetitionSaid.allMatches(prose).length +
          _repetitionStill.allMatches(prose).length,
      blame:
          _blameYou.allMatches(prose).length +
          _blameStop.allMatches(prose).length,
    );
  }

  /// Strips structured noise from [text] in the source-defined order.
  String _toProse(String text) {
    return text
        .replaceAll(_fencedCode, '\n')
        .replaceAllMapped(_pairedTag, (_) => '\n')
        .replaceAll(_bareTag, ' ')
        .replaceAll(_inlineCode, ' ')
        .replaceAll(_url, ' ')
        .replaceAll(_fileMention, ' ')
        .replaceAll(_quoteLine, '')
        .replaceAll(_imageMarker, ' ')
        .replaceAll(_ansiEscape, '');
  }

  /// Counts all-caps "shouting" sentences in [prose].
  int _countYelling(String prose) {
    var count = 0;
    for (final sentence in prose.split(_sentenceSplit)) {
      final letters = _letter.allMatches(sentence).length;
      if (letters < minLetters) {
        continue;
      }
      final uppers = _upperLetter.allMatches(sentence).length;
      if (uppers / letters > yellingThreshold) {
        count++;
      }
    }
    return count;
  }

  /// Counts anguished interjections, drama runs, "dude" and ellipses.
  int _countAnguish(String prose) {
    return _dramaRuns.allMatches(prose).length +
        _interjections.allMatches(prose).length +
        _dude.allMatches(prose).length +
        _ellipsis.allMatches(prose).length;
  }
}

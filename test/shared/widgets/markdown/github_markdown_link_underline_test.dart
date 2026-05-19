import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/github_reference_link_builder.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// App-wired GitHub markdown still uses cc_markdown's offset underline painter
/// (not the engine's baseline-hugging decoration) under a SelectionArea.
///
/// Pixel goldens of this path are platform-fragile: `appMarkdownStyle` names
/// Manrope, and Linux CI rasterizes it differently from a macOS capture. The
/// painter itself is pinned by `packages/cc_markdown/test/render/link_underline_test.dart`
/// (Ahem, no family). This test pins the *wiring*.
void main() {
  testWidgets(
    'selectable GitHub markdown strips the engine underline and paints one',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CcTheme(
              data: CcThemeData.light(),
              child: Builder(
                builder: (context) {
                  final style = appMarkdownStyle(context);
                  return CcMarkdown(
                    data:
                        'Inline: [See analysis details on SonarQube Cloud](https://sonarcloud.io/dashboard) and a ref #123.',
                    selectable: true,
                    style: style,
                    plugins: githubMarkdownPlugins,
                    options: githubMarkdownOptions,
                    builders: githubMarkdownBuilders.withOverrides(const {
                      'link': GitHubReferenceLinkBuilder(
                        currentOwner: 'o',
                        currentRepo: 'r',
                        knownWorkspaceRepos: {},
                      ),
                    }),
                    onTapLink: (_) {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'See analysis details on SonarQube Cloud',
          findRichText: true,
        ),
        findsOneWidget,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(_hasEngineUnderline(richText.text), isFalse);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.foregroundPainter != null &&
              w.child is Text,
        ),
        findsOneWidget,
      );
    },
  );
}

bool _hasEngineUnderline(InlineSpan span) {
  if (span is! TextSpan) {
    return false;
  }
  final decoration = span.style?.decoration;
  if (decoration != null && decoration.contains(TextDecoration.underline)) {
    return true;
  }
  return (span.children ?? const <InlineSpan>[]).any(_hasEngineUnderline);
}

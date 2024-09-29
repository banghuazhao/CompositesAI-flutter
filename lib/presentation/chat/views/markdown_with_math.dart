import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownWithMath extends StatelessWidget {
  final String markdownData;

  MarkdownWithMath({required this.markdownData});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdownData,
      selectable: true,
      // For better user experience
      builders: {'h5': InlineMathBuilder(), 'h4': NewlineMathBuilder()},
      inlineSyntaxes: [MathInlineSyntax(), MathNewlineSyntax()],
      // Custom inline syntax for inline math
      styleSheet: MarkdownStyleSheet(),
    );
  }
}

// Custom inline syntax to detect inline math ($...$)
class MathInlineSyntax extends md.InlineSyntax {
  MathInlineSyntax() : super(r'\\\((.+?)\\\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final mathExpression = match.group(1) ?? "";
    // print("Inline equation:" + mathExpression);
    // h4 is used for math equations. If there is h4 element, it will be render by math
    final element = md.Element.text("h5", mathExpression);
    parser.addNode(element); // Add the custom math node
    return true;
  }
}

// Custom inline syntax to detect inline math ($...$)
class MathNewlineSyntax extends md.InlineSyntax {
  MathNewlineSyntax() : super(r'\\\[((.|\n)+?)\\\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final mathExpression = match.group(1) ?? "";
    // print("New line equation: " + mathExpression);
    // h4 is used for math equations. If there is h4 element, it will be render by math
    final element = md.Element.text("h4", mathExpression);
    parser.addNode(element); // Add the custom math node
    return true;
  }
}

// Override the widget rendering for inline math
class NewlineMathBuilder extends MarkdownElementBuilder {
  @override
  Widget visitText(md.Text text, TextStyle? preferredStyle) {
    final mathExpression = text.text;
    // print("Math equation detected: $mathExpression");
    return Math.tex(mathExpression, textStyle: preferredStyle);
  }
}

class InlineMathBuilder extends MarkdownElementBuilder {
  @override
  Widget visitText(md.Text text, TextStyle? preferredStyle) {
    final mathExpression = text.text;
    // print("Math equation detected: $mathExpression");
    return Math.tex(mathExpression,
        mathStyle: MathStyle.text, textStyle: preferredStyle);
  }
}

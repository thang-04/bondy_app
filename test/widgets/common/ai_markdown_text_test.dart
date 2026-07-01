import 'package:bondy/widgets/common/ai_markdown_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders markdown without exposing raw markers', (tester) async {
    const markdown = '''
## Goi y nhe

1. **Mo loi tu nhien** - hoi ve so thich chung.
2. Giu tin nhan ngan gon.

- Dung giong am ap
- Trao quyen cho nguoi dung
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AiMarkdownText(data: markdown)),
      ),
    );

    expect(find.text('Goi y nhe', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('Mo loi tu nhien', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Dung giong am ap', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('##', findRichText: true), findsNothing);
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });

  testWidgets('uses the supplied text color for normal body content', (
    tester,
  ) async {
    const bodyColor = Color(0xFF123456);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiMarkdownText(data: 'Plain response', color: bodyColor),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Plain response'),
      ),
    );
    expect(
      _spanWithTextHasColor(richText.text, 'Plain response', bodyColor),
      isTrue,
    );
  });
}

bool _spanWithTextHasColor(InlineSpan span, String text, Color color) {
  if (span is! TextSpan) return false;

  if ((span.text?.contains(text) ?? false) && span.style?.color == color) {
    return true;
  }

  return span.children?.any(
        (child) => _spanWithTextHasColor(child, text, color),
      ) ??
      false;
}

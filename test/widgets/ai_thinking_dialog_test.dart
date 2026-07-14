import 'package:bondy/widgets/common/ai_thinking_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('show hiển thị popup với chữ trạng thái mặc định', (tester) async {
    final controller = AiThinkingController();
    late BuildContext ctx;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    controller.show(ctx);
    // Không dùng pumpAndSettle vì animation dots lặp vô hạn.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.isVisible, isTrue);
    expect(find.text('Bondy đang suy nghĩ…'), findsOneWidget);

    controller.hide(ctx);
    await tester.pumpAndSettle();

    expect(controller.isVisible, isFalse);
    expect(find.text('Bondy đang suy nghĩ…'), findsNothing);
  });

  testWidgets('nhận danh sách chữ trạng thái tùy biến theo persona', (
    tester,
  ) async {
    final controller = AiThinkingController();
    late BuildContext ctx;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    controller.show(ctx, messages: const ['Đang lật những lá bài…']);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Đang lật những lá bài…'), findsOneWidget);

    controller.hide(ctx);
    await tester.pumpAndSettle();
  });

  testWidgets('gọi show hai lần chỉ mở một popup', (tester) async {
    final controller = AiThinkingController();
    late BuildContext ctx;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    controller.show(ctx);
    controller.show(ctx);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AiThinkingDialog), findsOneWidget);

    controller.hide(ctx);
    await tester.pumpAndSettle();
    expect(find.byType(AiThinkingDialog), findsNothing);
  });
}

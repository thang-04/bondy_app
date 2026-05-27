import 'package:bondy/widgets/match/new_match_receipt_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders compatibility receipt and triggers actions', (
    tester,
  ) async {
    var openedChat = false;
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: NewMatchReceiptSheet(
              otherUserName: 'Linh',
              compatibilityScore: 82,
              factors: const [
                NewMatchReceiptFactor(label: 'Tính cách', score: 81),
                NewMatchReceiptFactor(label: 'Sở thích', score: 74),
                NewMatchReceiptFactor(label: 'Mục tiêu', score: 68),
              ],
              onOpenChat: () => openedChat = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Vì sao hai bạn match?'), findsOneWidget);
    expect(find.text('Bạn và Linh có nhiều điểm đồng điệu'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
    expect(find.text('Tính cách'), findsOneWidget);
    expect(find.text('Sở thích'), findsOneWidget);
    expect(find.text('Mục tiêu'), findsOneWidget);
    expect(find.text('Xem & nhắn tin'), findsOneWidget);
    expect(find.text('Đóng'), findsOneWidget);

    await tester.tap(find.text('Xem & nhắn tin'));
    expect(openedChat, isTrue);

    await tester.tap(find.text('Đóng'));
    expect(dismissed, isTrue);
  });
}

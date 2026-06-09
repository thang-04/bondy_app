import 'package:bondy/models/user_profile_model.dart';
import 'package:bondy/screens/home/main_shell_screen.dart';
import 'package:bondy/services/profile_service.dart';
import 'package:bondy/services/chat_service.dart';
import 'package:bondy/services/relationship_service.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/viewmodels/chat/chat_viewmodel.dart';
import 'package:bondy/viewmodels/relationship/relationship_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class _FakeChatService extends ChatService {
  _FakeChatService() : super(ApiClient());

  @override
  Future<List<ChatMatch>> listChats() async => [];
}

class _FakeRelationshipService extends RelationshipService {
  @override
  Future<RelationshipDashboard> getDashboard() async {
    return RelationshipDashboard(
      hasRelationship: false,
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('profile tab loads current account and opens edit profile', (
    tester,
  ) async {
    final profileService = _FakeProfileService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ChatViewModel(service: _FakeChatService()),
          ),
          ChangeNotifierProvider(
            create: (_) => RelationshipViewModel(service: _FakeRelationshipService()),
          ),
        ],
        child: MaterialApp(
          routes: {
            '/': (context) => MainShellScreen(profileService: profileService),
            '/edit-profile': (context) =>
                const Scaffold(body: Text('edit profile screen')),
            '/discover': (context) => const Scaffold(body: Text('discover')),
            '/chatbot': (context) => const Scaffold(body: Text('chatbot')),
            '/relationship/home': (context) =>
                const Scaffold(body: Text('relationship')),
            '/settings/premium': (context) =>
                const Scaffold(body: Text('premium')),
            '/settings/change-password': (context) =>
                const Scaffold(body: Text('change password')),
          },
        ),
      ),
    );

    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump();

    expect(profileService.getProfileCalls, 1);
    expect(find.text('Linh Tran'), findsOneWidget);
    expect(find.textContaining('linh@example.com'), findsOneWidget);
    expect(find.textContaining('Yeu cafe va am nhac'), findsOneWidget);
    expect(find.text('Người dùng Bondy'), findsNothing);

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    expect(find.text('edit profile screen'), findsOneWidget);
  });
}

class _FakeProfileService extends ProfileService {
  int getProfileCalls = 0;

  @override
  Future<UserProfileModel> getProfile() async {
    getProfileCalls++;
    return UserProfileModel(
      id: 'user-id',
      email: 'linh@example.com',
      name: 'Fallback Name',
      fullName: 'Linh Tran',
      city: 'Ho Chi Minh',
      bio: 'Yeu cafe va am nhac',
      gender: 'Nữ',
    );
  }

  @override
  Future<Map<String, dynamic>> getProfileStats() async {
    return {'streakDays': 7, 'matchCount': 3, 'weeklyActivities': 5};
  }
}

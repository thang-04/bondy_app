import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth/auth_viewmodel.dart';
import 'viewmodels/survey/survey_viewmodel.dart';

// Auth screens
import 'screens/auth/auth_gate_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/sign_up_phone_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/set_password_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/auth/basic_profile_setup_screen.dart';
import 'screens/auth/image_upload_screen.dart';
import 'screens/auth/google_map_location_screen.dart';

// Survey screens
import 'screens/survey/survey_intro_screen.dart';
import 'screens/survey/survey_question_screen.dart';
import 'screens/survey/survey_result_screen.dart';

// Main app screens
import 'screens/home/main_shell_screen.dart';

// Discover screens
import 'screens/discover/discover_matching_screen.dart';
import 'screens/discover/profile_detail_screen.dart';
import 'screens/discover/softened_discover_screen.dart';

// Chat screens
import 'screens/chat/matches_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/healing_chatbot_coach_screen.dart';
import 'screens/chat/active_chat_deeper_prompts_screen.dart';

// Healing screens
import 'screens/healing/content_hub_library_screen.dart';

// Social screens
import 'screens/social/weekend_date_suggestions_screen.dart';

// Relationship screens
import 'screens/relationship/relationship_home_dashboard.dart';
import 'screens/relationship/couples_emotions_checkin.dart';
import 'screens/relationship/conflict_resolution_tool.dart';
import 'screens/relationship/milestone_reminders_screen.dart';
import 'screens/relationship/relationship_confirmed_screen.dart';
import 'screens/relationship/relationship_invitation_screen.dart';

// Settings screens
import 'screens/settings/premium_paywall_screen.dart';
import 'screens/settings/change_password_screen.dart';
import 'screens/profile/edit_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env not found in assets - will use fallback URLs
  }
  runApp(const BondyApp());
}

class BondyApp extends StatelessWidget {
  const BondyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => SurveyViewModel()),
        // Add more viewmodels here later
      ],
      child: MaterialApp(
        title: 'Bondy',
      debugShowCheckedModeBanner: false,
      theme: BondyTheme.lightTheme,
      initialRoute: '/auth-gate',
      routes: {
        '/auth-gate': (context) => const AuthGateScreen(),
        '/': (context) => const OnboardingScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/sign-up': (context) => const SignUpPhoneScreen(),
        '/otp': (context) => const OtpVerificationScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const SetPasswordScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/profile-setup': (context) => const BasicProfileSetupScreen(),
        '/survey/intro': (context) => const SurveyIntroScreen(),
        '/survey/question': (context) => const SurveyQuestionScreen(),
        '/image-upload': (context) => const ImageUploadScreen(),
        '/location-setup': (context) => const GoogleMapLocationScreen(),
        '/survey/result': (context) => const SurveyResultScreen(),
        '/home': (context) => const MainShellScreen(),
        '/discover': (context) => const DiscoverMatchingScreen(),
        '/discover/softened': (context) => const SoftenedDiscoverScreen(),
        '/profile-detail': (context) => const ProfileDetailScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/matches': (context) => const MatchesListScreen(),
        '/chat': (context) => const ChatScreen(),
        '/chatbot': (context) => const HealingChatbotCoachScreen(),
        '/chat/deeper': (context) => const ActiveChatDeeperPromptsScreen(),
        '/content': (context) => const ContentHubLibraryScreen(),
        '/date-suggestions': (context) => const WeekendDateSuggestionsScreen(),
        '/relationship/home': (context) => const RelationshipHomeDashboard(),
        '/relationship/checkin': (context) => const CouplesEmotionsCheckin(),
        '/relationship/conflict-tool': (context) => const ConflictResolutionTool(),
        '/relationship/milestones': (context) => const MilestoneRemindersScreen(),
        '/relationship/confirmed': (context) => const RelationshipConfirmedScreen(),
        '/relationship/invite': (context) => const RelationshipInvitationScreen(),
        '/settings/premium': (context) => const PremiumPaywallScreen(),
        '/settings/change-password': (context) => const ChangePasswordScreen(),
      },
    ));
  }
}

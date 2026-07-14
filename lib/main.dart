import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'viewmodels/auth/auth_viewmodel.dart';
import 'viewmodels/chat/chat_viewmodel.dart';
import 'viewmodels/ai/ai_quota_viewmodel.dart';
import 'viewmodels/relationship/relationship_viewmodel.dart';
import 'viewmodels/survey/survey_viewmodel.dart';
import 'viewmodels/subscription/subscription_viewmodel.dart';
import 'services/analytics_service.dart';

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
import 'screens/auth/verify_otp_screen.dart';
import 'screens/auth/set_new_password_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/auth/basic_profile_setup_screen.dart';
import 'screens/auth/interests_setup_screen.dart';
import 'screens/auth/image_upload_screen.dart';
import 'screens/auth/google_map_location_screen.dart';
import 'screens/auth/match_preferences_setup_screen.dart';

// Survey screens
import 'screens/survey/survey_intro_screen.dart';
import 'screens/survey/survey_question_screen.dart';
import 'screens/survey/survey_result_screen.dart';
import 'screens/survey/deep_match_setup_screen.dart';

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
import 'screens/chat/bondy_ai_chat_screen.dart';
import 'screens/chat/active_chat_deeper_prompts_screen.dart';
import 'screens/chat/ai_hub_screen.dart';
import 'screens/chat/ai_mode_intake_screen.dart';
import 'screens/chat/zodiac_ai_chat_screen.dart';
import 'screens/chat/tarot_reading_screen.dart';
import 'screens/chat/emotional_checkin_ai_screen.dart';
import 'widgets/common/ai_chat_bubble.dart';
import 'widgets/common/ai_bubble_route_observer.dart';
import 'screens/chat/chat_info_screen.dart';

// Healing screens
import 'screens/healing/content_hub_library_screen.dart';
import 'screens/healing/healing_article_detail_screen.dart';
import 'screens/healing/healing_audio_player_screen.dart';
import 'screens/healing/healing_course_detail_screen.dart';
import 'screens/healing/healing_exercise_detail_screen.dart';
import 'screens/healing/healing_plan_screen.dart';
import 'screens/healing/checkin_result_bridge_screen.dart';
import 'screens/healing/reflection_complete_sheet.dart';

// Social screens
import 'screens/social/weekend_date_suggestions_screen.dart';

// Relationship screens
import 'screens/relationship/relationship_home_dashboard.dart';
import 'screens/relationship/couples_emotions_checkin.dart';
import 'screens/relationship/conflict_resolution_tool.dart';
import 'screens/relationship/milestone_reminders_screen.dart';
import 'screens/relationship/relationship_confirmed_screen.dart';
import 'screens/relationship/relationship_invitation_screen.dart';
import 'screens/relationship/relationship_connected_screen.dart';
import 'screens/relationship/relationship_timeline_screen.dart';

// Match screens
import 'screens/match/match_confirmation_screen.dart';

// Safety screens
import 'screens/safety/pre_date_checkin_screen.dart';
import 'screens/safety/active_checkin_screen.dart';

// Relationship extras
import 'screens/relationship/weekly_report_screen.dart';

// Settings screens
import 'screens/settings/premium_paywall_screen.dart';
import 'screens/settings/profile_privacy_screen.dart';
import 'screens/settings/change_password_screen.dart';
import 'screens/settings/notification_prefs_screen.dart';
import 'screens/settings/blocked_users_screen.dart';
import 'screens/settings/account_delete_screen.dart';
import 'screens/profile/edit_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase on all platforms (incl. Web). Failures are caught and
  // logged so a missing CDN / ad-blocker on web can't crash app startup.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Hide Android gesture bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  await loadRuntimeEnvironment();

  bool analyticsEnabled = resolveAnalyticsEnabled(
    environment: dotenv.isInitialized ? dotenv.env : const <String, String>{},
    environmentLoaded: dotenv.isInitialized,
  );
  String sentryDsn = '';
  String appEnv = 'production';

  if (dotenv.isInitialized) {
    sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
    appEnv = dotenv.env['APP_ENV'] ?? 'production';
  }

  // Analytics: --dart-define wins, then runtime env, then web release fallback.
  analytics.configure(enabled: analyticsEnabled);
  analytics.appOpen();

  // Crash reporting via Sentry — reads SENTRY_DSN from .env
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 0.2;
      options.environment = appEnv;
    }, appRunner: () => runApp(const BondyApp()));
  } else {
    // Sentry not configured — run normally.
    // Forward Flutter framework errors to the logger so they remain visible.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
    runApp(const BondyApp());
  }
}

Future<void> loadRuntimeEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
    return;
  } catch (_) {
    // .env may be rewritten by hosting or intentionally absent.
  }

  try {
    await dotenv.load(fileName: 'env.txt');
  } catch (_) {
    // No runtime env asset bundled — platform defaults will be used.
  }
}

List<NavigatorObserver> buildAnalyticsObservers() {
  try {
    return [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)];
  } catch (e) {
    debugPrint('Firebase Analytics observer unavailable: $e');
    return const <NavigatorObserver>[];
  }
}

class BondyApp extends StatelessWidget {
  const BondyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => SurveyViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => AiQuotaViewModel()..loadQuota()),
        ChangeNotifierProvider(create: (_) => RelationshipViewModel()),
        ChangeNotifierProvider(
          create: (_) => SubscriptionViewModel()..loadSubscription(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: aiNavigatorKey,
        title: 'Bondy',
        debugShowCheckedModeBanner: false,
        theme: BondyTheme.lightTheme,
        navigatorObservers: [
          ...buildAnalyticsObservers(),
          AiBubbleRouteObserver(),
          aiHubRouteObserver,
        ],
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final isWebLarge = mediaQuery.size.width > 500;

          // Bọc toàn bộ app trong AiChatBubble một lần duy nhất
          Widget appContent = AiChatBubble(
            key: aiBubbleKey,
            child: child ?? const SizedBox(),
          );

          if (isWebLarge) {
            return Scaffold(
              backgroundColor: const Color(
                0xFFFFFBF9,
              ), // Match Bondy background color
              body: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: appContent,
                    ),
                  ),
                ),
              ),
            );
          }
          return appContent;
        },

        // Internationalisation
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi'), Locale('en')],
        locale: const Locale('vi'), // default locale

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
          '/verify-otp': (context) {
            final email =
                ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return VerifyOtpScreen(email: email);
          },
          '/set-new-password': (context) {
            final email =
                ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return SetNewPasswordScreen(email: email);
          },
          '/verify-email': (context) => const VerifyEmailScreen(),
          '/profile-setup': (context) => const BasicProfileSetupScreen(),
          '/match-preferences/setup': (context) =>
              const MatchPreferencesSetupScreen(),
          '/interests-setup': (context) => const InterestsSetupScreen(),
          '/survey/intro': (context) => const SurveyIntroScreen(),
          '/survey/question': (context) => const SurveyQuestionScreen(),
          '/image-upload': (context) => const ImageUploadScreen(),
          '/location-setup': (context) => const GoogleMapLocationScreen(),
          '/survey/result': (context) => const SurveyResultScreen(),
          '/deep-match/setup': (context) => const DeepMatchSetupScreen(),
          '/home': (context) => const MainShellScreen(),
          '/home/healing': (context) => const MainShellScreen(initialIndex: 1),
          '/home/matches': (context) => const MainShellScreen(initialIndex: 2),
          '/home/profile': (context) => const MainShellScreen(initialIndex: 3),
          '/discover': (context) => const DiscoverMatchingScreen(),
          '/discover/softened': (context) => const SoftenedDiscoverScreen(),
          '/profile-detail': (context) => const ProfileDetailScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/matches': (context) => const MatchesListScreen(),
          '/chat': (context) => const ChatScreen(),
          '/chat/info': (context) => const ChatInfoScreen(),
          '/chatbot': (context) => const HealingChatbotCoachScreen(),
          '/ai-hub': (context) => const AiHubScreen(),
          '/ai-mode-intake': (context) => const AiModeIntakeScreen(),
          '/bondy-ai': (context) => const BondyAIChatScreen(),
          '/zodiac-ai': (context) => const ZodiacAiChatScreen(),
          '/tarot-reading': (context) => const TarotReadingScreen(),
          '/emotional-checkin-ai': (context) =>
              const EmotionalCheckinAiScreen(),
          '/healing/article-detail': (context) =>
              const HealingArticleDetailScreen(),
          '/healing/exercise-detail': (context) =>
              const HealingExerciseDetailScreen(),
          '/healing/course-detail': (context) =>
              const HealingCourseDetailScreen(),
          '/healing/plan': (context) => const HealingPlanScreen(),
          '/healing/audio-player': (context) =>
              const HealingAudioPlayerScreen(),
          '/healing/checkin-result': (context) =>
              const CheckinResultBridgeScreen(),
          '/healing/reflection-complete': (context) =>
              const ReflectionCompleteSheet(),
          '/chat/deeper': (context) => const ActiveChatDeeperPromptsScreen(),
          '/content': (context) => const ContentHubLibraryScreen(),
          '/date-suggestions': (context) =>
              const WeekendDateSuggestionsScreen(),
          '/relationship/home': (context) => const RelationshipHomeDashboard(),
          '/relationship/timeline': (context) =>
              const RelationshipTimelineScreen(),
          '/relationship/checkin': (context) => const CouplesEmotionsCheckin(),
          '/relationship/conflict-tool': (context) =>
              const ConflictResolutionTool(),
          '/relationship/milestones': (context) =>
              const MilestoneRemindersScreen(),
          '/relationship/confirmed': (context) =>
              const RelationshipConfirmedScreen(),
          '/relationship/invite': (context) =>
              const RelationshipInvitationScreen(),
          '/relationship/established': (context) =>
              const RelationshipConnectedScreen(),
          '/relationship/weekly-report': (context) =>
              const WeeklyReportScreen(),
          '/safety/pre-date-checkin': (context) => const PreDateCheckinScreen(),
          '/safety/active': (context) => const ActiveCheckinBanner(),
          '/community': (context) => const CommunityFeedScreen(),
          '/settings/premium': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final initialTab = args is Map<String, dynamic>
                ? (args['initialTab'] ?? args['tab'])?.toString()
                : null;
            return PremiumPaywallScreen(initialTab: initialTab);
          },
          '/settings/privacy': (context) => const ProfilePrivacyScreen(),
          '/settings/change-password': (context) =>
              const ChangePasswordScreen(),
          '/settings/notifications': (context) =>
              const NotificationPrefsScreen(),
          '/settings/blocked': (context) => const BlockedUsersScreen(),
          '/settings/account-delete': (context) => const AccountDeleteScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/match-confirm':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) =>
                    MatchConfirmationScreen(matchId: args['matchId'] as String),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}

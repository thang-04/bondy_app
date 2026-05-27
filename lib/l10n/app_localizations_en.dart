// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bondy';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get logout => 'Logout';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get emailHint => 'Your email';

  @override
  String get passwordHint => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account? Register';

  @override
  String get registerTitle => 'Register';

  @override
  String get otpTitle => 'Enter OTP';

  @override
  String otpSentTo(String email) {
    return 'OTP sent to $email';
  }

  @override
  String get profileSetupTitle => 'Set up profile';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get matchesTitle => 'Matches';

  @override
  String get healingTitle => 'Healing';

  @override
  String get sendMessage => 'Send';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get matchConfirmed => 'Match confirmed! 🎉';

  @override
  String get reportUser => 'Report user';

  @override
  String get blockUser => 'Block user';

  @override
  String get unmatch => 'Unmatch';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account?';

  @override
  String get crisisHotline => 'Crisis Support Line';

  @override
  String get delete => 'Delete';

  @override
  String get chatTitle => 'Messages';

  @override
  String get profileTitle => 'Profile';

  @override
  String get safetyCheckinTitle => 'Safety Check-in';

  @override
  String get safetyCheckinDesc =>
      'Enable check-in to ensure safety before an offline date';

  @override
  String get iAmSafe => 'I am safe';

  @override
  String get weeklyReportTitle => 'Weekly Report';

  @override
  String get promptsTitle => '3 things about you';

  @override
  String get addPrompt => 'Add answer';

  @override
  String get vibeTitle => 'Vibe / Style';

  @override
  String get vibeChill => 'Chill';

  @override
  String get vibeSerious => 'Serious';

  @override
  String get vibeAdventurous => 'Adventurous';

  @override
  String get vibeCreative => 'Creative';

  @override
  String get vibeIntellectual => 'Intellectual';

  @override
  String get vibePlayful => 'Playful';

  @override
  String get healingGateTitle => 'Check in before meeting someone new';

  @override
  String get healingGateDesc =>
      'Bondy suggests spending 2 minutes on an emotional check-in before discovering.';

  @override
  String get checkInNow => 'Check in now';

  @override
  String get later => 'Later';

  @override
  String get compatibilityReceiptTitle => 'Why did you match?';

  @override
  String get openChat => 'Open chat';
}
